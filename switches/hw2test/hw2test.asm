;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW2TEST                                  ;
;                            Homework #2 Test Code                           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the switch and encoder functions for
;                   Homework #2.  It sets up the stack and calls the homework
;                   test function.
;
; Input:            User presses on the switches and rotations on the rotary
;                   encoders are stored in memory.
; Output:           None.
;
; User Interface:   No real user interface.  The user inputs switch presses
;                   and rotations and appropriate data is written to memory.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      Only the last 128 switch entries are stored.
;
; Revision History:
;    5/02/18  Glen George       initial revision
;    5/04/18  Ray Sun           Modified for HW 2 submission: Added includes for 
;                               .asm and .inc files
;    5/05/18  Ray Sun           Renamed interrupt handler procedure and file.
;    5/07/18  Ray Sun           Verified functionality of all switch and 
;                               encoder reading procedures.





;set the device
.device ATMEGA64




;get the definitions for the device
.include  "m64def.inc"

;include all the .inc files since all .asm files are needed here (no linker)
.include "iodefines.inc"
.include "swencdefines.inc"



.cseg




;setup the vector area

.org    $0000

    JMP Start       ;reset vector
    JMP PC          ;external interrupt 0
    JMP PC          ;external interrupt 1
    JMP PC          ;external interrupt 2
    JMP PC          ;external interrupt 3
    JMP PC          ;external interrupt 4
    JMP PC          ;external interrupt 5
    JMP PC          ;external interrupt 6
    JMP PC          ;external interrupt 7
    JMP PC          ;timer 2 compare match
    JMP PC          ;timer 2 overflow
    JMP PC          ;timer 1 capture
    JMP PC          ;timer 1 compare match A
    JMP PC          ;timer 1 compare match B
    JMP PC          ;timer 1 overflow
    JMP PC          ;timer 0 compare match
    JMP PC          ;timer 0 overflow
    JMP PC          ;SPI transfer complete
    JMP PC          ;UART 0 Rx complete
    JMP PC          ;UART 0 Tx empty
    JMP PC          ;UART 0 Tx complete
    JMP PC          ;ADC conversion complete
    JMP PC          ;EEPROM ready
    JMP PC          ;analog comparator
    JMP PC          ;timer 1 compare match C
    JMP PC          ;timer 3 capture
    JMP Timer3CompareHandler    ;timer 3 compare match A
    JMP PC          ;timer 3 compare match B
    JMP PC          ;timer 3 compare match C
    JMP PC          ;timer 3 overflow
    JMP PC          ;UART 1 Rx complete
    JMP PC          ;UART 1 Tx empty
    JMP PC          ;UART 1 Tx complete
    JMP PC          ;Two-wire serial interface
    JMP PC          ;store program memory ready




; start of the actual program

Start:                          ; Start the CPU after a reset
    LDI R16, LOW(TopOfStack)    ; Initialize the stack pointer
    OUT SPL, R16
    LDI R16, HIGH(TopOfStack)
    OUT SPH, R16

    RCALL   InitPorts           ; Initialize switch/encoder input port
    RCALL   InitTimer3          ; Initialize switch debounce timer
    RCALL   InitSwEnc           ; Initialize switch/encoder shared variables

    SEI                         ; Turn on global interrupts

    RCALL   SwitchTest          ;do the switch tests
    RJMP    Start               ;shouldn't return, but if it does, restart




; SwitchTest
;
; Description:       This procedure tests the switch functions.  It loops
;                    calling each status function and when it finds a switch
;                    press or rotation the appropriate character is written to
;                    the key buffer (KeyBuf).  It also verifies that there is
;                    no longer a switch or rotation and if that is true it
;                    writes an 0xFF to the buffer.  Thus for properly working
;                    functions the buffer will contain the switch press and
;                    rotations alternating with bytes of 0xFF.  The function
;                    never returns.
;
; Operation:         For each switch its status functions are called.  If
;                    there is a press or rotation an appropriate letter is
;                    written to the buffer (KeyBuf).  Then the status function
;                    is called again and if there is no press or rotations (as
;                    should be the case) 0xFF is written to the buffer.  The
;                    function then loops and starts over, performing these
;                    tests in an infinite loop.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R4 - pointer into buffer.
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
; Registers Changed: flags, R4, R5, R16, Y (YH | YL)
; Stack Depth:       unknown (at least 2 bytes)
;
; Author:            Glen George
; Last Modified:     May 1, 2018

SwitchTest:
    CLR     R4              ;start at beginning of buffer

SwitchTestLoop:

