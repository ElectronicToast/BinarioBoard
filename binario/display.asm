;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 display.asm                                ;
;                         Binario Game Display Functions                     ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains functions to control the 8x8 
;                   dual color red/green LED matrix on the EE 10B Binario board. 
;
; Table of Contents:
;
;       Display buffer format notes
;   CODE SEGMENT 
;       Display functions:
;           ClearDisplay()              clears the display
;           FillDisplayR()              fills display with all red 
;           FillDisplayG()              fills display with all green
;           PlotPixel(r, c, color)      sets a pixel on the display to a color
;           SetCursor(r, c, c1, c2)     sets cursor position and colors
;       Blink functions: 
;           BlinkDisplay(b)             enables/disables blinking of display
;       Image plotting functions:
;           PlotImage(ptr)              plots image on display
;       Display buffer mutator functions:
;           SetDisplayBuffer(ptr)       sets display buffer to passed buffer
;       Display multiplexer:
;           MuxDisp()                   multiplexes display column-by-column
;       Accessor functions:
;           GetDispBufCol(c)            gets the `c`th (column) byte in disp buf
;       Initialization:
;           InitDisp()                  sets up all shared variables for display
;   DATA SEGMENT 
;       Shared variable list
;
; Revision History:
;    5/14/18    Ray Sun         Initial revision.
;    5/17/18    Ray Sun         Finished `PlotPixel` and `SetCursor`.
;    5/18/18    Ray Sun         Implemented extra credit `BlinkDisplay`, 
;                               `PlotImage`, and yellow as a color.
;    5/19/18    Ray Sun         Verified functionality of `PlotPixel`. Green
;                               in `SetCursor` is buggy.
;    5/19/18    Ray Sun         Fixed `SetCursor`. Modified error handling so 
;                               that either illegal row or column argument 
;                               disables the cursor entirely.
;    5/19/18    Ray Sun         Modified `ClearDisplay` so that the cursor is 
;                               also disabled when the display is cleared.
;    5/19/18    Ray Sun         Verified functionality of display testing 
;                               performed by `DisplayTest`. Successfully 
;                               demonstrated to TA. 
;    5/19/18    Ray Sun         Verified functionality of `PlotImage` extra 
;                               credit with the `DisplayTestEx` procedure. 
;                               Blinking does not occur when enabled.
;    5/19/18    Ray Sun         Removed magic numbers from comments. Edited some 
;                               label names for clarity.
;    5/19/18    Ray Sun         Modified cursor and blink counters to count down 
;                               from their top values, as initial values, rather 
;                               than counting up. Fixed blinking and verified
;                               functionality of `BlinkDisplay`.
;    6/11/18    Ray Sun         Moved `GetRowMask` to a separate display utility 
;                               functions file `disputil.asm`. Added functions
;                               to fill the display with red or green, and 
;                               to write a buffer passed in data memory to 
;                               the display buffer.
;    6/14/18    Ray Sun         Made checking for invalid arguments in 
;                               `PlotPixel` and `SetCursor` more efficient.
;    6/15/18    Ray Sun         Modified `PlotPixel` to not modify the row 
;                               and column arguments.



; Display buffer format:
;
; The LED matrix on the Binario board is organized as follows:
; 
;             PA  7  6  5  4  3  2  1  0      GREEN
;             
;                 Col
;     PC    Row   0  1  2  3  4  5  6  7
;     0       0   () () () () () () () ()
;     1       1   () () () () () () () ()
;     2       2   () () () () () () () ()
;     3       3   () () () () () () () ()
;     4       4   () () () () () () () ()
;     5       5   () () () () () () () ()
;     6       6   () () () () () () () ()
;     7       7   () () () () () () () ()
;     
;             PD   0  1  2  3  4  5  6  7     RED
; 
; The 16-byte display buffer organized as follows:
; 
;     Col     LEDs in col (LSB to MSB)     Counter    Mux Direction
;     0       R00, R01, ..., R07           0          |
;     1       R10, R11, ..., R17           1          |
;     :                                    :          |
;     8       R71, R72, ..., R77           8         \|/
;     ---------------------------------------         :     RESET
;     0       G00, G01, ..., G07           15         :      /|\
;     1       G10, G01, ..., G07           14         :       |
;     :                                    :          :       |
;     8       G70, G71, ..., G77           9          ........|
;     
; where (0, 0) is the top left-hand corner. The multiplexing is done as
; above in order to simplify the multiplexing routine and avoid any need of 
; reversing bytes (The two bytes in the one-hot column output buffer in the 
; multiplexer function, `dispBuf`, can be output directly to the column ports). 



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             DISPLAY FUNCTIONS                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; ClearDisplay:
;
; Description           This procedure clears the 8x8 R/G LED matrix display.
;                       Additionally, the display cursor is also disabled
;                       (no cursor shown at all).
;
; Operation             The display is cleared by clearing the `dispBuf` buffer,
;                       which indicates the LEDs that should be lit in each of 
;                       the 16 columns (8 LEDs for 8 rows in 1 column). The 
;                       starting address of the buffer is loaded into Z and 
;                       each byte is cleared while Z is incremented in a for 
;                       loop that loops from 0 -> N_COLS - 1. The cursor 
;                       is disabled with a call to `SetCursor()` with the 
;                       invalid row and column values used to disable the cursor
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [W] - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
; Local Variables       R17     Index to loop through the columns 
;                               in the display buffer.
;   
; Inputs                None.
; Outputs               None. All LEDs in the display matrix are turned off 
;                       after one cycle of 16 display multiplexer calls.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         The cursor is also disabled when the display is cleared.
;
; Registers Changed     flags, R16, R17, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/16/2018


ClearDisplay:

ClrDispForLoopInit:
    CLR     R16                 ; Use R16 to clear buffer columns (bytes)
    CLR     R17                 ; R17 - loop index, 0 -> N_DISP_COLS - 1
    
    LDI     ZL, LOW(dispBuf)    ; Load the buffer address into Z in order to
    LDI     ZH, HIGH(dispBuf)   ; store with offset later.
    
ClrDispForLoop:
    CPI     R17, N_COLS         ; Check if index >= number of columns
    BRGE    EndClrDispForLoop   ; If so, we are done clearing the buffer
    ;BRLT    ClrDispForLoopBody  ; Else we are not done clearing - continue
    
