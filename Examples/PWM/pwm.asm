;
;    Autor: Allan César		License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4 (XT)
;  
;    Projeto: 1º Criar um sinal alterável em RB1 com botão em RB0 usando Timer 2
;
;             Célculo do Timer 2: prescale x postscale x ciclo de maquina x PR2
;                                   1:4    x     1:4   x        1E-6      x  64    =    1,024ms                        
;

     list        p=16f628a

;  - Arquivos incluídos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, desliga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
;    Code Protection desligado
;
;    Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;

     __config    _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;  - Paginação de memória ---------------------------------------------------------------------------------------------------------------------------------------
;
;    Aqui em função do espelhemento de alguns SFR nos outros bancos (2 e 3) somente essa paginação é necessária
;

     #define     ctb0    bcf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 0
     #define     ctb1    bsf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 1
   
;  - Variáveis ou GPRs ------------------------------------------------------------------------------------------------------------------------------------------

     cblock      H'0070'                                                         ;Inicia alocação de memória no endereço 70h
   	    
     W_TEMP                                                                      ;Auxiliar para guardar W (acumulador) antes de interrupção
     STATUS_TEMP                                                                 ;Auxiliar para guardar STATUS antes interrupção
     
     endc                                                                        ;Termina alocação de memória
     
;  - Vetor Reset ------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                          ;Endereço de origem de todo programa
                        goto    Start                                            ;Desvia do vetor de interrupção

;  - Vetor de Interrupção ---------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                          ;Todas as interrupções apontam para este endereço

;  --- Context Saving -------------------------------------------------------------------------------------------------------------------------------------------						
;
;      Salva contexto antes de ir para rotinas de interrupção e usa SWAP para não ter uma flag Z no STATUS do contexto
;						
						
                        movwf   W_TEMP                                           ;W_TEMP = W(B'ZZZZ WWWW')
                        swapf   STATUS,W                                         ;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX') 
                        ctb0                                                     ;Muda para banco 0 para
                        movwf   STATUS_TEMP                                      ;Salva STATUS no STATUS_TEMP
						
;  ----- Rotinas de Interrupção ---------------------------------------------------------------------------------------------------------------------------------

                        btfsc   INTCON, INTF
                        goto    ISR_Int	
                        btfsc   PIR1, TMR2IF
                        goto    ISR_Timer2
                        
; - Interruption Service Routine Int ----------------------------------------------------------------------------------------------------------------------------

ISR_Int:
                        bcf     INTCON, INTF
                        ctb1
                        movf    PR2, W
                        addlw   D'128'
                        movwf   PR2
                        ctb0
                        goto    ISR_Exit
                        
; - Interruption Service Routine Timer 2 ------------------------------------------------------------------------------------------------------------------------

ISR_Timer2:     
                        bcf     PIR1, TMR2IF
                        comf    PORTB
                        goto    ISR_Exit				
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrupção
					
                        
						
; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    Reset_Interruptions
                        call    Reset_Timer2
                        ctb1   
                        movlw   B'11111101'
                        movwf   TRISB
                        ctb0
                        bcf     PORTB, RB1
                        
;                       ...

; - Rotina de loop para trabalhos contínuos ---------------------------------------------------------------------------------------------------------------------

Loop:					

;                       ...
		
                        goto    Loop                                             ;Fecha laço

; - Reset do modulo comparador ----------------------------------------------------------------------------------------------------------------------------------

Reset_Comparator:                        
                        ctb0                                                     ;Muda para banco 0 p/ trabalhar com CMCON
                        movlw   H'0007'                                          ;Desabilita CMCON
                        movwf   CMCON                                            ;CMCON = W
                        return                                                   ;Retorna contextualmente para o programa
                        
; - Reset das Interrupções --------------------------------------------------------------------------------------------------------------------------------------                        

Reset_Interruptions:
                        ctb1
                        bsf     PIE1, TMR2IE
                        ctb0
                        movlw   B'11010000'
                        movwf   INTCON
                        return

; - Reset do Timer 2 --------------------------------------------------------------------------------------------------------------------------------------------

Reset_Timer2:
                        ctb1
                        movlw   D'64'
                        movwf   PR2
                        ctb0
                        movlw   B'00100101'
                        movwf   T2CON
                        clrf    TMR2
                        return                        
                        
                        
                        						
                        end                                                      ;Fim do programa