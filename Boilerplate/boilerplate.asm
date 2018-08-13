;
;  Autor: Allan César		License: CC-BY-4.0
;
;  Data: Agosto/2018
;
;  MCU Utilizada: PIC16F628A (Microchip)
;  Clock: ?? (XT)
;  

   list		p=16f628a

;  - Arquivos incluídos -----------------------------------------------------------------------------------------------------------------------------------------
   
   #include	<p16f628a.inc>
   
;  - FUSE bits --------------------------------------------------------------------------------------------------------------------------------------------------
;  
;  Configura oscilador externo p/ RA6 e RA7, desliga Watchdog Timer, liga Power-Up Timer, liga a função Reset do pino RA5, desliga BOD, LVP desligado, Data e
;  Code Protection desligado
;
;  Portanto RA5, RA6, RA7 -> XXX ou HIGH-Z (input)
;
   __config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
