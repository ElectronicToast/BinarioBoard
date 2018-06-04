;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              eeromdefines.inc                              ;
;                         Binario Board EEROM Definitions                    ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions and constants related
;                   to the 93C46A EEPROM chip and the SPI interface to read 
;                   (and write) from the EEROM on the EE 10b Binario board.
;
; Table of Contents:
;
;   General EEROM definitions:
;           Address width for read buffer pattern in `ReadEEROM()`
;           Opcodes for EEPROM chip operations
;   SPI definitionss:
;           SPRC and SPSR bit patterns for initializing the SPI bus
;   
; Revision History:
;    6/01/18    Ray Sun         Initial revision.
;    6/02/18    Ray Sun         Added TOC.



.EQU    EEROM_ONE_ADDR      = 2             ; # to add to the 'read buffer' 
                                            ; in order to increment the 
                                            ; EEROM address by 1
                                            
.EQU    EEROM_OPCODE_READ   = 0b00000110    ; Opcode for SPDR to read from the 
                                            ; EEROM chip. This is combined with 
                                            ; the 6-bit address to create two 
                                            ; bytes to transmit (write to the 
                                            ; SPDR) to start reading.
.EQU    EEROM_OPCODE_NOP    = 0b00000000    ; 'Blank' transmission to the EEROM 
                                            ; Used when reading in two bytes.

                                            
.EQU    SPRC_MASTER     = 0b01010001  ; Initialization mask for SPRC
                          ; 0-------    SPI interrupts disabled
                          ; -1------    Enable SPI
                          ; --0-----    MSB transmitted first
                          ; ---1----    ATmega64 is the SPI master
                          ; ----0---    Leading edge is falling edge 
                          ; -----0--    Leading edge is sample
                          ; ------01    For a SCK rate of f_osc / 16 == 500 kHz
                            
.EQU    SPSR_MASTER     = 0b00000000  ; Initialization mask for SPSR
                          ; *-------    SPI interrupt flag
                          ; -*------    Write collision flag 
                          ; --00000-    Reserved bits 
                          ; -------0    Do not double the SCK frequency 
