;
;    Autor: Allan C�sar		License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4 (XT)
;  
;    Projeto: Fazer um PWM por hardware
;
;             Ciclo PWM = (PR2 + 1) x Prescale do TMR2 x (4 / Fosc) x ((CCPR1L + 1) / 256) = 4ms ou 250kHz
;                           
;             *tudo isso quando Duty Cycle for 100% ou seja CCPR1L = 255  
;             
;             Bot�es de inc. e dec. no RB4 e no RB5, respectivamente
;

     list        p=16f628a

;  - Arquivos inclu�dos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, desliga a fun��o Reset do pino RA5, desliga BOD, LVP desligado, Data e
;    Code Protection desligado
;
;    Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;

     __config    _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;  - Pagina��o de mem�ria ---------------------------------------------------------------------------------------------------------------------------------------
;
;    Aqui em fun��o do espelhemento de alguns SFR nos outros bancos (2 e 3) somente essa pagina��o � necess�ria
;

     #define     ctb0    bcf     STATUS, RP0                                     ;Cria mnem�nico p/ mudar p/ Banco de Registradores 0
     #define     ctb1    bsf     STATUS, RP0                                     ;Cria mnem�nico p/ mudar p/ Banco de Registradores 1
   
;  - Vari�veis ou GPRs ------------------------------------------------------------------------------------------------------------------------------------------

     cblock      H'0070'                                                         ;Inicia aloca��o de mem�ria no endere�o 70h
   	    
     W_TEMP                                                                      ;Auxiliar para guardar W (acumulador) antes de interrup��o
     STATUS_TEMP                                                                 ;Auxiliar para guardar STATUS antes interrup��o
     DUTY
     
     endc                                                                        ;Termina aloca��o de mem�ria
     
;  - Vetor Reset ------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                          ;Endere�o de origem de todo programa
                        goto    Start                                            ;Desvia do vetor de interrup��o

;  - Vetor de Interrup��o ---------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                          ;Todas as interrup��es apontam para este endere�o

;  --- Context Saving -------------------------------------------------------------------------------------------------------------------------------------------						
;
;      Salva contexto antes de ir para rotinas de interrup��o e usa SWAP para n�o ter uma flag Z no STATUS do contexto
;						
						
                        movwf   W_TEMP                                           ;W_TEMP = W(B'ZZZZ WWWW')
                        swapf   STATUS,W                                         ;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX') 
                        ctb0                                                     ;Muda para banco 0 para
                        movwf   STATUS_TEMP                                      ;Salva STATUS no STATUS_TEMP
						
;  ----- Rotinas de Interrup��o ---------------------------------------------------------------------------------------------------------------------------------
;       
;        Aqui teremos um l�gica de varredura utilizando o T0, novamente, isso � opcional. Por que fazer? Acho massa
;
                        btfss   INTCON, T0IF                                     ;O flag do timer 0 � 1?
                        goto    ISR_Exit                                         ;N�o, ent�o sai da interrup��o
                        bcf     INTCON, T0IF                                     ;Sim, ent�o limpa o flag
                        movlw   D'108'                                           ;Reinicia o tempo de varredura dos bot�es
                        movwf   TMR0                                             ;Coloca esse tempo no TMR0 para efetivar o reinicio 
                        btfss   PORTB, RB4                                       ;O bot�o de incremento foi pressionado (est� em 0) ?
                        goto    inc_PWM                                          ;Sim, incremente o meu Duty Cycle (em porcentagem)
                        btfss   PORTB, RB5                                       ;N�o, ent�o o de decremento foi pressionado (est� em 0)?
                        goto    dec_PWM                                          ;Sim, decremente o meu Duty Cycle (em porcentagem)
                        goto    ISR_Exit                                         ;N�o, ent�o saia da interrup��o
                        
                        
inc_PWM:                
                        movlw   D'255'                                           ;Coloca o valor a ser comparado com o CCPR1L em W
                        xorwf   CCPR1L, W                                        ;Se for igual a 200 minha opera��o vai gerar um Z = 1
                        btfsc   STATUS, Z                                        ;O flag Z do STATUS est� em 0?
                        goto    ISR_Exit                                         ;N�o, ent�o desvie para sa�da
                        incf    CCPR1L, F                                        ;Sim ent�o pode incrementar (n�o chegou ao m�ximo)
                        goto    ISR_Exit                                         ;Saia da interrup��o

dec_PWM:                
                        movlw   D'0'                                             ;Coloca o valor a ser comparado com o CCPR1L em W
                        xorwf   CCPR1L, W                                        ;Se for igual a 0 minha opera��o vai gerar um Z = 1
                        btfsc   STATUS, Z                                        ;O flag Z do STATUS est� em 0?
                        goto    ISR_Exit                                         ;N�o, ent�o desvie para sa�da
                        decf    CCPR1L, F                                        ;Sim ent�o pode decrementar (n�o chegou ao m�nimo)
                        goto    ISR_Exit                                         ;Saia da interrup��o

;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrup��o
					
                        
						
; - In�cio do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        ctb1                                                     ;Muda para banco 0
                        movlw   B'01010110'                                      ;Como queremos fazer um PWM alter�vel: ativamos os pull-ups do PORTB, incrementamos com clock interno
                        movwf   OPTION_REG                                       ;                                      usamos prescale 1:128 no timer 0
                        movlw   B'11110111'                                      ;OBRIGAT�RIO: configuramos o pino do PWM como OUT
                        movwf   TRISB                                            ;TRISB = W
                        movlw   D'255'                                           ;Colocamos o ciclo PWM para 4ms ou 250kHz
                        movwf   PR2                                              ;Lembrando: PWM = (PR2 + 1) x Prescale do TMR2 x (4 / Fosc) x ((CCPR1L + 1) / 256) = 4ms ou 250kHz
                                                                                 ;tudo isso quando Duty Cycle for 100% ou seja CCPR1L = 255
                        ctb0                                                     ;Muda para banco 1
                        movlw   B'00000111'                                      ;Desativa comparador
                        movwf   CMCON                                            ;CMCON = W
                        movlw   H'A0'                                            ;Habilita interrup��o geral e do Timer 0
                        movwf   INTCON                                           ;Isso tudo � opcional, faremos a varredura para ajuste fino do PWM   
                        movlw   B'00000110'                                      ;Habilita Timer 2 com prescale m�ximo 1:16
                        movwf   T2CON                                            ;Timer 2 � OBRIGAT�RIO 
                        clrf    CCPR1L                                           ;Duty cyle come�a em 0% 
                        movlw   H'3C'                                            ;Habilito o modo PWM (001111xx)
                        movwf   CCP1CON                                          ;TUDO PRONTO

; - Rotina de loop para trabalhos cont�nuos ---------------------------------------------------------------------------------------------------------------------
		
                        goto    $                                                ;Fecha la�o
               						
                        end                                                      ;Fim do programa