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
;    6/06/18    Ray Sun         Changed `PlayWinTune` function to a general
;                               `PlayTune` function that can play a melody 
;                               of frequencies and note durations passed in 
;                               from a table in program memory.
;    6/12/18    Ray Sun         Added non-delay `PlayMusic` function.


; Local include files
;.include "gendefines.inc"
;.include "iodefines.inc"
;.include "sounddefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                         PLAY MUSIC WITHOUT DELAY                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; PlayMusic:
;
; Description           This procedure plays a series of notes give in a table 
;                       in program memory passed in by reference with Z. The 
;                       music repeats until another call to this function is 
;                       made. 
;
; Operation:            The function makes a series of calls to `PlayNote` and 
;                       while reading through the table by incrementing Z and 
;                       accessing the data with the LPM instruction. The 
;                       The durations in the table are used to update the 
;                       output compare top value of the music timer. When 
;                       an output compare match on the music timer occurs, 
;                       the next note and duration are read from the table.
;
; Arguments             Z       Table of notes and delays to play, in the 
;                               following format
;                                       .DW     NOTE1   .DW     DELAY1
;                                       .DW     NOTE2   .DW     DELAY2
;                                       ...
;                               where the notes are frequencies in Hz, and 
;                               the durations are given in units of 
;                               milliseconds. Pauses in the tone are 
;                               specified with notes of zero frequency. 
;                               The table is terminated with a zero-duration
;                               entry, repeating or ending depending on 
;                               the frequency passed in at the terminator.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
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
; Registers Changed     None.
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/12/2018  


; PlayMusic:
;     STS     MusicTable, ZL              ; Store Z as the start of the tune table 
;     STS     MusicTable + 1, ZH
;     STS     MusicNotePtr, ZL            ; and as the current note pointer (start
;     STS     MusicNotePtr + 1, ZH        ; at beginning of table)
;     
;     LDI     R16, TIMER3A_ON             ; Change the music timer mode to CTC
;     STS     OCR3AH, R16                 ; to enable interrupts.
;     LDI     R16, TIMER3B_ON 
;     STS     OCR3AL, R16
;     
;     RET                                 ; and we are done
; 
;     
; 
; ; StopMusic:
; ;
; StopMusic:
;     RCALL   InitMusicTimer              ; Restore music timer to off state with 
;                                         ; initial output compare value. Also 
;                                         ; clear the counter.
;     CBI     EEROM_SPK_PORT, SPK_PIN     ; Turn off the speaker (output low)
;     RET                                 ; Done, so return 
;     
;     
;     
; ; PlayMusicNextNote:
; ;
; ; Description           This procedure plays a note in a series of notes in 
; ;                       a tune table passed to `PlayMusic`. This function is 
; ;                       called on every music timer output compare interrupt.
; ;                       The current note is played and the corresponding 
; ;                       duration is used to update the music timer output 
; ;                       compare top value. At the next interrupt handler 
; ;                       call, the next note, with the next duration, is played.
; ;                       If the note - delay is a music table terminator (0 
; ;                       delay), the next note is updated appropriately to 
; ;                       either repeat the table or to stop playing music.
; ;
; ; Operation:            
; ;
; ; Arguments             None.
; ; Return Values         None.
; ;   
; ; Global Variables      None.
; ; Shared Variables      None.
; ; Local Variables       R17|R16     Frequency of current note in table.
; ;                       R19|R18     Duration of current note in table.
; ;   
; ; Inputs                None.
; ; Outputs               The speaker plays a tone with the specified duration 
; ;                       from the current music table.
; ;   
; ; Error Handling        None. 
; ; Algorithms            None.
; ; Data Structures       None.
; ;   
; ; Limitations           None.
; ; Known Bugs            None.
; ; Special Notes         This function is intended to be called from the speaker 
; ;                       music timer counter output compare interrupt.
; ;
; ;                       This function is interrupt critical.
; ;
; ; Registers Changed     R16, R17, R18, R19, R20, Z
; ; Stack Depth           0 bytes
; ;
; ; Author                Ray Sun
; ; Last Modified         06/12/2018  
; 
;     
; PlayMusicNextNote:
;     LDS     ZL, MusicNotePtr            ; Load the current music table row 
;     LDS     ZH, MusicNotePtr + 1        ; into Z 
;     LPM     R16, Z+                     ; Get `PlayNote()` frequency 
;     LPM     R17, Z+                     ; in R17|R16 
;     LPM     R18, Z+                     ; Get the duration of the note
;     LPM     R19, Z+                     ; in R19|R18 
;     
;     CLR     R20 
;     CP      R18, R20                    ; If the delay is zero, we are at 
;     CPC     R19, R20                    ; the end of the music table
;     BREQ    MusicTblEnd                 ; Go check for termination or repeat
;     ;BRNE    MusicTblNext:               ; Otherwise we still have notes to play
;     
; MusicTblNext:
;     RCALL   PlayNote                    ; Play the note in R17|R16
;     STS     OCR3AH, R19                 ; Write new delay to output compare
;     STS     OCR3AL, R18                 ; register of the speaker timer
;     
;     ADIW    ZH:ZL, TUNE_TBL_WIDTH       ; Point `MusicNotePtr` to next row 
;     STS     MusicNotePtr, ZL            ; in the music table
;     STS     MusicNotePtr + 1, ZH     
;     RJMP    EndPlayMusicNextNote        ; and we are done
;     
; MusicTblEnd:                            ; If we are at the end of the table
;     LDI     R18, HIGH(NOTE_END)
;     CPI     R16, LOW(NOTE_END)          ; Check if the passed frequency is 
;     CPC     R17, R18                    ; a end-music terminator
;     BREQ    MusicTblRpt                 ; If so, restore beginning of table. 
;     RCALL   StopMusic                   ; Play no music 
;     RJMP    EndPlayMusicNextNote        ; and we are done
;     
; MusicTblRpt:                            ; If we wish to repeat, 
;     LDS     ZL, MusicTable              ; restore the note pointer to the 
;     LDS     ZH, MusicTable + 1          ; beginning of the music table
;     STS     MusicNotePtr, ZL 
;     STS     MusicNotePtr + 1, ZH 
;     ;RJMP    EndPlayMusicNextNote        ; and we are done
;     
; EndPlayMusicNextNote:
;     RET                                 ; We are done, so return
    
    
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                           PLAY MUSIC WITH DELAY                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  
; PlayTune:
;
; Description           This procedure plays a series of notes given in a table
;                       in program memory passed in by reference with Z. The 
;                       number of notes to be played, `n`, is passed by value 
;                       in R18. 
;
; Operation             The function makes a series of calls to `PlayNote` and 
;                       `DelayMsWord` while reading through the table by 
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
; Local Variables       See `PlayNote` and `DelayMsWord`.
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
    CLI                                 ; Don't interrupt division in `PlayNote`
    RCALL   PlayNote                    ; Play the tone 
    SEI                                 ; Re-enable interrupts
    POP     R18                         ; Restore the registers
    
    LPM     XL, Z+                      ; Get duration (word) in milliseconds
    LPM     XH, Z+                      ; in X register
    
    RCALL   DelayMsWord                 ; and wait
    
    DEC     R18                         ; Decrement loop counter 
    BRNE    PlayTuneLoop                ; If have not played all notes, repeat
    ;BREQ    EndPlayTune                 ; If have played all notes, done 
   
