;
;    Autor: Allan César           License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4MHz (XT)
;
;    Projeto: gerar um PWM de acordo com uma entrada de 2 Bytes na serial
;

     list        p=16f628a

;  - Arquivos incluídos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;  	 Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
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
   
     cblock      H'70'
       X 
       Y
       COUNTER
     endc
   
                         org     H'00'
                         goto    INIT
                         
                         org     H'04'
                         retfie                         
                        
     INIT:
                         ctb1
                         movlw   B'00000010'
                         movwf   TXSTA
                         movlw   D'25'
                         movwf   SPBRG
                         movlw   D'249'
                         movwf   PR2
                         bcf     TRISB, 3
                         ctb0
                         movlw   B'10010000'
                         movwf   RCSTA
                         movlw   B'00000111'
                         movwf   T2CON
                         movlw   B'00001111'
                         movwf   CCP1CON
                         movlw   D'10'
                         movwf   COUNTER
                         movlw   D'100'
                         movwf   CCPR1L
     
     LOOP:
                         btfss   PIR1, RCIF
                         goto    $-1
                         bcf     PIR1, RCIF
                         movlw   H'2F'
                         subwf   RCREG, W
                         movwf   X
                         
                        ; Multiplica dezena 
                         clrw
     MUL:                    
                         addwf   X, W
                         decfsz  COUNTER, F
                         goto    MUL
                         movlw   D'10'
                         movwf   COUNTER
                        ;------------------- 
                         
                         btfss   PIR1, RCIF
                         goto    $-1
                         bcf     PIR1, RCIF
                         movlw   H'2F'
                         subwf   RCREG, W
                         movwf   Y
                         
                         movf    X, W
                         addwf   Y
                         movwf   CCPR1L
                         ;bcf     STATUS, C
                         ;rrf     CCPR1L, F
                         ;bcf     STATUS, C
                         ;rrf     CCPR1L, F
                         
                         goto    LOOP
                         
                         end