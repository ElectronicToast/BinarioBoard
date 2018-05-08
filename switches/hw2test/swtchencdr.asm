;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               swtchencdr.asm                               ;
;                 Homework #2 Encoder and Switch Reading Functions           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the LRSwitch(), UDSwitch(),
;                   LeftRot(), RightRot(), DownRot(), UpRot() procedures
;                   for reading debounced switch and encoder inputs on the 
;                   EE 10b Binario board, in addition to initialization 
;                   routines and sub-procedures for reading and debouncing 
;                   the hardware input.
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Implemented switch debouncing and verified
;                               functionality on the board.
;    5/05/18    Ray Sun         Implemented encoder rotation debouncing and
;                               began debugging. Observed random setting of
;                               encoder rotation flags.
;    5/05/18    Ray Sun         Verified encoder debounce procedure
;                               functionality. R and U flags are being set
;                               by some unknown bug.
;    5/07/18    Ray Sun         Got encoders working properly. Fixed switch 
;                               debouncing algorithm by adding a condition to
;                               handle counter < 0 by setting counter = 0,
;                               keeping the switch as 'pressed' if it were 
;                               held down.



; local include files
;.include  "iodefines.inc"
;.include  "swdefines.inc"



; ################################ CODE SEGMENT ################################

.cseg



; -------------------------- QUAD ENCODER STATE TABLES -------------------------


; Tables of quadrature encoder states used in debouncing of rotations:
;
;   | i |   state[i]   |
;   +---+--------------|
;   | 0 |      11      |    CCW 1 cycle     Detent
;   | 1 |      01      |    /|\
;   | 2 |      00      |     |
;   | 3 |      10      |     |
;   | 4 |      11      |    --- CENTER      Detent
;   | 5 |      01      |     |
;   | 6 |      00      |     |
;   | 7 |      10      |    \|/
;   | 8 |      11      |    CW 1 cycle      Detent
;
; Each table has the state bits in positions appropriate for the particular
; encoder input so no bit-shifting is required in the code

LREncTbl: .DB 0b11000000, 0b01000000
          .DB 0b00000000, 0b10000000
          .DB 0b11000000, 0b01000000
          .DB 0b00000000, 0b10000000 
          .DB 0b11000000, 0b00000000    ; pad end with zero for even table
          
UDEncTbl: .DB 0b00011000, 0b00001000
          .DB 0b00000000, 0b00010000
          .DB 0b00011000, 0b00001000
          .DB 0b00000000, 0b00010000 
          .DB 0b00011000, 0b00000000    ; pad end with zero for even table
            
   
   
; ---------------------------- SWITCH READ FUNCTIONS ---------------------------



; LRSwitch:
;
; Description       This function checks whether the left/right encoder switch 
;                   has been pressed since this function was last called.
;                     
; Operation         A shared variable or flag `lr_hasPress` is set by the 
;                   switch debounce procedure if the left/right switch has been 
;                   pressed since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; Return Values     The function returns TRUE (Z = 1) if the left/right switch 
;                   has been pressed since the last time it was called. 
;                   Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  lr_hasPress - If the left/right switch has been pressed 
;                         since the last call.
; Local Variables   None.
;                     
; Inputs            Left/right encoder switch.
; Outputs           Whether the left/right switch has been pressed since the 
;                   last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `lr_hasPress` is initialized to 0 in the initialization 
;                   procedure.
;
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018

LRSwitch:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, lr_hasPress        ; Get the current switch flag status
    LDI     R17, FALSE              ; Clear the left/right switch flag
    STS     lr_hasPress, R17

    OUT     SREG, R3                ; Restore flags (and interrupt bit) 

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  



; UDSwitch()
;
; Description       This function checks whether the up/down encoder switch 
;                   has been pressed since this function was last called.
;                     
; Operation         A shared variable or flag `ud_hasPress` is set by the 
;                   switch debounce procedure if the up/down switch has been 
;                   pressed since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; Return Values     The function returns TRUE (Z = 1) if the up/down switch 
;                   has been pressed since the last time it was called. 
;                   Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  ud_hasPress - If the up/down switch has been pressed 
;                         since the last call.
; Local Variables   None.
;                     
; Inputs            Up/down encoder switch.
; Outputs           Whether the up/down switch has been pressed since the 
;                   last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `ud_hasPress` is initialized to 0 in the initialization 
;                   procedure.
;
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018
;                     

