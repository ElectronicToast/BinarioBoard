;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                disputil.asm                                ;
;                    Binario Game Display Utility Functions                  ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains general utility functions 
;                   pertinent to the display for the EE 10b Binario board.
;
; Table of Contents:
;
;       Accessor functions:
;           GetRowMask(r)               returns one-hot mask for `r`th LED
;
; Revision History:
;    6/11/18    Ray Sun         Initial revision.



; ################################ CODE SEGMENT ################################
.cseg



; GetRowMask(r):
;
; Description           This function returns a one-hot bitmask (byte)
;                       corresponding to the `r`th LED in any column in R2, and 
;                       its logical inverse in R3. 
;
; Operation             The topmost LED in each column (#0) is represented by
;                       a constant mask [1000 0000]. This is logically 
;                       right-shifted `r` times to produce the correct mask 
;                       for the `r`th position. This mask is also inverted 
;                       for use in clearing the LED.
;
; Arguments             r       R16     row number,     0 - 7 (0: top)
; Return Values                 R2      the row mask, one-hot byte 
;                               R3      ! row mask
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
;   
; Inputs                None.
; Outputs               None. 
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         R16 is trashed in the function, as it is used as the 
;                       loop counter for shifting.
;
; Registers Changed     flags, R2, R3, R16, R20
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/17/2018


GetRowMask:

;RowMaskForLoopInit              ; Build a row mask (R2) in order to turn on 
    LDI     R20, ROW_MASK_INIT  ; or off the correct row position in a column
                                ; Use R16 as an index (LSR the initial row mask 
                                ; of [1000 0000] - row 0 - `r` times)
RowMaskForLoop:
    CPI     R16, 0              ; Check if we've looped `r` times (count down)
    BREQ    EndRowMask          ; If so, we have correct row mask; exit loop
    ;BRNE    RowMaskForLoop      ; Else, continue to LSR the row mask 
    
RowMaskForLoopBody:
    LSR     R20                 ; Shift the row position right (up) by 1
    DEC     R16                 ; Decrement index (`r` in R16 is trashed)
    RJMP    RowMaskForLoop      ; and check condition again.
    
EndRowMask:
	MOV 	R2, R20             ; Get mask in R2
    MOV     R3, R2              ; Copy the mask to R3 and invert it - 
    COM     R3                  ; for use in turning off pixels if necessary
    RET                         ; Done so return 