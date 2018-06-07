;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                swencinit.asm                               ;
;                  Quadrature Encoder and Switch Init Functions              ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the necessary procedures to 
;                   initialize the I/O port and timers on the ATmega64 in order 
;                   to test the switch and rotary encoder reading functions for 
;                   the EE 10b Binario board.
;
; Table of Contents:
;
;   InitSwEncPorts              Initializes the switch/encoder I/O port 
;   InitSwEncTimer              Initializes Timer 3 for use with the switch/
;                               encoder interrupt handler.
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Removed unnecessary .dseg from file
;    6/06/18    Ray Sun         Renamed file to better reflect purpose and 
;                               replaced references to ports with definitions
;                               in `iodefines.inc`. Added a TOC.



; ################################ CODE SEGMENT ################################
.cseg



; local include files
;.include  "iodefines.inc"
;.include  "swencdefines.inc"



; InitSwEncPorts:
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
; Registers Changed     R16
; Stack Depth           0 bytes
;
; Author            Ray Sun
; Last Modified     06/06/2018


InitSwEncPorts:                         ; Initialize I/O port directions
        LDI     R16, INDATA             ; Initialize port E to all inputs
        OUT     SW_ENC_DDR, R16
        CLR     R16                     ; Disable internal pullups on port E
        OUT     SW_ENC_PORT, R16
        ;RJMP    EndInitSwEncPorts      ; Done initializing ports
        
EndInitSwEncPorts:                       ; Done, so return
        RET

        
        
; InitSwEncTimer:
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


InitSwEncTimer:                     ; Setup timer 3 for switches and encoders
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
    ;RJMP   EndInitSwEncTimer        ; Done setting up the timer

EndInitSwEncTimer:                  ; Done initializing the timer - return
    RET
    