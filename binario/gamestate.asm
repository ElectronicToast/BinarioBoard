;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 gamestate.asm                              ;
;                       Binario board game state routines                    ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for updating 
;                   the state of the game on the EE 10b Binario board.
;
; Table of Contents:
;
; Revision History:
;    6/14/18    Ray Sun         Initial revision.
;    6/14/18    Ray Sun         Wrote a game initialization function that 
;                               reads the first board (no multi board 
;                               support yet).



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               MAIN GAME LOOP                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; GameLoop:
;
;


GameLoop:

EndGameLoop:
    RJMP    GameLoop                ; Do not terminate
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             GAME INITIALIZATION                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; InitGame:
;
;


InitGame:
    LDI     YL, LOW(gameSolution)   ; Get the memory address of the game
    LDI     YH, HIGH(gameSolution)  ; solution shared variable in Z
    LDI     R16, GAME_COLS          ; Get # of bytes to read from EEROM 
    LDI     R17, FIRST_GAME_ADDR    ; Get the EEROM byte address to read 
                                    ; the first game from 
    PUSH    R17
    PUSH    R16
    RCALL   ReadEEROM               ; Read the solution into `gameSolution`
    POP     R16
    POP     R17
    ADD     R17, R16                ; R17 <- byte address of first column 
                                    ; in the fixed positions buffer 
    LDI     YL, LOW(gameFixedPos)   ; Get the memory address of the game
    LDI     YH, HIGH(gameFixedPos)  ; fixed positions shared variable in Z
    RCALL   ReadEEROM               ; Read fixed positions into `gameFixedPos`
    
LoadGameForLoopInit:                ; Now construct the game state buffer
    CLR     R16                     ; Use R16 as 0 -> GAMEBOARD_COLS counter 
    CLR     R17
    
LoadGameForLoop:
    CPI     R16, GAME_COLS          ; If have read all the columns
    BRGE    LoadGameUpdateDisp      ; we are done - go update the display
    ;BRLT    LoadGameForLoopBody     ; Otherwise, we still have columns to read 
    
LoadGameForLoopBody:
    LDI     ZL, LOW(gameSolution)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameSolution)  ; solution shared variable in Z
    ADD     ZL, R16                 ; Add the current loop index
    ADC     ZH, R17
    LD      R18, Z                  ; R18 <- column of game solution 
    MOV     R19, R18
    COM     R19                     ; R19 = !(game solution column)
    
    LDI     ZL, LOW(gameFixedPos)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameFixedPos)  ; fixed position shared variable in Z
    ADD     ZL, R16                 ; Add the current loop index
    ADC     ZH, R17
    LD      R20, Z                  ; R20 <- column of fixed positions 
    
    AND     R18, R20                ; Red column of game state = 
                                    ; (game solution) AND (fixed positions)
    AND     R19, R20                ; Green column of game state = 
                                    ; !(game solution) AND (fixed positions)
              
    LDI     ZL, LOW(gameState)      ; Get the memory address of the game
    LDI     ZH, HIGH(gameState)     ; state in Z
    ADD     ZL, R16                 ; Add the current loop index
    ADC     ZH, R17
    ST      Z, R18                  ; Store red column in game statw low col 
    STD     Z + GAME_COLS, R19      ; and green column in high col
    
    INC     R16                     ; Increment loop counter
    RJMP    LoadGameForLoop         ; and check the condition again
    
LoadGameUpdateDisp:
    LDI     ZL, LOW(gameState)      ; Get the memory address of the game
    LDI     ZH, HIGH(gameState)     ; state in Z
    RCALL   SetDisplayBuffer        ; and update the display buffer with it
    
EndInitGame:
    RET                             ; We are done, so return
    
    
    
; ################################ DATA SEGMENT ################################
.dseg



; ------------------------------ SHARED VARIABLES ------------------------------

gameState:          .BYTE   16      ; Game state display buffer - holds 
                                    ; columnwise data for the state of each LED
gameSolution:       .BYTE   8       ; The solution to the current game
                                    ; 8 bytes with first byte as leftmost column
                                    ;   `1` - red; `0` - green
gameFixedPos:       .BYTE   8       ; The fixed positions in the current game
                                    ; Same format as the game solution, where 
                                    ;   `1` - fixed; `0` - player-changeable