EndPlayTune:
    CLR     R16                         ; Turn off the speaker
    CLR     R17
    RCALL   PlayNote
    RET                                 ; Done, so return
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                MUSIC TABLES                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; TuneTableNone:
;
; Description:          This table contains a dummy note `NOTE_RPT` that 
;                       is intended to be played with `PlayMusic` whenever no 
;                       music is desired.
;
; Author:               Ray Sun
; Last Modified:        06/12/2018

;TuneTabNone:
;    .DW     NOTE_END    .DW     1       ; A dummy note to not hog the processor
;    .DW     NOTE_RPT    .DW     0       ; Terminator for repeating
    
    

; TuneTabDenied:
;
; Description:          This table contains a sequence of notes and delays 
;                       to play two short beeps in an "access denied" tune.
;                       Each row in the table comprises two words; the first
;                       is the frequency of the note to play, in Hz, while the 
;                       second is the duration of the note, in milliseconds.
;
; Author:               Ray Sun
; Last Modified:        06/14/2018

TuneTabDenied:
    .DW     NOTE_G3     .DW     150
    .DW     0           .DW     50
    .DW     NOTE_G3     .DW     150
    ; Terminator to use with non-delay music function
    .DW     NOTE_END    .DW     0
    
    

; TuneTab1Up:
;
; Description           This table contains a sequence of notes and durations 
;                       to play the 1-Up sound from Super Mario Bros.
;                       Each row in the table comprises two words; the first
;                       is the frequency of the note to play, in Hz, while the 
;                       second is the duration of the note, in milliseconds.
;
;                       In the Binario game implementation, this sound is 
;                       played upon selecting a game.
;
; Author:               Ray Sun
; Last Modified:        06/14/2018

TuneTab1Up:
    .DW     NOTE_E6     .DW     125
    .DW     NOTE_G6     .DW     125
    .DW     NOTE_E7     .DW     125
    .DW     NOTE_C7     .DW     125
    .DW     NOTE_D7     .DW     125
    .DW     NOTE_G7     .DW     125
    ; Terminator to use with non-delay music function
    .DW     NOTE_END    .DW     0
  
  
  
; TuneTabMarioClear:
;
; Description:          This table contains the values of arguments for the 
;                       `PlayTune` function to play a slightly modified version
;                       of the stage clear tune from Super Mario Bros. 
;                       Each row in the table comprises two words; the first
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
    .DW     NOTE_DS4    .DW     166
    .DW     NOTE_GS4    .DW     166
    .DW     NOTE_C5     .DW     166
    .DW     NOTE_DS5    .DW     166
    .DW     NOTE_GS5    .DW     500
    .DW     NOTE_DS5    .DW     500
    .DW     NOTE_AS3    .DW     166
    .DW     NOTE_D4     .DW     166
    .DW     NOTE_F4     .DW     166
    .DW     NOTE_AS4    .DW     166
    .DW     NOTE_D5     .DW     166
    .DW     NOTE_F5     .DW     166
    .DW     NOTE_AS5    .DW     500
    .DW     0           .DW     50
    .DW     NOTE_AS5    .DW     166
    .DW     0           .DW     50
    .DW     NOTE_AS5    .DW     166
    .DW     0           .DW     50
    .DW     NOTE_AS5    .DW     166
    .DW     NOTE_C6     .DW     750
    ; Terminator to use with non-delay music function
    .DW     NOTE_END    .DW     0
    
    

; ################################ DATA SEGMENT ################################
.dseg



; ------------------------------ SHARED VARIABLES ------------------------------

MusicTable:     .BYTE 2
MusicNotePtr:   .BYTE 2