CheckLRSwitch:              ;check LRSwitch function

    PUSH    R4              ;save buffer index around call to LRSwitch
    RCALL   LRSwitch        ;check for left/right switch
    POP     R4
    BRNE    CheckUDSwitch   ;if none, check up/down switch

    LDI     R16, '2'        ;otherwise have a switch
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling LRSwitch
    RCALL   LRSwitch        ;check for left/right switch again
    POP     R4              ;   (shouldn't be one)
    BREQ    CheckUDSwitch   ;if have one, don't write FF, just check next

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   CheckUDSwitch


CheckUDSwitch:              ;check UDSwitch function

    PUSH    R4              ;save buffer index around call to UDSwitch
    RCALL   UDSwitch        ;check for up/down switch
    POP     R4
    BRNE    CheckRotLeft    ;if none, check left rotation
 
    LDI     R16, '1'        ;otherwise have a switch
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling UDSwitch
    RCALL   UDSwitch        ;check for up/down switch again
    POP     R4              ;   (shouldn't be one)
    BREQ    CheckRotLeft    ;if have one, don't write FF, just check next

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   CheckRotLeft


CheckRotLeft:               ;check LeftRot function

    PUSH    R4              ;save buffer index around call to LeftRot
    RCALL   LeftRot         ;check for left rotation
    POP     R4
    BRNE    CheckRotRight   ;if none, check right rotation

    LDI     R16, 'L'        ;otherwise have a left rotation
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling LeftRot
    RCALL   LeftRot         ;check for left rotation again
    POP     R4              ;   (shouldn't be one)
    BREQ    CheckRotRight   ;if have one, don't write FF, just check next

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   CheckRotRight


CheckRotRight:              ;check RightRot function

    PUSH    R4              ;save buffer index around call to RightRot
    RCALL   RightRot        ;check for right rotation
    POP     R4
    BRNE    CheckRotUp      ;if none, check up rotation

    LDI     R16, 'R'        ;otherwise have a right rotation
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling RightRot
    RCALL   RightRot        ;check for right rotation again
    POP     R4              ;   (shouldn't be one)
    BREQ    CheckRotUp      ;if have one, don't write FF, just check next

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   CheckRotUp


CheckRotUp:                 ;check UpRot function

    PUSH    R4              ;save buffer index around call to UpRot
    RCALL   UpRot           ;check for up rotation
    POP     R4
    BRNE    CheckRotDown    ;if none, check down rotation

    LDI     R16, 'U'        ;otherwise have an up rotation
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling UpRot
    RCALL   UpRot           ;check for up rotation again
    POP     R4              ;   (shouldn't be one)
    BREQ    CheckRotDown    ;if have one, don't write FF, just check next

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   CheckRotDown


CheckRotDown:               ;check DownRot function

    PUSH    R4              ;save buffer index around call to DownRot
    RCALL   DownRot         ;check for down rotation
    POP     R4
    BRNE    DoneCheckSw     ;if none, done checking switches

    LDI     R16, 'D'        ;otherwise have a down rotation
    RCALL   StoreBuff       ;store it in the buffer

    PUSH    R4              ;save index while calling DownRot
    RCALL   DownRot         ;check for down rotation again
    POP     R4              ;   (shouldn't be one)
    BREQ    DoneCheckSw     ;if have one, don't write FF, done

    LDI     R16, 0xFF       ;otherwise no switch so write FF
    RCALL   StoreBuff
    ;RJMP   DoneCheckSw


DoneCheckSw:                ;done checking switch functions
    JMP     SwitchTestLoop  ;keep looping forever


    RET                     ;should never get here




; StoreBuff
;
; Description:       This procedure stores the byte passed in R16 at the
;                    offset in the KeyBuf buffer passed in R4.  The offset is
;                    updated and the new offset is returned in R4.
;
; Operation:         The Y register is loaded with the buffer address.  The
;                    passed offset is then added to this address and the
;                    passed byte is stored at this location.  The passed
;                    offset is then incremented and returned.
;
; Arguments:         R4  - offset in KeyBuf at which to write the passed byte.
;                    R16 - byte to write to the buffer at the passed offset.
; Return Value:      R4  - offset of the next location in the buffer.
;
; Local Variables:   Y - pointer into buffer.
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
; Registers Changed: flags, R4, R16, R17, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 1, 2018

StoreBuff:

    LDI     YL, LOW(KeyBuf)     ;get buffer location to store switch at
    LDI     YH, HIGH(KeyBuf)

    LDI     R17, 0              ;for carry propagation
    ADD     YL, R4              ;add the passed offset
    ADC     YH, R17

    STD     Y + 0, R16          ;store the passed byte in the buffer

    INC     R4                  ;update the buffer offset, wrapping at 256


    RET                         ;all done, return




;the data segment


.dseg


; buffer in which to store keys (length must be 256)
KeyBuf:     .BYTE   256


; the stack - 128 bytes
            .BYTE   127
TopOfStack: .BYTE   1       ;top of the stack




; since don't have a linker, include all the .asm files

.include "init.asm"
.include "swencirhdlr.asm"
.include "swtchencdr.asm"
