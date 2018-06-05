;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  sound.asm                                 ;
;                         Homework #4 Sound Functions                        ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for playing 
;                   sound on the EE 10b Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Sound functions:
;           PlayNote()          Play a tone of a specified frequency
;
; Revision History:
;    6/01/18    Ray Sun         Initial revision.
;    6/03/18    Ray Sun         Moved division algorithm to a general divide 24-
;                               bit unsigned integer by 16-bit unsigned integer 
;                               subroutine.
;    6/04/18    Ray Sun         Verified `PlayNote()` functionality. Fixed order 
;                               of writing to OC1A - H then L.



; Local include files
;.include "gendefines.inc"
;.include "iodefines.inc"
;.include "sounddefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; PlayNote(f):
;
; Description           This procedure plays a note with the passed frequency 
;                       `f`, in Hz, on the speaker. This tone is played until
;                       another function call with a new tone is made. A 
;                       frequency of `0` (0 Hz) turns off the speaker. Sound is 
;                       played by generating a square wave.
;
; Operation             The speaker is connected to OC1A, the output compare
;                       flag output pin for Timer1. OC1A is set to toggle its 
;                       logic level on every CTC compare match. 
;
;                       If `f` is zero (turn off the speaker), Timer1 is set to
;                       normal mode to turn off the OC1A toggling.
;
;                       Otherwise, Timer1 is set to CTC output compare mode 
;                       where OC1A is toggled on every compare match. The 
;                       speaker will play a tone of frequency of 
;
;                           f_OC1A = f_I/O_clk / (2 * N * (1 + OCR1A) )
;
;                       where N is the pre-scale factor and OCR1A is the value 
;                       in the output compare register A for Timer1. Therefore,
;                       given `f`, OCR1A should be set to 
;
;                           OCR1A = f_I/O_clk / (2 * N * f_OC1A) - 1
;
;                       This division is carried out by a modified version of
;                       the 16-bit division algorithm presented on the EE 10b 
;                       website. A 24-bit constant `SPK_FREQSCALE` is defined as 
;                       the I/O clock frequency (8 MHz) divided by twice the
;                       prescale. This value is divided by `f`, and the quotient
;                       minus one is written to OCR1A in order to toggle the 
;                       speaker line at the appropriate frequency.
;
; Arguments             f       R17|R16     The frequency of the tone to play, 
;                                           in Hz
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       R20|R19|R18 Dividend `SPK_FREQSCALE`used in division to 
;                                   find value to write to OC1A.
;                       R3|R2       Temporary 16-bit buffer to hold quotient / 
;                                   remainder of division.
;   
; Inputs                None.
; Outputs               The speaker plays a tone with the passed frequency `f`,
;                       in Hz. `f` = 0 turns off the speaker.
;   
; Error Handling        None. No error checking is performed on the frequency 
;                       `f`. 
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         The speaker initialization function sets OC1A to output.
;                       Initialization turns off the speaker.
;
; Registers Changed     R2, R3, R16, R17, R18, R19, R20, R22
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/01/2018  


PlayNote:
    CLR     R18
    CP      R16, R18            ; Compare with carry to check if `f` is zero
    CPC     R17, R18            ; to turn off the speaker 
    BRNE    SpeakerOn           ; If `f` is nonzero, go turn on the speaker
    ;BREQ   SpeakerOff          ; Else, the speaker is off 
        
SpeakerOff:                             ; If want to turn off speaker
    LDI     R16, TIMER1A_OFF            ; Turn off the speaker by setting
    OUT     TCCR1A, R16                 ; the speaker timer to normal mode
    LDI     R16, TIMER1B_OFF            ; Write the normal mode bitmask
    OUT     TCCR1B, R16                 ; to both control registers 
    CBI     EEROM_SPK_PORT, SPK_PIN     ; Turn off the speaker (output low)
    RJMP    EndPlayNote                 ; Done, so return
    
SpeakerOn:                              ; If `f` is nonzero   
    LDI     R18, TIMER1A_ON             ; Write the toggle mode bitmask
    OUT     TCCR1A, R18                 ; to control registers to turn on
    LDI     R18, TIMER1B_ON             ; toggle mode 
    OUT     TCCR1B, R18
	;RJMP    SpkRateDivLoopInit         ; go update OCR1A w/ correct rate
    
    LDI     R18, LOW(SPK_FREQSCALE)     ; Load SPK_FREQSCALE into R20|R19|R18 
    LDI     R19, LOW(SPK_FREQSCALE >> BYTE_LEN)    ; (dividend - 24 bits)
    LDI     R20, LOW(SPK_FREQSCALE >> WORD_LEN)    
    
    RCALL   Div24by16           ; Do the division - result in R19|R8, and the 
                                ; divisor (frequency) in R17|R16
    
	CLR     R16
    SUBI    R18, 1              ; Subtract 1 from low 2 bytes of quotient
    SBC     R19, R16            ; to get OCR1A value (toggle period)
    OUT     OCR1AH, R19         ; Write the toggle value to OCR1A
	OUT     OCR1AL, R18
    ;RJMP   EndPlayNote          ; and we are done

EndPlayNote:
    RET                         ; Done, so return

    

; Div24by16
;
; Description:          This function divides a 24-bit unsigned value passed in
;                       R20|R19|R18 by the 16-bit unsigned value passed in 
;                       R17|R16. The quotient is returned in R20|R19|R18 and the 
;                       remainder is returned in R3|R2.
;
; Operation:            The function divides R20|R19|R28 / R17|R16 with a 
;                       restoring division algorithm with a 16-bit temporary 
;                       register R3|R2 and shifting the quotient into 
;                       R20|R19|R28 as the dividend is shifted out. Since the 
;                       carry flag is the inverted quotient bit (and this is 
;                       shifted into the quotient), the quotient is inverted at 
;                       the end of the division.
;
; Arguments:            R20|R19|R18    - 24-bit unsigned dividend.
;                       R17|R16        - 16-bit unsigned divisor.
; Return Values:        R20|R19|R18    - 24-bit quotient.
;                       R3|R2          - 16-bit remainder.
;
; Local Variables:      bitcnt (R22) - number of bits left in division.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R2, R3, R16, R17, R18, R19, R20, R22
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/03/2018  


Div24by16:
    LDI     R22, 24             ; use R21 as loop counter
    CLR     R3                  ; Use R3|R2 to hold remainder / quotient bit
    CLR     R2
    
Div24by16Loop:                  ; Repeat until gone through SPK_FREQ_NBITS
    ROL     R18                 ; Rotate bit into remainder R3|R2
    ROL     R19                 ; and quotient into dividend R20|R19|R18
    ROL     R20 
    ROL     R2 
    ROL     R3 
    CP      R2, R16             ; Check if we can subtract divisor 
    CPC     R3, R17
    BRCS    Div24by16SkipSub    ; Cannot divide - do not subtract
    SUB     R2, R16             ; Otherwise subtract divisor from dividend 
    SBC     R3, R17
	;RJMP    Div24by16SkipSub
   
Div24by16SkipSub:
    DEC     R22                 ; Decrement the loop counter 
    BRNE    Div24by16Loop      ; If not done, keep looping
    
    ROL     R18                 ; Done - rotate the last quotient bit in
    ROL     R19 
    ROL     R20 
    COM     R18                 ; and invert quotient (carry flag is
    COM     R19                 ;   inverse of quotient bit)
    COM     R20 
    
EndDiv24by16:
    RET                         ; Done, so return
