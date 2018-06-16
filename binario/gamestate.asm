;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 gamestate.asm                              ;
;                       Binario Board Game State Routines                    ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for updating 
;                   the state of the game on the EE 10b Binario board.
;
; Table of Contents:
;
;   CODE SEGMENT
;       Main Game Loop:
;           GameLoop            The main game loop, which handles reading 
;                               user input and updating the state of the game. 
;                               Loops forever. 
;           UpdateGameState     Subroutine for the main game loop. Handles 
;                               reading user input and updating the game state 
;                               buffer when the game is running and not won. 
;                               Polls switch and encoder inputs.
;       Initialization / Reset functions:
;           SelectGame          Allows user to select multiple games by reading 
;                               games from the EEROM according to user input 
;                               (L/R encoder rotations - cycle games). Pressing 
;                               the L/R switch selects the displayed game.
;           LoadGame            Loads the buffers for the game solution and 
;                               the game's fixed positions from a EEROM 
;                               byte address passed in through R17.
;           ResetGame           Resets game state buffer and display buffer to 
;                               the stored game solution and fixed positions.
;                               Called before game start and on an 
;                               U/D switch press.
;
; Revision History:
;    6/14/18    Ray Sun         Initial revision.
;    6/14/18    Ray Sun         Wrote a game initialization function that 
;                               reads the first board (no multi board 
;                               support yet).
;    6/15/18    Ray Sun         Verified non-extra credit gameplay.
;    6/15/18    Ray Sun         Replaced `InitGame` with multiple functions that 
;                               support multiple game selection.
;    6/15/18    Ray Sun         Modified `PlotPixel` to not modify the row 
;                               and column arguments.



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               MAIN GAME LOOP                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; GameLoop:
;
;


GameLoop:
    LDS     R16, gameIsWon          ; Check if the game has been won
    TST     R16                     ; If `hasWon` is TRUE, then do not update 
    BRNE    CheckReset              ; just check for reset.

    RCALL   UpdateGameState         ; Otherwise go check for user input and 
                                    ; update the game state 
    RCALL   IsDone                  ; Check if we are done 
    BRNE    GameNotFilled           ; If not, repeat the game loop 
    RCALL   HasWon                  ; If we are done, check if the game is won 
    BRNE    GameWrong               ; If not, the game is filled in incorrectly 
    ;RJMP    GameWon                ; Otherwise, the game is won 
    
GameWon:
    SER     R16 
    STS     gameIsWon, R16          ; Set has won flag, stop updating game state
    LDI     R16, CURSOR_OFF_IDX     ; Turn off the cursor by calling `SetCursor`
    RCALL   SetCursor               ; with an invalid row argument 
    RCALL   FillDisplayG            ; Fill the display with greens 
    SER     R16
    RCALL   BlinkDisplay            ; and blink the display (TRUE) 
    LDI     ZL, LOW(2 * TuneTabMarioClear)  ; Get Mario stage clear tune
    LDI     ZH, HIGH(2 * TuneTabMarioClear) ; table (freqs, delays)
    LDI     R18, TUNE_MARIOCLEAR_LEN        ; Get number of tones
    RCALL   PlayTune                ; Play Mario stage clear sound
    CLR     R16 
    RCALL   BlinkDisplay            ; Stop blinking display (FALSE)
    LDI     ZL, LOW(gameStateBuf)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameStateBuf)  ; state in Z
    RCALL   SetDisplayBuffer        ; and restore the display buffer with it
                                    ; so user can view solution.
    RJMP    CheckReset              ; go check for reset
    
    
GameWrong:
    LDS     R16, gameIsWrong        ; Load the game-filled-incorrectly flag 
    TST     R16                     ; and check if set
    BRNE    CheckReset              ; If not, go reset - do not play "wrong"
                                    ; tune again until some position is cleared 
    LDI     ZL, LOW(2 * TuneTabDenied)  ; Get denied tune table (freqs, delays)
    LDI     ZH, HIGH(2 * TuneTabDenied) ; in Z
    LDI     R18, TUNE_DENIED_LEN        ; Get number of tones   
    RCALL   PlayTune                ; Play denied sound 
    SER     R16                     ; and set the flag to not play sound again 
    STS     gameIsWrong, R16        ; until a position has been cleared
    RJMP    CheckReset              ; and we are done 

GameNotFilled:                      
    CLR     R16                     ; Clear the game is filled incorrectly 
    STS     gameIsWrong, R16        ; flag if game not filled
    ;RJMP    CheckReset              ; and go check for reset 
    
