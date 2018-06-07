;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  eerom.asm                                 ;
;                         Homework #4 EEROM Functions                        ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the procedures for reading from 
;                   the external on-board EEROM (93C46A EEPROM chip) on the EE 
;                   10b Binario board.
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
;    6/03/18    Ray Sun         Moved reading a word of data from the EEROM 
;                               (a single READ instruction) into its own
;                               subroutine. Made a small subroutine for waiting
;                               for a SPI transmission/reception to finish.
;    6/04/18    Ray Sun         Re-wrote `ReadEEROM()` loop to read two bytes 
;                               per loop while accounting for if `a` and `n` 
;                               are such that 1 byte is left to be read on
;                               the last loop iteration.
;    6/04/18    Ray Sun         Verified functionality of `ReadEEROM()`.
;    6/06/18    Ray Sun         Corrected `ReadEEROMWord` by ensuring that 
;                               if the word address is larger than 6 bits,
;                               the higher bits do not mess up the READ opcode 
;                               transmitted on SPI.



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
;                       (and possibly one more, if `n` is odd) on the serial 
;                       EEROM chip must be performed. To accomplish this,
;                       the procedure loops over all `n` bytes to be read but 
;                       reads a word per loop by calling the `ReadEEROMWord()`
;                       subroutine with successive EEROM word address arguments
;                       (`A` := `a`/2). The word data is then stored at Y+.
;
;                       If `a` is odd, the first byte received (the high byte at 
;                       [A5..A0] is skipped.
;
;                       If the last iteration of the loop corresponds to one 
;                       remaining byte to be read, the low byte from the final 
;                       `ReadEEROMWord()` call is not stored.
;
; Arguments             n       R16         Unsigned number of bytes to read.
;                       a       R17         The EEROM byte address to read from.
;                       p       Y (R29|R28) The address at which to store the 
;                                           data read from EEROM.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       R17     EEROM word addresss `A` to read from for data. 
;                       R19|R18 EEROM data word returned by `ReadEEROMWord()`
;                               calls for each `A` of interest.
;                       R20     Flag that is set if `a` is odd and cleared 
;                               otherwise. If set, first byte read is skipped
;                               since reading `a` >> 1 gives a high byte before 
;                               the first byte of interest. Cleared after first 
;                               byte skip, if applicable.
;   
; Inputs                `n` bytes from the serial EEPROM chip are read into 
;                       data memory.
; Outputs               None.
;   
; Error Handling        It is assumed that enough available memory is
;                       present at the passed address to store the data 
;                       read by the procedure.
;
;                       `a` is assumed to be such that `a` / 2 results in a 
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
; Registers Changed     R16, R17, R18, R19, R20
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/04/2018  


ReadEEROM:
    LDI     R20, 0b0000001              ; Check if `a` is odd - if so ignore
    AND     R20, R17                    ;   first read byte. Use R20 as flag
    LSR     R17                         ; A := a/2 - get the word address

ReadEEROMLoop:
    CPI     R16, 0                      ; If have read all bytes desired 
    BREQ    EndReadEEROM                ; then we are done.
    ;BRNE    ReadEEROMLoopBody           ; Otherwise continue reading.
    
ReadEEROMLoopBody:                      ; Read two bytes from EEROM at a time
    RCALL   ReadEEROMWord               ; Do READ at A, get data word in R19|R18
    SBRC    R20, 0                      ; If `a` was even, do not skip 1st byte 
    RJMP    ReadEEROMSkipFirstByte      ; Otherwise, skip 1st byte 
    
ReadEEROMStoreHighByte:
    ST      Y+, R19                     ; Always store the high byte 
    DEC     R16                         ; Decrement loop counter 
    RJMP    ReadEEROMStoreLowByte       ; and go store low byte
    
ReadEEROMSkipFirstByte:                 ; Skip first byte - increment Y
    CLR     R20                         ; Disable flag, should skip only 1st 
    ;RJMP    ReadEEROMStoreLowByte       ; and go store low byte
    
ReadEEROMStoreLowByte:
    CPI     R16, 0                      ; If at an odd number of bytes left
    BREQ    EndReadEEROM                ; (counter = 0) don't store last byte
    ST      Y+, R18                     ; Store the low byte
    DEC     R16                         ; Dec loop counter because read 2 bytes
    ;RJMP    ReadEEROMEndLoopBody
    
ReadEEROMEndLoopBody:
    INC     R17                         ; Increment the EEROM word address `A`
    RJMP    ReadEEROMLoop               ; and check if done reading 
    
EndReadEEROM:
    RET                                 ; (RET: 4 cycles). Done, so return
    

    
; ReadEEROMWord(A):
;
; Description           This procedure reads a word of data from the serial 
;                       EEROM (93C64A EEPROM chip) at the EEROM word address 
;                       `A`, passed in by value through R17. The data is 
;                       returned in R19|R18.
;
; Operation             The READ operation is initiated by sending 
;                                   [000000 11][0  A5..A0  0]
;                       where `A` is the EEROM word address, over SPI. The 
;                       trailing zero ensures that the subsequent incoming data 
;                       (2 bytes) over SPI is aligned with the data organization 
;                       in the EEROM. 
;
;                       Reading the data from the EEROM is initiated by sending 
;                       a "NOP" byte transmission over SPI, allowing the data 
;                       to be clocked into the SPDR. The data memory pointer Y 
;                       is incremented after each read. Reading is performed 
;                       twice to obtain the two bytes in the word.
;
; Arguments             A       R17         The EEROM word address to read from.
; Return Values         R19|R18             The EEROM data word.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
;   
; Inputs                2 bytes from the serial EEPROM chip are read into 
;                       data memory.
; Outputs               None.
;   
; Error Handling        None. It is assumed that `A` is a valid EEROM word 
;                       address. If `A` is larger than 6 bits, the high bits 
;                       are ignored.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R18, R19
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/04/2018

  
ReadEEROMWord:

SetChipSel:
    SBI     EEROM_SPK_PORT, EEROM_CS_PIN    ; Set the CS line high 
 
StartEEROMRead:                         ; Transmit READ opcode + word address
    LDI     R18, EEROM_OPCODE_READ      ; Get the opcode for reading 
    ROR     R18                         ; [00000 110] -> [000000 11]
    OUT     SPDR, R18                   ; Start transmitting READ opcode 
    RCALL   SPIWaitTx                   ; Wait for transmission to complete
    MOV     R18, R17                    ; Copy word address -> R18
    LSL     R18                         ; [00 a5..a0] -> [0 a5..a0, 0]
    ANDI    R18, 0x7F                   ; Make sure high bit is zero.
    OUT     SPDR, R18                   ; Finish transmit READ + word address
    RCALL   SPIWaitTx                   ; Wait for transmission to complete

ReadEEROMHighByte:
    LDI     R18, EEROM_OPCODE_NOP       ; Transmit "NOP" to begin clocking in 
    OUT     SPDR, R18                   ; high byte data
    RCALL   SPIWaitTx                   ; wait for reception to finish
    IN      R19, SPDR                   ; Get the high byte in R19

ReadEEROMLowByte:
    OUT     SPDR, R18                   ; Transmit "NOP" again to get low byte
    RCALL   SPIWaitTx                   ; Wait for reception to finish
    IN      R18, SPDR                   ; Get the low byte in R18
    
ClearChipSel:
    CBI     EEROM_SPK_PORT, EEROM_CS_PIN    ; Set the CS line low (RET takes 4 
    ;RJMP    EndReadEEROMWord            ; cycles, more than the 2 cycles / 
                                        ; 25 ns needed).
EndReadEEROMWord:
    RET                                 ; We are done, so return
   

 
; SPIWaitTx():
;
; Description           This function waits until a SPI transmission (or 
;                       reception) is complete.
;
; Operation             The function loops until the SPIF flag in the SPSR
;                       SPI status register is set.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
;   
; Inputs                None.
; Outputs               None.
;   
; Error Handling        None.
;
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     None.
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/03/2018


SPIWaitTx:                              ; Wait for SPI transmission to complete
    SBIS    SPSR, SPIF                  ; - loop until SPIF is set
    RJMP    SPIWaitTx
	RET                                 ; Done, so return
