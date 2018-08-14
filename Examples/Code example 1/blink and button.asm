;
;  Autor: Allan César		License: CC-BY-4.0
;
;  Data: Agosto/2018
;
;  MCU Utilizada: PIC16F628A (Microchip)
;  Clock: 4MHz (XT)
;  

   list         p=16f628a

;  - Arquivos incluídos -----------------------------------------------------------------------------------------------------------------------------------------
   
   #include     <p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;  	 Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
;    Code Protection desligado
;
;    Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;

   __config     _XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF

;  - Paginação de memória ---------------------------------------------------------------------------------------------------------------------------------------
;
;    Aqui em função do espelhemento de alguns SFR nos outros bancos (2 e 3) somente essa paginação é necessária
;

   #define      ctb0    bcf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 0
   #define      ctb1    bsf     STATUS, RP0                                     ;Cria mnemônico p/ mudar p/ Banco de Registradores 1
   
;  - Variáveis ou GPRs ------------------------------------------------------------------------------------------------------------------------------------------
   cblock       H'000C'
   	
   W_TEMP
   STATUS_TEMP
   
   endc
;  - Vetor Reset ------------------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0000'                                         ;Endereço de origem de todo programa
                        goto    Start                                           ;Desvia do vetor de interrupção

;  - Vetor de Interrupção ---------------------------------------------------------------------------------------------------------------------------------------

                        org     H'0004'                                         ;Todas as interrupções apontam para este endereço

;  -- Context Saving --------------------------------------------------------------------------------------------------------------------------------------------						
;
;  	  Salva contexto antes de ir para rotinas de interrupção e usa SWAP para não ter uma flag Z no STATUS do contexto
;						
						movwf   W_TEMP 											;W_TEMP = W(B'ZZZZ WWWW')
						swapf 	STATUS,W 										;W = STATUS(B'XXXX YYYY' -> B'YYYY XXXX') 
						ctb0 												    ;Muda para banco 0 para
						movwf 	STATUS_TEMP 									;Salva STATUS no STATUS_TEMP
						
;  --- Rotinas de Interrupção -----------------------------------------------------------------------------------------------------------------------------------

;  	   ...						
						
;  -- Get Back Context ------------------------------------------------------------------------------------------------------------------------------------------						
						
                        swapf   STATUS_TEMP, W                                  ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                          ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                       ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                       ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
					
                        retfie                                                  ;Retorna de interrupção
						
; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        call    PinsRst
                        call    InterruptionsRst
Loop:					
						
                        goto    Loop                                            ;Fecha laço
						
; - 'Reseta' pinos ---------------------------------------------------------------------------------------------------------------------------------------------						

PinsRst:				
                        ctb0                                                    ;Muda para Banco 0 para evitar erros
                        clrf    PORTA                                           ;Segundo o fabricante, colocamos como Output
                        clrf    PORTB                                           ;
                        movlw   H'0007'                                         ;Bits necessários para desligar módulo comparador
                        movwf   CMCON                                           ;CMCON = W
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com TRISx
                        movlw   B'11111111'                                     ;Todos os bits do TRISA ficam como input (fabricante)
                        movwf   TRISA                                           ;TRISA = W
						movlw   B'11011111'                                     ;Apenas o 6 bit como out no PORTB
						movwf   TRISB                                           ;TRISB = W
						ctb0                                                    ;Muda para Banco para inicializar pinos
					    return                                                  ;Retorna contexto para programa principal

; - 'Reset' interrupções ---------------------------------------------------------------------------------------------------------------------------------------

InterruptionsRst:       
                        ctb1                                                    ;Muda para Banco 1 para trabalhar com INTCON E OPTION
                        movlw   B'10010111'                                     ;W = config do OPTION
                        movwf   OPTION_REG                                      ;OPTION_REG = W
                        movlw   B'10110000'                                     ;Habilita interrupções, somente do timer 0 e externa e zera os flags
                        movwf   INTCON                                          ;INTCON = W		    
                        ctb0                                                    ;Muda para Banco 0 por padrão do código
					    return                                                  ;Retorna contexto para programa principal
					    
; - Fim do programa --------------------------------------------------------------------------------------------------------------------------------------------		
						end														;Fim do programa
												