CheckReset:
    RCALL   UDSwitch                ; Check for reset 
    BRNE    EndGameLoop             ; If no press, repeat loop
    RCALL   SelectGame              ; Otherwise, reset the game.

EndGameLoop:
    RJMP    GameLoop                ; Do not terminate
    RET                             ; Should not get here
    
    
; UpdateGameState:
;
;


UpdateGameState:
    LDS     R16, gameCursorRow      ; Get current cursor (r, c) in 
    LDS     R17, gameCursorCol      ; (R16, R17)
    RCALL   GetPosColor             ; and get the corresponding color in R18    
    
UpdatePosColor:
    RCALL   LRSwitch                ; Check if we have a L/R switch press 
    BRNE    UpdateCrsPos            ; If not, go check for cursor pos updates
    RCALL   CanChange               ; Check if we can change cursor position
    BREQ    CrsCannotChange         ; If not, play denied sound
    ;BREQ    CycleCrsPosColor        ; If have press and can change, go update 
                                    ; color of position
    
CycleCrsPosColor:
    INC     R18                     ; Cycle through colors 
                                    ;       [Clear] -> [R] -> [G] -> [Clear] 
    CPI     R18, N_GAME_COLORS      ; Check if need to wrap around 
    BRLT    NewColorIsGood          ; If new color < # game colors, is good
    LDI     R18, PIXEL_OFF          ; Otherwise wrap around - reset
NewColorIsGood:
    RCALL   PlotGridPos             ; Write the new color to the game state 
                                    ; at the cursor position     
    RCALL   PlotPixel               ; and also update the display
    
    LDI     ZL, LOW(2 * TuneTabCoin)    ; Play the coin collected sound from 
    LDI     ZH, HIGH(2 * TuneTabCoin)   ; Super Mario Bros - get table in Z
    LDI     R18, TUNE_COIN_LEN          ; Get number of tones
    RCALL   PlayTune                    ; Play the tune 
    RJMP    UpdateCrsPos            ; and go check for cursor position updates 

CrsCannotChange:                    ; If the cursor position is fixed and change
    PUSH    R18                     ; Save R18 (current position color)
    LDI     ZL, LOW(2 * TuneTabDenied)  ; is attempted, play denied sound
    LDI     ZH, HIGH(2 * TuneTabDenied) ; Get table start in Z
    LDI     R18, TUNE_DENIED_LEN        ; Get number of tones
    RCALL   PlayTune                    ; Play the tune 
    POP     R18                     ; Restore R18 
    ;RJMP    UpdateCrsPos            ; and go check cursor pos updates
    
UpdateCrsPos:                       ; Poll rotary encoders and update cursor 
                                    ; position as appropriate
    RCALL   LeftRot    
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no left rotation, do not decrement col 
    DEC     R17                     ; Otherwise move cursor left - decrement col
    
    RCALL   RightRot   
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no right rotation, do not increment col 
    INC     R17                     ; Otherwise move cursor right - inc col
    
    RCALL   DownRot    
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no down rotation, do not increment row 
    INC     R16                     ; Otherwise move cursor down - increment row
    
    RCALL   UpRot        
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no up rotation, do not decrement row 
    DEC     R16                     ; Otherwise move cursor up - decrement row
    ;RJMP    CheckNewCrsPos          ; and go check if the new (r, c) is valid
    
CheckNewCrsPos:                     ; Make sure that the new cursor position is
                                    ; in range
CheckRowUvf:
    CPI     R16, 0                  ; Check if new row < 0
    BRGE    CheckRowOvf              ; If not, go check if row > maximum row 
    CLR     R16                     ; If row is negative, set it to the minimum 
CheckRowOvf:
    CPI     R16, N_GAME_ROWS        ; Check if new row > max allowed
    BRLT    CheckColUvf             ; If not, go check columns
    LDI     R16, N_GAME_ROWS - 1    ; If row > max, set row to the max allowed 
CheckColUvf:
    CPI     R17, 0                  ; Check if new col < 0
    BRGE    CheckColOvf             ; If not, go check if col > maximum col 
    CLR     R17                     ; If col is negative, set it to the minimum 
CheckColOvf:
    CPI     R17, N_GAME_COLS        ; Check if new col > max allowed
    BRLT    UpdateCrsColors         ; If not, we are done checking
    LDI     R17, N_GAME_COLS - 1    ; If col > max, set col to the max allowed 
    
