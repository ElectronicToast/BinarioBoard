;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  tunes.asm                                 ;
;                         Binario board music routines                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for playing 
;                   music on the EE 10b Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Sound functions:
;           PlayTune()          Play a series of notes, each with a specified 
;                               duration, from a table.
;
; Revision History:
;    6/05/18    Ray Sun         Initial revision.
;    6/06/18    Ray Sun         Changed `PlayWinTune()` function to a general
;                               `PlayTune()` function that can play a melody 
;                               of frequencies and note durations passed in 
;                               from a table in program memory.


; Local include files
;.include "gendefines.inc"
;.include "iodefines.inc"
;.include "sounddefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; PlayTune(Z, n):
;
; Description           This procedure plays a series of notes given in a table
;                       in program memory passed in by reference with Z. The 
;                       number of notes to be played, `n`, is passed by value 
;                       in R18. 
;
; Operation             The function makes a series of calls to `PlayNote()` and 
;                       `DelayMsWord()` while reading through the table by 
;                       incrementing Z and accessing the data with the LPM
;                       instruction
;
; Arguments             Z           Table of notes and delays to play, in the 
;                                   following format
;                                       .DW     NOTE1   .DW     DELAY1
;                                       .DW     NOTE2   .DW     DELAY2
;                                       ...
;                                   where the notes are frequencies in Hz, and 
;                                   the durations are given in units of 
;                                   milliseconds. Pauses in the tone are 
;                                   specified with notes of zero frequency.
;                       n   R18     The number of notes to play; the length 
;                                   of the tune table.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       See `PlayNote()` and `DelayMsWord()`.
;   
; Inputs                None.
; Outputs               The speaker plays a series of tones according to the 
;                       frequencies and delays specified in the passed table.
;   
; Error Handling        None. 
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R2, R3, R16, R17, R18, R19, R20, R22, Z
; Stack Depth           3 bytes
;
; Author                Ray Sun
; Last Modified         06/06/2018  


PlayTune:

PlayTuneLoop:
    LPM     R16, Z+                     ; Get `PlayNote()` frequency 
    LPM     R17, Z+                     ; in R17|R16 
	PUSH    R18                         ; Save registers around `PlayNote` call
    CLI
    RCALL   PlayNote                    ; Play the tone 
    SEI
    POP     R18                         ; Restore the registers
    LPM     XL, Z+                      ; Get duration (word) in milliseconds
    LPM     XH, Z+                      ; in X register
    RCALL   DelayMsWord                 ; and wait
    DEC     R18                         ; Decrement loop counter 
    BRNE    PlayTuneLoop                ; If have not played all notes, repeat
    ;BREQ    EndPlayWinTune              ; If have played all notes, done 
   
EndPlayTune:
    CLR     R16                         ; Turn off the speaker
    CLR     R17
    RCALL   PlayNote
    RET                                 ; Done, so return
    
    
    
; TuneTabMarioClear:
;
; Description:          This table contains the values of arguments for the 
;                       `PlayTune` function to play a slightly modified version
;                       of the stage clear tune from Super Mario Bros. Each 
;                       'row' in the table comprises two words; the first entry
;                       is the frequency of the note to play, in Hz, while the 
;                       second is the duration of the note, in milliseconds.
;
;                       For the Binario game implementation, this tune is 
;                       played upon game completion.
;
; Author:               Ray Sun
; Last Modified:        06/06/2018


TuneTabMarioClear:
    .DW     NOTE_G3     .DW     166
    .DW     NOTE_C4     .DW     166
    .DW     NOTE_E4     .DW     166
    .DW     NOTE_G4     .DW     166
    .DW     NOTE_C5     .DW     166
    .DW     NOTE_E5     .DW     166
    .DW     NOTE_G5     .DW     500
    .DW     NOTE_E5     .DW     500
    .DW     NOTE_E3     .DW     166
    .DW     NOTE_C4     .DW     166
    .DW     NOTE_Eb4    .DW     166
    .DW     NOTE_Ab4    .DW     166
    .DW     NOTE_C5     .DW     166
    .DW     NOTE_Eb5    .DW     166
    .DW     NOTE_Ab5    .DW     500
    .DW     NOTE_Eb5    .DW     500
    .DW     NOTE_Bb3    .DW     166
    .DW     NOTE_D4     .DW     166
    .DW     NOTE_F4     .DW     166
    .DW     NOTE_Bb4    .DW     166
    .DW     NOTE_D5     .DW     166
    .DW     NOTE_F5     .DW     166
    .DW     NOTE_Bb5    .DW     500
    .DW     0           .DW     50
    .DW     NOTE_Bb5    .DW     166
    .DW     0           .DW     50
    .DW     NOTE_Bb5    .DW     166
    .DW     0           .DW     50
    .DW     NOTE_Bb5    .DW     166
    .DW     NOTE_C6     .DW     750
