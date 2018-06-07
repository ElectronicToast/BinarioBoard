; ################################ CODE SEGMENT ################################
.cseg



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
