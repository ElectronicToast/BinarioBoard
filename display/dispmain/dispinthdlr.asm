;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              dispinthdlr.asm                               ;
;                   Display Multiplexing Interrupt Handler                   ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the `Timer3CompareHandler` 
;                   procedure that performs display multiplexing on a Timer3 
;                   CTC compare match for the 8x8 dual color LED matrix display 
;                   on the EE 10b Binario board. The display is multiplezed
;                   such that one column out of 16 (8 red, 8 green) is 
;                   displayed between interrupt handler calls.
;
; Table of Contents:
;
;   CODE SEGMENT 
;       Display Interrupt Handler:
;           Timer3CompareHandler()
;
; Revision History:
;    5/16/18    Ray Sun         Initial revision.
;    5/17/18    Ray Sun         Modified `Timer3CompareHandler` to push the 
;                               necessary registers changed by `MuxDisp`
;                               and its subroutines.
;    5/18/18    Ray Sun         Added TOC.



; ################################ CODE SEGMENT ################################
.cseg



; Timer3CompareHandler:
;
; Description             This procedure calls the display multiplexing 
;                         procedure on every CTC compare interrupt generated 
;                         by Timer3.
;   
; Operation               When Timer3 generates a CTC output compare interrupt
;                         the display muxing procedure `MuxDisp` is called.
;   
; Arguments               None.
; Return Values           None.
;       
; Global Variables        None.
; Shared Variables        See `MuxDisp`.
; Local Variables         None.
;       
; Inputs                  None.
; Outputs                 The display is multiplexed (the next column is 
;                         displayed) on each interrupt handler call).
;   
; Error Handling          None.
; Algorithms              None.
; Data Structures         None.
;       
; Limitations             None.
; Known Bugs              None.
; Special Notes           None.
; 
; Registers Changed       None.
; Stack Depth             13 bytes
;
; Author                  Ray Sun
; Last Modified           05/19/2018   


Timer3CompareHandler:
    PUSH    ZH                  ; Save Z and Y
    PUSH    ZL
    PUSH    YH
    PUSH    YL
    PUSH    R19                 ; Save all registers used in `DispMux`
    PUSH    R18                 ; R2...R5, R16...R19
	PUSH    R17                 
    PUSH    R16
	PUSH    R5      
	PUSH    R4
    PUSH    R3                  
    PUSH    R2
    IN      R2,     SREG        ; Store status register (flags)
    PUSH    R2
    
    CLI                         ; Disable global interrupts
    RCALL   MuxDisp             ; Do display multiplexing
    
    POP     R2
    OUT     SREG,   R2          ; Restore all pushed registers
	POP     R2  
    POP     R3 
    POP     R4
    POP     R5
    POP     R16                 
	POP     R17
    POP     R18 
    POP     R19
    POP     YL                  ; Finally, restore Y and Z
    POP     YH 
    POP     ZL 
    POP     ZH 
    ;RJMP    DoneTimer3DispintHdlr   ; Done, so re-enable interrupts and return
    
 DoneTimer3CompareHandler:
    RETI                        ; Done, so return and reenable interrupts
