;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  INIT.asm                                ;
;              Homework #2 Encoder and Switch Testing Init Functions         ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the necessary procedures to 
;                   initialize the I/O port and timers in order to test the 
;                   switch and rotary encoder reading functions for the EE 10b
;                   Binario board.
;
; Revision History:
;    5/04/18    Ray Sun         Initial version



; ################################ CODE SEGMENT ################################
.cseg



; local include files
;.include  "iodefines.inc"
;.include  "swdefines.inc"



; InitPorts:
;
; Description       This procedure initializes I/O port E as input in order to 
;                   read switch and rotary encoder input. Additionally, all
;                   other ports are set up as input.
;
; Operation         The constant `INDATA`, a byte of 0's to indicate the input 
;                   direction, is loaded into R16 and output to the data
;                   direction register for Port E.
;
; Arguments         None.
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  None.
; Local Variables   None.
; 
; Inputs            None.
; Outputs           None.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed R16
; Stack Depth       0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018

InitPorts:                              ; Initialize I/O port directions
        LDI     R16, INDATA             ; Initialize port E to all inputs
        OUT     DDRE, R16
        CLR     R16                     ; Disable internal pullups on port E
        OUT     PORTE, R16
        ;RJMP    EndInitPorts            ; Done initializing ports
        
EndInitPorts:                           ; Done, so return
        RET

        
        
; InitTimer3:
;
; Description       This procedure initializes the system timers in order to 
;                   test the switch and encoder procedures. Timer 3 is set 
;                   up in CTC mode with a output compare value appropriate 
;                   to read the inputs (1 ms)
; 
; Operation         Timer3 is set up in CTC mode with an appropriate TOP value 
;                   by register writes.
; 
; Arguments         None.
; Return Values     None.
; 
; Global Variables  None.
; Shared Variables  None.
; Local Variables   None.
; 
; Inputs            None.
; Outputs           Timer 3 is initialized.
; 
; Error Handling    None.
; Algorithms        None.
; Data Structures   None.
; 
; Limitations       None.
; Known Bugs        None.
; Special Notes     None.
;
; Registers Changed R16
; Stack Depth       0 bytes
;
; Author            Ray Sun
; Last Modified     05/04/2018

InitTimer3:                         ; Setup timer 3
    LDI     R16, HIGH(TIMER3RATE)   ; Set the rate for timer 3
    STS     OCR3AH, R16             ; Must write high byte first
    LDI     R16, LOW(TIMER3RATE)
    STS     OCR3AL, R16

    CLR     R16                     ; Clear the count register
    STS     TCNT3H, R16             ; Always write high byte first
    STS     TCNT3L, R16             ; Initialize counter to 0

    LDI     R16, TIMER3A_ON         ; Set up both control registers TCCR3
    STS     TCCR3A, R16
    LDI     R16, TIMER3B_ON         
    STS     TCCR3B, R16

    LDS     R16, ETIMSK             ; Get the current timer interrupt masks
    ORI     R16, 1 << OCIE3A        ; Turn on timer 3 compare interrupts
    STS     ETIMSK, R16
    ;RJMP   EndInitTimer3           ; Done setting up the timer

EndInitTimer3:                          ; Done initializing the timer - return
    RET



; ################################ DATA SEGMENT ################################
.dseg
