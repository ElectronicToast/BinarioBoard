;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              eeromdefines.inc                              ;
;                         Binario Board EEROM Definitions                    ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions and constants related
;                   to the 93C46A EEPROM chip on the EE 10b Binario board and  
;                   the SPI interface to communicate with the EEROM.
;
; Table of Contents:
;
;   General EEROM definitions:
;           Opcodes for EEPROM chip operations
;   SPI definitionss:
;           SPRC bit pattern for initializing the SPI bus
;   
; Revision History:
;    6/01/18    Ray Sun         Initial revision.
;    6/02/18    Ray Sun         Added TOC.
;    6/04/18    Ray Sun         Removed unnecessary initialization bit pattern 
;                               for SPSR.



; EEROM chip opcodes:
                                       
.EQU    EEROM_OPCODE_READ   = 0b00000110    ; Opcode for SPDR to read from the 
                                            ; EEROM chip. This is combined with 
                                            ; the 6-bit address to create two 
                                            ; bytes to transmit (write to the 
                                            ; SPDR) to start reading.
.EQU    EEROM_OPCODE_NOP    = 0b00000000    ; 'Blank' transmission to the EEROM 
                                            ; Used when reading in two bytes.
        
; SPI initialization bit patterns:
        
.EQU    SPCR_MASTER     = 0b01010001  ; Initialization mask for SPRC
                          ; 0-------    SPI interrupts disabled
                          ; -1------    Enable SPI
                          ; --0-----    MSB transmitted first
                          ; ---1----    ATmega64 is the SPI master
                          ; ----0---    Leading edge is falling edge 
                          ; -----0--    Leading edge is sample
                          ; ------01    For a SCK rate of f_osc / 16 == 500 kHz
