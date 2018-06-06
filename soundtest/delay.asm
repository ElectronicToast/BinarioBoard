; ################################ CODE SEGMENT ################################
.cseg



; DelayMsWord():
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
DelayMsLoop:                ; Outer loop runs R16 times
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
    
    

; Delay16():
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
; Registers Changed:    flags, R16, Y (YH | YL)
; Stack Depth:          0 bytes
;
; Author:               Glen George
; Last Modified:        May 6, 2018



Delay16:

Delay16Loop:                ;outer loop runs R16 times
    LDI     YL, LOW(20000)  ;inner loop is 4 clocks
    LDI     YH, HIGH(20000) ;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:           ;do the delay
    SBIW    Y, 1
    BRNE    Delay16InnerLoop

    DEC     R16             ;count outer loop iterations
    BRNE    Delay16Loop


DoneDelay16:                ;done with the delay loop - return
    RET
