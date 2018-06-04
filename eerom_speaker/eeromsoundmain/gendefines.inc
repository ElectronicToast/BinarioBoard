;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               gendefines.inc                               ;
;                         General Hardware Definitions                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains general-purpose and hardware
;                   specific definitions for the EE 10b Binario board and its 
;                   ATmega64, such as logical constants.
;
; Table of Contents:
;
;   General constants:
;           TRUE and FALSE          logical 1 and 0
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision. Split from `iodefines.inc`



; General Constants

.EQU    TRUE = 0xFF			; a `true` Boolean value
.EQU	FALSE = 0			; a `false` Boolean value
