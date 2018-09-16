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

     #include    <p16f628a.inc>
     __config    _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

     #define     ctb0    bcf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 0
     #define     ctb1    bsf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 1

     cblock      H'0070'                                                         ;Inicia alocação de memória no endereço 70h
   	    
     DUTY   
   
     endc                                                                        ;Termina alocação de memória
   
                        org     H'0000'                                          ;Endereço de origem de todo programa
                        goto    Start                                            ;Desvia do vetor de interrupção
                        
                        org     H'0004'                                          ;Todas as interrupções apontam para este endereç
                        btfsc   INTCON, T0IF
                        goto    ISR_TMR0
                        btfsc   PIR1, TMR1IF
                        goto    ISR_TMR1
                        btfsc   PIR1, TMR2IF
                        goto    ISR_TMR2
						goto    ISR_Exit
						
ISR_TMR0:
                        bcf     INTCON, T0IF
                        bcf     INTCON, T0IE
                        call    recharge_TMR0
                        btfss   PORTB, 5
                        goto    decf_DUTY
                        btfss   PORTB, 6
                        goto    incf_DUTY
                        goto    ISR_Exit
						
ISR_TMR1:
                        bcf     PIR1, TMR1IF						
						bsf     PORTB, 4
				        bsf     T2CON, TMR2ON
						call    recharge_TMR1
                        goto    ISR_Exit
                     
ISR_TMR2:                 
                        bcf     PIR1, TMR2IF
                        bcf     PORTB, 4
                        bcf     T2CON, TMR2ON 
                        call    recharge_TMR2_with_DUTY
                        bsf     INTCON, T0IE
                        goto    ISR_Exit                
             						
ISR_Exit:
                        retfie

incf_DUTY:
						movf    DUTY, W
                        xorlw   D'0'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        decf    DUTY, f
                        goto    ISR_Exit

decf_DUTY:
						movf    DUTY, W
                        xorlw   D'247'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        incf    DUTY, f
                        goto    ISR_Exit

; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        
                        
                        call    configure_PORTx
                        call    recharge_TMR0
                        call    recharge_TMR1
                        clrf    DUTY
                        call    recharge_TMR2_with_DUTY
                        call    configure_TMRx
                        call    configure_Interruptions      
                        
Loop:					                    
                        nop
                        nop
                        nop
                        nop
                        nop
                        nop
                        nop
                        nop
                        nop
                        goto    Loop                                             ;Fecha laço

recharge_TMR0:
                        ctb0    
                        movlw   D'227'
                        movwf   TMR0
                        return
                        
recharge_TMR1:
                        ctb0
                        movlw   H'F0'
                        movwf   TMR1L
                        movlw   H'D8'
                        movwf   TMR1H
                        return

recharge_TMR2_with_DUTY:        
                        ctb0
                        movf    DUTY, W
                        movwf   TMR2
                        return

configure_PORTx:            
                        ctb1
                        bcf     TRISB, 4
                        ctb0
                        return
                        
configure_TMRx:
                        ctb1
                        movlw   B'00000001'
                        movwf   OPTION_REG
                        movlw   D'247'
                        movwf   PR2
                        ctb0
                        movlw   B'00110001'
                        movwf   T1CON
                        movlw   B'00001011'
                        movwf   T2CON
                        return
                       
configure_Interruptions:
                        ctb1
                        movlw   B'00000011'
                        movwf   PIE1
                        ctb0
                        movlw   B'11100000'
                        movwf   INTCON	
                        return  
                        
                        end                                                      ;Fim do programa 