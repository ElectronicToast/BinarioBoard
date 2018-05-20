;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                dispmain.asm                                ;
;                     Homework #3 Display Testing Main Loop                  ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains `Start`, a main loop that 
;                   initializes the stack, I/O, and shared variables necessary
;                   for the 8x8 dual color LED matrix display of the EE 10b
;                   Binario board and calls the `DisplayTest` function 
;                   to test the display.
;
;                   This is the main loop for Homework #3, EE 10b.
;
;                   Submission for Homework 3, EE 10b, by Ray Sun 
;                   California Institute of Technology
;
; Table of Contents:
;
;       .device definition 
;       Include .inc files
;   CODE SEGMENT 
;       Interrupt vector table
;       Start()                 The main loop
;   DATA SEGMENT 
;       Stack definitions 
;       Include .asm files 
;
; Revision History:
;    5/17/18    Ray Sun         Initial revision.
;    5/18/18    Ray Sun         Included `gendefines.inc` 
;    5/18/18    Ray Sun         Added TOC.
;    5/19/18    Ray Sun         Verified functionality of display testing 
;                               performed by `DisplayTest()`. Successfully 
;                               demonstrated to TA. 
;    5/19/18    Ray Sun         Verified functionality of `PlotImage()` extra 
;                               credit with the `DisplayTestEx()` procedure. 
;                               Blinking doesn't work.



; Set the device
.device ATMEGA64

; Chip definitions
.include "m64def.inc"

; Local include files
.include "gendefines.inc"
.include "iodefines.inc"
.include "dispdefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; Setup the vector area

.org    $0000

    JMP Start                   ;reset vector
    JMP PC                      ;external interrupt 0
    JMP PC                      ;external interrupt 1
    JMP PC                      ;external interrupt 2
    JMP PC                      ;external interrupt 3
    JMP PC                      ;external interrupt 4
    JMP PC                      ;external interrupt 5
    JMP PC                      ;external interrupt 6
    JMP PC                      ;external interrupt 7
    JMP PC                      ;timer 2 compare match
    JMP PC                      ;timer 2 overflow
    JMP PC                      ;timer 1 capture
    JMP PC                      ;timer 1 compare match A
    JMP PC                      ;timer 1 compare match B
    JMP PC                      ;timer 1 overflow
    JMP PC                      ;timer 0 compare match
    JMP PC                      ;timer 0 overflow
    JMP PC                      ;SPI transfer complete
    JMP PC                      ;UART 0 Rx complete
    JMP PC                      ;UART 0 Tx empty
    JMP PC                      ;UART 0 Tx complete
    JMP PC                      ;ADC conversion complete
    JMP PC                      ;EEPROM ready
    JMP PC                      ;analog comparator
    JMP PC                      ;timer 1 compare match C
    JMP PC                      ;timer 3 capture
    JMP Timer3CompareHandler    ;timer 3 compare match A
    JMP PC                      ;timer 3 compare match B
    JMP PC                      ;timer 3 compare match C
    JMP PC                      ;timer 3 overflow
    JMP PC                      ;UART 1 Rx complete
    JMP PC                      ;UART 1 Tx empty
    JMP PC                      ;UART 1 Tx complete
    JMP PC                      ;Two-wire serial interface
    JMP PC                      ;store program memory ready
    
    
    
; Start:
;
; Description           This is the main loop to test the functions for 
;                       multiplexing the 8x8 R/G LED matrix display for the EE 
;                       10b Binario board, in addition to the functions to 
;                       clear the display, set pixels, and set the cursor.
; 
; Operation             The main loop sets up the stack pointer to the top of 
;                       the stack and calls the functions to initialize the 
;                       timers and the shared variables used by the display 
;                       function. Then, the `DisplayTest()` procedure is called.
;                       The procedure loops forever.
; 
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                None.
; Outputs               The display is controlled by `DisplayTest.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           `DisplayTest` loops forever; therefore, the program
;                       cannot be terminated without resetting the processor or 
;                       removing power.
; Known Bugs            None.
; Special Notes         None.
;
; Author                Ray Sun
; Last Modified         05/16/2018   



Start:                          ; Start the CPU after a reset
    LDI     R16, LOW(TopOfStack)    ; Initialize the stack pointer
    OUT     SPL, R16
    LDI     R16, HIGH(TopOfStack)
    OUT     SPH, R16

    RCALL   InitDispPorts       ; Initialize display output ports
    RCALL   InitTimer3          ; Initialize display multiplexing timer
    RCALL   InitDisp            ; Initialize display shared variables, 
                                ; initial cursor position, etc.

    SEI                         ; Turn on global interrupts
     
    RCALL   DisplayTest         ; Perform display tests
    ;RCALL   DisplayTestEx       ; Perform extra credit display tests
    RJMP    Start               ; Should not get here, but if we do, restart



; ################################ DATA SEGMENT ################################
.dseg



; The stack - 128 bytes
                .BYTE   127
TopOfStack:     .BYTE   1       ;top of the stack

; Since we do not have a linker, include all the .asm files
.include "hw3test.asm"          ; The test code
;.include "hw3xtest.asm"         ; The extra credit test code
.include "dispinit.asm"
.include "dispinthdlr.asm"
.include "display.asm"
