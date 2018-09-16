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

     #define     ctb0           bcf     STATUS, RP0                               ;Cria mnemônico p/ mudar p/ Banco de Registradores 0
     #define     ctb1           bsf     STATUS, RP0                               ;Cria mnemônico p/ mudar p/ Banco de Registradores 1
     #define     high_pwm_1     bsf     PORTB, 4
     #define     low_pwm_1      bcf     PORTB, 4
     #define     test_inc_pwm   btfss   PORTB, 5
     #define     test_dec_pwm   btfss   PORTB, 6
     #define     high_pwm_2     bsf     PORTB, 1
     #define     low_pwm_2      bcf     PORTB, 1
     #define     high_pwm_3     bsf     PORTB, 2
     #define     low_pwm_3      bcf     PORTB, 2
     #define     high_pwm_4     bsf     PORTB, 3
     #define     low_pwm_4      bcf     PORTB, 3
     
     cblock      H'0070'                                                         ;Inicia alocação de memória no endereço 70h
   	    
     DUTY   
     flag
     duty1 
     duty2
     duty3
     duty4
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
                        test_inc_pwm
                        goto    incf_DUTY
                        test_dec_pwm
                        goto    decf_DUTY
                        goto    ISR_Exit
						
ISR_TMR1:
                        bcf     PIR1, TMR1IF						
						call    recharge_TMR1
						
						btfss   flag, 0
						goto    $+3
						movf    duty1, W
						high_pwm_1 
                        btfss   flag, 1
                        goto    $+3
                        movf    duty2, W
                        high_pwm_2
                        btfss   flag, 2
                        goto    $+3
                        movf    duty3, W
                        high_pwm_3
                        btfss   flag, 3
                        goto    $+3
                        movf    duty4, W
                        high_pwm_4
                        
						movwf   DUTY
						call    recharge_TMR2_with_DUTY
	                    bsf     T2CON, TMR2ON
                        goto    ISR_Exit
                     
ISR_TMR2:                 
                        bcf     PIR1, TMR2IF
                        
                        btfss   flag, 0
						goto    $+2
						low_pwm_1 
                        btfss   flag, 1
                        goto    $+2
                        low_pwm_2
                        btfss   flag, 2
                        goto    $+2
                        low_pwm_3
                        btfss   flag, 3
                        goto    $+2
                        low_pwm_4
                        
                        
                        bcf     T2CON, TMR2ON 
                        
                        bcf     STATUS, C
						rlf     flag
                        btfsc   flag, 4
                        call    reset_flag
                        
                        
                        bsf     INTCON, T0IE
                        goto    ISR_Exit                
             						
ISR_Exit:
                        retfie

incf_DUTY:
						movf    duty1, W
                        xorlw   D'0'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        decf    duty1, f
                        goto    ISR_Exit

decf_DUTY:
						movf    duty1, W
                        xorlw   D'247'
                        btfsc   STATUS, Z
                        goto    ISR_Exit
                        incf    duty1, f
                        goto    ISR_Exit

; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        
                        
                        call    reset_flag
                        call    reset_var
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
                        movlw   H'3C'
                        movwf   TMR1L
                        movlw   H'F6'
                        movwf   TMR1H
                        return

recharge_TMR2_with_DUTY:        
                        ctb0
                        movf    DUTY, W
                        movwf   TMR2
                        return

configure_PORTx:            
                        ctb1
                        movlw   B'11100001'  
                        movwf   TRISB
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
reset_flag:
                        movlw   B'00000001'
                        movwf   flag
                        return
 
reset_var:              
                        clrf    duty1
                        clrf    duty2
                        clrf    duty3
                        clrf    duty4
                        return
                        
                        end                                                      ;Fim do programa 