UpdateCrsColors:
    RCALL   CanChange               ; Check if we can change the cursor position
    BREQ    UpdateCrsColorsFixed    ; If cannot, update accordingly 
                                    ; Otherwise blink [Curr Color][Next Color]
    MOV     R19, R18                ; Get the current color in R19
    INC     R19                     ; Increment to get next color 
                                    ;       [Clear] -> [R] -> [G] -> [Clear] 
    CPI     R19, N_GAME_COLORS      ; Check if need to wrap around 
    BRLT    NextColorIsGood          ; If new color < # game colors, is good
    LDI     R19, PIXEL_OFF          ; Otherwise wrap around - reset
NextColorIsGood:
    RJMP    UpdateCursor            ; Done - appropriate colors in R18, R19
    
UpdateCrsColorsFixed:               ; If instead the cursor position is fixed 
    LDI     R19, PIXEL_YELLOW       ; One color is yellow
                                    ; The other is color of pos, in R18 
    ;RJMP    UpdateCursor            ; Done - appropriate colors in R18, R19
    
UpdateCursor:
    STS     gameCursorRow, R16      ; Store the updated cursor row 
    STS     gameCursorCol, R17      ; and column
    
    RCALL   SetCursor               ; Finally, update the cursor with the new 
                                    ; position and appropriate colors.
        
EndUpdateGameState:
    RET                             ; We are done, so return 
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                         GAME INITIALIZATION / RESET                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SelectGame:
    LDI     R16, CURSOR_OFF_IDX     ; Turn off the cursor by calling `SetCursor`
    RCALL   SetCursor               ; with an invalid row argument 
    
    LDI     R17, FIRST_GAME_ADDR    ; Read the first game first by default
    
SelectGameLoop:
    RCALL   LeftRot                 ; Decrement down the list of games if L rot
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no left rotation, do not decrement col 
    DEC     R17                     ; Otherwise move cursor left - decrement col
    
    RCALL   RightRot                ; Increment up the list of games if R rot
    IN      R20, SREG
    SBRC    R20, Z_FLAG_BIT         ; If no right rotation, do not increment col 
    INC     R17                     ; Otherwise move cursor right - inc col
    
CheckGameSelUvf:
    CPI     R17, 0                  ; Check if game # < 0
    BRGE    CheckGameSelOvf         ; If not, go check if col > maximum col 
    LDI     R17, N_GAMES - 1        ; If # is negative, wrap around 
CheckGameSelOvf:
    CPI     R17, N_GAMES            ; Check if game # > max allowed
    BRLT    ReadGame                ; If not, we are done checking
    CLR     R17                     ; If col > max, wrap around 
    
ReadGame:
    PUSH    R17                     ; Save the # game reading from around call
    LDI     R16, GAME_EEROM_LEN     ; Get # of bytes to read from EEROM in total
    MUL     R17, R16                ; Get EEROM byte address to read from in 
                                    ; R1|R0
    MOV     R17, R0                 ; Get low byte of product in R17 - games'
                                    ; addresses do not require high byte
    RCALL   LoadGame                ; Get the game solution and fixed positions 
                                    ; from the EEROM
    RCALL   InitGameState           ; Use game soln and fixed pos to update
                                    ; state and display 
    POP     R17                     ; Restore # game.
    RCALL   LRSwitch                ; Check if L/R switch has been pressed 
    BRNE    SelectGameLoop          ; If not, the game has not been selected 
    ;BREQ    EndSelectGame           ; If so, game has been selected
    
EndSelectGame:
    RCALL   ResetGame               ; Put the cursor in upper left corner.
    RET                             ; The game solution, fixed positions, and 
                                    ; game state buffer are in memory.
                                    
                                    
                                    
; LoadGame:
;
;


LoadGame:
    LDI     YL, LOW(gameSolution)   ; Get the memory address of the game
    LDI     YH, HIGH(gameSolution)  ; solution shared variable in Z
    LDI     R16, N_GAME_COLS        ; Get # of bytes to read from first call
    PUSH    R17                     ; Save registers around ReadEEROM call
    PUSH    R16
    RCALL   ReadEEROM               ; Read the solution into `gameSolution`
    POP     R16                     ; and restore the registers
    POP     R17
    ADD     R17, R16                ; R17 <- byte address of first column 
                                    ; in the fixed positions buffer 
    LDI     YL, LOW(gameFixedPos)   ; Get the memory address of the game
    LDI     YH, HIGH(gameFixedPos)  ; fixed positions shared variable in Z
    RCALL   ReadEEROM               ; Read fixed positions into `gameFixedPos`
    ;RJMP    EndLoadGame
    
EndLoadGame:
    RET                             ; We are done, so return
    
    
    
