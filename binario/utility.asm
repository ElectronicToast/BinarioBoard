;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 utility.asm                                ;
;                         General AVR utility routines                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains general-purpose utility 
;                   functions for AVR microcontrollers, such as delays and 
;                   division algorithms.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Delay functions:
;           DelayMsLoop         Delays by the number of milliseconds passed in 
;                               X (word).
;           Delay16             Delays by the number of tens of milliseconds 
;                               passed in R16.
;       Arithmetic functions:
;           Div24by16           Divides the 24-bit unsigned value in R20..R18 
;                               by the 16-bit unsigned value in R17..R16 and 
;                               returns the result in R20..R18.
;           Mul16by8            Multiplies the 16-bit unsigned value in X 
;                               by the 8-bit unsigned value in R16 and 
;                               returns the result in R20|R19|R18.
;
; Revision History:
;    6/05/18    Ray Sun         Initial revision.
;    6/06/18    Ray Sun         Moved the delay functions from `delay.asm` to 
;                               this file and deleted the former.
;    6/15/18    Ray Sun         Added a multiply 16-bit by 8-bit function 
;                               for use with delayless music.



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               DELAY FUNCTIONS                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; DelayMsWord:
;
; Description:          This procedure delays the number of clocks passed in 
;                       X times 8000.  Thus with a 8 MHz clock the passed 
;                       delay is in 1 millisecond units.
;
; Operation:            The function just loops decrementing Y until it is 0.
;
; Arguments:            X - 1/8000 the number of CPU clocks to delay.
; Return Value:         None.
;
; Local Variables:      None.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Registers Changed:    flags, X, Y
; Stack Depth:          0 bytes
;
; Author:               Ray Sun
; Last Modified:        June 5, 2018


DelayMsWord:

DelayMsLoop:                ; Outer loop runs `X` times
    LDI     YL, LOW(2000)   ; Inner loop takes 4 clocks
    LDI     YH, HIGH(2000)  ; so loop 2000 times to get 8000 clocks
DelayMsInnerLoop:           ; Do the delay
    SBIW    Y, 1
    BRNE    DelayMsInnerLoop

    SBIW    X, 1            ; Count outer loop iterations
    BRNE    DelayMsLoop
    ;BREQ    DoneDelayMsWord

DoneDelayMsWord:            ; Done with the delay loop - return
    RET
    
    

; Delay16:
;
; Description:          This procedure delays the number of clocks passed in R16
;                       times 80000.  Thus with a 8 MHz clock the passed delay 
;                       is in 10 millisecond units.
;
; Operation:            The function just loops decrementing Y until it is 0.
;
; Arguments:            R16 - 1/80000 the number of CPU clocks to delay.
; Return Value:         None.
;
; Local Variables:      None.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Registers Changed:    flags, R16, Y (YH | YL),
; Stack Depth:          0 bytes
;
; Author:               Glen George
; Last Modified:        May 6, 2018


Delay16:

Delay16Loop:                ;outer loop runs R16 times
    LDI     YL, LOW(20000)  ;inner loop is 4 clocks
    LDI     YH, HIGH(20000) ;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:               ;do the delay
    SBIW    Y, 1
    BRNE    Delay16InnerLoop

    DEC     R16             ;count outer loop iterations
    BRNE    Delay16Loop


DoneDelay16:                ;done with the delay loop - return
    RET

    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            ARITHMETIC FUNCTIONS                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Div24by16:
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
    BRNE    Div24by16Loop       ; If not done, keep looping
    
    ROL     R18                 ; Done - rotate the last quotient bit in
    ROL     R19 
    ROL     R20 
    COM     R18                 ; and invert quotient (carry flag is
    COM     R19                 ;   inverse of quotient bit)
    COM     R20 
    
EndDiv24by16:
    RET                         ; Done, so return

    
    
; Mul16by8:
;
; Description:          This function multiplies a 16-bit unsigned value passed
;                       in X by the 8-bit unsigned value passed in 
;                       R16. The 24-bit product is returned in R20|R19|R18.
;
; Operation:            Multiplication is performed according to the following 
;                       algorithm:
;                           product = (256 * ZH * R16) + (XL * R16) 
;                       This is done by first multiplying the low byte of 
;                       the 16-bit multiplicand, XL, by R16, and storing the 
;                       result as the product. Then the high byte 
;                       XH is multiplied by R16 and the result is added to the 
;                       upper two bytes of the product. This implements
;                       multiplication by 16^2 = 256. The carry from the 
;                       addition is added to the high byte.
;
; Arguments:            X               - 16-bit unsigned multiplicand.
;                       R16             - 8-bit unsigned multiplicand.
; Return Values:        R20|R19|R18     - 24-bit product
;
; Local Variables:      None.
; Shared Variables:     None.
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
; Algorithms            Multiplication with carry algorithm.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R0, R1, R18, R19, R20
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/15/2018  


Mul16by8:
    MUL     XL, R16         ; Multiply low byte
    MOVW    R19:R18, R1:R0  ; Move the product over to low 2 output registers
    MUL     XH, R16         ; Multiply high byte
    MOV     R20, R1         ; Move the "overflow" to the high output register 
    ADD     R19, R0         ; Add high product to middle byte 
    BRCC    NoIncMulOv      ; If no carry, do not increment high byte 
    INC     R20             ; Otherwise, increment the high byte
NoIncMulOv:
    RET
    