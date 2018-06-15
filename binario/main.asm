;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  main.asm                                  ;
;                           Binario Game Main Loop                           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Set the device
.device ATMEGA64

; Chip definitions
.include "m64def.inc"

; Local include files
.include "gendefines.inc"
.include "iodefines.inc"
.include "timerdefines.inc"

.include "gamedefines.inc"
.include "swencdefines.inc"
.include "dispdefines.inc"
.include "sounddefines.inc"
.include "eeromdefines.inc"
.include "tunesdefines.inc"



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
    JMP Timer0CompareHandler    ;timer 0 compare match
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
    JMP PC;Timer3CompareHandler    ;timer 3 compare match A
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
; Description           This is the main loop for testing the functions for 
;                       playing music on the EE 10b Binario board.
; 
; Operation             The main loop sets up the stack pointer to the top of 
;                       the stack and calls the functions to initialize the 
;                       timer for the speaker, the SPI bus for the EEROM, and 
;                       the I/O port. Interrupts are enabled, and then the 
;                       `PlayTune()` procedure is called. The procedure 
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
; Outputs               MEEP.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Author                Ray Sun
; Last Modified         06/06/2018   


Start:                          ; Start the CPU after a reset
    LDI     R16, LOW(TopOfStack)    ; Initialize the stack pointer
    OUT     SPL, R16
    LDI     R16, HIGH(TopOfStack)
    OUT     SPH, R16

    RCALL   InitSwEncDispTimer  ; Set up all timers
    RCALL   InitSpkTimer        ; Initialize speaker timer; turn off speaker
    ;RCALL   InitMusicTimer      ; Set up the no-delay music timer
    RCALL   InitDispPorts       ; Set up all I/O ports
    RCALL   InitEEROMSpkPorts  
    
    RCALL   InitDisp
    RCALL   InitEEROM
    
    RCALL   InitGame            ; Initialize the game state and display it
    
    SEI                         ; Turn on global interrupts
    
;    RCALL   GameLoop            ; and update the state as play progresses

;    LDI     ZL, LOW(2 * TuneTabMarioClear)  ; Get Mario stage clear tune
;    LDI     ZH, HIGH(2 * TuneTabMarioClear) ; table (freqs, delays)
;    RCALL   PlayMusic                       ; Play the music
    
;    RCALL   DisplayTest
;    LDI     R16, TRUE
;    RCALL   BlinkDisplay

TuneTest:
;    RCALL   FillDisplayG
    LDI     ZL, LOW(2 * TuneTabDenied)  ; Get Mario stage clear tune
    LDI     ZH, HIGH(2 * TuneTabDenied) ; table (freqs, delays)
    LDI     R18, TUNE_DENIED_LEN        ; Get number of tones
    RCALL   PlayTune            ; Play Mario stage clear sound
;    RCALL   FillDisplayR
    LDI     R16, 255            ; Wait about 2.5 s to repeat
    RCALL   Delay16
    RJMP    TuneTest
    
	RJMP    Start               ; Should not get here, but if we do, restart



; ################################ DATA SEGMENT ################################
.dseg



; The stack - `STACK_SIZE` bytes
                .BYTE   STACK_SIZE - 1
TopOfStack:     .BYTE   1       ;top of the stack

; Since we do not have a linker, include all the .asm files
.include "timerinit.asm"            ; Initialization function files
.include "swencinit.asm"            
.include "dispinit.asm"
.include "eeromsoundinit.asm"

;.include "hw3test.asm"

.include "binairq.asm"              ; Interrupt handlers

.include "gamestate.asm"
.include "swtchencdr.asm"
.include "display.asm"
.include "sound.asm"
.include "eerom.asm"
.include "tunes.asm"
.include "utility.asm"
.include "disputil.asm"