; ResetGame:
;
; Description           This function resets the game to the starting tableau 
;                       initially selected with `SelectGame`                      
;
; Operation             For every physical display column in the game state
;                       buffer, the positions in that column that are filled is 
;                       given by ORing the red column and the green column 
;                       corresponding to the phsical column in the buffer.
;                       All positions in the game grid are filled if each of 
;                       these physical columns are all filled. A flag is 
;                       initialized to TRUE and cleared if any one column is
;                       found to be not completely filled.
;                                     
; Arguments             None.
; Return Values         Z flag              Set if the entire grid is filled 
;                                           and cleared otherwise.
;   
; Global Variables      None.
; Shared Variables      gameStateBuf [W]    The game state display buffer
;                       gameSolution [R]    The game solution read from EEROM 
;                       gameFixedPos [R]    Fixed positions read from EEROM 
;                       gameCursorCol [W]   Cursor column 
;                       gameCursorRow [W]   Cursor row 
;                       gameIsWon [W]       Game has been won flag 
;                       gameIsWrong [W]     Game is filled incorrectly flag
; Local Variables       None.      
;   
; Inputs                None.
; Outputs               The cursor is set to the upper left hand corner and 
;                       blinks according to the state of that position.
;                       
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         This function should not be called before a call to 
;                       `SelectGame`.
;
; Registers Changed     flags
; Stack Depth           9 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018

ResetGame:
    RCALL   InitGameState           ; Restore game state from solution and 
                                    ; fixed positions 
    CLR     R16 
    STS     gameIsWon, R16          ; Clear game won flag 
    STS     gameIsWrong, R16        ; and game filled-and-incorrect flag
    STS     gameCursorCol, R16      ; Set the cursor to the upper left hand 
    STS     gameCursorRow, R16      ; corner (arbitrary)
    
    LDI     ZL, LOW(2 * TuneTab1Up)     ; Play the 1-Up sound from 
    LDI     ZH, HIGH(2 * TuneTab1Up)    ; Super Mario Bros - get table in Z
    LDI     R18, TUNE_1UP_LEN           ; Get number of tones
    RCALL   PlayTune                    ; Play the tune
    
    RET                             ; and we are done 
    
    
 
; InitGameState:
;
;

 
InitGameState:
    CLR     R16                     ; Use R16 as 0 -> GAMEBOARD_COLS counter 
    CLR     R17
    
InitGameStateLoop:
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
              
    LDI     ZL, LOW(gameStateBuf)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameStateBuf)  ; state buffer in Z
    ADD     ZL, R16                 ; Add the current loop index
    ADC     ZH, R17
    ST      Z, R18                  ; Store red column in game statw low col 
    STD     Z + N_GAME_COLS, R19    ; and green column in high col
    
    INC     R16                     ; Increment loop counter
   
    CPI     R16, N_GAME_COLS        ; If have read all the columns
    ;BRGE    InitGameStateUpdateDisp ; we are done - go update the display
    BRLT    InitGameStateLoop       ; Otherwise, we still have columns to read 
    
InitGameStateUpdateDisp:
    LDI     ZL, LOW(gameStateBuf)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameStateBuf)  ; state in Z
    RCALL   SetDisplayBuffer        ; and update the display buffer with it
    ;RJMP    EndInitGameState
    
EndInitGameState:
    RET                             ; We are done, so return 
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                           GAME UTILITY FUNCTIONS                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; IsDone:
;
; Description           This function returns TRUE (Z flag set) if every 
;                       position on the game grid is filled in and FALSE 
;                       (Z flag cleared) otherwise.                       
;
; Operation             For every physical display column in the game state
;                       buffer, the positions in that column that are filled is 
;                       given by ORing the red column and the green column 
;                       corresponding to the phsical column in the buffer.
;                       All positions in the game grid are filled if each of 
;                       these physical columns are all filled. A flag is 
;                       initialized to TRUE and cleared if any one column is
;                       found to be not completely filled.
;                                     
; Arguments             None.
; Return Values         Z flag              Set if the entire grid is filled 
;                                           and cleared otherwise.
;   
; Global Variables      None.
; Shared Variables      gameStateBuf [R]    The game state display buffer
; Local Variables       gameStateCol        Temporary variable to store each  
;                                           column in the game state buffer          
;   
; Inputs                None.
; Outputs               None.
;                       
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags
; Stack Depth           9 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


