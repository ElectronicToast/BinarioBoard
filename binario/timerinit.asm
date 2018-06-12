;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               timerdefines.inc                             ;
;                         Binario Game Timer Definitions                     ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains the functions for initializing 
;                   the ATmega64 timers for the EE 10b Binario board, as related 
;                   to the peripherals on the board (rotary encoder switches, 
;                   8x8 red/green LED display, speaker, EEROM).
;
; Table of Contents:
;
;   Timer initialization functions
;       Timer 0 (Encoder/switch reading, display multiplexing - CTC compare):
;           InitSwEncDispTimer
;       Timer 1 (Speaker)
;           InitSpkTimer
;
; Revision History:
;    6/10/18    Ray Sun         Initial revision.



; ################################ CODE SEGMENT ################################
.cseg



; InitSwEncDispTimer:
;
; Description           This procedure initializes the system timers in order to 
;                       test the switch and encoder procedures. Timer 0 is set 
;                       up in CTC mode with an output compare value and prescale 
;                       appropriate to read the inputs and to multiplex the 
;                       display (around 1 ms)
; 
; Operation             Timer 2 is set up in CTC mode with an appropriate TOP 
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
; Outputs               Timer 0 is initialized to CTC output compare mode.
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
; Last Modified         06/10/2018


InitSwEncDispTimer:                 ; Setup timer 2

    LDI     R16, TIMER0_ON          ; Set up the control register TCCR0
    OUT     TCCR0, R16

    CLR     R16                     ; Clear the count register
    OUT     TCNT0, R16              ; Initialize counter to 0

    LDI     R16, TIMER0RATE         ; Set the rate for timer 0
    OUT     OCR0, R16
    
    IN      R16, TIMSK              ; Turn on compare match interrupts
    ORI     R16, 1 << OCIE0
    OUT     TIMSK, R16
    
    ;RJMP   EndInitSwEncDispTimer    ; Done setting up the timer

EndInitSwEncDispTimer:              ; Done initializing the timer - return
    RET
    
    

; InitSpkTimer():
; 
; Description           This procedure initializes the system timers in order to 
;                       test the sound procedures. Timer 1 is set up in normal 
;                       mode in order to turn off the speaker at initialization.
; 
; Operation             Timer1 is set up in normal mode with OCR1A output 
;                       disabled. This disables sound when this initialization 
;                       routine is called. Timer1 will be set in CTC output 
;                       compare mode (toggle OCR1A output) by the function
;                       `PlayNote()` if that function is called with a non-zero 
;                       frequency `f` argument.
;   
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
;   
; Inputs                None.
; Outputs               The speaker is disabled (no tone) when this function 
;                       is called.
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
; Last Modified         06/01/2018  


InitSpkTimer:
    CLR     R16                     ; Clear the Timer1 count registers
    OUT     TCNT1H, R16             ; Initialize counter to 0
    OUT     TCNT1L, R16             

    LDI     R16, TIMER1A_OFF        ; Disable the speaker on start-up by setting
    OUT     TCCR1A, R16             ; Timer1 in normal mode with counter 
    LDI     R16, TIMER1B_OFF        ; disabled.
    OUT     TCCR1B, R16
    ;RJMP    EndInitSpkTimer
    
EndInitSpkTimer:                    ; Done so return
    RET
