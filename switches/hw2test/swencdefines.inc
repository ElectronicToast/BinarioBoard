;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              swencdefines.inc                              ;
;                      Switch and Encoder Input Definitions                  ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions and constants related
;                   to the pushbutton switch and the quadrature encoder inputs
;                   on the EE 10b Binario board.
;
; Revision History:
;    5/04/18    Ray Sun         Initial version
;    5/05/18    Ray Sun         Added switch and encoder bitmasks for reading 
;                               I/O port E.


; Switch and encoder input port - Port E 

.EQU        SW_ENC_PORT = PINE


; Input bitmasks:

.EQU        LR_SW_MASK  = 0b00100000    ; L/R switch - PE5
.EQU        UD_SW_MASK  = 0b00000100    ; U/D switch - PE2
.EQU        LR_ENC_MASK = 0b11000000    ; L/R encoder lines - PE7, PE6  
.EQU        UD_ENC_MASK = 0b00011000    ; U/D encoder lines - PE4, PE3


; Switch debounce counter top value

.EQU        SW_DEB_TIME = 30            ; Pushbutton switch debounce time
                                        ; 30 runs of interrupt handler = 30 ms


; Encoder tables definitions

.EQU        ENC_TBL_CENTER_OFFSET = 4   ; Offset to center of tables
.EQU        ENC_TBL_FULL_CCW = 0        ; Index of CCW end of table
.EQU        ENC_TBL_FULL_CW  = 8        ; Index of CW end of table