IsDone:
    PUSH    ZH                      ; Save all used registers
    PUSH    ZL 
    PUSH    R19 
    PUSH    R18 
    PUSH    R17 
    PUSH    R16 
    PUSH    R5
    PUSH    R4 
    IN      R4, SREG                ; and also save the flags
    PUSH    R4 
    
    SER     R16                     ; Use R16 as flag - initially true.
    CLR     R17                     ; and use R17 as 0 -> N_GAME_COLS counter
    LDI     R18, N_GAME_COLS
    LDI     R19, TRUE 
  
IsDoneLoop:
    RCALL   GetGameStateCol         ; Get game state low (reds) column in R4 
    MOV     R5, R4                  ; and copy it to R5
    ADD     R17, R18               
    RCALL   GetGameStateCol         ; Get game state high (greens) col in R4 
    OR      R5, R4                  ; Check if red col & green col != all full 
    CPSE    R5, R19                 ; If all filled, do not clear flag 
    CLR     R16                     ; Otherwise, clear the flag 
    SUBI    R17, N_GAME_COLS - 1    ; Go back to low col and inc counter
    
    CPI     R17, N_GAME_COLS        ; If have looped through all physical 
    ;BRGE    EndIsDone               ; columns, then we are done 
    BRLT    IsDoneLoop              ; Otherwise continue looping through cols
    
EndIsDone:
    POP     R4                      ; Restore all used registers and the 
    OUT     SREG, R4                ; flags
    CPI     R16, TRUE               ; Set the Z flag appropriately
    POP     R4
    POP     R5 
    POP     R16
    POP     R17 
    POP     R18 
    POP     R19 
    POP     ZL 
    POP     ZH
    RET                             ; and we are done



; HasWon:
;
; Description           This function returns TRUE (Z flag set) if the game 
;                       state matches the game solution, and FALSE otherwise.               
;
; Operation             The solution is stored with 
;                               `1` : red           `0` : green 
;                       The game is won if for all red (low) columns in the 
;                       game state display buffer, each column matches 
;                       each column in the solution. This is determined by 
;                       looping through the columns in the solution and 
;                       clearing a flag if any mismatch is found; namely,
;                           gameStateBuf[col] XOR gameSoln[col] != 0
;                                     
; Arguments             None.
; Return Values         Z flag              Set if the game is won
;                                           and cleared otherwise.
;   
; Global Variables      None.
; Shared Variables      gameStateBuf [R]    The game state display buffer
;                       gameSoln [R]        The game solution buffer (`1` for 
;                                           red, `0` for green).
; Local Variables       R4      Stores each column in the game state buffer         
;                       R5      Stores each column in the game solution
;   
; Inputs                None.
; Outputs               None.
;                       
; Error Handling        None. This function does not check if the grid is 
;                       completely full; therefore, the results of this function 
;                       are only meaningful if `IsDone` returns TRUE.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags
; Stack Depth           9 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


HasWon:
    PUSH    ZH                      ; Save all used registers
    PUSH    ZL 
    PUSH    R19 
    PUSH    R18 
    PUSH    R17 
    PUSH    R16 
    PUSH    R5
    PUSH    R4 
    IN      R4, SREG                ; and also save the flags
    PUSH    R4 
    
    SER     R16                     ; Use R16 as flag - initially true.
    CLR     R17                     ; and use R17 as 0 -> N_GAME_COLS counter 
  
HasWonLoop:
    RCALL   GetGameStateCol         ; Get game state low (reds) column in R4 
    CLR     R5 
    LDI     ZL, LOW(gameSolution)   ; Load the solution starting address into Z  
    LDI     ZH, HIGH(gameSolution)
    ADD     ZL, R17                 ; Add column offset in `R17`
    ADC     ZH, R5                  ; and carry through to high byte (+0 w/ C)
    LD      R5, Z                   ; Get solution column in R5
    EOR     R5, R4                  ; Red col XOR solution col should be all
                                    ; cleared if solution is correct
    TST     R5
    BREQ    HasWonColIsGood         ; If all cleared, then don't clear flag 
    CLR     R16                     ; Otherwise clear the flag 

HasWonColIsGood:
    INC     R17                     ; Increment loop counter
    CPI     R17, N_GAME_COLS        ; If have looped through all physical 
    ;BRGE    EndHasWon               ; columns, then we are done 
    BRLT    HasWonLoop              ; Otherwise continue looping through cols
    
EndHasWon:
    POP     R4                      ; Restore all used registers and the 
    OUT     SREG, R4                ; flags
    CPI     R16, TRUE               ; Set the Z flag appropriately
    POP     R4
    POP     R5 
    POP     R16
    POP     R17 
    POP     R18 
    POP     R19 
    POP     ZL 
    POP     ZH
    RET                             ; and we are done
    