ClrDispForLoopBody:
    ST      Z+, R16             ; Clear column in buffer and increment address
    INC     R17                 ; Increment loop index
    RJMP    ClrDispForLoop      ; and check condition again

EndClrDispForLoop:              ; If done with clearing, disable the cursor 
    LDI     R16, CURSOR_OFF_IDX ; Pass the cursor disable row/col index as 
    MOV     R17, R16            ; the row and column arguments of `SetCursor` 
    RCALL   SetCursor           ; to disable the cursor.
    ;RJMP    EndClearDisplay     ; and we are done

EndClearDisplay:                ; so return
    RET

    

; FillDisplayR:
;
; Description           This procedure fills the 8x8 R/G LED matrix display.
;                       with all red.
;
; Operation             The display is filled with red by first turning on 
;                       all of the red columns. This is done by writing 
;                       `ALL_LEDS_ON` to each of the red columns in the display 
;                       buffer. Then all of the green columns are turned off 
;                       by writing `ALL_LEDS_OFF` to each of the green columns.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [W] - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
; Local Variables       R17     Index to loop through the columns 
;                               in the display buffer.
;   
; Inputs                None.
; Outputs               None. All red LEDs in the display are turned on while 
;                       all green LEDs are turned off. The cursor is disabled.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         The cursor is also disabled when the display is cleared.
;
; Registers Changed     flags, R16, R17, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/11/2018


FillDisplayR:

SetRLoopInit:                   ; Turn on all of the red LEDs - low cols in buf
    LDI     R16, ALL_LEDS_ON    ; Use R16 to set buffer columns (bytes)
    CLR     R17                 ; R17 - loop index, 0 -> N_DISP_COLS - 1
    
    LDI     ZL, LOW(dispBuf)    ; Load the buffer address into Z in order to
    LDI     ZH, HIGH(dispBuf)   ; store with offset later.
    
SetRLoop:
    CPI     R17, N_DISP_COLS    ; Check if index >= number of display cols
    BRGE    ClrGLoopInit        ; If so, we are done setting the reds
    ;BRLT    SetRLoopBody        ; Else we are not done setting - continue
    
SetRLoopBody:
    ST      Z+, R16             ; Set column in buffer and increment address
    INC     R17                 ; Increment loop index
    RJMP    SetRLoop            ; and check condition again
    
ClrGLoopInit:                   ; Turn off all the green LEDs - high cols in buf
    LDI     R16, ALL_LEDS_OFF   ; Use R16 to clear buffer columns (bytes)
    CLR     R17                 ; R17 - loop index, 0 -> N_DISP_COLS - 1
    
ClrGLoop:
    CPI     R17, N_DISP_COLS    ; Check if index >= number of display cols
    BRGE    EndClrGLoop         ; If so, we are done clearing the greens
    ;BRLT    ClrGLoopBody        ; Else we are not done clearing - continue
    
ClrGLoopBody:
    ST      Z+, R16             ; Set column in buffer and increment address
    INC     R17                 ; Increment loop index
    RJMP    ClrGLoop            ; and check condition again

EndClrGLoop:                    ; If done with clearing, disable the cursor 
    LDI     R16, CURSOR_OFF_IDX ; Pass the cursor disable row/col index as 
    LDI     R17, CURSOR_OFF_IDX ; the row and column arguments of `SetCursor` 
    RCALL   SetCursor           ; to disable the cursor.
    ;RJMP    EndFillDispR        ; and we are done

EndFillDispR:                   ; so return
    RET
    
    
    
; FillDisplayG:
;
; Description           This procedure fills the 8x8 R/G LED matrix display.
;                       with all green.
;
; Operation             The display is filled with green by first turning off 
;                       all of the red columns. This is done by writing 
;                       `ALL_LEDS_OFF` to each red column in the display 
;                       buffer. Then all of the green columns are turned on 
;                       by writing `ALL_LEDS_ON` to each of the green columns.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [W] - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
; Local Variables       R17     Index to loop through the columns 
;                               in the display buffer.
;   
; Inputs                None.
; Outputs               None. All green LEDs in the display are turned on while 
;                       all red LEDs are turned off. The cursor is disabled.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         The cursor is also disabled when the display is cleared.
;
; Registers Changed     flags, R16, R17, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/11/2018


FillDisplayG:

ClrRLoopInit:                   ; Turn off all of the red LEDs - low cols in buf
    LDI     R16, ALL_LEDS_OFF   ; Use R16 to clear buffer columns (bytes)
    CLR     R17                 ; R17 - loop index, 0 -> N_DISP_COLS - 1
    
    LDI     ZL, LOW(dispBuf)    ; Load the buffer address into Z in order to
    LDI     ZH, HIGH(dispBuf)   ; store with offset later.
    
ClrRLoop:
    CPI     R17, N_DISP_COLS    ; Check if index >= number of display cols
    BRGE    SetGLoopInit        ; If so, we are done clearing the reds
    ;BRLT    ClrRLoopBody        ; Else we are not done clearing - continue
    
ClrRLoopBody:
    ST      Z+, R16             ; Clear column in buffer and increment address
    INC     R17                 ; Increment loop index
    RJMP    ClrRLoop            ; and check condition again
    
SetGLoopInit:                   ; Turn on all the green LEDs - high cols in buf
    LDI     R16, ALL_LEDS_ON    ; Use R16 to set buffer columns (bytes)
    CLR     R17                 ; R17 - loop index, 0 -> N_DISP_COLS - 1
    
SetGLoop:
    CPI     R17, N_DISP_COLS    ; Check if index >= number of display cols
    BRGE    EndSetGLoop         ; If so, we are done setting the greens
    ;BRLT    SetGLoopBody        ; Else we are not done setting - continue
    
SetGLoopBody:
    ST      Z+, R16             ; Set column in buffer and increment address
    INC     R17                 ; Increment loop index
    RJMP    SetGLoop            ; and check condition again

EndSetGLoop:                    ; If done with clearing, disable the cursor 
    LDI     R16, CURSOR_OFF_IDX ; Pass the cursor disable row/col index as 
    LDI     R17, CURSOR_OFF_IDX ; the row and column arguments of `SetCursor` 
    RCALL   SetCursor           ; to disable the cursor.
    ;RJMP    EndFillDispG        ; and we are done