UDSwitch:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, ud_hasPress        ; Get the current switch flag status
    LDI     R17, FALSE              ; Clear the up/down switch flag
    STS     ud_hasPress, R17

    OUT     SREG, R3                ; Restore flags (and interrupt bit)

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  



; LeftRot:
;
; Description       This function checks whether the left/right quadrature 
;                   encoder has been rotated counterclockwise since this 
;                   function was last called.
; 
; Operation         A shared variable or flag `lr_hasLeft` is set by the 
;                   left/right encoder reading procedure if the left/right
;                   encoder has been rotated counterclockwise by a full cycle
;                   since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; 
; Return Values     The function returns TRUE (Z = 1) if the left/right encoder 
;                   has been rotated counterclockwise since the last time it was 
;                   called. Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  lr_hasLeft - If the left/right encoder has been rotated 
;                       CCW since the last function call.
; Local Variables   None.
; 
; Inputs            Left/right quadrature encoder.
; Outputs           Whether the left/right encoder has been rotated 
;                   counterclockwise since the last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `lr_hasLeft` is initialized to 0 in the initialization 
;                   procedure.
;                     
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018            

LeftRot:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, lr_hasLeft         ; Get the current encoder flag status
    LDI     R17, FALSE              ; Clear the left rotation encoder flag
    STS     lr_hasLeft, R17

    OUT     SREG, R3                ; Restore flags (and interrupt bit)

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  




; RightRot:
;
; Description       This function checks whether the left/right quadrature 
;                   encoder has been rotated clockwise since this function was 
;                   last called.
; 
; Operation         A shared variable or flag `lr_hasRight` is set by the 
;                   left/right encoder reading procedure if the left/right
;                   encoder has been rotated clockwise by a full cycle
;                   since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; 
; Return Values     The function returns TRUE (Z = 1) if the left/right encoder 
;                   has been rotated clockwise since the last time it was 
;                   called. Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  lr_hasRight - If the left/right encoder has been rotated 
;                       CW since the last function call.
; Local Variables   None.
; 
; Inputs            Left/right quadrature encoder.
; Outputs           Whether the left/right encoder has been rotated 
;                   clockwise since the last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `lr_hasRight` is initialized to 0 in the initialization 
;                   procedure.
;                     
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018            

RightRot:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, lr_hasRight        ; Get the current encoder flag status
    LDI     R17, FALSE              ; Clear the right rotation encoder flag
    STS     lr_hasRight, R17

    OUT     SREG, R3                ; Restore flags 

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  



; DownRot:
;
; Description       This function checks whether the up/down quadrature 
;                   encoder has been rotated clockwise since this function was 
;                   last called.
; 
; Operation         A shared variable or flag `ud_hasDown` is set by the 
;                   up/down encoder reading procedure if the up/down
;                   encoder has been rotated clockwise by a full cycle
;                   since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; 
; Return Values     The function returns TRUE (Z = 1) if the up/down encoder 
;                   has been rotated clockwise since the last time it was 
;                   called. Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  ud_hasDown - If the up/down encoder has been rotated 
;                       CW since the last function call.
; Local Variables   None.
; 
; Inputs            Up/down quadrature encoder.
; Outputs           Whether the up/down encoder has been rotated 
;                   clockwise since the last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `ud_hasDown` is initialized to 0 in the initialization 
;                   procedure.
;                     
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018     

DownRot:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, ud_hasDown         ; Get the current encoder flag status
    LDI     R17, FALSE              ; Clear the down rotation encoder flag
    STS     ud_hasDown, R17

    OUT     SREG, R3                ; Restore flags (and interrupt bit) 

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  