; CanChange(r, c):
;
; Description           This procedure returns TRUE (Z flag set) if the grid 
;                       position at (r, c) is allowed to be changed by the user.
;                       Otherwise, FALSE (Z is cleared) is returned.
;
; Operation             The inputs `r` and `c` are checked, and if either is 
;                       invalid (out of range), the function returns. 
;                       Otherwise the column in the initial fixed positions 
;                       buffer corresponding to `c` is read, and whether or not 
;                       the position (r, c) is fixed is determined by inverting 
;                       the result of ANDing the column with a one-hot row mask 
;                       with the bit corresponding to `r`.
;
;                       In the two display buffers (display and game state)
;                       the rows are reversed - the MSB of a column in either 
;                       buffer is Row 0.                       
;                                     
; Arguments             r     R1    Row number of position 
;                       c     R17   (Physical) column number of position
; Return Values         Z flag      Set if position can be changed.
;                                   Cleared otherwise.
;   
; Global Variables      None.
; Shared Variables      gameFixedPos [R]    Initial fixed positions buffer
; Local Variables       fixedPosCol         Column in the buffer of the fixed 
;                                           initial starting positions          
;   
; Inputs                None.
; Outputs               None.
;                       
; Error Handling        If values of `r` or `c` that are out of range of the 
;                       dimensions of the display are passed, FALSE is returned.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags
; Stack Depth           7 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


CanChange:
    CPI     R16, DISP_SIZE          ; Check if `r` < 0 or > last physical col
    BRSH    EndCanChange            ; If so, invalid, so return
    CPI     R17, DISP_SIZE          ; Check if `c` < 0 or > last physical col
    BRSH    EndCanChange            ; If so, invalid, so return 
    
    PUSH    ZH                      ; Save all used registers
    PUSH    ZL 
    PUSH    R17 
    PUSH    R16 
    PUSH    R3
    PUSH    R2 
    IN      R2, SREG                ; and also save the flags
    PUSH    R2 
    
    RCALL   GetRowMask              ; Get row mask corresponding to `r` in R2
    
    CLR     R16
    LDI     ZL, LOW(gameFixedPos)   ; Load the fixed positions' buffer starting 
    LDI     ZH, HIGH(gameFixedPos)  ; address into Z  
    ADD     ZL, R17                 ; Add column offset in `R17`
    ADC     ZH, R16                 ; and carry through to high byte (+0 w/ C)
    LD      R17, Z                  ; Get fixed positions column in R17
    
    AND     R17, R2                 ; Get the bit at (r, c) of interest
    CPSE    R17, R16                ; Check if that bit is set (fixed)
    SER     R16                     ; If not, pos can be changed; set flag (R16)
    RJMP    EndCanChange 

EndCanChange:
    POP     R2                      ; Restore all used registers and the 
    OUT     SREG, R2                ; flags
    CPI     R16, TRUE               ; Set the Z flag appropriately
    POP     R2
    POP     R3 
    POP     R16
    POP     R17 
    POP     ZL 
    POP     ZH
    RET                             ; and we are done        
        
        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            GAME STATE FUNCTIONS                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; PlotGridPos(r, c, color):
