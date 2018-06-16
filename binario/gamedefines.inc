;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                gamedefines.inc                             ;
;                            Binario Game Definitions                        ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contain definitions related to the 
;                   the state of the Binario game on the EE 10b Binario board.
;
; Table of Contents:
;   EEROM game storage definitions:
;       Address of first game in the EEROM 
;       Number of games stored in EEROM 
;       Size of each game in EEROM
;   Game definitions:
;       Grid dimensions
;       Number of colors in the game
;
; Revision History:
;    6/14/18    Ray Sun         Initial revision.
;    6/15/18    Ray Sun         Added EEROM definitions for multi-game selection 



; EEROM game storage definitions:

.EQU    FIRST_GAME_ADDR = 0             ; # of the first game in the EEROM
.EQU    N_GAMES         = 8             ; Total # of games in the EEROM 
.EQU    GAME_EEROM_LEN  = 16            ; Length of a game in the EEROM - 16 B

; Game definitions:

.EQU    N_GAME_ROWS     = 8             ; Dimensions
.EQU    N_GAME_COLS     = 8
.EQU    N_GAME_COLORS   = 3             ; Number of colors in the game