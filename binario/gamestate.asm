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
    LDS     R16, hasWon             ; Check if the game has been won
    SBRS    R16, 0                  ; If `hasWon` is TRUE, then do not update 
    RCALL   UpdateGameState         ; Otherwise go check for user input and 
                                    ; update the game state 
    ;RCALL   CheckWin
EndGameLoop:
    RJMP    GameLoop                ; Do not terminate
    
    
    
; UpdateGameState:
;
;


UpdateGameState:
    LDS     R16, gameCursorRow      ; Get current cursor (r, c) in 
    LDS     R17, gameCursorCol      ; (R16, R17)
    RCALL   GetPosColor             ; and get the corresponding color in R18
    
    RCALL   LRSwitch                ; Check if we have a L/R switch press 
    BRNE    UpdateCrsPos            ; If not, go check for cursor pos updates
    ;BREQ    UpdateColor             ; If have press, update color of position
    
UpdateColor:
    MOV     R19, R18                ; Store new color in R19
    INC     R18                     ; Cycle through colors 
                                    ;       [Clear] -> [R] -> [G] -> [Clear] 
    CPI     R18, N_GAME_COLORS      ; Check if need to wrap around 
    ;BRGE    WriteNewColor
    
UpdateCrsPos:

EndUpdateGameState:
    RET                             ; We are done, so return 
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             GAME INITIALIZATION                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; InitGame:
;
;


InitGame:
    LDI     YL, LOW(gameSolution)   ; Get the memory address of the game
    LDI     YH, HIGH(gameSolution)  ; solution shared variable in Z
    LDI     R16, N_GAME_COLS        ; Get # of bytes to read from EEROM 
    LDI     R17, FIRST_GAME_ADDR    ; Get the EEROM byte address to read 
                                    ; the first game from 
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
    
LoadGameForLoopInit:                ; Now construct the game state buffer
    CLR     R16                     ; Use R16 as 0 -> GAMEBOARD_COLS counter 
    CLR     R17
    
LoadGameForLoop:
    CPI     R16, N_GAME_COLS        ; If have read all the columns
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
              
    LDI     ZL, LOW(gameStateBuf)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameStateBuf)  ; state buffer in Z
    ADD     ZL, R16                 ; Add the current loop index
    ADC     ZH, R17
    ST      Z, R18                  ; Store red column in game statw low col 
    STD     Z + N_GAME_COLS, R19    ; and green column in high col
    
    INC     R16                     ; Increment loop counter
    RJMP    LoadGameForLoop         ; and check the condition again
    
LoadGameUpdateDisp:
    LDI     ZL, LOW(gameStateBuf)   ; Get the memory address of the game
    LDI     ZH, HIGH(gameStateBuf)  ; state in Z
    RCALL   SetDisplayBuffer        ; and update the display buffer with it
    
    CLR     R16 
    STS     gameIsWon, R16          ; Clear game won flag 
    STS     gameIsWrong, R16        ; and game filled-and-incorrect flag
    STS     gameCursorCol, R16      ; Set the cursor to the upper left hand 
    STS     gameCursorRow, R16      ; corner (arbitrary)
    ;RJMP    EndInitGame
    
EndInitGame:
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
; Registers Changed     flags, R4, R5, R16, R17, R18, R19, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


IsDone:
    SER     R16                     ; Use R16 as flag - initially true.
    CLR     R17                     ; and use R17 as 0 -> N_GAME_COLS counter
    LDI     R18, N_GAME_COLS
    LDI     R19, TRUE 
    
IsDoneForLoop:
    CPI     R17, N_GAME_COLS        ; If have looped through all physical 
    BRGE    EndIsDone               ; columns, then we are done 
    ;BRLT    IsDoneForLoopBody       ; Otherwise continue looping through cols 
  
IsDoneForLoopBody:
    RCALL   GetGameStateCol         ; Get game state low (reds) column in R4 
    MOV     R5, R4                  ; and copy it to R5
    ADD     R17, R18               
    RCALL   GetGameStateCol         ; Get game state high (greens) col in R4 
    AND     R5, R4                  ; Check if red col & green col != all full 
    CPSE    R5, R19                 ; If all filled, do not clear flag 
    CLR     R16                     ; Otherwise, clear the flag 
    SUBI    R17, N_GAME_COLS - 1    ; Go back to low col and inc counter
    RJMP    IsDoneForLoop           ; and check condition again
    
EndIsDone:
    CPI     R16, TRUE               ; Set the Z flag appropriately
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
; Registers Changed     flags, R4, R16, R17, R18, R19, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


HasWon:
    SER     R16                     ; Use R16 as flag - initially true.
    CLR     R17                     ; and use R17 as 0 -> N_GAME_COLS counter
    
HasWonForLoop:
    CPI     R17, N_GAME_COLS        ; If have looped through all physical 
    BRGE    EndHasWon               ; columns, then we are done 
    ;BRLT    HasWonForLoopBody       ; Otherwise continue looping through cols 
  
HasWonForLoopBody:
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
    RJMP    HasWonForLoop           ; and check condition again
    
EndHasWon:
    CPI     R16, TRUE               ; Set the Z flag appropriately
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
; Registers Changed     flags, R2, R3, R16, R17, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


CanChange:
    CPI     R16, DISP_SIZE          ; Check if `r` < 0 or > last physical col
    BRSH    EndCanChange            ; If so, invalid, so return
    CPI     R17, DISP_SIZE          ; Check if `c` < 0 or > last physical col
    BRSH    EndCanChange            ; If so, invalid, so return 
    
    RCALl   GetRowMask              ; Get row mask corresponding to `r` in R2
    
    CLR     R16
    LDI     ZL, LOW(gameFixedPos)   ; Load the fixed positions' buffer starting 
    LDI     ZH, HIGH(gameSolution)  ; address into Z  
    ADD     ZL, R17                 ; Add column offset in `R17`
    ADC     ZH, R16                 ; and carry through to high byte (+0 w/ C)
    LD      R17, Z                  ; Get fixed positions column in R17
    
    AND     R17, R2                 ; Get the bit at (r, c) of interest
    CPSE    R17, R16                ; Check if that bit is cleared (off)
    SER     R16                     ; If not, pos can be changed; set flag (R16)
    RJMP    EndCanChange 

EndCanChange:
    CPI     R16, TRUE               ; Set the Z flag appropriately
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
; Registers Changed     flags, R2, R3, R4, R16, R17, R18, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


PlotGridPos:
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
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


GetPosColor:
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
gameFixedPos:       .BYTE   8       ; The fixed positions in the current game
                                    ; Same format as the game solution, where 
                                    ;   `1` - fixed; `0` - player-changeable
