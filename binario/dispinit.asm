;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 dispinit.asm                               ;
;              Homework #3 Display Testing Initialization Functions          ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the necessary procedures to 
;                   initialize the I/O ports and timers on the ATmega64 in order 
;                   to test the display functions for the EE 10b Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Port initialization:
;           InitDispPorts()             Initializes the ports of the display 
;       Timer initialization:
;           InitTimer3()                Set up Timer 3 for CTC output compare
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Removed unnecessary .dseg from file
;    5/14/18    Ray Sun         Renamed `init.asm` to `dispinit.asm` and 
;                               modified `InitPorts` to set the display 
;                               ports as output for HW 3 submission. Also
;                               renamed to `InitDispPorts`
;    5/18/18    Ray Sun         Added TOC.



; ################################ CODE SEGMENT ################################
.cseg



; local include files
;.include  "gendefines.inc"
;.include  "iodefines.inc"
;.include  "dispdefines.inc"



; InitDispPorts:
;
; Description           This procedure initializes the I/O ports driving the
;                       display (row output, red column output, green column 
;                       output) as outputs and initializes them as off.
;
; Operation             The constant `OUTDATA`, a byte of 1's to indicate the 
;                       output direction, is loaded into R16 and output to the 
;                       data direction register for the row port and the two
;                       column ports.
;
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                None.
; Outputs               The display row port (C) and column ports (A and D) are 
;                       set as output and initialized to off.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R16
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/14/2018

InitDispPorts:                          ; Initialize I/O port directions
        LDI     R16, OUTDATA            ; Initialize all display ports as 
        OUT     ROW_DDR, R16            ; all outputs
        OUT     COL_R_DDR, R16
        OUT     COL_G_DDR, R16
        CLR     R16                     ; And all outputs are low (off)
        OUT     ROW_PORT, R16
        OUT     COL_PORT_R, R16
        OUT     COL_PORT_G, R16
        ;RJMP    EndInitPorts            ; Done initializing ports
        
EndInitPorts:                           ; Done, so return
        RET

        
        
; InitTimer3:
;
; Description           This procedure initializes the system timers in order to 
;                       test the switch and encoder procedures. Timer 3 is set 
;                       up in CTC mode with a output compare value appropriate 
;                       to read the inputs (1 ms)
; 
; Operation             Timer3 is set up in CTC mode with an appropriate TOP 
;                       value by register writes.
; 
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                None.
; Outputs               Timer 3 is initialized to CTC output compare mode.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R16
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/04/2018

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

EndInitTimer3:                      ; Done initializing the timer - return
    RET
    