EndFillDispG:                   ; so return
    RET
    
    
    
; PlotPixel(r, c, color):
;
; Description           This function sets the pixel at row `r` and column `c` 
;                       to the specified color `color`.`r` and `c` are 
;                       "physical" row/column positions, with allowed values 
;                       from 0 to 7. The color may be clear, red, green, or 
;                       yellow.
;
; Operation             A row mask, a one-hot bit pattern or mask for 
;                       the `r`th LED in the desired column to be turned on or 
;                       off, is constructed. If the red bit (LSB) in `color` is 
;                       set, the red LED (in column `c`) is turned on by ORing
;                       the row mask with the display buffer column 
;                       corresponding to `c`, and storing the result back into 
;                       the display buffer. Otherwise, that LED is turned off
;                       by ANDing the inverse of the row mask with the buffer 
;                       column and storing the result. Similarly, if the 
;                       green bit (first bit above LSB) is set, the green LED 
;                       (in column `c` + `N_DISP_COLS`) is turned on by ORing 
;                       with the row mask; else it is turned off by ANDing 
;                       with the inverse of the mask.
;
; Arguments             r       R16     row number,     0 - 7 (0: top)
;                       c       R17     column number,  0 - 7 (0: left)
;                       color   R18     the color to be set (R, G, or Y)
;                               FORMAT: [0000 00(green bit)(red bit)]
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [R/W] - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
; Local Variables       R4      Contents of buffer column at `c` (used for 
;                               writing both low and high columns of `c`) 
;                       R2      One-hot mask for which LED in the col to turn on 
;                       R3      Inverse (NOT) of row mask
;   
; Inputs                None.
; Outputs               None. The desired pixel on the display is set to the 
;                       specified color with display multiplexer calls.
;   
; Error Handling        If invalid arguments are passed (e.g. negative `r`, `c`, 
;                       or `color`, the display buffer is unchanged.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     flags, R4, R17, Z
;       + subroutines   R2, R3
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/15/2018


PlotPixel:
    PUSH    R17                 ; Save cursor row and column (R16, R17)
    PUSH    R16
                                ; Do nothing if invalid arguments passed
    CPI     R16, N_DISP_ROWS    ; Check if `r` negative or > last physical col
    BRSH    EndPlotPixel        ; If so, invalid, so return
    CPI     R17, N_DISP_COLS    ; Check if `c` negative or > last physical col
    BRSH    EndPlotPixel        ; If so, invalid, so return 
    CPI     R18, N_COLORS       ; If `color` is negative or > the number of 
    BRSH    EndPlotPixel        ; colors, invalid, so return
    
    RCALL   GetRowMask          ; Get row mask for `r` in R2 and inverse in R3
    
PltPixSetLowCol:
    RCALL   GetDispBufCol       ; Get low column (buffer address + `c`) in R4
                                ; and corresponding address in Z
    SBRS    R18, RED_BIT        ; If red bit is set in `color`, turn on red 
    RJMP    PltPixClrLowCol     ; If not set, clear the low column (red)

    OR      R4, R2              ; If set, OR `c`th red column with mask to 
                                ; turn on the red LED at (r, c)
    RJMP    EndPltPixSetLowCol  ; and go store the new buffer
    
PltPixClrLowCol:                ; If the red bit is not set, clear low column
    AND     R4, R3              ; AND `c`th red column with !mask to turn off 
                                ; the red LED at (r, c)
    ;RJMP    EndPltPixSetLowCol  ; and go store the new buffer 
    
EndPltPixSetLowCol:
    ST      Z, R4               ; Store new buffer at address buffer + `c`
    
PltPixSetHighCol:
    LDI     R16, N_DISP_COLS    ; Get the `c` + N_DISP_COLS col (the high col) 
    ADD     R17, R16            ; in R4 and the corresponding address in Z.
    RCALL   GetDispBufCol       ; Z is already buffer start address + `c` before
 
    SBRS    R18, GREEN_BIT      ; If green bit is set in `color`, turn on green 
    RJMP    PltPixClrHighCol    ; If not set, clear the high column (green)
    
    OR      R4, R2              ; If set, OR `c`th green column with mask to 
                                ; turn on the green LED at (r, c)
    RJMP    EndPltPixSetHighCol ; and go store the new buffer.
    
PltPixClrHighCol:               ; If the green bit is not set, clear high column
    AND     R4, R3              ; AND `c`th green column with !mask to turn off 
                                ; the green LED at (r, c)
    ;RJMP    EndPltPixSetHighCol ; and go store the new buffer.
    
EndPltPixSetHighCol:        
    ST      Z, R4               ; Write the new `c`th green column buffer
    
EndPlotPixel:
    POP     R16                 ; Restore row, column arguments 
    POP     R17
    RET                         ; Done, so return


    
; SetCursor(r, c, c1, c2):
;
; Description           This procedure sets the cursor of the EE 10b Binario 
;                       board display to a specified row `r` and column `c`. 
;                       The cursor will blink using the passed colors `c1` and 
;                       `c2`. The cursor is considered to alternate between 
;                       two states, 'ON' and 'OFF', as stored in the shared 
;                       flag `cursorState`, where Color 1 is displayed when 
;                       'ON' (TRUE) and Color 2 is displayed when 'OFF' (FALSE). 
;
; Operation             Shared variables for the two cursor columns 
;                       corresponding to the `physical` cursor column `c` are 
;                       stored. Additionally, a one-cold row mask to be used 
;                       for turning off the cursor pixel at (r, c) is stored.
;                       Furthermore, four one-hot row masks - one for each LED 
;                       for each of the cursor states - are stored. The cursor 
;                       is disabled by passing an invalid row argument `r` or 
;                       column argument `c` to this function.
;
; Arguments             r       R16     row number,     0 - 7 (0: top)
;                       c       R17     column number,  0 - 7 (0: left)
;                       c1      R18     the first color to blink with 
;                       c2      R19     the second color to blink with 
;                           0 - none (pixel is off)
;                           1 - red 
;                           2 - green
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      cursorLowCol [W] - column number (0-7) of the cursor 
;                           position in the low columns (red) = `c`
;                       cursorHighCol [W] - column number (8-15) of the cursor 
;                           position in the high columns (green) = `c` + 8
;                       cursorNotRowMask [W] - one-cold row mask with the 
;                           cursor pixel (`r`) off.
;                       cursorRMsk1 [W]- one-hot row mask for red LED, state 1
;                       cursorRMsk2 [W]- one-hot row mask for red LED, state 2
;                       cursorGMsk1 [W]- one-hot row mask for green LED, state 1
;                       cursorGMsk2 [W]- one-hot row mask for green LED, state 2
;   
; Inputs                None.
; Outputs               The desired cursor position `r`, `c` on the display is 
;                       set to blink with the specified colors with calls 
;                       to the display multiplexer from the interrupt handler.
;   
; Error Handling        If the passed row number `r` or column number `c` is out 
;                       of bounds (negative or greater than 7), the cursor is 
;                       is turned off entirely ("disabled"). No error handling 
;                       is performed for color arguments.
;                       
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         The cursor blinks between two states, which we call 
;                       ON or State 1 (c1 is displayed) and OFF or State 2 (c2 
;                       is displayed). The current state is stored in the flag 
;                       `cursorState` (if ON, TRUE; if OFF, FALSE) and used in 
;                       the display multiplexer function. 
;
; Registers Changed     flags, R16, R17, R20
;       + subroutines   R2, R3, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/14/2018


SetCursor:
    CPI     R16, N_DISP_ROWS    ; If `r` is negative or > last physical column, 
    BRSH    DisableCursor       ; is invalid, so go disable the cursor
    CPI     R17, N_DISP_COLS    ; If `c` is negative or > last physical column, 
    BRSH    DisableCursor       ; is invalid, so go disable the cursor 
    CPI     R18, N_COLORS       ; If either passed color is invalid (negative
    BRSH    DisableCursor       ; or > largest # color) disable the cursor 
    CPI     R19, N_COLORS
    BRSH    DisableCursor
    
    RJMP    StoreCursorCols     ; If we are good, go store the cursor cols
    
DisableCursor:                  ; If we have invalid `r` or `c` argument
	LDI 	R17, CURSOR_OFF_IDX
    STS     cursorLowCol, R17   ; Store the invalid rpw/column index indicator 
    STS     cursorHighCol, R17  ; as the low and high columns 
    RJMP    EndSetCursor        ; No need to update the individual state masks 
                                ; muxer will never be on a cursor column
StoreCursorCols:
    STS     cursorLowCol, R17   ; Store the two cursor columns - `c` and `c` +
    LDI     R20, N_DISP_COLS    ; N_DISP_COLS (for red and green LEDs) - in
	ADD     R17, R20
    STS     cursorHighCol, R17  ; `cursorLowCol` and `cursorHighCol`
    
    RCALL   GetRowMask          ; Get the one-hot row mask for `r` in R2 and 
                                ; its NOT in R3
    STS     cursorNotRowMask, R3    ; Store !(row mask) for use in display muxer
    CLR     R16                 ; Clear R16 for later use in turning masks off
    ;RJMP    SetCrsCheckC1R
    
SetCrsCheckC1R:                 ; Check if `c1` has any red in it
    SBRC    R18, RED_BIT        ; See if `c1` has the red bit set
    RJMP    SetCrsC1RMask       ; If so, turn on red 
    STS     cursorRMsk1, R16    ; Otherwise, red mask for state 1 is all off
    RJMP    SetCrsCheckC2R      ; Go check if `c2` has red
    
SetCrsC1RMask:                  ; If `c1` has the red bit set
    STS     cursorRMsk1, R2     ; red mask for state 1 is the row mask, R2
    ;RJMP    SetCrsCheckC2R
   
SetCrsCheckC2R:                 ; Check if `c2` has any red in it
    SBRC    R19, RED_BIT        ; See if `c2` has the red bit set
    RJMP    SetCrsC2RMask       ; If so, turn on red 
    STS     cursorRMsk2, R16    ; Otherwise, red mask for state 2 is all off
    RJMP    SetCrsCheckC1G      ; and go check if `c1` has any green in it
    
SetCrsC2RMask:                  ; If `c2` has the red bit set
    STS     cursorRMsk2, R2     ; red mask for state 2 is the row mask, R2
    ;RJMP    SetCrsCheckC1G     ; and go check if `c1` has any green in it
    
SetCrsCheckC1G:                 ; Now check if `c1` has any green in it
    SBRC    R18, GREEN_BIT      ; See if `c1` has the green bit set
    RJMP    SetCrsC1GMask       ; If so, turn on green 
    STS     cursorGMsk1, R16    ; Otherwise, green mask for state 1 is all off
    RJMP    SetCrsCheckC2G      ; Go check if `c2` has green
    
SetCrsC1GMask:                  ; If `c1` has the green bit set 
    STS     cursorGMsk1, R2     ; green mask for state 1 is the row mask, R2
    ;RJMP    SetCrsCheckC2G
   
SetCrsCheckC2G:                 ; Check if `c2` has any green in it
    SBRC    R19, GREEN_BIT      ; See if `c2` has the green bit set
    RJMP    SetCrsC2GMask       ; If so, turn on green 
    STS     cursorGMsk2, R16    ; Otherwise, green mask for state 2 is all off
    RJMP    EndSetCursor        ; and we are done
    
SetCrsC2GMask:                   ; If `c2` has the green bit set
    STS     cursorGMsk2, R2     ; green mask for state 2 is the row mask, R2
    ;RJMP    EndSetCursor       ; and we are done
    
EndSetCursor:
    RET                         ; Done, so return 
    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                              DISPLAY BLINKING                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; BlinkDisplay(b):
;
; Description           This function enables blinking of the display if the 
;                       passed flag `b` is TRUE, and turns off blinking if `b` 
;                       is FALSE.
;
; Operation             A shared variable `blinkEn` is used to enable or 
;                       disable blinking. The flag `b` is stored in 
;                       `blinkEn`, which causes the multiplexing function 
;                       to blink the display.
;
; Arguments             b       R16     Whether to enable/disable blinking
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      blinkEn [W] - shared flag that is TRUE if the display
;                           blinking is enabled and FALSE otherwise.
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
; Special Notes         "Blinking" indicates that whatever is on the display 
;                       without blinking enabled is displayed for half of 
;                       some period, and the display is clear for the other 
;                       half of that period.
;
; Registers Changed     None.
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/17/2018


BlinkDisplay:
    STS     blinkEn, R16        ; Write flag to `blinkEn` to en/disable blinking
    RET                         ; Done so return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                PLOT IMAGE                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; PlotImage(ptr):
;
; Description           This function takes in a pointer `ptr` to an image 
;                       stored in 16 bytes in program memory and displays the 
;                       specified image on the LED matrix.
;
; Operation             The image passed is formatted in interleaved columns:
;                                   [R0][G0][R1][G1] ... [R7][G7]
;                       while the display buffer has the format 
;                                   [R0]...[R7], [G0]...[G7]
;                       In order to store the image into the buffer, a for loop 
;                       that writes two columns (the red and green columns of a 
;                       `physical` column on the display) to the buffer per 
;                       iteration. The loop index runs from 0 -> N_DISP_COLS - 
;                       1. The red column corresponding to the index 
;                       in the buffer is written from the `index`th byte in the 
;                       image. Then the green column corresponding to the index 
;                       (`index` + N_DISP_COLS) is written from the (`index`+1) 
;                       th byte in the image. Y is used to point to the column 
;                       of interest in the buffer and is incremented once per 
;                       loop (Y and Y + N_DISP_COLS are written) while Z is 
;                       incremented twice.
;
; Arguments             ptr     Z   16 bytes in program memory 
;                           - Format: 8 red columns (starting with left-most)
;                             interleaved with 8 green columns (starting with 
;                             left-most)
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [W] - The display buffer, indicating which row  
;                           LEDs in each of the 16 columns should be lit.
; Local Variables       Y           Pointer to columns in the display buffer
;                       R16         Loop index for writing to buffer, 0 ->
;                                   N_DISP_COLS - 1
;   
; Inputs                None.
; Outputs               The image is loaded into the display buffer and 
;                       displayed on the LED matrix with calls to the 
;                       display multiplexer from the interrupt handler.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         This function loads the red columns ("low" columns in 
;                       the buffer) and the green columns ("high" columns) 
;                       individually. Thus, the color yellow is supported.
;
; Registers Changed     flags, R16, R17, Y, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/18/2018


PlotImage:
    LDI     YL, LOW(dispBuf)    ; Load the buffer address into Y  
    LDI     YH, HIGH(dispBuf)

PltImgForLoopInit:
    CLR     R16                 ; Initialize R16 to 0 for use as loop index
    
PltImgForLoop:
    CPI     R16, N_DISP_COLS    ; If index > N_DISP_COLS - 1, done loading 
    BRGE    EndPlotImage        ; the image - return
    ;BRLT    PltImgForLoopBody   ; Otherwise continue loading reds
     
PltImgForLoopBody:              ; Get and store two rows (1 physical col) of img
    LPM     R17, Z+             ; Get even (red) image col and increment image 
                                ; pointer to go through the image
    ST      Y, R17              ; and store it in the corresponding buffer col
    ADIW    Y, N_DISP_COLS      ; Add N_DISP_COLS to Y to point to green column
    LPM     R17, Z+             ; Get odd (green) img col and inc pointer again
    ST      Y, R17              ; and store it in the corresponding buffer col
    SBIW    Y, N_DISP_COLS - 1  ; Go back to the reds 1 physical column down 
    INC     R16                 ; Increment the loop index
    RJMP    PltImgForLoop       ; and check the loop condition again

EndPlotImage:
    RET                         ; Done so return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            SET DISPLAY BUFFER                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; SetDisplayBuffer(ptr)
;
; Description           This function takes in a pointer `ptr` to a display  
;                       buffer stored in 16 bytes in data memory and writes 
;                       the passed buffer to the display buffer.
;
; Operation             The passed buffer in data memory has the same format 
;                       as the display buffer; namely,
;                                   [R0]...[R7], [G0]...[G7]
;                       To write the passed buffer to the display buffer, Y 
;                       is initialized to point to the address of the display 
;                       buffer. The contents pointed to by Z are stored at Y, 
;                       then both Z and Y are postincremented. Since the display 
;                       buffer has `N_COLS` columns, this is done for
;                       `N_COLS` times.
;
; Arguments             ptr     Z   16 byte buffer in data memory 
;                           - Format: Same as display buffer.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispBuf [W] - The display buffer, indicating which row  
;                           LEDs in each of the 16 columns should be lit.
; Local Variables       Y           Pointer to columns in the display buffer
;                       R16         Loop index for writing to buffer, 0 ->
;                                   NUM_COLS - 1
;   
; Inputs                None.
; Outputs               The passed buffer is loaded into the display buffer and 
;                       displayed on the LED matrix with calls to the 
;                       display multiplexer from the interrupt handler.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         This function loads the red columns ("low" columns in 
;                       the buffer) and the green columns ("high" columns) 
;                       individually. Thus, the color yellow is supported.
;
; Registers Changed     flags, R16, R17, Y, Z
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/11/2018


SetDisplayBuffer:
    LDI     YL, LOW(dispBuf)    ; Load the buffer address into Y  
    LDI     YH, HIGH(dispBuf)
    
SetDispBufLoopInit:
    CLR     R16                 ; Use R16 as loop index, 0 -> NUM_COLS
    
SetDispBufLoop:
    CPI     R16, N_COLS         ; If index > N_COLS - 1, we are done 
    BRGE    EndSetDisplayBuffer 
    ;BRLLT   SetDispBufLoopBody  ; Otherwise we are not done - continue writing

SetDispBufLoopBody:
    LD      R17, Z+             ; Copy contents at Z to display buffer pointer
    ST      Y+, R17             ; while postincrementing both pointers
    INC     R16                 ; Increment loop index
    RJMP    SetDispBufLoop      ; and check loop condition again.
    
EndSetDisplayBuffer:
    RET                         ; We are done, so return 
    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            DISPLAY MULTIPLEXER                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; MuxDisp:
;
; Description           This function performs multiplexing of the LED matrix 
;                       display per display interrupt handler call. One column 
;                       of the matrix is displayed per period between calls. 
;                       This function should be called regularly so that the 
;                       display appears to be on continuously (e.g. at a 
;                       rate of 1 ms or below).     
;
; Operation             A column counter `dispColCtr` cycles through the 16
;                       columns in the order
;                                       R0 -> R7, G0 -> G7
;                       while a 16-bit one-hot column mask `dispColMask`, which
;                       indicates the single column to be displayed, is rotated 
;                       such that the columns are active in that order.
;                       The high 8 bits of this mask are written to the green 
;                       column port (A), while the low 8 bits are written to the 
;                       red LED column port (D). The column in the display 
;                       buffer `dispBuf` corresponding to `dispColCtr` is 
;                       simultaneously output to the row port (C). This turns on 
;                       1 of the 16 columns with the appropriate LEDs in that 
;                       column.
;
;                       Cursor blinking is performed by checking whether the 
;                       current column is the (physical) cursor column. If so,
;                       and the desired cursor color corresponding to the 
;                       current state matches with the LED color of the current 
;                       column, the cursor LED is turned on. Else the cursor 
;                       is turned off.
;
;                       If display blinking is enabled, blinking is handled by 
;                       a flag `blinkOff` that turns off the entire display 
;                       at a specified constant rate.
;
;                       Both the cursor state and blink state are toggled when 
;                       respective counters reach a predefined top value.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispColCtr [R/W} - 0 - 15 counter that keeps track of  
;                           which column we are at 
;                                       0 ... 8,  9 ...15
;                                       R0    R7  G0   G7
;                       dispRowBuf [R] - 16-byte buffer indicating which rows 
;                           to turn on during each call of `MuxDisp()`.
;                       dispColMask [R/W] - 16-bit one-hot column mask indicating
;                           which column to display
;                               low  8 - reds   (LSB is red column 7)
;                               high 8 - greens (LSB is green column 0)
;                           Initialized to [0000 0000 0000 0001] (red col 0)
;                           The 1 is rotated as follows around the buffer
;                                         PORT A   PORT D
;                                       G0     G7 R7     R0
;                                       0000 0000 0000 0001 <---
;                                       0000 0000 1<-- ----
;                                  ---> 1000 0000 0000 0000
;                                       ---- -->1 0000 0000, RESET
;                           causing the columns to display in the order 
;                                       R0 -> R7 -> G0 -> G7
;                       cursorLowCol [R] - Low column of cursor position
;                       cursorHighCol [R] - High column of cursor position
;                       cursorState [R/W] - current state of the cursor pixel, 
;                           ON (TRUE, Color 1 is displayed) or OFF (FALSE, 
;                           Color 1 is displayed)
;                       cursorCtr [R/W] - counter that determines the period of 
;                           the cursor blinking.
;                       cursorNotRowMask [R] - one-cold row mask for turning off 
;                           the cursor pixel.
;                       cursorRMsk1 [R]- one-hot row mask for red LED, state 1
;                       cursorRMsk2 [R]- one-hot row mask for red LED, state 2
;                       cursorGMsk1 [R]- one-hot row mask for green LED, state 1
;                       cursorGMsk2 [R]- one-hot row mask for green LED, state 2
;                       blinkEn [R]- TRUE if the display blinking is enabled and 
;                           FALSE otherwise.
;                       blinkOff [R/W]- TRUE if the blinking display is
;                           currently off and FALSE if the display is on
;                       blinkCtr [R/W] - counter that determines the period of 
;                           the display blinking.
; Local Variables       R4      Row output buffer, obtained with `GetDispBufCol`
;                               with the current column and modified if 
;                               the cursor is on the current column or blinking 
;                               is enabled.
;                       R19     Flag that is TRUE if the current column is the 
;                               high cursor column and FALSE if it is the low 
;                               cursor column. No meaning if cursor is disabled.
;                       R5      Local copy of cursor state flag.
;                       Y       Used to decrement cursor and blink counters 
;                               and check for reset.
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
; Registers Changed     flags, R4, R5, R16, R17, R18, R19, Z, Y
;       + subroutines   R2, R3
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/19/2018


MuxDisp:
    LDS     R17, dispColCtr         ; Get the current col # in R17 and use it 
    RCALL   GetDispBufCol           ; to get the buffer column (rows lit) in R4
    ;RJMP    CheckOnCursorCol 
    
CheckOnCursorCol:                   ; Modify the row in R4 for cursor if needed
    CLR     R19                     ; Use R19 to find if on high or low col
    LDS     R16, cursorLowCol       ; Get the low (reds) cursor column
    CP      R16, R17                ; and check if we are currently on that col 
	BREQ    OnCrsLowCol             ; If so, go set R18 as a flag for the col
	LDS     R16, cursorHighCol      ; Get the high (greens) cursor column
    CPSE    R16, R17                ; and check if we are currently on that col 
    RJMP    CheckBlinkEnabled       ; If not, no need to modify mask for cursor 
    LDI     R18, TRUE               ; Use R18 as flag - TRUE if we are on high 
                                    ; col and FALSE if we are on low col
	RJMP    TurnOffCrsPix           ; Go turn off the cursor pixel
   
OnCrsLowCol:
    LDI     R18, FALSE              ; Use R18 as flag - FALSE if on low col
    RJMP    TurnOffCrsPix           ; Otherwise, go turn off cursor pixel first
    
TurnOffCrsPix:
    LDS     R16, cursorNotRowMask   ; Turn off the cursor pixel first by ANDing 
    AND     R4, R16                 ; the row output with ! cursor row mask
    
TurnOnCrsPix:
    LDS     R5, cursorState         ; Check if we are in cursor state 1
    LDI     R17, CURSOR_STATE_1     
    CPSE    R5, R17 
    RJMP    CrsTurnOnState2         ; If not, we are in state 2
    ;RJMP    CrsTurnOnState1
    
CrsTurnOnState1:                    ; If we are in cursor state 1
    CPSE    R18, R19                ; If we are on the high column 
    RJMP    CrsState1High           ; go OR row mask with state 1 green mask  
                                    ; to turn on the green LED
    LDS     R16, cursorRMsk1        ; Otherwise we are on the low column
    OR      R4, R16                 ; OR the row mask with state 1 red mask 
    RJMP    UpdateCrsCtr            ; go update cursor counter / toggle state

CrsState1High:                      ; If we are in State 1 and on high col
    LDS     R16, cursorGMsk1        
    OR      R4, R16                 ; OR the row mask with state 1 green mask 
    RJMP    UpdateCrsCtr            ; go update cursor counter / toggle state
    
CrsTurnOnState2:                    ; If we are in cursor state 2
    CPSE    R18, R19                ; If we are on the high column 
    RJMP    CrsState2High           ; go OR row mask with state 2 green mask  
                                    ; to turn on the green LED
    LDS     R16, cursorRMsk2        ; Otherwise we are on the low column
    OR      R4, R16                 ; OR the row mask with state 2 red mask 
    RJMP    UpdateCrsCtr            ; go update cursor counter / toggle state

CrsState2High:                      ; If we are in State 2 and on high col
    LDS     R16, cursorGMsk2        
    OR      R4, R16                 ; OR the row mask with state 2 green mask 
    RJMP    UpdateCrsCtr            ; go update cursor counter / toggle state

UpdateCrsCtr:                       ; Inc cursor ctr and check for toggle/reset
    LDS     YL, cursorCtr           ; Get the cursor counter value (two bytes) 
    LDS     YH, cursorCtr + 1       ; in Y
    SBIW    Y, 1                    ; Decrement the counter 
    BRNE    StoreCrsCtr             ; If not yet counted down store counter back 
    ;BREQ    ResetCrsCtr            ; If at top, reset counter and toggle state
    
ResetCrsCtr:
    LDI     YL, LOW(CURSOR_CTR_TOP) ; If have counted down, reset cursor counter
    LDI     YH, HIGH(CURSOR_CTR_TOP); to the top value
    STS     cursorCtr, YL       
    STS     cursorCtr + 1, YH                    
    COM     R5                      ; Invert the `cursorState` flag to toggle 
    STS     cursorState, R5         ; the cursor state
    ;RJMP    StoreCrsCtr            ; and store the cursor counter back

StoreCrsCtr:                        ; Store the cursor counter    
    STS     cursorCtr, YL
    STS     cursorCtr + 1, YH  
    ;RJMP    CheckBlinkEnabled:
    
    
CheckBlinkEnabled:
    LDS     R16, blinkEn            ; Check if blinking is enabled - from the
    TST     R16                     ; `blinkEn` flag 
    BREQ    OutputDisplayPorts      ; If false, no blinking - go update col mask 
    LDS     R16, blinkOff           ; Check if we are currently blinking off -    
    CLR     R18                     ; use the blink on/off `blinkOff` flag 
    CPSE    R16, R18                ; If on (`blinkOff` is set), do not clear
    CLR     R4                      ; If we are blinking off, clear the row mask 
    ;RJMP    UpdateBlinkCtr         ; and inc counter, toggle state if needed

UpdateBlinkCtr:                     ; Inc blink counter and check for toggle/rst
    LDS     YL, blinkCtr            ; Get the blink counter value (two bytes) 
    LDS     YH, blinkCtr + 1        ; in Y
    SBIW    Y, 1                    ; Decrement the counter 
    BRNE    StoreBlinkCtr           ; If not yet counted down store counter back 
    ;BREQ    ResetBlinkCtr           ; If at top, reset counter and toggle state
    
ResetBlinkCtr:
    LDI     YL, LOW(BLINK_CTR_TOP)  ; If have counted down, reset blink counter 
    LDI     YH, HIGH(BLINK_CTR_TOP) ; to the top value
    STS     blinkCtr, YL       
    STS     blinkCtr + 1, YH
    COM     R16                     ; Invert the `blinkOff` flag to toggle the 
    STS     blinkOff, R16           ; state of blinking
    ;RJMP    StoreBlinkCtr           ; and store the blink counter back

StoreBlinkCtr:                      ; Store the blink counter    
    STS     blinkCtr, YL
    STS     blinkCtr + 1, YH  
    
    
OutputDisplayPorts:
    LDS     R17, dispColMask        ; Load the current column mask into R17:R16
    LDS     R16, dispColMask + 1
    OUT     ROW_PORT, R4            ; Output the row buffer to the row port
    OUT     COL_PORT_R, R17         ; and the two column buffers (the two 
    OUT     COL_PORT_G, R16         ; bytes of the mask) to the column ports

    LSL     R17                     ; and "advance" the mask by 1
    ROR     R16                     ; Rotate the carry into high byte
    LDS 	R18, dispColCtr         ; Increment the column counter
    INC     R18 
	CPI     R18, N_COLS             ; If the counter is less than the number of 
	BRLO    StoreColMaskCtr         ; cols, no need to reset - store mask & ctr
                                    ; Otherwise, reset the mask and counter
    CLR     R18                     ; Reset the column counter
    LDI     R16, COL_MASK_START_H   ; Load the starting mask into R16:R17 
    LDI     R17, COL_MASK_START_L   
    ;RJMP    StoreColMaskCtr         ; and go store the mask 
    
StoreColMaskCtr:                    ; Store the column mask (either rotated/ 
    STS     dispColMask + 1, R16    ; shifted, or reset as above)
    STS     dispColMask, R17
	STS     dispColCtr, R18         ; and store the new column counter value
    ;RJMP   EndMuxDisp              ; and we are done
    
EndDMuxDisp:
    RET                             ; Done so return 
    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             ACCESSOR FUNCTIONS                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    

; GetDispBufCol(index):
;
; Description           This function returns the column (byte) in the display 
;                       buffer `dispBuf` that corresponds to the passed 
;                       argument `index` (R17) in register R4. Additionally, 
;                       the corresponding address of the buffer column is 
;                       returned in Z.
;
; Operation             The address of `dispBuf` is loaded into Z and the passed 
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
; Shared Variables      dispBuf [R] - 16-byte buffer indicating which bytes 
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
; Last Modified         05/17/2018


GetDispBufCol:
    CLR     R4                  ; Clear R4 for adding 0 w/ carry later
    LDI     ZL, LOW(dispBuf)    ; Load the buffer starting address into Z  
    LDI     ZH, HIGH(dispBuf)
    ADD     ZL, R17             ; Add offset passed in through `R17`
    ADC     ZH, R4              ; and carry through to high byte (+0 w/ C)
    LD      R4, Z               ; Get buffer column (byte of row LEDs) in R4
    RET                         ; Done, so return

    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                           DISPLAY INITIALIZATION                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; InitDisp:
;
; Description           This function initializes all shared variables used by 
;                       the display procedures for the EE 10b Binario board.
;                       The display is cleared, blinking is disabled, and 
;                       the cursor is turned off (no cursor at all).
;
; Operation             The column counter `dispColCtr` and the column one-hot 
;                       mask `dispColMask` are set so that the first column 
;                       displayed is red column 0. The display buffer is cleared 
;                       to give a blank display after initialization. Blinking 
;                       of the display is initialized as disabled, and the 
;                       cursor is initialized as off completely.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      dispColCtr  - 0 -> 15 column counter. Cycles from R0 ->
;                           R7, G0 -> G7.
;                       dispBuf     - 16-byte buffer indicating which bytes 
;                           in the column (which rows should be on) for each 
;                           of the 16 columns (8 red, 8 green).
;                       dispColMask - the one-hot 16-bit indicator of the
;                           currently lit column. Initialized to 0x0001.
;                       cursorState - current state of the cursor pixel, either 
;                           ON (TRUE, Color 1 is displayed) or OFF (FALSE, 
;                           Color 1 is displayed).
;                       cursorCtr - counter that determines the period of 
;                           the cursor blinking.
;                       cursorLowCol - Low column of cursor position (0-7)
;                       cursorHighCol - High column of cursor position (8-15)
;                       cursorNotRowMask - one-cold row mask for turning off 
;                           cursor pixel
;                       cursorRMsk1 - one-hot row mask for red LED, state 1
;                       cursorRMsk2 - one-hot row mask for red LED, state 2
;                       cursorGMsk1 - one-hot row mask for green LED, state 1
;                       cursorGMsk2 - one-hot row mask for green LED, state 2
;                       blinkEn - shared flag that is TRUE if the display
;                           should blink and FALSE otherwise.
;                       blinkOff - shared flag that is TRUE if the display is
;                           currently off during the blinking and FALSE if the 
;                           display is currently on.
;                       blinkCtr - counter that determines the period of
;                           blinking in terms of the rate of calls to 
;                           the interrupt handler.
; Local Variables       None.
;   
; Inputs                None.
; Outputs               The display is cleared, blinking is disabled, and 
;                       the cursor is disabled.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R16, R17, Y
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         05/18/2018


InitDisp:
    RCALL   ClearDisplay        ; Clear the display on start-up 
    
    LDI     R17, COL_MASK_START_L   ; Initialize the one-hot column output mask
    LDI     R16, COL_MASK_START_H   ; used in the display multiplexer function
    STS     dispColMask, R17        ; to the starting pattern [0x00 0x01]
    STS     dispColMask + 1, R16
    
    CLR     R16
    STS     dispColCtr, R16     ; Start display muxing col counter at 0
    STS     cursorRMsk1, R16    ; Clear all of the cursor state column masks
    STS     cursorRMsk2, R16
    STS     cursorGMsk1, R16
    STS     cursorGMsk2, R16
    STS     blinkEn, R16        ; Start with blinking disabled
    STS     blinkOff, R16       ; If blinking is enabled, start with display on 
    
    LDI     YL, LOW(BLINK_CTR_TOP)  ; Start blink counter at top value
    LDI     YH, HIGH(BLINK_CTR_TOP)
    STS     blinkCtr, YL       
    STS     blinkCtr + 1, YH
    LDI     YL, LOW(CURSOR_CTR_TOP) ; Start cursor counter at top value
    LDI     YH, HIGH(CURSOR_CTR_TOP)
    STS     cursorCtr, YL       
    STS     cursorCtr + 1, YH
    
    SER     R16                 ; Initialize the one-cold ! cursor row mask 
    STS     cursorNotRowMask, R16   ; to all bits high (no cursor pixel row on)

    LDI     R16, CURSOR_STATE_1 ; Start with the cursor in ON state (state 1)
    STS     cursorState, R16    
    
    LDI     R16, CURSOR_OFF_IDX ; Start with the cursor off (no cursor at all)
    STS     cursorLowCol, R16   ; by writing the invalid column number to 
    STS     cursorHighCol, R16  ; both cursor column numbers

    ;RJMP    EndInitDisp
    
EndInitDisp:
    RET                         ; Finished, so return 



; ################################ DATA SEGMENT ################################
.dseg



; ------------------------------ SHARED VARIABLES ------------------------------
;
; Notes:
; - The cursor and blink counters are two bytes since it is desirable to 
;   set their top values above 255 [interrupt handler calls] (255 ms).
; - All row masks or buffers (bytes indicating the LEDs in a single column)
;   are reversed since the row port is reversed with respect to the numbering 
;   of rows.

dispBuf:        .BYTE   16      ; 16-byte columnwise display buffer

; Display multiplexing:
dispColCtr:     .BYTE   1       ; 0->15 counter that keeps track of the column 
                                ; that `DispMux` is currently displaying  
dispColMask:    .BYTE   2       ; 16-bit one-hot mask or buffer that keeps track 
                                ; of the column that `DispMux` is currently 
                                ; displaying. The low 8 bits correspond to the 
                                ; red column port, while the high 8 bits 
                                ; correspond to the green column port.   

; Cursor:

cursorState:    .BYTE   1       ; current state of the cursor pixel, either 
                                ; 'ON' (TRUE, state 1) or 'OFF' (FALSE, state 2)            
cursorLowCol:   .BYTE   1       ; column number (0-7) of the cursor 
                                ; position in the low columns (red)
cursorHighCol:  .BYTE   1       ; column number (8-15) of the cursor 
                                ; position in the high columns (green) = low + 8
cursorCtr:      .BYTE   2       ; counter that determines the period of the 
                                ; cursor toggling between states.
cursorNotRowMask:   .BYTE   1   ; One-cold row mask for turning off cursor pixel
cursorRMsk1:    .BYTE   1       ; One-hot mask, red (bit 0) in cursor state 1
cursorRMsk2:    .BYTE   1       ; One-hot mask, red (bit 0) in cursor state 2
cursorGMsk1:    .BYTE   1       ; One-hot mask, green (bit 1) in cursor state 1
cursorGMsk2:    .BYTE   1       ; One-hot mask, green (bit 1) in cursor state 2
                                
; Blinking:

blinkEn:        .BYTE   1       ; TRUE if blinking is enabled; FALSE otherwise.
blinkOff:       .BYTE   1       ; TRUE if the blinking display is currently 
                                ; off; FALSE if on.
blinkCtr:       .BYTE   2       ; counter that determines the period of the 
                                ; display blinking.
