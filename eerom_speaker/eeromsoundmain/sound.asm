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
;                       frequency of `0` (0 Hz) turns off the speaker. 
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
;                       is written to OCR1A in order to toggle the speaker line 
;                       at the appropriate frequency.
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
; Registers Changed     R2, R3, R16, R17, R18, R19, R20, R21
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
        
SpeakerOff:                     ; If want to turn off speaker
    LDI     R16, TIMER1_NORMAL_CTR_BITS_A   ; Turn off the speaker by setting
    OUT     TCCR1A, R16                     ; the speaker timer to normal mode
    LDI     R16, TIMER1_NORMAL_CTR_BITS_B   ; Write the normal mode bitmask
    OUT     TCCR1B, R16                     ; to both control registers 
    CBI     EEROM_SPK_PORT, SPK_PIN         ; Turn off the speaker
    RJMP    EndPlayNote                     ; Done, so return
    
SpeakerOn:                      ; If `f` is nonzero
    CLR     R18                 ; Reset the speaker counter
    OUT     TCNT1H, R18             
    OUT     TCNT1L, R18         
    LDI     R18, TIMER1_TOGGLE_CTR_BITS_A   ; Write the toggle mode bitmask
    OUT     TCCR1A, R18                     ; to control registers to turn on
    LDI     R18, TIMER1_TOGGLE_CTR_BITS_B   ; toggle mode 
    OUT     TCCR1B, R18
	;RJMP    SpkRateDivLoopInit              ; go update OCR1A w/ correct rate
    
SpkRateDivLoopInit:             ; Set up Glen[TM] division to set toggle rate
    LDI     R18, LOW(SPK_FREQSCALE)         ; Load SPK_FREQSCALE into R20|R19|R18 
    LDI     R19, LOW(SPK_FREQSCALE >> 8)    ; (dividend - 24 bits)
    LDI     R20, LOW(SPK_FREQSCALE >> 16)    
    LDI     R21, SPK_FREQ_NBITS ; Get # bits of dividend for loop counter
    CLR     R2                  ; Use R3|R2 to hold remainder / quotient bit
    CLR     R3
    
SpkRateDivLoop:                 ; Repeat until gone through SPK_FREQ_NBITS
    ROL     R18                 ; Rotate bit into remainder R3|R2
    ROL     R19                 ; and quotient into dividend R20|R19|R18
    ROL     R20 
    ROL     R2 
    ROL     R3 
    CP      R2, R16             ; Check if we can subtract divisor 
    CPC     R3, R17
    BRCS    SpkRateDivSkipSub   ; Cannot divide - do not subtract
    SUB     R2, R16             ; Otherwise subtract divisor from dividend 
    SBC     R3, R17
	;RJMP    SpkRateDivSkipSub
   
SpkRateDivSkipSub:
    DEC     R21                 ; Decrement the loop counter 
    BRNE    SpkRateDivLoop      ; If not done, keep looping
    
    ROL     R18                 ; Done - rotate the last quotient bit in
    ROL     R19 
    ROL     R20 
    COM     R18                 ; and invert quotient (carry flag is
    COM     R19                 ;   inverse of quotient bit)
    COM     R20 
    
	CLR     R16
    DEC     R18                 ; Subtract 1 from low 2 bytes of quotient
    SBC     R19, R16            ; to get OCR1A period
    OUT     OCR1AL, R18         ; Write the period to OCR1A
	OUT     OCR1AH, R19
    ;RJMP   EndPlayNote        ; and we are done

EndPlayNote:
    RET                         ; Done, so return
