;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              sounddefines.inc                              ;
;                    Binario Board Sound Output Definitions                  ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions and constants related
;                   to the speaker on the EE 10b Binario board.
;
; Table of Contents:
;       Speaker constants:
;           SPK_CLK_FREQ        Speaker timer clock frequency - system clock 
;           SPK_PRESCALE        Speaker timer prescale value
;           SPK_FREQSCALE       Frequency dividend for the `PlayNote` function -
;                               equal to half of the clock frequency divided by 
;                               the prescale factor
;   
; Revision History:
;    6/01/18    Ray Sun         Initial revision.
;    6/04/18    Ray Sun         Removed definition for the number of bits of 
;                               `SPK_FREQSCALE`, as the division in `PlayNote()`
;                               is now a general divide-24-by-16 subroutine.
;    6/04/18    Ray Sun         Defined `SPK_FREQSCALE` in terms of speaker 
;                               timer clock frequency and the prescale 


; Speaker output compare rate constants 

.EQU    SPK_CLK_FREQ    = 8000000       ; Clock for speaker - system clock
.EQU    SPK_PRESCALE    = 8             ; Speaker timer prescale factor
.EQU    SPK_FREQSCALE   = SPK_CLK_FREQ / (2 * SPK_PRESCALE) ; Frequency dividend     