; UpRot:
;
; Description       This function checks whether the up/down quadrature 
;                   encoder has been rotated counterclockwise since this 
;                   function was last called.
; 
; Operation         A shared variable or flag `ud_hasUp` is set by the 
;                   up/down encoder reading procedure if the up/down
;                   encoder has been rotated counterclockwise by a full cycle
;                   since the last call. Z is set if this flag is 1 and 
;                   cleared otherwise, then the flag is cleared. This is done
;                   with interrupts disabled (critical code).
; 
; Arguments         None.
; 
; Return Values     The function returns TRUE (Z = 1) if the up/down encoder 
;                   has been rotated counterclockwise since the last time it was 
;                   called. Otherwise, the function returns FALSE (Z = 0).
; 
; Global Variables  None.
; Shared Variables  ud_hasUp - If the up/down encoder has been rotated 
;                       CCW since the last function call.
; Local Variables   None.
; 
; Inputs            Up/down quadrature encoder.
; Outputs           Whether the up/down encoder has been rotated 
;                   counterclockwise since the last call, stored in the Z flag.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     `ud_hasUp` is initialized to 0 in the initialization 
;                   procedure.      
;                     
; Registers Changed     flags, R3, R16, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018     

UpRot:
    IN      R3, SREG                ; Save interrupt flag status
    CLI                             ; and disable interrupts

    LDS     R16, ud_hasUp           ; Get the current encoder flag status
    LDI     R17, FALSE              ; Clear the up rotation encoder flag
    STS     ud_hasUp, R17

    OUT     SREG, R3                ; Restore flags (and interrupt bit) 

    CPI     R16, TRUE               ; Now set the zero flag correctly
    RET                             ; Done so return  



; ------------------------- SWITCH DEBOUNCE FUNCTIONS --------------------------



