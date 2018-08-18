;
;    Autor: Allan César         License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;    
;    Clock: 4MHz (XT)
;
;    Projeto: dois LEDs piscam em frequência diferentes e quando o botão é pressionado e os pinos dos LEDs perdem os estados (LOW)
;  

     list         p=16f628a

;  - Arquivos incluídos ----------------------------------------------------------------------------------------------------------------------------------------------------
   
     #include     <p16f628a.inc>
   
;  - FUSE bits -------------------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
;    Code Protection desligado
;
;    Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;

     __config     _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;  - Paginação de memória --------------------------------------------------------------------------------------------------------------------------------------------------
;
;    Aqui em função do espelhemento de alguns SFR nos outros bancos (2 e 3) somente essa paginação é necessária
;
 
     #define      ctb0    bcf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 0
     #define      ctb1    bsf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 1
   
;  - Variáveis ou GPRs -----------------------------------------------------------------------------------------------------------------------------------------------------
     
     cblock      H'0070'                                                         ;Inicia alocação de memória no endereço 70h
   	    
     W_TEMP                                                                      ;Auxiliar para guardar W (acumulador) antes de interrupção
     STATUS_TEMP                                                                 ;Auxiliar para guardar STATUS antes interrupção
     COUNTER0                                                                    ;Contador auxiliar do Timer 0
     COUNTER1                                                                    ;Contador auxiliar do Timer 1     
     
     endc                                                                        ;Termina alocação de memória                                                                        ;
     
;  - Vetor Reset -----------------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                         ;Endereço de origem de todo programa
                        goto    Start                                           ;Desvia do vetor de interrupção

;  - Vetor de Interrupção --------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                         ;Todas as interrupções apontam para este endereço

;  -- Context Saving -------------------------------------------------------------------------------------------------------------------------------------------------------						
;
;     Salva contexto antes de ir para rotinas de interrupção e usa SWAP para não ter uma flag Z no STATUS do contexto
;						

                        movwf   W_TEMP                                          ;W_TEMP = W(B'ZZZZ WWWW')
                        swapf   STATUS,W                                        ;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX')
                        ctb0                                                    ;Muda para banco 0 para
                        movwf   STATUS_TEMP                                     ;Salva STATUS no STATUS_TEMP
						
;  --- Chama rotinas de Interrupção ----------------------------------------------------------------------------------------------------------------------------------------

                        btfsc   INTCON, T0IF                                    ;Testa a flag de interrupção e pula uma linha se estiver zerada 
                        goto    ISR_Timer0                                      ;Chama rotina de interrupção
                        btfsc   PIR1, TMR1IF                                    ;Testa a flag de interrupção e pula uma linha se estiver zerada
                        goto    ISR_Timer1                                      ;Chama rotina de interrupção
                        btfsc   INTCON, INTF                                    ;Testa a flag de interrupção e pula uma linha se estiver zerada
                        goto    ISR_Interruption                                ;Chama rotina de interrupção
						
;  -- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------------------						

ISR_Exit:						
                        swapf   STATUS_TEMP, W                                  ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                          ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                       ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                       ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                  ;Retorna de interrupção

; - Interrupt Service Routine do Timer 0 ----------------------------------------------------------------------------------------------------------------------------------- 
			
ISR_Timer0:                 
                        bcf     INTCON, T0IF                                    ;Limpa a flag de interrupção!
                        decfsz  COUNTER0, F                                     ;Decrementa contador e salva valor nele mesmo. Se for 0 pule
                        goto    jump_if_COUNTER0_clear                          ;Não é 0, então não recarregue o valor inicial do contador e nem troque o sinal lógico do LED
                        call    Reset_Counter0                                  ;Recarrega valor no contador
                        ctb0                                                    ;Garante que estamos no Banco 0
                        movlw   B'00100000'                                     ;Valor que vamos fazer xor (inverte o bit 5)
                        xorwf   PORTB, F                                        ;PORTB = PORTB XOR W
jump_if_COUNTER0_clear:                    
                        call    Reset_Timer0                                    ;Recarrega timer 0
                        goto    ISR_Exit                                        ;Vai para rotina de interrupção
                        
; - Interrupt Service Routine do Timer 1 ----------------------------------------------------------------------------------------------------------------------------------- 
			
ISR_Timer1:                 
                        bcf     PIR1, TMR1IF                                    ;Limpa a flag de interrupção!
                        decfsz  COUNTER1, F                                     ;Decrementa contador e salva valor nele mesmo. Se for 0 pule
                        goto    jump_if_COUNTER1_clear                          ;Não é 0, então não recarregue o valor inicial do contador e nem troque o sinal lógico do LED
                        call    Reset_Counter1                                  ;Recarrega valor no contador
                        ctb0                                                    ;Garante que estamos no Banco 0
                        movlw   B'00010000'                                     ;Valor que vamos fazer xor (inverte o bit 5)
                        xorwf   PORTB, F                                        ;PORTB = PORTB XOR W
jump_if_COUNTER1_clear:                   
                        call    Reset_Timer1                                    ;Recarrega timer 0
                        goto    ISR_Exit                                        ;Vai para rotina de interrupção
                                                
; - Interrupt Service Routine do Externo ----------------------------------------------------------------------------------------------------------------------------------- 
			
