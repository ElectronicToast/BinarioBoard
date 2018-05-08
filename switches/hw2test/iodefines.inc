;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                iodefines.inc                               ;
;                         General Hardware Definitions                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains general-purpose and hardware
;                   specific definitions for the EE 10b Binario board and the 
;                   ATmega64, such as the timers.
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Fixed `TIMER3RATE` to correspond to 1 ms on the 
;                               8 MHz clock used on the board. 



; General Constants

.EQU    TRUE = 0xFF			; a `true` Boolean value
.EQU	FALSE = 0			; a `false` Boolean value


; Timer 3 definitions:

.EQU	TIMER3A_ON = 0b00000000		; Turn on timer 3
					                ;  00------  no output on OC1A
					                ;  --00----  no output on OC1B
					                ;  ----00--  reserved
					                ;  ------00  no PWM output

.EQU	TIMER3B_ON = 0b00001001	    ; Turn on timer 3
					                ;  0-------  disable noise canceler
                                    ;  -0------  capture on falling edge
					                ;  --00----  reserved
					                ;  ----1---  clear on compare match
					                ;  -----001  run timer on clk

.EQU	TIMER3RATE = 7999		    ; This is 1 ms assuming 8 MHz clock
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms
                    
                    
; I/O Port definitions:

.EQU    INDATA     = 0b00000000		; Data direction 0 is input for I/O ports