; SwDeb:   
;     
; Description       This function debounces both quadrature encoder pushbutton 
;                   switch inputs on the Binario board.
; 
; Operation         Two identical switch debouncing algorithms are used, one
;                   for each switch. For each switch, a debounce counter that 
;                   decreases from a defined initial 'debounce time' is defined.
;                   If the switch is read as not pressed, the debounce counter 
;                   is reset to the debounce time. Otherwise, the debounce 
;                   counter is decremented; if it reaches zero, the switch is 
;                   debounced as pressed. The debounced flags `lr_hasPress` and 
;                   `ud_hasPress` are set by this procedure but only cleared by 
;                   the `LRSwitch()` and `UDSwitch()` procedures. 
; 
; Arguments         None.
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  lr_deb_ctr - Debounce counter for the left/right switch.
;                   ud_deb_ctr - Debounce counter for the up/down switch.
;                   lr_hasPress - flag indicating a debounced L/R switch 
;                       press (cleared by `LRSwitch`
;                   ud_hasPress - flag indicating a debounced U/D switch 
;                       press (cleared by `UDSwitch`
; Local Variables   None.
; 
; Inputs            Left/right encoder and up/down encoder switches, through 
;                   the accessor functions `GetLRSw()` and `GetUDSw()`.
; Outputs           lr_hasPress, ud_hasPress - switch flags
; 
; Error Handling    None. 
; Algorithms        The simple decremented debounce-counter method of debouncing
;                   pushbutton switches presented in class is used twice to 
;                   debounce both switches.              
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     The same `SW_DEB_TIME` initial counter value is used for 
;                   both switches.
;                     
; Registers Changed     R16, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018   

SwDeb:

DebLRSw:                            ; Debounce L/R switch
    RCALL   LRSwStatus              ; Update flags from L/R switch reading
    BREQ    DebLRSwDown             ; If zero (pressed) go count down 
    ;BRNE    DebLRSwUp               ; Else switch is up
    
DebLRSwUp:                          ; If switch is up, 
    LDI     R16,    SW_DEB_TIME     ; reset the L/R debounce counter 
    STS     lr_deb_ctr, R16
    RJMP    EndDebLRSw              ; Done, so go check other switch
    
DebLRSwDown:                        ; If L/R switch pressed, decrement and check
    LDS     R16,    lr_deb_ctr      ; Decrement the L/R debounce counter
    DEC     R16
    STS     lr_deb_ctr, R16
    BREQ    DebLRSwCtrZero          ; If counter is zero, then switch is pressed 
    BRMI    DebLRSwCtrNeg           ; If counter < 0, set counter = 0
    RJMP    EndDebLRSw              ; Else not debounced, so check other switch;

DebLRSwCtrZero:
    LDI     R16, TRUE               ; If L/R counter -> zero, switch is pressed
    STS     lr_hasPress, R16        ; Set L/R has press flag
    RJMP    EndDebLRSw               ; Done, so go check other switch
 
DebLRSwCtrNeg:
    CLR     R16                     ; If L/R counter < 0, set the counter 
    STS     lr_deb_ctr, R16         ; to zero
 
EndDebLRSw:                         ; Done with debouncing the L/R switch
    ;RJMP    DebUDSw
    
DebUDSw:                            ; Now check the U/D switch
    RCALL   UDSwStatus              ; Update flags from U/D switch reading
    BREQ    DebUDSwDown             ; If zero (pressed) go count down 
    ;BRNE    DebUDSwUp               ; Else switch is up
    
DebUDSwUp:                          ; If switch is up, 
    LDI     R16,    SW_DEB_TIME     ; reset the U/D debounce counter 
    STS     ud_deb_ctr, R16
    RJMP    EndSwDeb                ; Done, so return
   
DebUDSwDown:                        ; If U/D switch pressed, decrement and check
    LDS     R16,    ud_deb_ctr      ; Decrement the U/D debounce counter
    DEC     R16
    STS     ud_deb_ctr, R16
    BREQ    DebUDSwCtrZero          ; If counter is zero, then switch is pressed 
    BRMI    DebUDSwCtrNeg           ; If counter < 0, set counter = 0
    RJMP    EndSwDeb                ; Else done, so return

DebUDSwCtrZero:
    LDI     R16, TRUE               ; If U/D counter -> zero, switch is pressed
    STS     ud_hasPress, R16        ; Set U/D has press flag
    RJMP    EndSwDeb                ; Done, so return

DebUDSwCtrNeg:
    CLR     R16                     ; If U/D counter < 0, set the counter 
    STS     ud_deb_ctr, R16         ; to zero
    
EndDebUDSw:                         ; Done with debouncing the U/D switch
    ;RJMP    EndSwDeb

EndSwDeb:                   
    RET                             ; Done, so return

        
        
; LREncDeb 
;         
; Description       This function debounces the left/right quadrature encoder 
;                   input (A and B lines) on the Binario board.
; 
; Operation         A rotational position index `lr_enc_index` is initialized
;                   to ENC_TBL_CENTER_OFFSET (corresponding to a state of 11). 
;                   The current encoder state is read. If the state corresponds 
;                   to the next CCW encoder state, the index is decremented 
;                   (as along the enc_state table). Otherwise, if the state 
;                   corresponds to the next CW encoder state, the index is 
;                   incremented. Otherwise, if the state is not the same as 
;                   before, the index is reset to ENC_TBL_CENTER_OFFSET. A full 
;                   CCW cycle corresponds to a cycle where the index goes from 
;                           ENC_TBL_CENTER_OFFSET -> ENC_TBL_FULL_CCW
;                   and CW to a cycle 
;                           ENC_TBL_CENTER_OFFSET -> ENC_TBL_FULL_CW.
;                   Flags are set to indicate full rotation cycles.
; 
; Arguments         None.;       + Subroutines   R0, R17
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  lr_hasLeft - Flag indicating a debounced CCW rotation of L/R
;                       since the last call to `LeftRot()`. Is set by this
;                       procedure and cleared by `LeftRot()`.
;                   lr_hasRight - Flag indicating a debounced CW rotation of L/R
;                       since the last call to `RightRot()`. Is set by this
;                       procedure and cleared by 'RightRot()'.
;                   lr_enc_index - Index of the left/right encoder state 
;                       in the `enc_state` table. Defaults to 
;                       ENC_TBL_CENTER_OFFSET.
; Local Variables   lr_enc_state - State of the left/right encoder A, B lines
; 
; Inputs            Left/right quadrature encoder (through `GetLREnc()` ).
; Outputs           lr_hasLeft, lr_hasRight - flags indicating rotations.
; 
; Error Handling    If the current encoder state does not either change to one 
;                   CW or CCW position from the current index, or stays at 
;                   the state corresponding to the current index, the index is 
;                   reset to the center address ENC_TBL_CENTER_OFFSET.
;                     
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;                     
; Registers Changed     R1, R16, flags
;       + Subroutines   R0, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018 


LREncDeb:
    RCALL   LREncStatus             ; Get raw L/R encoder reading on R16
    MOV     R1, R16                 ; and store it in R1
    
    LDS     R16, lr_enc_index       ; Get current L/R encoder index on R16
    RCALL   GetLREncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against current state
    BREQ    EndLREncDeb             ; If zero, no movement - return
    
    LDS     R16, lr_enc_index       ; Get (current + 1) L/R encoder index on R16
	INC     R16
    RCALL   GetLREncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against (current + 1) 
    BREQ    LREncMovedCW            ; If zero, has moved CW by 1 index 
    
    LDS     R16, lr_enc_index       ; Get (current - 1) L/R encoder index on R16
	DEC     R16
    RCALL   GetLREncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against (current - 1) 
    BREQ    LREncMovedCCW           ; If zero, has moved CCW by 1 index 
    
    LDI     R16, ENC_TBL_CENTER_OFFSET  ; Otherwise some error happened -
    STS     lr_enc_index, R16       ; restore the center index
    RJMP    EndLREncDeb             ; and return
    
LREncMovedCW:                       ; If L/R encoder was moved CW by 1 position
    LDS     R16, lr_enc_index       ; increment the L/R index
    INC     R16
    STS     lr_enc_index, R16
    RJMP    LREncCheckCycle        ; and check for a full CW cycle
    
LREncMovedCCW:                      ; If L/R encoder was moved CCW by 1 position
    LDS     R16, lr_enc_index       ; decrement the L/R index
    DEC     R16
    STS     lr_enc_index, R16
    ;RJMP    LREncCheckCycle        ; and check for a full CCW cycle
    
LREncCheckCycle:                    ; Check if a full rotation has occurred
    CPI     R16, ENC_TBL_FULL_CW    ; Check if we have full CW rotation     
    BREQ    LREncFullCW             ; and indicate so
    CPI     R16, ENC_TBL_FULL_CCW   ; Else, check if we have full CCW rotation     
    BREQ    LREncFullCCW            ; and indicate so
    RJMP    EndLREncDeb                ; Otherwise, return
    
LREncFullCW:                        ; If we have a full CW rotation
    LDI     R16, TRUE               ; Set `lr_hasRight` flag 
    STS     lr_hasRight, R16 
    LDI     R16, ENC_TBL_CENTER_OFFSET 
    STS     lr_enc_index, R16       ; and reset index to the center index
    RJMP    EndLREncDeb             ; Done, so return

LREncFullCCW:                       ; If we have a full CCW rotation
    LDI     R16, TRUE               ; Set `lr_hasLeft` flag 
    STS     lr_hasLeft, R16 
    LDI     R16, ENC_TBL_CENTER_OFFSET 
    STS     lr_enc_index, R16       ; and reset index to the center index
    ;RJMP    EndLREncDeb             ; Done, so return
    
EndLREncDeb: 
    RET                             ; Done, so return



; UDEncDeb:
; 
; Description       This function debounces the up/down quadrature encoder 
;                   input (A and B lines) on the Binario board.
; 
; Operation         A rotational position index `ud_enc_index` is initialized
;                   to ENC_TBL_CENTER_OFFSET (corresponding to a state of 11). 
;                   The current encoder state is read. If the state corresponds 
;                   to the next CCW encoder state, the index is decremented 
;                   (as along the enc_state table). Otherwise, if the state 
;                   corresponds to the next CW encoder state, the index is 
;                   incremented. Otherwise, if the state is not the same as 
;                   before, the index is reset to ENC_TBL_CENTER_OFFSET. A full 
;                   CCW cycle corresponds to a cycle where the index goes from 
;                           ENC_TBL_CENTER_OFFSET -> ENC_TBL_FULL_CCW
;                   and CW to a cycle 
;                           ENC_TBL_CENTER_OFFSET -> ENC_TBL_FULL_CW. 
;                   Flags are set to indicate full rotation cycles.
; 
; Arguments         None.
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  ud_hasUp - Flag indicating a debounced CCW rotation of U/D
;                       since the last call to `UpRot()`. Is set by this 
;                       procedure and cleared by `UpRot()`.
;                   ud_hasDown - Flag indicating a debounced CW rotation of U/D
;                       since the last call to `DownRot()`. Is set by this 
;                       procedure and cleared by `DownRot()`.
;                   ud_enc_index - Index of the up/down encoder state 
;                       in the `enc_state` table. Defaults to 
;                       ENC_TBL_CENTER_OFFSET.
; Local Variables   ud_enc_state - State of the up/down encoder A, B lines
; 
; Inputs            up/down quadrature encoder (through `GetUDEnc()` ).
; Outputs           ud_hasUp, ud_hasDown - flags indicating rotations.
; 
; Error Handling    If the current encoder state does not either change to one 
;                   CW or CCW position from the current index, or stays at 
;                   the state corresponding to the current index, the index is 
;                   reset to the center index, ENC_TBL_CENTER_OFFSET.
;                     
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R0, R1, R16, flags
;       + Subroutines   R0, R17
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018 

UDEncDeb:
    RCALL   UDEncStatus             ; Get raw U/D encoder reading on R16
    MOV     R1, R16                 ; and store it in R1
    
    LDS     R16, ud_enc_index       ; Get current U/D encoder index on R16
    RCALL   GetUDEncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against current state
    BREQ    EndUDEncDeb             ; If zero, no movement - return
    
    LDS     R16, ud_enc_index       ; Get (current + 1) U/D encoder index on R16
	INC     R16
    RCALL   GetUDEncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against (current + 1) 
    BREQ    UDEncMovedCW            ; If zero, has moved CW by 1 index 
    
    LDS     R16, ud_enc_index       ; Get (current - 1) U/D encoder index on R16
	DEC     R16
    RCALL   GetUDEncState           ; and get the corresponding state on R0 
    CP      R1, R0                  ; Compare new state against (current - 1) 
    BREQ    UDEncMovedCCW           ; If zero, has moved CCW by 1 index 
    
    LDI     R16, ENC_TBL_CENTER_OFFSET  ; Otherwise some error happened -
    STS     ud_enc_index, R16       ; restore the center index
    RJMP    EndUDEncDeb             ; and return
    
UDEncMovedCW:                       ; If U/D encoder was moved CW by 1 position
    LDS     R16, ud_enc_index       ; increment the U/D index
    INC     R16
    STS     ud_enc_index, R16
    RJMP    UDEncCheckCycle        ; and check for a full CW cycle
    
UDEncMovedCCW:                      ; If U/D encoder was moved CCW by 1 position
    LDS     R16, ud_enc_index       ; decrement the U/D index
    DEC     R16
    STS     ud_enc_index, R16
    ;RJMP    UDEncCheckCycle        ; and check for a full CCW cycle
    
UDEncCheckCycle:                    ; Check if a full rotation has occurred
    CPI     R16, ENC_TBL_FULL_CW    ; Check if we have full CW rotation     
    BREQ    UDEncFullCW             ; and indicate so
    CPI     R16, ENC_TBL_FULL_CCW   ; Else, check if we have full CCW rotation     
    BREQ    UDEncFullCCW            ; and indicate so
    RJMP    EndUDEncDeb             ; Otherwise, return
    
UDEncFullCW:                        ; If we have a full CW rotation
    LDI     R16, TRUE               ; Set `ud_hasDown` flag 
    STS     ud_hasDown, R16 
    LDI     R16, ENC_TBL_CENTER_OFFSET 
    STS     ud_enc_index, R16       ; and reset index to the center index
    RJMP    EndUDEncDeb             ; Done, so return

UDEncFullCCW:                       ; If we have a full CCW rotation
    LDI     R16, TRUE               ; Set `ud_hasUp` flag 
    STS     ud_hasUp, R16 
    LDI     R16, ENC_TBL_CENTER_OFFSET 
    STS     ud_enc_index, R16       ; and reset index to the center index
    ;RJMP    EndUDEncDeb             ; Done, so return
    
EndUDEncDeb: 
    RET                             ; Done, so return



; GetLREncState:
; 
; Description       This function returns the state of the left/right encoder 
;                   given a table index.
; 
; Operation         The left/right encoder table index is passed in through R16.
;                   The address of the table in memory is stored in Z, and 
;                   the index is added to Z. A LPM instruction puts the 
;                   corresponding state in the table into R0.
; 
; Arguments         R16 - left/right encoder state table index
; Return Values     R0  - the corresponding left/right encoder state, in the 
;                         format [AB00 0000]
; 
; Global Variables  None.
; Shared Variables  None.
; Local Variables   Z   - table start address in memory, to which the index is 
;                         added to get the state.
; 
; Inputs            Encoder state table index [0 to 8].
; Outputs           The corresponding encoder state (8 bits) that would result
;                   from masking an actual I/O input of that state with the 
;                   left/right encoder bitmask.
; 
; Error Handling    None.
;                     
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R0, R16, R17, Z, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018 

GetLREncState:
    LDI     ZH,    HIGH(2 * LREncTbl)   ; Get L/R encoder table address
    LDI     ZL,    LOW(2 * LREncTbl)    
	CLR     R17
    ADD     ZL,    R16                  ; Add index passed in through R16 
    ADC     ZH,    R17                  ; and carry into ZH if necessary
    LPM                                 ; Get the corresponding state in R0
    RET                                 ; and return
    
    

; GetUDEncState:
; 
; Description       This function returns the state of the up/down encoder 
;                   given a table index.
; 
; Operation         The up/down encoder table index is passed in through R16.
;                   The address of the table in memory is stored in Z, and 
;                   the index is added to Z. A LPM instruction puts the 
;                   corresponding state in the table into R0.
; 
; Arguments         R16 - up/down encoder state table index
; Return Values     R0  - the corresponding up/down encoder state, in the 
;                         format [000A B000]
; 
; Global Variables  None.
; Shared Variables  None.
; Local Variables   Z   - table start address in memory, to which the index is 
;                         added to get the state.
; 
; Inputs            Encoder state table index [0 to 8].
; Outputs           The corresponding encoder state (8 bits) that would result
;                   from masking an actual I/O input of that state with the 
;                   up/down encoder bitmask.
; 
; Error Handling    None.
;                     
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R0, R16, R17, Z, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018 

GetUDEncState:
    LDI     ZH,    HIGH(2 * UDEncTbl)   ; Get U/D encoder table address
    LDI     ZL,    LOW(2 * UDEncTbl)   
	CLR     R17 
    ADD     ZL,    R16                  ; Add index passed in through R16 
    ADC     ZH,    R17                  ; and carry into ZH if necessary
    LPM                                 ; Get the corresponding state in R0
    RET                                 ; and return
    
    
    
; ----------------------- UN-DEBOUNCED ACCESSOR FUNCTIONS ----------------------



; LRSwStatus:
;
; Description       This procedure returns the raw left/right switch reading 
;                   value (0 if pressed, 1 if not pressed)
; 
; Operation         I/O port E is read into R16 and masked with an appropriate 
;                   bitmask to extract the L/R switch input. This is returned
;                   over register R16
;                     
; Arguments         None.
; Return Values     R16 : 00[L/R SW] 0  0000        - L/R switch input
; 
; Global Variables  None.
; Shared Variables  None.
;                     
; Local Variables   None.
; 
; Inputs            None.
; Outputs           Non-debounced left/right switch readings.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R16, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018

LRSwStatus:
    IN      R16, SW_ENC_PORT
    ANDI    R16, LR_SW_MASK
    RET

    
    
; UDSwStatus:
;
; Description       This procedure returns the raw up/down switch reading 
;                   value (0 if pressed, 1 if not pressed)
; 
; Operation         I/O port E is read into R16 and masked with an appropriate 
;                   bitmask to extract the U/D switch input. This is returned
;                   over register R16
;                     
; Arguments         None.
; Return Values     R16 : 0000 0[U/D SW]00          - U/D switch input
; 
; Global Variables  None.
; Shared Variables  None.
;                     
; Local Variables   None.
; 
; Inputs            None.
; Outputs           Non-debounced up/down switch readings.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R16, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018

UDSwStatus:
    IN      R16, SW_ENC_PORT
    ANDI    R16, UD_SW_MASK
    RET

    
    
; LREncStatus:
;
; Description       This procedure returns the raw left/right quadrature encoder  
;                   lines reading.
; 
; Operation         I/O port E is read into R16 and masked with an appropriate 
;                   bitmask to extract the U/D encoder lines input. This is 
;                   returned over register R16
;                     
; Arguments         None.
; Return Values     R16 : [L/R ENC A][L/R ENC B]00  0000   - L/R encoder lines
; 
; Global Variables  None.
; Shared Variables  None.
;                     
; Local Variables   None.
; 
; Inputs            None.
; Outputs           Non-debounced left/right encoder readings.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R16, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018

LREncStatus:
    IN      R16, SW_ENC_PORT
    ANDI    R16, LR_ENC_MASK
    RET

    
    
; UDEncStatus:
;
; Description       This procedure returns the raw up/down quadrature encoder  
;                   lines reading.
; 
; Operation         I/O port E is read into R16 and masked with an appropriate 
;                   bitmask to extract the U/D encoder lines input. This is 
;                   returned over register R16
;                     
; Arguments         None.
; Return Values     R16 : 000[U/D ENC A]   [U/D ENC B]000   - U/D encoder lines
; 
; Global Variables  None.
; Shared Variables  None.
;                     
; Local Variables   None.
; 
; Inputs            None.
; Outputs           Non-debounced up/down encoder readings.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R16, flags
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/05/2018

UDEncStatus:
    IN      R16, SW_ENC_PORT
    ANDI    R16, UD_ENC_MASK
    RET
 


; -------------------------- INITIALIZATION FUNCTIONS --------------------------



; InitSwEnc:
;
; Description       This procedure initializes all shared variables used by the 
;                   functions to read and debounce the encoders and switches.
; 
; Operation         This procedure should be called on system start-up. It 
;                   resets all of the debounced switch press and encoder 
;                   rotation Boolean flags. Additionally, the encoder state 
;                   table center memory address is initialized.
;                     
; Arguments         None.
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  lr_hasPress - Debounced left/right switch input
;                   ud_hasPress - Debounced up/down switch input
;                   lr_hasLeft - Have left/right encoder CCW rotation
;                   lr_hasRight - Have left/right encoder CW rotation
;                   ud_hasUp - Have up/down encoder CCW rotation
;                   ud_hasDown - Have up/down encoder CW rotation
;                   lr_enc_index - Left/right index for encoder table
;                   ud_enc_index - Up/down index for encoder table
;                     
; Local Variables   None.
; 
; Inputs            None.
; Outputs           All switch and encoder press or rotation flags are set to 0.
;                   The encoder state indices are initialized to the center of 
;                   their respective tables, at the index 
;                   `ENC_TBL_CENTER_OFFSET`.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed     R16, Z
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018

InitSwEnc:
    LDI     R16, FALSE        
    STS     lr_hasPress, R16            ; Initialize all shared Boolean
    STS     ud_hasPress, R16            ; flags (have switch presses,
    STS     lr_hasLeft,  R16            ; have encoder rotations) to FALSE
    STS     lr_hasRight, R16 
    STS     ud_hasDown,  R16 
    STS     ud_hasUp,    R16
    
    ; Debounce counters are always updated per CTC interrupt so no need to init
    ;STS     lr_deb_ctr
    ;STS     ud_deb_ctr
    
    LDI     R16, ENC_TBL_CENTER_OFFSET  ; Initialize encoder table indices to
    STS     lr_enc_index, R16           ; the center offset
    STS     ud_enc_index, R16
    ;RJMP    EndInitSwEnc                ; Done with the initialization
    
EndInitSwEnc:
    RET                                 ; Done so return



; ################################ DATA SEGMENT ################################

.dseg



; ------------------------------ SHARED VARIABLES ------------------------------



; Boolean (byte) shared variable flags for debounced switch and encoder readings
lr_hasPress:    .BYTE 1     ; Debounced left/right switch input
ud_hasPress:    .BYTE 1     ; Debounced up/down switch input
lr_hasLeft:     .BYTE 1     ; Have left/right encoder CCW rotation
lr_hasRight:    .BYTE 1     ; Have left/right encoder CW rotation
ud_hasUp:       .BYTE 1     ; Have up/down encoder CCW rotation
ud_hasDown:     .BYTE 1     ; Have up/down encoder CW rotation

; Byte shared variables for encoder table address indices
lr_enc_index:   .BYTE 1     ; Left/right index for encoder table
ud_enc_index:   .BYTE 1     ; Up/down index for encoder table

; Byte shared variables for debounce counters 
lr_deb_ctr:     .BYTE 1     ; Left/right switch debounce counter
ud_deb_ctr:     .BYTE 1     ; Up/down switch debounce counter