;
; Description           This function sets the pixel at row `r` and column `c` 
;                       to the specified color `color` in the game state 
;                       buffer.`r` and `c` are "physical" row/column positions, 
;                       with allowed values from 0 to 7. The color may be clear, 
;                       red, green, or yellow.
;
; Operation             A row mask, a one-hot bit pattern or mask for 
;                       the `r`th LED in the desired column to be turned on or 
;                       off, is constructed. If the red bit (LSB) in `color` is 
;                       set, the red LED (in column `c`) is turned on by ORing
;                       the row mask with the game state display buffer column 
;                       corresponding to `c`, and storing the result back into 
;                       the display buffer. Otherwise, that LED is turned off
;                       by ANDing the inverse of the row mask with the buffer 
;                       column and storing the result. Similarly, if the 
;                       green bit (first bit above LSB) is set, the green LED 
;                       (in column `c` + `N_DISP_COLS`) is turned on by ORing 
;                       with the row mask; else it is turned off by ANDing 
;                       with the inverse of the mask.
;
; Arguments             r               row number,     0 - 7 (0: top)
;                       c               column number,  0 - 7 (0: left)
;                       color           the color to be set (R, G, or Y)
;                               FORMAT: [0000 00(green bit)(red bit)]
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      gameStateBuf [R/W]  - 16-byte buffer indicating which  
;                           bytes in the column (which rows should be on) for 
;                           each of the 16 columns (8 red, 8 green).
; Local Variables       rowMask     The row mask corresponding to `r`
;   
; Inputs                None.
; Outputs               None.
;   
; Error Handling        If invalid arguments are passed (e.g. negative `r`, `c`, 
;                       or `color`, the game state buffer is unchanged.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags, R2, R3, R4, Z
; Stack Depth           2 bytes
;
; Author                Ray Sun
; Last Modified         06/15/2018


PlotGridPos:
    PUSH    R17                 ; Save cursor row and column (R16, R17)
    PUSH    R16
                                ; Do nothing if invalid arguments passed
    CPI     R16, DISP_SIZE      ; Check if `r` negative or > last physical col
    BRSH    EndPlotGridPos      ; If so, invalid, so return
    CPI     R17, DISP_SIZE      ; Check if `c` negative or > last physical col
    BRSH    EndPlotGridPos      ; If so, invalid, so return 
    CPI     R18, NUM_COLORS     ; If `color` is negative or > the number of 
    BRSH    EndPlotGridPos      ; colors, invalid, so return
    
    RCALL   GetRowMask          ; Get row mask for `r` in R2 and inverse in R3
    
PltGPSetLowCol:
    RCALL   GetGameStateCol     ; Get low column (buffer address + `c`) in R4
                                ; and corresponding address in Z
    SBRS    R18, RED_BIT        ; If red bit is set in `color`, turn on red 
    RJMP    PltGPClrLowCol      ; If not set, clear the low column (red)

    OR      R4, R2              ; If set, OR `c`th red column with mask to 
                                ; turn on the red LED at (r, c)
    RJMP    EndPltGPSetLowCol   ; and go store the new buffer
    
PltGPClrLowCol:                 ; If the red bit is not set, clear low column
    AND     R4, R3              ; AND `c`th red column with !mask to turn off 
                                ; the red LED at (r, c)
    ;RJMP    EndPltGPSetLowCol   ; and go store the new buffer 
    
EndPltGPSetLowCol:
    ST      Z, R4               ; Store new buffer at address buffer + `c`
    
PltGPSetHighCol:
    LDI     R16, DISP_SIZE      ; Get the `c` + DISP_SIZE column (the high col) 
    ADD     R17, R16            ; in R4 and the corresponding address in Z.
    RCALL   GetGameStateCol     ; Z is already buffer start address + `c` before
 
    SBRS    R18, GREEN_BIT      ; If green bit is set in `color`, turn on green 
    RJMP    PltGPClrHighCol     ; If not set, clear the high column (green)
    
    OR      R4, R2              ; If set, OR `c`th green column with mask to 
                                ; turn on the green LED at (r, c)
    RJMP    EndPltGPSetHighCol ; and go store the new buffer.
    
PltGPClrHighCol:               ; If the green bit is not set, clear high column
    AND     R4, R3              ; AND `c`th green column with !mask to turn off 
                                ; the green LED at (r, c)
    ;RJMP    EndPltGPSetHighCol ; and go store the new buffer.
    
EndPltGPSetHighCol:        
    ST      Z, R4               ; Write the new `c`th green column buffer
    
EndPlotGridPos:
    POP     R16                 ; Restore row, column arguments 
    POP     R17
    RET                         ; Done, so return
    
    
    
; GetPosColor:
;
; Description           This function returns the color of the position 
;                       (r, c) in the game state display buffer. If the 
;                       passed row `r` or column `c` are invalid, an invalid 
;                       color `COLOR_INVALID` is returned.
;
; Operation             The presence of red and green at (r, c) in the 
;                       game state buffer is determined by ANDing the one-hot 
;                       row mask corresponding to `r` with the corresponding 
;                       two columns in the game state buffer. The color is 
;                       constructed as 
;                                   0000 00[green bit][red bit]
;                                     
; Arguments             r   R16     Row of pixel whose color is desired
;                       c   R17     Physical column # of pixel             
; Return Values         color   R18 The color of the passed position in the 
;                                   game state, or `COLOR_INVALID` if invalid 
;                                   input is provided.
;   
; Global Variables      None.
; Shared Variables      gameState [R] - the game state buffer
; Local Variables       redBit      The bit corresponding to the red LED at 
;                                   (r, c) of the game state buffer   
;                       greenBit    The bit corresponding to the green LED at 
;                                   (r, c) of the game state buffer
;   
; Inputs                None.
; Outputs               None.
;                       
; Error Handling        If the passed `r` and `c` are out of range, an invalid 
;                       color value `COLOR_INVALID` is returned.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags, R2, R3, R4, R16, R17, R18, Z
; Stack Depth           6 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


GetPosColor:
    PUSH    ZH                  ; Save Z,
    PUSH    ZL 
    PUSH    R17                 ; arguments, and
    PUSH    R16 
    PUSH    R3                  ; local variables
    PUSH    R2
    
    CLR     R18
    CPI     R16, N_GAME_ROWS    ; Check if `r` negative or > last physical col
    BRSH    PosInvalidColor     ; If so, invalid, so return
    CPI     R17, N_GAME_COLS    ; Check if `c` negative or > last physical col
    BRSH    PosInvalidColor     ; If so, invalid, so return 
    
    RCALL   GetRowMask          ; Get the row mask for `r` in R2 
                                ; and its logical ! in R3
    RCALL   GetGameStateCol     ; Get the low `c` game state column in R4
    AND     R4, R2              ; Get red bit at (r, c)
    BREQ    PosNoRed            ; If zero, there is no red in the position 
    LDI     R18, PIXEL_RED      ; Else there is red - fill color with red color
    
PosNoRed:                       ; Now check if the position has green
    LDI     R16, N_GAME_COLS 
    ADD     R17, R16            ; Get the high col # (`c` + N_GAME_COLS) in R17 
    RCALL   GetGameStateCol     ; and get the game state column (greens)
    AND     R4, R2              ; Get green bit at (r, c)
    BREQ    EndGetPosColor      ; If zero, there is no green in the position 
    ORI     R18, PIXEL_GREEN    ; Else there is green - fill color with green
    RJMP    EndGetPosColor      ; and we are done 
                                
PosInvalidColor:
    LDI     R18, PIXEL_INVALID  ; Return the "invalid color"
    ;RJMP    EndGetPosColor
    
EndGetPosColor:
    POP     R2                  ; Restore all pushed registers
    POP     R3 
    POP     R16 
    POP     R17 
    POP     ZL 
    POP     ZH
    RET                         ; Done, so return 

    

; GetGameStateCol(index):
;
; Description           This function returns the column (byte) in the game  
;                       state `gameStateBuf` that corresponds to the passed 
;                       argument `index` (R17) in register R4. Additionally, 
;                       the corresponding address of the buffer column is 
;                       returned in Z.
;
; Operation             The address of `gameStateBuf` is loaded into Z and the 
;                       offset is added, with carry into the high byte. The 
;                       contents of the buffer at the address now in Z are 
;                       loaded into R4 with the LPM instruction.
;
; Arguments             index       R17     Offset from start of buffer
;                           Since the buffer is only 16 bytes long, only 
;                           one offset byte is required.
; Return Values                     R4      The buffer column 
;                                   Z       Address of the buffer column
;   
; Global Variables      None.
; Shared Variables      gameStateBuf [R] - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
; Local Variables       None.
;   
; Inputs                None.
; Outputs               None. 
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags, R4, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


GetGameStateCol:
    CLR     R4                  ; Clear R4 for adding 0 w/ carry later
    LDI     ZL, LOW(gameStateBuf)   ; Load the buffer starting address into Z  
    LDI     ZH, HIGH(gameStateBuf)
    ADD     ZL, R17             ; Add offset passed in through `R17`
    ADC     ZH, R4              ; and carry through to high byte (+0 w/ C)
    LD      R4, Z               ; Get buffer column (byte of row LEDs) in R4
    RET                         ; Done, so return

    
    
; ################################ DATA SEGMENT ################################
.dseg



; ------------------------------ SHARED VARIABLES ------------------------------

gameIsWon:          .BYTE   1       ; Flag for if the game is won (active high)
gameIsWrong:        .BYTE   1       ; TRUE if game is filled and incorrect

gameCursorRow:      .BYTE   1       ; Game cursor position
gameCursorCol:      .BYTE   1

gameStateBuf:       .BYTE   16      ; Game state display buffer - holds 
                                    ; columnwise data for the state of each LED
                                    
gameSolution:       .BYTE   8       ; The solution to the current game
                                    ; 8 bytes with first byte as leftmost column
                                    ;   `1` - red; `0` - green
                                    ; This is read in from EEROM.
gameFixedPos:       .BYTE   8       ; The fixed positions in the current game
                                    ; Same format as the game solution, where 
                                    ;   `1` - fixed; `0` - player-changeable
                                    ; This is read in from EEROM.
