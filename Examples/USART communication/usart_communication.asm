;
;    Autor: Allan César           License: CC-BY-4.0
;
;    Data: Agosto/2018
;
;    MCU Utilizada: PIC16F628A (Microchip)
;
;    Clock: 4MHz (XT)
;
;    Projeto: enviar um "A" para serial ao pressionar um botão e responder com a letra minúscula ao enviar um CAPs pela serial
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

                        btfsc   INTCON, INTF                                     ;A interrupção foi externa?
                        goto    ISR_Interruption                                 ;Sim, então trate
                        btfsc   PIR1, RCIF                                       ;Não, então foi de recepção?
                        goto    ISR_Receptor					                 ;Sim, então trate
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrupção

; - Interruption Service Routine de Externo ---------------------------------------------------------------------------------------------------------------------


ISR_Interruption:
                        bcf     INTCON, INTF                                     ;Limpa flag da interrupção externa
                        movlw   "A"                                              ;Coloca o char "A" no W
                        movwf   TXREG                                            ;Envia o W
                        goto    ISR_Exit                                         ;Vai para rotina de saída da interrupção


; - Interruption Service Routine do Receptor --------------------------------------------------------------------------------------------------------------------

ISR_Receptor:           
                        bcf     PIR1, RCIF                                       ;Limpa flag da interrupção de recepção USART
                        movf    RCREG, W                                         ;Tira o dado recebido do RCREG e move para W
                        addlw   D'32'                                            ;Addiciona 32 ao W que tinha o ASCII maiúsculo 
                        movwf   TXREG                                            ;Sai da rotina de interrupção
                        goto    ISR_Exit				
						
; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    Config_Interruptions                             ;Configura interrupções (mal encapsulado)

Loop:					

;                       ...
		
                        goto    Loop                                             ;Fecha laço
						
; - Configura Interrupções --------------------------------------------------------------------------------------------------------------------------------------

Config_Interruptions:
                        ctb1                                                     ;Muda para banco 1
                        movlw   H'FF'                                            ;W = H'FF'
                        movwf   TRISB                                            ;TRISB = W
                        movlw   D'25'                                            ;BR = Fosc / 16(SPBRG + 1)
                        movwf   SPBRG                                            ;SPBRG = 25 logo BR ~= 9600
                        movlw   B'00100110'                                      ;Don't care (Assincrono), 8 bits, transmissão ligada, modo assincrono, unused, High Speed, TSR está vazio, dont'care   
                        movwf   TXSTA                                            ;          0                 0              1                0            0         1             1             0       
                        ctb0                                                     ;Muda para banco 0
                        movlw   B'10010000'                                      ;Habilita serial, recp. 8 bits, don'care(Assincrono), recepção contínua, dont'care (8 bits), o resto é flag e fica zerado 
                        movwf   RCSTA                                            ;       1               0                0                    1                   0                   000     
                        movlw   B'00010000'                                      ;Digo que ainda não há transmissão (preciosismo)
                        movwf   PIR1                                             ;
                        movlw   B'11010000'                                      ;Habilito interrupções e interrupções dos perifericos e externa
                        movwf   INTCON                                           ;
                        ctb1                                                     ;Muda para banco 1
                        movlw   B'00100000'                                      ;Começa a permitir interrupções de recepção
                        movwf   PIE1                                             ;
                        ctb0                                                     ;Muda para banco 0
                        return				                                     ;Volta para rotina principal
						
						
                        end                                                      ;Fim do programa
											