ISR_Interruption:                 
                        bcf     INTCON, INTF                                    ;Limpa a flag de interrupção!
                        ctb1                                                    ;Muda para Banco 1 vamos trabalhar com OPTION
                        movlw   B'00000010'                                     ;Valor que vamos fazer xor (inverte o bit 1)
                        xorwf   OPTION_REG, F                                   ;OPTION_REG = OPTION_REG XOR W
                        ctb0                                                    ;Muda para Banco 0 (PADRÃO)
                        goto    ISR_Exit                                        ;Vai para rotina de interrupção
						
; - Início do programa -----------------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    Reset_Counter0                                  ;Inicializa contadores
                        call    Reset_Counter1                                  ;          "
                        call    Reset_Timer0                                    ;Configura antes para não dar prob. quando habilitar interrupções
                        call    Reset_Timer1                                    ;                           "
                        call    Reset_Ports                                     ;Configura inicialmente os pinos
                        call    Reset_Interruptions                             ;Habilita as interrupções e o programa está pronto!
Loop:					
                        nop                                                     ;Gasta 1 ciclo de máquina
                        nop
                        nop
                        goto    Loop                                            ;Fecha laço

; - Reset do contador do timer 0 -------------------------------------------------------------------------------------------------------------------------------------------

Reset_Counter0:                 
                        movlw   D'20'                                           ;Valor que vamos carregar no contador auxiliar do timer 0                              
                        movwf   COUNTER0                                        ;COUNTER0 = W
                        return                                                  ;Retorna para contexto do programa

; - Reset do contador do timer 1 -------------------------------------------------------------------------------------------------------------------------------------------

Reset_Counter1:
                        movlw   D'5'                                            ;Valor que vamos carregar no contador auxiliar do timer 0                              
                        movwf   COUNTER1                                        ;COUNTER = W
                        return                                                  ;Retorna para contexto do programa

; - Reset do timer 0 -------------------------------------------------------------------------------------------------------------------------------------------------------

Reset_Timer0:              
                        ctb0                                                    ;Garante que estamos no Banco 0
                        movlw   D'60'                                           ;W = D'60'
                        movwf   TMR0                                            ;TMR0 conta de 60 a 255
                        return                                                  ;Retorna para o contexto do programa
                       
; - Reset do timer 1 -------------------------------------------------------------------------------------------------------------------------------------------------------
                       
Reset_Timer1:              
                        ctb0                                                    ;Muda para banco 0
                        movlw   H'B0'                                           ;65536 - 50000 = 15536 = 3CB0h
                        movwf   TMR1L                                           ;Move o nibble inferior para TMR1L
                        movlw   H'3C'                                           ;W = nibble superior
                        movwf   TMR1H                                           ;TMR1H = W
                        return                                                  ;Retorna para contexto do programa
                              						
; - Reset de ports ---------------------------------------------------------------------------------------------------------------------------------------------------------				

Reset_Ports:				
                        ctb0                                                    ;Muda para Banco 0 para evitar erros
                        clrf    PORTA                                           ;Segundo o fabricante, colocamos como Output
                        clrf    PORTB                                           ;                     "
                        movlw   H'0007'                                         ;Bits necessários para desligar módulo comparador
                        movwf   CMCON                                           ;CMCON = W
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com TRISx
                        movlw   B'11111111'                                     ;Todos os bits do TRISA ficam como input (fabricante)
                        movwf   TRISA                                           ;TRISA = W
                        movlw   B'11001111'                                     ;Apenas o 5 e 6 bit como out no PORTB
                        movwf   TRISB                                           ;TRISB = W
                        ctb0                                                    ;Muda para Banco para inicializar pinos                       
                        return                                                  ;Retorna contextualmente para fluxo

; - Reset de interrupções --------------------------------------------------------------------------------------------------------------------------------------------------

Reset_Interruptions:       
                        ctb1                                                    ;Escolhe banco 1 para trabalhar com os enables de perifericos
                        bsf     PIE1, TMR1IE                                    ;Habilita interrupção do TMR1                        		    
                        ctb0                                                    ;Muda para Banco 0 por padrão do código
                        bcf     PIR1, TMR1IF                                    ;Limpa a flag de interrupção para evitar qualquer problema (preciosismo)
                        movlw   B'00110001'                                     ;Configura o TMR1:
                        movwf   T1CON                                           ; <7,6> Não implementado <5,4> 8 de prescale <3> Oscilador interno <2> Ignore <1> clock interno <0> Inicia timer 
                                                                                ;Tempo de um overflow = 8 * até 256 * até 256 * CY (1us) 
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com INTCON E OPTION
                        movlw   B'10010111'                                     ;W = config do OPTION
                        movwf   OPTION_REG                                      ;OPTION_REG = W
                        movlw   B'11110000'                                     ;Habilita interrupções, somente do timer 0, 1 e externa e zera os flags
                        movwf   INTCON                                          ;INTCON = W
                        ctb0                                                    ;Muda para banco 0
                        return                                                  ;Retorna contexto para programa principal


; - Fim do programa --------------------------------------------------------------------------------------------------------------------------------------------------------	
						
                        end                                                     ;Fim do programa
												