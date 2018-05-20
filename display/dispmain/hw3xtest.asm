;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3XTEST                                 ;
;                      Homework #3 Extra Credit Test Code                    ;
;                                    EE 10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #3 extra credit.  The function
; makes a number of calls to the display functions to test them.  The
; functions included are:
;    DisplayTestEx - test the homework extra credit display functions
;
; The local functions included are:
;    Delay16Ex - delay the passed amount of time
;
; `DisplayTest` is called in the test main loop, located in the file 
; `dispmain.asm`. Blinking may be enabled during the testing by calling 
; `BlinkDisplay(TRUE)` in the main loop.
;
; Table of Contents
;
;   CODE SEGMENT
;       Extra credit display testing routine:
;           DisplayTestEx()         Tests `PlotImage()` by displaying a 
;                                   scrolling "< Binario >" message and a 
;                                   starburst animation at the end.
;       Other functions:
;           Delay16x()              Delays by a multiple of 1/80,000 clocks. 
;       Test tables:
;           TestPITab               Table of images (each 8 words, a red col 
;                                   and a green col) to pass to `PlotImage()` 
;                                   to display the scrolling  "< Binario >" .
;           TestSSCTab              Table of images to pass to `PlotImage()`
;                                   to display the starburst animation.
;
; Revision History:
;    5/15/18  Glen George               initial revision
;    5/19/18  Ray Sun                   Modified comments to reflect HW 3 
;                                       submission.
;    5/19/18  Ray Sun                   Added a TOC.




; chip definitions
;.include  "m64def.inc"

; local include files
;    none




.cseg




; DisplayTestEx
;
; Description:       This procedure tests the display functions.  It tests the
;                    PlotImage function by calling it with a number of arrays
;                    in memory.
;
; Operation:         The PlotImage function is called with a number of test
;                    arrays with delays between each call.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20         - test counter.
;                    Z (ZH | ZL) - pointer to test image.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R20, Y (YH | YL), Z (ZH | ZL)
; Stack Depth:       unknown (at least 5 bytes)
;
; Author:            Glen George
; Last Modified:     May 13, 2018

DisplayTestEx:


    RCALL   ClearDisplay        ;first clear the display


PlotImageTests:             ;do the PlotImage tests
    LDI     ZL, LOW(2 * TestPITab)  ;start at the beginning of the
    LDI     ZH, HIGH(2 * TestPITab) ;   PlotImage test table
    LDI     R20, 60         ;get the number of rows to output

PlotImageTestLoop:

    PUSH    ZL              ;save registers around PlotImage call
    PUSH    ZH
    PUSH    R20
    RCALL   PlotImage       ;call the function
    POP     R20             ;restore the registers
    POP     ZH
    POP     ZL

    LDI     R16, 10         ;100 ms delay between scrolls
    RCALL   Delay16Ex       ;and do the delay

    ADIW    Z, 2            ;scroll the display
    DEC     R20             ;update loop counter
    BRNE    PlotImageTestLoop   ;and keep looping if not done
    ;BREQ   PlotImageTest2      ;otherwise do some more tests


PlotImageTest2:             ;do more PlotImage tests
    LDI     ZL, LOW(2 * TestPITab2) ;start at the beginning of the
    LDI     ZH, HIGH(2 * TestPITab2);   second PlotImage test table
    LDI     R20, 7          ;get the number of images to output

PlotImageTestLoop2:

    PUSH    ZL              ;save registers around PlotImage call
    PUSH    ZH
    PUSH    R20
    RCALL   PlotImage       ;call the function
    POP     R20             ;restore the registers
    POP     ZH
    POP     ZL

    LDI     R16, 25         ;250 ms delay between images
    RCALL   Delay16Ex       ;and do the delay

    ADIW    Z, 16           ;move to next image
    DEC     R20             ;update loop counter
    BRNE    PlotImageTestLoop2  ;and keep looping if not done
    ;BREQ   DoneDisplayTestEx       ;otherwise done with tests


DoneDisplayTestEx:          ;have done all the tests
    RJMP    DisplayTestEx       ;start over and loop forever


    RET                     ;should never get here




; Delay16Ex
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units.
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         R16 - 1/80000 the number of CPU clocks to delay.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 6, 2018

Delay16Ex:

Delay16ExLoop:              ;outer loop runs R16 times
    LDI     YL, LOW(20000)  ;inner loop is 4 clocks
    LDI     YH, HIGH(20000) ;so loop 20000 times to get 80000 clocks
Delay16ExInnerLoop:         ;do the delay
    SBIW    Y, 1
    BRNE    Delay16ExInnerLoop

    DEC     R16             ;count outer loop iterations
    BRNE    Delay16ExLoop


DoneDelay16Ex:              ;done with the delay loop - return
    RET




; Test Tables


; TestPITab
;
; Description:      This table contains screens to send to the PlotImage
;                   function to test it.  Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte.  The table is designed to be scrolled one
;                   column at a time.
;
; Author:           Glen George
; Last Modified:    May 13, 2018

TestPITab:
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




; TestPITab2
;
; Description:      This table contains screens to send to the PlotImage
;                   function to test it.  Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte.  The table contains a number of screens
;                   which are meant to be displayed one at a time.
;
; Author:           Glen George
; Last Modified:    May 15, 2018

TestPITab2:
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
