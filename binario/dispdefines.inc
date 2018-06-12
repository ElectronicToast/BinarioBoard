;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               dispdefines.inc                              ;
;               Binario Board / ATmega64 Display Output Definitions          ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions and constants related
;                   to the 8x8 R/G LED matrix display and associated I/O ports
;                   on the EE 10b Binario board.
;
; Table of Contents:
;   
;   Color definitions:
;           Clear, red, green, yellow 
;           Number of colors 
;   Display definitions:
;           Size of display (8)
;           Number of display columns (16, 2 per physical column)
;           Bit patterns for columns for all on/off
;   Display counter definitions:
;           Blinking and cursor counter top values 
;   Column output mask (buffer) definitions:
;           Initial column output mask - 2 bytes 
;   Row mask (buffer) definitions:
;           One-hot encoding for first LED in a column (#0)
;   Cursor definitions:
;           Invalid cursor column number - used to turn off the cursor
;
; Revision History:
;    5/14/18    Ray Sun         Initial revision.
;    5/18/18    Ray Sun         Changed all bitmasks to be in binary format.
;    5/18/18    Ray Sun         Added TOC.
;    5/18/18    Ray Sun         Added definitions for the red bit and the green 
;                               bit in a "color" byte, in order to use SBRC
;                               and SBRC instructions in display routines.
;    5/19/18    Ray Sun         Modified the values of the cursor and blink 
;                               top values to give a moderately fast cursor 
;                               cycling rate and a slower blink rate.
;    6/06/18    Ray Sun         Moved port definitions to `iodefines.inc`
;    6/11/18    Ray Sun         Added definitions for bit patterns of all 
;                               LEDs on/off in a column



; Color definitions 
; - Colors are stored as [0000 00(G)(R)]; yellow is low two bits both on

.EQU    PIXEL_OFF   = 0b00000000    ; No LED on                 [0]
.EQU    PIXEL_RED   = 0b00000001    ; Red LED on                [1]
.EQU    PIXEL_GREEN = 0b00000010    ; Green LED on              [2]
.EQU    PIXEL_YELLOW= 0b00000011    ; Both LEDs on (yellow)     [3]
.EQU    RED_BIT     = 0             ; Bit 0 is red bit 
.EQU    GREEN_BIT   = 1             ; Bit 1 is green bit
.EQU    NUM_COLORS  = 4             ; Number of colors, for error checking

; Display definitions

.EQU    DISP_SIZE   = 8             ; Physical number of rows/cols. Assumes 
                                    ; square display
.EQU    NUM_COLS    = 16            ; Number of columns (16)
.EQU    ALL_LEDS_ON = 0b11111111    ; Bit pattern for all LEDs on in a column 
.EQU    ALL_LEDS_OFF =0b00000000    ; Bit pattern for all LEDs off in a column

; Counter 'top' values (period is 2 times top value)

.EQU    BLINK_CTR_TOP   = 500       ; 500 interrupt handler calls = 500 ms
.EQU    CURSOR_CTR_TOP  = 100       ; 100 interrupt handler calls = 100 ms

; Start of the one-hot column mask for column-wise multiplexing

.EQU    COL_MASK_START_L = 0b00000001    ; Start multiplexing at the first red          
.EQU    COL_MASK_START_H = 0b00000000    ; column - [0000 0000] [0000 0001]

; LED position masks

.EQU    ROW_MASK_INIT = 0b10000000  ; First LED in any column (Row 0) - 
                                    ; LSB of each column (byte) in the buffer
                                    ; Is 0x80 since row port is reversed.
                                    
; Cursor definitions

.EQU    CURSOR_STATE_1 = 1          ; Constants to indicate the state of the 
.EQU    CURSOR_STATE_2 = 0          ; cursor: ON (State 1) or OFF (State 2)
.EQU    CURSOR_OFF_IDX = -1         ; Invalid cursor row/col index - disable the 
                                    ; cursor when passed to `SetCursor()`
