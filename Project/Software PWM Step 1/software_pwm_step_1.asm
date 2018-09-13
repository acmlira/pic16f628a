;
;    Autor: Allan César		License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 16MHz (XT)
;  
;    Projeto: Fazer um led ficar aceso durante 1.5 ms em em uma frequência de 50Hz, em seguida aplicar isso a um servo motor 
;             Saída = RB4 
;

     list        p=16f628a

;  - Arquivos incluídos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
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
     DUTY   
   
     endc                                                                        ;Termina alocação de memória
     
;  - Vetor Reset ------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                          ;Endereço de origem de todo programa
                        goto    Start                                            ;Desvia do vetor de interrupção

;  - Vetor de Interrupção ---------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                          ;Todas as interrupções apontam para este endereç

;  --- Context Saving -------------------------------------------------------------------------------------------------------------------------------------------						
;
;      Salva contexto antes de ir para rotinas de interrupção e usa SWAP para não ter uma flag Z no STATUS do contexto
;						

						
                        movwf   W_TEMP                                           ;W_TEMP = W(B'ZZZZ WWWW')
                        swapf   STATUS,W                                         ;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX') 
                        ctb0                                                     ;Muda para banco 0 para
                        movwf   STATUS_TEMP                                      ;Salva STATUS no STATUS_TEMP
						
;  ----- Rotinas de Interrupção ---------------------------------------------------------------------------------------------------------------------------------

                        btfsc   INTCON, T0IF
                        goto    ISR_T0
                        btfsc   PIR1, TMR1IF
                        goto    ISR_T1
                        btfsc   PIR1, TMR2IF
                        goto    ISR_T2
						goto    ISR_Exit
						
ISR_T0:
                        bcf     INTCON, T0IF
                        bcf     INTCON, T0IE
                        movlw   D'227'
                        movwf   TMR0
                        btfss   PORTB, 5
                        goto    DEC_Duty
                        btfss   PORTB, 6
                        goto    INC_Duty
                        goto    ISR_Exit					
						
INC_Duty:
						movf    DUTY, W
                        xorlw   D'0'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        decf    DUTY, f
                        goto    ISR_Exit

DEC_Duty:
						movf    DUTY, W
                        xorlw   D'247'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        incf    DUTY, f
                        goto    ISR_Exit
						
ISR_T1:
                        bcf     PIR1, TMR1IF						
						bsf     PORTB, 4
				        bsf     T2CON, TMR2ON
						
						movlw   H'F0'
                        movwf   TMR1L
                        movlw   H'D8'
                        movwf   TMR1H
                        goto    ISR_Exit
                     
ISR_T2:                 
                        bcf     PIR1, TMR2IF
                        bcf     PORTB, 4
                        bcf     T2CON, TMR2ON 
                        movf    DUTY, W
                        movwf   TMR2
                        bsf     INTCON, T0IE
Pass:                        
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
                        movlw   D'0'
                        movwf   DUTY
                        
                        ctb1
                        movlw   B'00000011'
                        movwf   PIE1
                        
                        bcf     TRISB, 4
                        movlw   B'00000001'
                        movwf   OPTION_REG
                        
                        movlw   D'247'
                        movwf   PR2
                        
                        ctb0
                        movlw   B'11100000'
                        movwf   INTCON
                        
                        movlw   D'227'
                        movwf   TMR0
                        
                        movlw   H'F0'
                        movwf   TMR1L
                        movlw   H'D8'
                        movwf   TMR1H
                        
                        movlw   B'00110001'
                        movwf   T1CON
                        movlw   B'00001011'
                        movwf   T2CON
                        
;                       ...

; - Rotina de loop para trabalhos contínuos ---------------------------------------------------------------------------------------------------------------------

Loop:					

;                       ...
		
                        goto    Loop                                             ;Fecha laço			
                        end                                                      ;Fim do programa