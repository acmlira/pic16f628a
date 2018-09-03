;
;    Autor: Allan C�sar           License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4MHz (XT)
;
;    Projeto: enviar um "A" para serial ao pressionar um bot�o e responder com a letra min�scula ao enviar um CAPs pela serial
;

     list        p=16f628a

;  - Arquivos inclu�dos -----------------------------------------------------------------------------------------------------------------------------------------
   
     #include    <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;  	 Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a fun��o Reset do pino RA5, desliga BOD, LVP desligado, Data e
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

                        btfsc   INTCON, INTF                                     ;A interrup��o foi externa?
                        goto    ISR_Interruption                                 ;Sim, ent�o trate
                        btfsc   PIR1, RCIF                                       ;N�o, ent�o foi de recep��o?
                        goto    ISR_Receptor					                 ;Sim, ent�o trate
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrup��o

; - Interruption Service Routine de Externo ---------------------------------------------------------------------------------------------------------------------


ISR_Interruption:
                        bcf     INTCON, INTF                                     ;Limpa flag da interrup��o externa
                        movlw   "A"                                              ;Coloca o char "A" no W
                        movwf   TXREG                                            ;Envia o W
                        goto    ISR_Exit                                         ;Vai para rotina de sa�da da interrup��o


; - Interruption Service Routine do Receptor --------------------------------------------------------------------------------------------------------------------

ISR_Receptor:           
                        bcf     PIR1, RCIF                                       ;Limpa flag da interrup��o de recep��o USART
                        movf    RCREG, W                                         ;Tira o dado recebido do RCREG e move para W
                        addlw   D'32'                                            ;Addiciona 32 ao W que tinha o ASCII mai�sculo 
                        movwf   TXREG                                            ;Sai da rotina de interrup��o
                        goto    ISR_Exit				
						
; - In�cio do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    Config_Interruptions                             ;Configura interrup��es (mal encapsulado)

Loop:					

;                       ...
		
                        goto    Loop                                             ;Fecha la�o
						
; - Configura Interrup��es --------------------------------------------------------------------------------------------------------------------------------------

Config_Interruptions:
                        ctb1                                                     ;Muda para banco 1
                        movlw   H'FF'                                            ;W = H'FF'
                        movwf   TRISB                                            ;TRISB = W
                        movlw   D'25'                                            ;BR = Fosc / 16(SPBRG + 1)
                        movwf   SPBRG                                            ;SPBRG = 25 logo BR ~= 9600
                        movlw   B'00100110'                                      ;Don't care (Assincrono), 8 bits, transmiss�o ligada, modo assincrono, unused, High Speed, TSR est� vazio, dont'care   
                        movwf   TXSTA                                            ;          0                 0              1                0            0         1             1             0       
                        ctb0                                                     ;Muda para banco 0
                        movlw   B'10010000'                                      ;Habilita serial, recp. 8 bits, don'care(Assincrono), recep��o cont�nua, dont'care (8 bits), o resto � flag e fica zerado 
                        movwf   RCSTA                                            ;       1               0                0                    1                   0                   000     
                        movlw   B'00010000'                                      ;Digo que ainda n�o h� transmiss�o (preciosismo)
                        movwf   PIR1                                             ;
                        movlw   B'11010000'                                      ;Habilito interrup��es e interrup��es dos perifericos e externa
                        movwf   INTCON                                           ;
                        ctb1                                                     ;Muda para banco 1
                        movlw   B'00100000'                                      ;Come�a a permitir interrup��es de recep��o
                        movwf   PIE1                                             ;
                        ctb0                                                     ;Muda para banco 0
                        return				                                     ;Volta para rotina principal
						
						
                        end                                                      ;Fim do programa
											