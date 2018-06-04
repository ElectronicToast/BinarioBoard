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
;           SPK_FREQ_NBITS      Number of bits of frequency scale numerator
;           SPK_FREQSCALE       Frequency dividend for the `PlayNote` function -
;                               equal to half of the clock frequency divided by 
;                               the prescale factor - SPK_FREQ_NBITS bits
;   
; Revision History:
;    6/01/18    Ray Sun         Initial revision.



.EQU    SPK_FREQ_NBITS  = 24            ; #Bits of frequency division dividend

.EQU    SPK_FREQSCALE   = 500_000       ; I/O clk divided by (2 * prescale)
