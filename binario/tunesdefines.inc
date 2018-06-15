;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               tunesdefines.inc                             ;
;                           Speaker Music Definitions                        ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions related to music 
;                   for the EE 10b Binario board.
;
; Table of Contents:
;   
;   Tune tables' width 
;   Table terminators for use with no-delay music 
;       End terminator frequency
;       Repeat terminator frequency
;   Music tables' lengths
;   Musical notes
;
; Revision History:
;    6/10/18    Ray Sun         Initial revision.
;    6/12/18    Ray Sun         Added terminators for use with the non-delay 
;                               music function



; Width of the tune tables:

.EQU    TUNE_TBL_WIDTH          = 4

; Table terminators 

.EQU    NOTE_END                = 0         ; Frequency to terminate music
.EQU    NOTE_RPT                = 0xFFFF    ; Frequency to repeat music 

; Tune lengths (notes)

.EQU    TUNE_DENIED_LEN         = 3
.EQU    TUNE_1UP_LEN            = 6
.EQU    TUNE_MARIOCLEAR_LEN     = 30

; Musical notes

.EQU    NOTE_B0     = 31
.EQU    NOTE_C1     = 33
.EQU    NOTE_CS1    = 35
.EQU    NOTE_D1     = 37
.EQU    NOTE_DS1    = 39
.EQU    NOTE_E1     = 41
.EQU    NOTE_F1     = 44
.EQU    NOTE_FS1    = 46
.EQU    NOTE_G1     = 49
.EQU    NOTE_GS1    = 52
.EQU    NOTE_A1     = 55
.EQU    NOTE_AS1    = 58
.EQU    NOTE_B1     = 62
.EQU    NOTE_C2     = 65
.EQU    NOTE_CS2    = 69
.EQU    NOTE_D2     = 73
.EQU    NOTE_DS2    = 78
.EQU    NOTE_E2     = 82
.EQU    NOTE_F2     = 87
.EQU    NOTE_FS2    = 93
.EQU    NOTE_G2     = 98
.EQU    NOTE_GS2    = 104
.EQU    NOTE_A2     = 110
.EQU    NOTE_AS2    = 117
.EQU    NOTE_B2     = 123
.EQU    NOTE_C3     = 131
.EQU    NOTE_CS3    = 139
.EQU    NOTE_D3     = 147
.EQU    NOTE_DS3    = 156
.EQU    NOTE_E3     = 165
.EQU    NOTE_F3     = 175
.EQU    NOTE_FS3    = 185
.EQU    NOTE_G3     = 196
.EQU    NOTE_GS3    = 208
.EQU    NOTE_A3     = 220
.EQU    NOTE_AS3    = 233
.EQU    NOTE_B3     = 247
.EQU    NOTE_C4     = 262
.EQU    NOTE_CS4    = 277
.EQU    NOTE_D4     = 294
.EQU    NOTE_DS4    = 311
.EQU    NOTE_E4     = 330
.EQU    NOTE_F4     = 349
.EQU    NOTE_FS4    = 370
.EQU    NOTE_G4     = 392
.EQU    NOTE_GS4    = 415
.EQU    NOTE_A4     = 440
.EQU    NOTE_AS4    = 466
.EQU    NOTE_B4     = 494
.EQU    NOTE_C5     = 523
.EQU    NOTE_CS5    = 554
.EQU    NOTE_D5     = 587
.EQU    NOTE_DS5    = 622
.EQU    NOTE_E5     = 659
.EQU    NOTE_F5     = 698
.EQU    NOTE_FS5    = 740
.EQU    NOTE_G5     = 784
.EQU    NOTE_GS5    = 831
.EQU    NOTE_A5     = 880
.EQU    NOTE_AS5    = 932
.EQU    NOTE_B5     = 988
.EQU    NOTE_C6     = 1047
.EQU    NOTE_CS6    = 1109
.EQU    NOTE_D6     = 1175
.EQU    NOTE_DS6    = 1245
.EQU    NOTE_E6     = 1319
.EQU    NOTE_F6     = 1397
.EQU    NOTE_FS6    = 1480
.EQU    NOTE_G6     = 1568
.EQU    NOTE_GS6    = 1661
.EQU    NOTE_A6     = 1760
.EQU    NOTE_AS6    = 1865
.EQU    NOTE_B6     = 1976
.EQU    NOTE_C7     = 2093
.EQU    NOTE_CS7    = 2217
.EQU    NOTE_D7     = 2349
.EQU    NOTE_DS7    = 2489
.EQU    NOTE_E7     = 2637
.EQU    NOTE_F7     = 2794
.EQU    NOTE_FS7    = 2960
.EQU    NOTE_G7     = 3136
.EQU    NOTE_GS7    = 3322
.EQU    NOTE_A7     = 3520
.EQU    NOTE_AS7    = 3729
.EQU    NOTE_B7     = 3951
.EQU    NOTE_C8     = 4186
.EQU    NOTE_CS8    = 4435
.EQU    NOTE_D8     = 4699
.EQU    NOTE_DS8    = 4978