;
;    Autor: Allan César		License: CC-BY-4.0
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
     
     A0                                                                          ;Armazena o conteúdo de um dos números a serem multiplicados ou dividos
     B0                                                                          ;Armazena o conteúdo de um dos números a serem multiplicados ou dividos
     C0                                                                          ;Byte menos significativo do resultado
     C1                                                                          ;Byte mais significativo do resultado
 
     
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

;        ...						
						
;  --- Get Back Context -----------------------------------------------------------------------------------------------------------------------------------------						
						
ISR_Exit:
                        swapf   STATUS_TEMP, W                                   ;W = STATUS_TEMP(B'YYYY XXXX' -> B'XXXX YYYY') 
                        movwf   STATUS                                           ;STATUS = W (Pega STATUS original)
                        swapf   W_TEMP, F                                        ;W_TEMP = W_TEMP('ZZZZ WWWW' -> B'WWWW ZZZZ')
                        swapf   W_TEMP, W                                        ;W = W_TEMP(B'WWWW ZZZZ' -> B'ZZZZ WWWW')
                        retfie                                                   ;Retorna de interrupção
						
; - Início do programa ------------------------------------------------------------------------------------------------------------------------------------------

Start:					
                        movlw   D'20'                                            ;W = primeiro operando
                        movwf   A0                                               ;A0 = W
                        movlw   D'5'                                             ;W = segundo operando ou operador da divisão
                        movwf   B0                                               ;B0 = W
                        call    Mul                                              ;Chama sub-rotina de multiplicação
                                                                                 ;Retornará -> <C1:C0> = A0 x B0 ou A0 / B0
		
; - Rotina de loop para trabalhos contínuos ---------------------------------------------------------------------------------------------------------------------

Loop:					
                        nop
                        nop
                        nop
                        
;                       ...
		
                        goto    Loop                                             ;Fecha laço
	
; - Desenvolvimento das Sub-Rotinas Auxiliares ------------------------------------------------------------------------------------------------------------------

Mul:
                        clrf    C0                                               ;Limpa conteúdo do registrador C0
                        clrf    C1                                               ;Limpa conteúdo do registrador C1
                        movf    A0,W                                             ;W = A0
                        movwf   C0                                               ;C0 = W = A0
	
Loop_Mul:
                        decf    B0,F                                             ;B0 = B0 - 1
                        btfsc   STATUS,Z                                         ;B0 igual a zero?
                        return                                                   ;Sim, então terminou de multiplicar
                                                                                 ;Não então:
                        movf    A0,W                                             ;W = A0
                        addwf   C0,F                                             ;C0 = W + C0 = A0 + C0
                        btfsc   STATUS,C                                         ;Houve transbordo em C0?
                        incf    C1,F                                             ;Sim, incrementa C1
                        goto    Loop_Mul                                         ;Não, fecha laço
	
Div:
                        clrf    C0                                               ;Limpa registrador C0
Loop_Div:
                        movf    B0,W                                             ;W = B0
                        subwf   A0,F                                             ;A0 = W - A0 = B0 - A0
                        btfss   STATUS,C                                         ;Testa para ver se houve carry
                        goto    Inc_Quotient                                     ;Não, então o dividendo é menor que zero, adiciona 1 ao quociente e sai
                        incf    C0,F                                             ;Sim, já que o dividendo é maior que zero, incrementa o quociente
                        goto    Loop_Div                                         ;Retorna para novo ciclo de subtração
Inc_Quotient:
                        incf    C0,F                                             ;Se dividendo for menor ou igual a zero, incrementa quociente
                        return                                                   ;Fim da sub-rotina

; - Reset do modulo comparador ----------------------------------------------------------------------------------------------------------------------------------

Reset_Comparator:                        
                        ctb0                                                     ;Muda para banco 0 p/ trabalhar com CMCON
                        movlw   H'0007'                                          ;Desabilita CMCON
                        movwf   CMCON                                            ;CMCON = W
                        return                                                   ;Retorna contextualmente para o programa
                        
                        
                        
                        
                        						
                        end                                                      ;Fim do programa