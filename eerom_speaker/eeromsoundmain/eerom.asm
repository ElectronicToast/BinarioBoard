;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  eerom.asm                                 ;
;                         Homework #4 EEROM Functions                        ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for reading from 
;                   the external EEROM (93C46A EEPROM chip) on the EE 10b
;                   Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       EEROM reading functions:
;           ReadEEROM()         Read a given number of bytes from the EEROM 
;                               at a given EEROM address into data memory.
;
; Revision History:
;    6/02/18    Ray Sun         Initial revision.
;    6/02/18    Ray Sun         Added pulling CS line low at the end of every 
;                               EEROM READ operation (once 2 bytes are read)



; Local include files
;.include "gendefines.inc"
;.include "iodefines.inc"
;.include "eeromdefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; ReadEEROM(a, p, n):
;
; Description           This procedure reads `n` bytes of data from the serial 
;                       EEROM (93C64A EEPROM chip) at the address `a`. The 
;                       data is stored at the data address `p`.  
;
; Operation             To read `n` bytes from EEROM, `n`/2 READ instructions
;                       on the serial EEROM chip must be performed. This is 
;                       accomplished by looping over all bits to be read and 
;                       sending the READ opcode, with the appropriate EEROM 
;                       word address, over SPI on every odd iteration of the 
;                       loop (whereas reading is performed on all iterations).
;
;                       In particular, the READ operation is initiated by
;                       sending 
;                                   [000000 11][0  A5..A0  0]
;                       where `A` = `a`/2, the EEROM word address. After the
;                       READ transmission is sent, the word address `A` is 
;                       incremented. The trailing zero ensures that 
;                       the subsequent incoming data (2 bytes) is aligned with 
;                       the data organization in the EEROM. 
;
;                       If `a` is odd, the first byte received (the low byte at 
;                       [A5..A0] is skipped, and an extra byte is read at the
;                       end of the loop.
;
;                       Reading the data from the EEROM is initiated by sending 
;                       a "NOP" byte transmission over SPI, allowing the data 
;                       to be clocked into the SPDR. The data memory pointer Y 
;                       is incremented after each read.
;
; Arguments             n       R16         The number of bytes to read.
;                       a       R17         The EEROM byte address to read from.
;                       p       Y (R29|R28) The address at which to store the 
;                                           data read from EEROM.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       R18|R17 A 16-bit "read pattern" comprising 
;                                       [000000 11][0 A5...A0 0]
;                               where A = `a` / 2. Sending the latter 10 bits of 
;                               this pattern effects a read operation. The 
;                               trailing zero is present so that the received
;                               data bytes are aligned with the contents of 
;                               the SPDR at reception.
;                       R20     Flag that is set if `a` is odd and cleared 
;                               otherwise. If set, first byte read is skipped
;                               since reading `a` >> 1 gives 1 byte before 
;                               byte of interest. Cleared after first byte skip 
;                               if applicable.
;                       R21     Loop counter for reading `n` bits, 0 -> `n` - 1
;   
; Inputs                `n` bytes from the serial EEPROM chip are read into 
;                       data memory.
; Outputs               None.
;   
; Error Handling        It is assumed that enough available memory is
;                       present at the passed address to store the data 
;                       read by the procedure.
;
;                       `a` is assumed to be such that `a` >> 1 results in a 
;                       valid EEROM word address.
;
;                       `n` = 0 results in no reading.
;
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R17, R18, R19, R20, R21
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/02/2018  



ReadEEROM:
    LDI     R18, EEROM_OPCODE_READ      ; Get the opcode for reading 
    
    LDI     R20, 0x01                   ; Check if `a` is odd - if so ignore
    AND     R20, R17                    ;   first read byte. Use R20 as flag
    LSL     R17                         ; a := a/2 - get the word address
    
    LSL     R17                         ; Rotate the address into high position
    LSL     R17                         ;       [00, a5..a0] -> [a5..a0, 00]
    LSR     R18                         ; Get two bytes to transmit in R18|R17
    ROR     R17                         ;       [0... 0 11][0, a5..a0, 0]
    CLR     R21                         ; Initialize a loop counter, 0 -> `n`-1

ReadEEROMLoop:
    CP      R21, R16                    ; If have read all bytes desired 
    BREQ    EndReadEEROM                ; then we are done.
    ;BRNE    ReadEEROMLoopBody           ; Otherwise continue reading.
    
ReadEEROMLoopBody:                      ; Read two bytes from EEROM at a time
    LDI     R19, 0x01                   ; Check if loop counter is odd or even
    AND     R19, R21
    BRNE    ReadEEROMDoRx               ; If odd, don't send opcode - go read 
                                        ; second half of word
    ;BREQ    ReadEEROMDoTx               ; Otherwise go send read opcode 
    
ReadEEROMDoTx: 
    SBI     EEROM_SPK_PORT, EEROM_CS_PIN    ; Pull CS line high 
    OUT     SPDR, R18                   ; Send opcode with word address 
    RCALL   SPIWaitTx                   ; Wait for transmission to complete
    OUT     SPDR, R17                   ; Finish transmitting opcode + addr 
    RCALL   SPIWaitTx                   ; Wait for transmission to complete
    ;RJMP    ReadEEROMEndWaitTx          ; and go increment the EEROM address
    
ReadEEROMEndWaitTx:
    LDI     R19, EEROM_ONE_ADDR         ; Increment (word) address in read
    ADD     R18, R19                    ; buffer by 1 address.
    ;RJMP    ReadEEROMDoRx               ; and go receive the data
    
ReadEEROMDoRx:
    LDI     R19, EEROM_OPCODE_NOP       ; Send a "NOP" to the EEPROM chip 
    OUT     SPDR, R19                   ; in order to read in data
    RCALL   SPIWaitTx
    IN      R19, SPDR                   ; Read data byte into R19
    CPI     R20, 1                      ; Check if `a` (byte addr) is odd 
    BREQ    ReadEEROMSkipFirstByte      ; Don't store first byte if `a` is odd
    ;BRNE    ReadEEROMStoreByte          ; Otherwise store 1st byte.
    
ReadEEROMStoreByte:                     ; Otherwise store first byte and all 
    ST      Y+, R19                     ; subsequent bytes while inc pointer
    RJMP    ReadEEROMEndLoopBody        ; and check to repeat loop
    
ReadEEROMSkipFirstByte:                 ; Skip first byte - increment Y
    LDI     R20, 1                      ; Add 1 to Y (trash the flag, not needed          
    ADD     YL, R20                     ; anymore)
    CLR     R20                         ; Disable flag, should skip only 1st 
                                        ; loop if odd
    ADC     YH, R20                     
    RJMP    ReadEEROMLoop               ; Do not inc loop counter - read one 
                                        ; extra byte because skipped first
    
ReadEEROMEndLoopBody:
    SBRC    R21, 0                      ; If R21 is even, not done reading word 
    CBI     EEROM_SPK_PORT, EEROM_CS_PIN    ; Else done with READ, pull down CS 
                                        ; line for at least 2 clocks 
    INC     R21                         ; Increment loop counter 
    RJMP    ReadEEROMLoop               ; and check if done reading 
    
EndReadEEROM:
    CBI     EEROM_SPK_PORT, EEROM_CS_PIN    ; Pull CS line low (at least 4 clks)
    RET                                 ; (RET: 4 cycles). Done, so return



SPIWaitTx:                              ; Wait for SPI transmission to complete -
    SBIS    SPSR, SPIF                  ; when SPIF is set
    RJMP    SPIWaitTx
	RET
    
