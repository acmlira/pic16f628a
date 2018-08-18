;
;    Autor: Allan C�sar		License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4MHz (XT)
;
;    Projeto: Piscar led na frequencia primeiro de 0,5 Hz, se apertar o bot�o essa frequ�ncia deve ser aumentada drasticamente
;             usando interrup��es.
;

     list         p=16f628a

;  - Arquivos inclu�dos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include     <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a fun��o Reset do pino RA5, desliga BOD, LVP desligado, Data e
;    Code Protection desligado
;
;    Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;

     __config     _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;  - Pagina��o de mem�ria ---------------------------------------------------------------------------------------------------------------------------------------
;
;    Aqui em fun��o do espelhemento de alguns SFR nos outros bancos (2 e 3) somente essa pagina��o � necess�ria
;
     
     #define     ctb0    bcf     STATUS, RP0                                    ;Cria mnem�nico p/ mudar p/ Banco de Registradores 0
     #define     ctb1    bsf     STATUS, RP0                                    ;Cria mnem�nico p/ mudar p/ Banco de Registradores 1
     
;  - Vari�veis ou GPRs ------------------------------------------------------------------------------------------------------------------------------------------
     
     cblock      H'0070'                                                        ;Inicia aloca��o de mem�ria no endere�o 70h
   	    
     W_TEMP                                                                     ;Auxiliar para guardar W (acumulador) antes de interrup��o
     STATUS_TEMP                                                                ;Auxiliar para guardar STATUS antes interrup��o
     COUNTER                                                                    ;Contador auxiliar
     
     endc                                                                       ;Termina aloca��o de mem�ria
     
;  - Vetor Reset ------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                         ;Endere�o de origem de todo programa
                        goto    Start                                           ;Desvia do vetor de interrup��o

;  - Vetor de Interrup��o ---------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                         ;Todas as interrup��es apontam para este endere�o

;  --- Context Saving -------------------------------------------------------------------------------------------------------------------------------------------						
;
;      Salva contexto antes de ir para rotinas de interrup��o e usa SWAP para n�o ter uma flag Z no STATUS do contexto
;						

                        movwf   W_TEMP                                          ;W_TEMP = W(B'ZZZZ WWWW')
                        swapf   STATUS,W                                        ;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX') 
                        ctb0                                                    ;Muda para banco 0 por padr�o
                        movwf   STATUS_TEMP                                     ;Salva STATUS no STATUS_TEMP
						
;  ----- Chama rotinas de Interrup��o ---------------------------------------------------------------------------------------------------------------------------

                        btfsc   INTCON, T0IF                                    ;Testa a flag de interrup��o e pula uma linha se estiver zerada 
                        goto    ISR_Timer0                                      ;Chama rotina de interrup��o
                        btfsc   INTCON, INTF                                    ;Testa a flag de interrup��o e pula uma linha se estiver zerada
                        goto    ISR_Interruption                                ;Chama rotina de interrup��o
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						

ISR_Exit:						
                        swapf   STATUS_TEMP, W                                  ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                          ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                       ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                       ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                  ;Retorna de interrup��o

; - Interrupt Service Routine do Timer 0 ------------------------------------------------------------------------------------------------------------------------
			
ISR_Timer0:                 
                        bcf     INTCON, T0IF                                    ;Limpa a flag de interrup��o!
                        decfsz  COUNTER, F                                      ;Decrementa contador e salva valor nele mesmo. Se for 0 pule
                        goto    jump_if_COUNTER_clear                           ;N�o � 0, ent�o n�o recarregue o valor inicial do contador e nem troque o sinal l�gico do led 
                        call    Reset_Counter                                   ;Recarrega valor no contador 
                        ctb0                                                    ;Garante que estamos no Banco 0
                        movlw   B'00100000'                                     ;Valor que vamos fazer xor (inverte o bit 5)
                        xorwf   PORTB, F                                        ;PORTB = PORTB XOR W
jump_if_COUNTER_clear:
                        call    Reset_Timer0                                    ;Recarrega timer 0
                        goto    ISR_Exit                                        ;Vai para rotina de sa�da de interrup��o
                                                
