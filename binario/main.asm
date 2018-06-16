;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  main.asm                                  ;
;                           Binario Game Main File                           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the main loop for the EE 10b 
;                   Binario board. The main loop initializes the stack pointer,
;                   all requisite I/O ports and timers, and the SPI bus for 
;                   interfacing from the external EEROM. The `SelectGame`
;                   function is called to prompt the user to select a starting 
;                   tableau, and then the game state loop `GameLoop` is called.
;                   This function never returns.
;
;                   Submission for Homework 5, EE 10b, by Ray Sun 
;                   California Institute of Technology
;
; Table of Contents:
;
;       .device definition 
;       Include .inc files
;   CODE SEGMENT 
;       Interrupt vector table  (No interrupts for sound / EEROM)
;       Start()                 The main loop.
;   DATA SEGMENT 
;       Stack definitions 
;       Include .asm files 
;
; Game Notes:
;
; Inputs:       User input through the two switches and encoders are polled:
;                       L/R press   Select game (init)
;                                   Toggle current position (gameplay)
;                       U/D press   Reset game to starting tableau (gameplay)
;                       Left rot.   Cycle through games (init)
;                                   Move cursor left (gameplay)
;                       Right rot.  Cycle through games (init)
;                                   Move cursor right (gameplay)
;                       Down rot.   Move cursor down (gameplay)
;                       Up rot.     Move cursor up (gameplay)
;
; Outputs:      The display is used to show an introductory message on 
;               start-up and then the possible games for the user to select. 
;               During gameplay the current state of the game, with the cursor, 
;               is shown. The speaker is used to play various sound effects 
;               corresponding to game events and background music.
;
; Reset:        The user may reset the game during gameplay by pressing the 
;               U/D switch. This will prompt the user to select a new starting 
;               tableau.
;
; Init:         Upon start-up the user is presented with a welcome message. 
;               Then the user is prompted to select a starting tableau by 
;               rotating the L/R encoder, and pressing the L/R switch to
;               confirm. Gameplay then begins, accompained by a sound effect.
;
; Gameplay:     During gameplay, the user may move the position of the cursor 
;               with the rotary encoders. Pressing the L/R switch cycles 
;               the color of the current cursor position 
;                       [Clear] -> [Red] -> [Green] -> [Clear]
;               if the current position can be changed. If the position is 
;               part of the starting tableau (fixed), a "denied" sound effect 
;               is played. Pressing the U/D switch resets the game (see above).
;
; Cursor:       If the current cursor position may be changed, the cursor 
;               blinks between the current position color and the next position 
;               color (that which will be updated if the user presses the L/R 
;               switch). If the current position cannot be changed, the 
;               cursor blinks between yellow and the fixed color. In this
;               fashion the player may always determine
;                   (1) the current color of the cursor position
;                   (2) if the current position can be updated 
;                   (3) if the current position is fixed 
;
; Winning:      When all positions in the game grid are filled, the game 
;               state is checked for correctness. If it matches the game 
;               solution read from the EEROM, the screen is filled with green 
;               and blinking is turned on while a "win" tune is played. 
;               After the tune plays, the solution is restored in order to allow
;               the user to view the solution. The cursor is turned off, and 
;               the state of the game is locked. Pressing the U/D switch 
;               resets the game (see above).
;
; Losing:       If the grid is filled but does not match the solution, the 
;               solution is incorrect. In this case, a short "denied" tune is 
;               played. This tune plays once and does not play again until at 
;               least one position is cleared and the grid is filled incorrectly 
;               again. The user is permitted to change positions to correct 
;               the game; there is no "you lose" outcome.
;
; Revision History:
;    6/14/18    Ray Sun         Initial revision.
;    6/15/18    Ray Sun         Verified all non-extra-credit, in addition to 
;                               playing sound with delays.



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
.include "messagedefines.inc"
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
; Description           This is the main loop for the Binario game. This
;                       procedure sets up the stack pointers and all I/O ports 
;                       and timers needed for the game. It then initializes the 
;                       Binario game state by calling the `SelectGame` function.
;                       Once the user has selected the game, the `GameLoop`
;                       function, which handles the game state, is called. That 
;                       function does not return. 
; 
; Operation             The main loop sets up the stack pointer to the top of 
;                       the stack and calls the functions to initialize the 
;                       system timers, I/O ports, and SPI. The 
;                       `DisplayWelcomeMessage` is called to show the intro 
;                       message. The user is prompted to select a game with 
;                       the `SelectGame` function. Once the game has been 
;                       selected, the `GameLoop` function, which runs the game, 
;                       is called.
; 
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                See `GameLoop` and `SelectGame`, or see above.
; Outputs               The selected game's starting tableau is displayed once 
;                       `GameLoop` is called. The cursor is initially positioned 
;                       in the upper left hand corner.
; 
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
; 
; Limitations           The state of the game is volatile.
; Known Bugs            None.
; Special Notes         None.
;
; Author                Ray Sun
; Last Modified         06/15/2018   


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
    
    RCALL   InitSwEnc           ; Init switch/encoder shared variables.
    RCALL   InitDisp            ; Init display shared variables.
    RCALL   InitEEROM           ; Set up SPI for the external EEROM 
    
    SEI                         ; Turn on global interrupts

    RCALL   DisplayWelcomeMessage   ; Show the introductory message

    RCALL   SelectGame          ; Select the game
    RCALL   GameLoop            ; and update the state as play progresses

;    LDI     ZL, LOW(2 * TuneTabMarioClear)  ; Get Mario stage clear tune
;    LDI     ZH, HIGH(2 * TuneTabMarioClear) ; table (freqs, delays)
;    RCALL   PlayMusic                       ; Play the music
    
;    RCALL   DisplayTest
;    LDI     R16, TRUE
;    RCALL   BlinkDisplay

;TuneTest:
;    RCALL   FillDisplayG
;    LDI     ZL, LOW(2 * TuneTabMarioClear)  ; Get Mario stage clear tune
;    LDI     ZH, HIGH(2 * TuneTabMarioClear) ; table (freqs, delays)
;    LDI     R18, TUNE_MARIOCLEAR_LEN        ; Get number of tones
;    RCALL   PlayTune            ; Play Mario stage clear sound
;    RCALL   FillDisplayR
;    LDI     R16, 255            ; Wait about 2.5 s to repeat
;    RCALL   Delay16
;    RJMP    TuneTest
    
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
.include "message.asm"
.include "tunes.asm"
.include "utility.asm"
.include "disputil.asm"
