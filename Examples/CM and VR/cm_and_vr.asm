;
;    Autor: Allan C�sar		License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: ?? (XT)
;  
;    Projeto: ??
;

     list        p=16f628a

;  - Arquivos inclu�dos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;    Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a fun��o Reset do pino RA5, desliga BOD, LVP desligado, Data e
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

                        bcf     PIR1, CMIF
                        bsf     PORTB, 7
                        btfss   CMCON, C2OUT
                        bcf     PORTB, 7
                        goto    ISR_Exit			
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrup��o
						
; - In�cio do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        ctb1
                        bsf     TRISA, RA1
                        bsf     TRISA, RA2
                        bcf     TRISB, RB7
                        movlw   B'10001000'
                        movwf   VRCON
                        movlw   B'01000000'
                        movwf   PIE1
                        
                        ctb0
                        movlw   B'00101010'
                        movwf   CMCON
                        
                        movlw   B'11000000'
                        movwf   INTCON
;                       ...

; - Rotina de loop para trabalhos cont�nuos ---------------------------------------------------------------------------------------------------------------------

Loop:					

;                       ...
		
                        goto    Loop                                             ;Fecha la�o

; - Reset do modulo comparador ----------------------------------------------------------------------------------------------------------------------------------

Reset_Comparator:                        
                        ctb0                                                     ;Muda para banco 0 p/ trabalhar com CMCON
                        movlw   H'0007'                                          ;Desabilita CMCON
                        movwf   CMCON                                            ;CMCON = W
                        return                                                   ;Retorna contextualmente para o programa
                        
                        
                        
                        
                        						
                        end                                                      ;Fim do programa