;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  message.asm                               ;
;                     Scrolling Message / Animations Routines                ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains procedures for displaying
;                   scrolling messages and animations on the EE 10b Binario 
;                   board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Scrolling message functions:
;           DisplayWelcomeMessage   Displays a starburst animation, followed by 
;                                   a scrolling "welcome message"
;                                           <| B i n a r i o |>
;                                   followed by another starburst.
;       Animations functions:
;           DisplayStarburst        Displays a starburst animation pattern.
;       Scrolling message tables:
;           MsgTabWelcome           Welcome message table. Each row is two 
;                                   bytes - red image column data followed by 
;                                   green column data. 
;
; Revision History:
;    6/15/18    Ray Sun         Initial revision.



; ################################ CODE SEGMENT ################################
.cseg



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                         MESSAGE / ANIMATION FUNCTIONS                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; DisplayWelcomeMessage:
;
; Description:          This procedure displays a starburst animation, followed 
;                       by a scrolling "welcome message"
;                                       <| B i n a r i o |>
;                       followed by another starburst. This procedure is
;                       intended to be called when the Binario game is 
;                       powered on.
;   
; Operation:            The PlotImage function is called with a number of
;                       arrays with delays between each call in order to 
;                       display the animations and the scrolling message.
;   
; Arguments:            None.
; Return Value:         None.
;   
; Local Variables:      R20         - counter for looping 
;                       Z (ZH | ZL) - pointer to images / rows of scrolling.
; Shared Variables:     None.
; Global Variables:     None.
;   
; Input:                None.
; Output:               None.
;   
; Error Handling:       None.
;   
; Algorithms:           None.
; Data Structures:      None.
;   
; Registers Changed:    flags, R16, R20, Y, Z
; Stack Depth:          6
;
; Author                Ray Sun
; Last Modified         06/15/2018


DisplayWelcomeMessage:
    RCALL   ClearDisplay            ; First, clear the display

    RCALL   DisplayStarburst        ; Show a starburst animation 
    
ShowWelcome:
    LDI     ZL, LOW(2 * MsgTabWelcome)  ; Start at the beginning of the
    LDI     ZH, HIGH(2 * MsgTabWelcome) ; welcome message table
    LDI     R20, MSG_WELCOME_LEN        ; and get the number of rows to output

WelcomeMsgLoop:
    PUSH    ZL                      ; Save registers around PlotImage call
    PUSH    ZH
    PUSH    R20
    RCALL   PlotImage               ; Plot the image 
    POP     R20                     ; Restore the registers
    POP     ZH
    POP     ZL

    LDI     R16, MSG_SCROLL_DELAY   ; 100 ms delay between scrolls
    RCALL   Delay16                 ; and do the delay

    ADIW    Z, MSG_TAB_WIDTH        ; Scroll the display by pointing down table
    DEC     R20                     ; Decrement loop counter
    BRNE    WelcomeMsgLoop          ; and keep looping if not done
    ;BREQ   EndDisplayWelcomeMessage    ; Otherwise, show another starburst 
    
EndDisplayWelcomeMessage:
    RCALL   DisplayStarburst        ; Show another starburst animation 
    RET                             ; and we are done


  
; DisplayStarburst:
;
; Description:          This procedure displays a starburst animation.
;   
; Operation:            The `PlotImage` function is called with the starburst 
;                       animation table with delays between each call to 
;                       display the animation.
;   
; Arguments:            None.
; Return Value:         None.
;   
; Local Variables:      R20         - counter for looping 
;                       Z (ZH | ZL) - pointer to frames in animation 
; Shared Variables:     None.
; Global Variables:     None.
;   
; Input:                None.
; Output:               None.
;   
; Error Handling:       None.
;   
; Algorithms:           None.
; Data Structures:      None.
;   
; Registers Changed:    flags, R16, R20, Y, Z
; Stack Depth:          3
;
; Author                Ray Sun
; Last Modified         06/15/2018
  
  
DisplayStarburst:
    LDI     ZL, LOW(2 * MovTabStarburst)     ; Start at the beginning of the
    LDI     ZH, HIGH(2 * MovTabStarburst)    ; starburst table
    LDI     R20, MOV_STARBURST_LEN  ; Get the number of images to output

StarburstLoop:
    PUSH    ZL                      ; Save registers around PlotImage call
    PUSH    ZH
    PUSH    R20
    RCALL   PlotImage               ; Plot next frame in animation
    POP     R20                     ; Restore the registers
    POP     ZH
    POP     ZL

    LDI     R16, MOV_DELAY          ; Delay for `MOV_DELAY` * 10 ms between
    RCALL   Delay16                 ; frames of animation

    ADIW    Z, NUM_COLS             ; Move to next image
    DEC     R20                     ; update loop counter
    BRNE    StarburstLoop           ; and keep looping if not done
    ;BREQ   EndDisplayStarburst     ; Otherwise done with tests

