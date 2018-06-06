; ################################ CODE SEGMENT ################################
.cseg



PlayWinTune:
    LDI     ZL, LOW(2 * TuneTableMarioStageClear)   ; Start at beginning of the
    LDI     ZH, HIGH(2 * TuneTableMarioStageClear)  ; win tune table
    LDI     R20, TUNE_MARIOSTAGECLEAR_LEN           ; Get number of tones
    
PlayWinTuneLoop:
    LPM     R16, Z+                     ; Get `PlayNote()` frequency 
    LPM     R17, Z+                     ; in R17|R16 
    PUSH    ZL			                ; Save registers around `PlayNote` call
	PUSH    ZH
	PUSH    R20
    RCALL   PlayNote                    ; Play the tone 
    POP     R20                         ; Restore the registers
    POP     ZH
    POP     ZL
    LPM     XL, Z+                      ; Get delay time in ms in X
    LPM     XH, Z+
    RCALL   DelayMsWord                 ; and wait
    DEC     R20                         ; Decrement loop counter 
    BRNE    PlayWinTuneLoop             ; If have not played all notes, repeat
    ;BREQ    EndPlayWinTune              ; If have played all notes, done 
   
EndPlayWinTune:
    CLR     R16                         ; Turn off the speaker
    CLR     R17
    RCALL   PlayNote
    RET                                 ; Done, so return
    
    
    
TuneTableMarioStageClear:
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
