;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                iodefines.inc                               ;
;                         Binario Game I/O Definitions                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains general-purpose and hardware
;                   specific definitions for the ATmega64 I/O on 
;                   the EE 10b Binario board, related to the peripherals on 
;                   the board (rotary encoder switches, 8x8 red/green LED 
;                   display, speaker, EEROM).
;
; Table of Contents:
;
;   Port definitions 
;           Switches/encoders port and DDR 
;           Display port and DDR 
;           EEROM/speaker port and DDR
;   Port data directions:
;           INDATA              Data direction for input
;           OUTDATA             Data direction for output
;           SPK_EEROM_DATA      Data direction for speaker and EEROM port
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Fixed `TIMER3RATE` to correspond to 1 ms on the 
;                               8 MHz clock used on the board. 
;    5/14/18    Ray Sun         Modified for HW 3, including `OUTDATA` to
;                               specify output in the DDR of a port
;    5/18/18    Ray Sun         Moved general definitions to `gendefines.inc` 
;    5/18/18    Ray Sun         Added TOC.  
;    5/29/18    Ray Sun         Added speaker and EEROM port definitions for 
;                               HW 4 submission. 
;    6/01/18    Ray Sun         Moved all port definitions from earlier homework
;                               to this include file.
;    6/02/18    Ray Sun         Commented out definitions not used for the 
;                               speaker and EEROM for now.
;    6/06/18    Ray Sun         Added all I/O and timer related definitions for 
;                               the overall project.
;    6/10/18    Ray Sun         Moved timer definitions to separate file 
;                               `timerdefines.inc`. Replaced Timer 3 definitions
;                               with definitions to set up Timer 2 in CTC 
;                               output compare mode with a period of ~ 1 ms 
;                               in order to use Timer 3 to play music.



; I/O Port definitions:

.EQU    SW_ENC_PORTIN   = PINE      ; Switch and encoder input port - Port E
.EQU    SW_ENC_PORT     = PORTE
.EQU    SW_ENC_DDR      = DDRE      ; and DDR

.EQU    ROW_PORT    = PORTC         ; Display ports: Ports A, C, and D
.EQU    ROW_DDR     = DDRC          ; Row output port and DDR - C
.EQU    COL_PORT_G  = PORTA         ; Green columns' port and DDR - A
.EQU    COL_G_DDR   = DDRA
.EQU    COL_PORT_R  = PORTD         ; Red columns' port and DDR - D
.EQU    COL_R_DDR   = DDRD

.EQU    EEROM_SPK_PORT      = PORTB         ; Speaker and EEROM (SPI) - Port B
.EQU    EEROM_SPK_DDR       = DDRB 
.EQU    EEROM_SPK_DATA_DIR  = 0b0100111     ; Port B mask for speaker and SPI bus
                            ;   -1-----     ; Speaker is output
                            ;   ---0---     ; MISO - input
                            ;   ----111     ; SCK, MOSI, and !SS - output
.EQU    SPK_PIN             = 6             ; The speaker output line - OC1A
.EQU    EEROM_CS_PIN        = 0             ; Chip select pin # in the SPI port


; I/O Port data directions:

.EQU    INDATA     = 0b00000000     ; Data direction 0 is input for I/O ports
.EQU    OUTDATA    = 0b11111111     ; Data direction 1 is output for I/O ports
.EQU    SPK_EEROM_DATA  = 0b0100111 ; Port B data direction for speaker and SPI
                        ;   -1----- ; Speaker - output
                        ;   ---0--- ; MISO - input
                        ;   ----111 ; MOSI, SCK, and !SS - output                           