EndDisplayStarburst:
    RET                             ; We are done, so return

        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        MESSAGE / ANIMATION TABLES                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; MsgTabWelcome
;
; Description:      This table contains screens to send to the PlotImage
;                   function to display a scrolling "welcome" message:
;                                   <| B i n a r i o |>
;                   Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte.  The table is designed to be scrolled one
;                   column at a time.
;
; Author:           Ray Sun. Adapted from "TestPITab" by Glen George
; Last Modified:    06/15/2018

MsgTabWelcome:
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00011000, 0b00011000
    .DB 0b00111100, 0b00111100
    .DB 0b01111110, 0b01111110
    .DB 0b11111111, 0b11111111
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b10000001, 0b00000000
    .DB 0b11111111, 0b00000000
    .DB 0b10010001, 0b00000000
    .DB 0b10010001, 0b00000000
    .DB 0b01101110, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000001
    .DB 0b00000000, 0b00100111
    .DB 0b00000000, 0b00000001
    .DB 0b00000000, 0b00000000
    .DB 0b00010000, 0b00010000
    .DB 0b00011111, 0b00011111
    .DB 0b00001000, 0b00001000
    .DB 0b00010000, 0b00010000
    .DB 0b00010000, 0b00010000
    .DB 0b00001111, 0b00001111
    .DB 0b00000000, 0b00000000
    .DB 0b00100110, 0b00000000
    .DB 0b00101001, 0b00000000
    .DB 0b00101001, 0b00000000
    .DB 0b00011111, 0b00000000
    .DB 0b00000001, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000001 
    .DB 0b00000000, 0b00001111 
    .DB 0b00000000, 0b00010001 
    .DB 0b00000000, 0b00010000 
    .DB 0b00000000, 0b00001000 
    .DB 0b00000000, 0b00000000
    .DB 0b00000001, 0b00000001
    .DB 0b00100111, 0b00100111
    .DB 0b00000001, 0b00000001
    .DB 0b00000000, 0b00000000
    .DB 0b00001110, 0b00000000
    .DB 0b00010001, 0b00000000
    .DB 0b00010001, 0b00000000
    .DB 0b00001110, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b11111111, 0b11111111
    .DB 0b01111110, 0b01111110
    .DB 0b00111100, 0b00111100
    .DB 0b00011000, 0b00011000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    
    
    
; MovTabStarburst
;
; Description:      This table contains screens to send to the PlotImage
;                   function to test it. Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte. The table contains a number of screens
;                   which are meant to be displayed one at a time. When 
;                   displayed in sequence, a starburst animation is produced 
;                   on the display.
;
; Author:           Ray Sun. Adapted from "TestPITab2" by Glen George
; Last Modified:    06/15/2018

MovTabStarburst:
    .DB 0b00000000, 0b00000000      ;screen 1
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00001000, 0b00001000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000

    .DB 0b00000000, 0b00000000      ;screen 2
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000
    .DB 0b00001000, 0b00001000
    .DB 0b00011100, 0b00010100
    .DB 0b00001000, 0b00001000
    .DB 0b00000000, 0b00000000
    .DB 0b00000000, 0b00000000

    .DB 0b00000000, 0b00000000      ;screen 3
    .DB 0b00000000, 0b00000000
    .DB 0b00001000, 0b00001000
    .DB 0b00011100, 0b00010100
    .DB 0b00110110, 0b00101010
    .DB 0b00011100, 0b00010100
    .DB 0b00001000, 0b00001000
    .DB 0b00000000, 0b00000000

    .DB 0b00000000, 0b00000000      ;screen 4
    .DB 0b00001000, 0b00001000
    .DB 0b00101010, 0b00100010
    .DB 0b00010100, 0b00001000
    .DB 0b01100011, 0b01011101
    .DB 0b00010100, 0b00001000
    .DB 0b00101010, 0b00100010
    .DB 0b00001000, 0b00001000

    .DB 0b00000000, 0b00000000      ;screen 5
    .DB 0b01001001, 0b01000001
    .DB 0b00100010, 0b00001000
    .DB 0b00000000, 0b00011100
    .DB 0b01000001, 0b00111110
    .DB 0b00000000, 0b00011100
    .DB 0b00100010, 0b00001000
    .DB 0b01001001, 0b01000001

    .DB 0b00000000, 0b00000000      ;screen 6
    .DB 0b01000001, 0b00001000
    .DB 0b00000000, 0b00101010
    .DB 0b00000000, 0b00011100
    .DB 0b00000000, 0b01111111
    .DB 0b00000000, 0b00011100
    .DB 0b00000000, 0b00101010
    .DB 0b01000001, 0b00001000

    .DB 0b00000000, 0b00000000      ;screen 7
    .DB 0b00000000, 0b01001001
    .DB 0b00000000, 0b00101010
    .DB 0b00000000, 0b00011100
    .DB 0b00000000, 0b01111111
    .DB 0b00000000, 0b00011100
    .DB 0b00000000, 0b00101010
    .DB 0b00000000, 0b01001001
