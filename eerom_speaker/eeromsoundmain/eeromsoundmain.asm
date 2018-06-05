;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             eeromsoundmain.asm                             ;
;                 Homework #4 Sound and EEROM Testing Main Loop              ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the main loop for testing the 
;                   speaker and EEROM reading routines for the EE 10b Binario 
;                   board. The main loop initializes the stack pointer, the 
;                   speaker and EEROM port, the speaker timer, and the SPI bus.
;                   Then, the `EEROMSoundTest()` procedure is called. This 
;                   procedure tests the speaker routine by playing a sequence 
;                   of notes, and then tests reading from the EEROM by calling
;                   the read procedure while playing notes of increasing pitch. 
;                   Once tests complete successfully, a portion of the Twilight 
;                   Zone theme song is played.
;
;                   This is the main loop for Homework #4, EE 10b.
;
;                   Submission for Homework 4, EE 10b, by Ray Sun 
;                   California Institute of Technology
;
; Table of Contents:
;
;       .device definition 
;       Include .inc files
;   CODE SEGMENT 
;       Interrupt vector table  (No interrupts for sound / EEROM)
;       Start()                 The main loop
;   DATA SEGMENT 
;       Stack definitions 
;       Include .asm files 
;
; Inputs:       None.
; Outputs:      The speaker is used to play tones of various frequencies by 
;               `EEROMSoundTest()`. Additionally, the display is used to 
;               indicate whether the EEROM tests were successful (all green,
;               with a short tone) or not (all red, two short tones).
; 
; Revision History:
;    5/29/18    Ray Sun         Initial revision.
;    6/04/18    Ray Sun         Verified functionality of the speaker and EEROM 
;                               procedures.
;    6/04/18    Ray Sun         Successfully demonstrated HW 4 test code to a TA



; Set the device
.device ATMEGA64

; Chip definitions
.include "m64def.inc"

; Local include files
.include "gendefines.inc"
.include "iodefines.inc"
.include "sounddefines.inc"
.include "eeromdefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; Setup the vector area

.org    $0000

    JMP Start   ;reset vector
    JMP PC      ;external interrupt 0
    JMP PC      ;external interrupt 1
    JMP PC      ;external interrupt 2
    JMP PC      ;external interrupt 3
    JMP PC      ;external interrupt 4
    JMP PC      ;external interrupt 5
    JMP PC      ;external interrupt 6
    JMP PC      ;external interrupt 7
    JMP PC      ;timer 2 compare match
    JMP PC      ;timer 2 overflow
    JMP PC      ;timer 1 capture
    JMP PC      ;timer 1 compare match A
    JMP PC      ;timer 1 compare match B
    JMP PC      ;timer 1 overflow
    JMP PC      ;timer 0 compare match
    JMP PC      ;timer 0 overflow
    JMP PC      ;SPI transfer complete
    JMP PC      ;UART 0 Rx complete
    JMP PC      ;UART 0 Tx empty
    JMP PC      ;UART 0 Tx complete
    JMP PC      ;ADC conversion complete
    JMP PC      ;EEPROM ready
    JMP PC      ;analog comparator
    JMP PC      ;timer 1 compare match C
    JMP PC      ;timer 3 capture
    JMP PC      ;timer 3 compare match A
    JMP PC      ;timer 3 compare match B
    JMP PC      ;timer 3 compare match C
    JMP PC      ;timer 3 overflow
    JMP PC      ;UART 1 Rx complete
    JMP PC      ;UART 1 Tx empty
    JMP PC      ;UART 1 Tx complete
    JMP PC      ;Two-wire serial interface
    JMP PC      ;store program memory ready
    
    
    
; Start:
;
; Description           This is the main loop for testing the functions for 
;                       playing sound and reading from the EEROM on the EE 10b 
;                       Binario board.
; 
; Operation             The main loop sets up the stack pointer to the top of 
;                       the stack and calls the functions to initialize the 
;                       timer for the speaker, the SPI bus for the EEROM, and 
;                       the I/O port. Interrupts are enabled, and then the 
;                       `EEROMSoundTest()` procedure is called. The procedure 
;                       loops forever.
; 
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                None.
; Outputs               The display is controlled by `EEROMSoundTest()` - all 
;                       green if the EEROM tests pass and red otherwise. Also,
;                       the speaker is used to play tones of varying 
;                       frequencies during the EEROM and sound tests.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           `EEROMSoundTest()` does not return, so the program 
;                       cannot be terminated without removing power or resetting
;                       the processor.
; Known Bugs            None.
; Special Notes         None.
;
; Author                Ray Sun
; Last Modified         06/01/2018   



Start:                          ; Start the CPU after a reset
    LDI     R16, LOW(TopOfStack)    ; Initialize the stack pointer
    OUT     SPL, R16
    LDI     R16, HIGH(TopOfStack)
    OUT     SPH, R16

    RCALL   InitEEROMSpkPorts   ; Initialize EEROM and speaker I/O port
    RCALL   InitSpkTimer        ; Initialize speaker timer; turn off speaker
    RCALL   InitEEROM           ; Initialize SPI bus for communication with 
                                ; the EEROM chip
    SEI                         ; Turn on global interrupts

    RCALL   EEROMSoundTest      ; Perform EEROM and sound tests
	RJMP    Start               ; Should not get here, but if we do, restart



; ################################ DATA SEGMENT ################################
.dseg



; The stack - 128 bytes
                .BYTE   127
TopOfStack:     .BYTE   1       ;top of the stack

; Since we do not have a linker, include all the .asm files
.include "hw4test.asm"          ; The test code
.include "eeromsoundinit.asm"
.include "sound.asm"
.include "eerom.asm"
