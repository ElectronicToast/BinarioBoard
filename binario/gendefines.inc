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
;   System constants:
;           Stack size
;           Z flag position in SREG
;   General constants:
;           TRUE and FALSE          logical 1 and 0
;           Number of bits in a byte and a word
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision. Split from `iodefines.inc`
;    6/02/18    Ray Sun         Added definitions for the length of a byte and 
;                               a word.
;    6/14/18    Ray Sun         Added stack size definition and Z flag position.



; System Constants:

.EQU    STACK_SIZE  = 128   ; # bytes allocated for the stack

.EQU    Z_FLAG_BIT  = 1     ; The Z flag is the first bit in SREG

; General Constants

.EQU    TRUE    = 0xFF      ; A `true` Boolean value
.EQU    FALSE   = 0         ; A `false` Boolean value

.EQU    BYTE_LEN = 8        ; The number of bits in a byte
.EQU    WORD_LEN = 16       ; The number of bits in a word