; - Interrupt Service Routine do Externo ------------------------------------------------------------------------------------------------------------------------
			
ISR_Interruption:                 
                        bcf     INTCON, INTF                                    ;Limpa a flag de interrup��o!
                        ctb1                                                    ;Muda para Banco 1 vamos trabalhar com OPTION
                        movlw   B'00000010'                                     ;Valor que vamos fazer xor (inverte o bit 1)
                        xorwf   OPTION_REG, F                                   ;OPTION_REG = OPTION_REG XOR W
                        ctb0                                                    ;Muda para Banco 0 (PADR�O)
                        goto    ISR_Exit                                        ;Retorna para rotina de sa�da de interrup��o
						
; - In�cio do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    Reset_Counter                                   ;Inicializa vari�veis
                        call    Reset_Timer0                                    ;Configura antes para n�o dar prob. quando habilitar interrup��es
                        call    Reset_Ports                                     ;Configura inicialmente os pinos
                        call    Reset_Interruptions                             ;Habilita as interrup��es e o programa est� pronto!
Loop:					
                        nop                                                     ;Gasta 1 ciclo de m�quina
                        nop                                                     ;            "
                        nop                                                     ;            "
                        goto    Loop                                            ;Fecha la�o

; - Reset do modulo comparador ----------------------------------------------------------------------------------------------------------------------------------

Reset_Comparator:                        
                        ctb0                                                    ;Muda para banco 0 p/ trabalhar com CMCON
                        movlw   H'0007'                                         ;Desabilita CMCON
                        movwf   CMCON                                           ;CMCON = W
                        return                                                  ;Retorna contextualmente para o programa
						
; - Reset contador (COUNTER) ------------------------------------------------------------------------------------------------------------------------------------

Reset_Counter:                 
                        movlw   D'10'                                           ;Valor que vamos carregar no contador auxiliar do timer 0                              
                        movwf   COUNTER                                         ;COUNTER = W
                        return                                                  ;Retorna para contexto do programa

; - Reset timer 0 -----------------------------------------------------------------------------------------------------------------------------------------------

Reset_Timer0:              
                        ctb0                                                    ;Garante que estamos no Banco 0
                        movlw   D'60'                                           ;W = D'60'
                        movwf   TMR0                                            ;TMR0 conta de 60 a 255
                        return                                                  ;Retorna para o contexto do programa
                        						
; - Reset ports -------------------------------------------------------------------------------------------------------------------------------------------------						

Reset_Ports:				
                        ctb0                                                    ;Muda para Banco 0 para evitar erros
                        clrf    PORTA                                           ;Segundo o fabricante, colocamos como Output
                        clrf    PORTB                                           ;                    "
                        movlw   H'0007'                                         ;Bits necess�rios para desligar m�dulo comparador
                        movwf   CMCON                                           ;CMCON = W
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com TRISx
                        movlw   B'11111111'                                     ;Todos os bits do TRISA ficam como input (fabricante)
                        movwf   TRISA                                           ;TRISA = W
                        movlw   B'11011111'                                     ;Apenas o 6 bit como out no PORTB
                        movwf   TRISB                                           ;TRISB = W
                        ctb0                                                    ;Muda para Banco para inicializar pinos
                        return                                                  ;Retorna contexto para programa principal

; - Reset interrup��es ------------------------------------------------------------------------------------------------------------------------------------------

Reset_Interruptions:       
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com INTCON E OPTION
                        movlw   B'10010111'                                     ;W = config do OPTION
                        movwf   OPTION_REG                                      ;OPTION_REG = W
                        movlw   B'10110000'                                     ;Habilita interrup��es, somente do timer 0 e externa e zera os flags
                        movwf   INTCON                                          ;INTCON = W		    
                        ctb0                                                    ;Muda para Banco 0 por padr�o do c�digo
                        return                                                  ;Retorna contexto para programa principal
				



                        end                                                     ;Fim do programa						