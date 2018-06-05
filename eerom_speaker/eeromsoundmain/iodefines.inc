;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                iodefines.inc                               ;
;                         General Hardware Definitions                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains general-purpose and hardware
;                   specific definitions for the EE 10b Binario board and the 
;                   ATmega64, such as the I/O ports and timers.
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
;   Timer definitions
;       Timer 1 (Speaker)
;           Timer 1 control registers for normal mode (speaker off) and 
;               CTC output compare toggle mode (speaker on)
;       Timer 3 (OLD - Encoder/switch reading, display multiplexing - CTC cmp):
;           Timer 3 control register masks for CTC output compare mode 
;           Timer 3 output compare top value
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



; I/O Port definitions:

.EQU    SW_ENC_PORT = PINE          ; Switch and encoder input port - Port E
.EQU    SW_ENC_DDR  = DDRE          ; and DDR

.EQU    ROW_PORT    = PORTC         ; Display ports: Ports A, C, and D
.EQU    ROW_DDR     = DDRC          ; Row output port and DDR - C
.EQU    COL_PORT_G  = PORTA         ; Green columns' port and DDR - A
.EQU    COL_G_DDR   = DDRA
.EQU    COL_PORT_R  = PORTD         ; Red columns' port and DDR - D
.EQU    COL_R_DDR   = DDRD

.EQU    EEROM_SPK_PORT      = PORTB         ; Speaker and EEROM (SPI) - Port B
.EQU    EEROM_SPK_DDR       = DDRB 
.EQU    SPK_PIN             = 6             ; The speaker output line - OC1A
.EQU    EEROM_SPK_DATA_DIR  = 0b0100111     ; Port B mask for speaker and SPI bus
                            ;   -1-----     ; Speaker is output
                            ;   ---0---     ; MISO - input
                            ;   ----111     ; SCK, MOSI, and !SS - output
.EQU    EEROM_CS_PIN        = 0             ; Chip select pin # in the SPI port


; I/O Port data directions:

.EQU    INDATA     = 0b00000000     ; Data direction 0 is input for I/O ports
.EQU    OUTDATA    = 0b11111111     ; Data direction 1 is output for I/O ports
.EQU    SPK_EEROM_DATA  = 0b0100111 ; Port B data direction for speaker and SPI
                        ;   -1----- ; Speaker - output
                        ;   ---0--- ; MISO - input
                        ;   ----111 ; MOSI, SCK, and !SS - output

        
; Speaker timer (Timer 1) control register bitmasks:

.EQU TIMER1_NORMAL_CTR_BITS_A = 0b00000000  ; TCCR1B bitmask when speaker is off
                                            ; 00------    No output on OC1A 
                                            ; --00----    No output on OC1B
                                            ; ----00--    No output on OC1C
                                            ; ------00    Normal operation
                            
.EQU TIMER1_NORMAL_CTR_BITS_B = 0b00001000  ; TCCR1B bitmask when speaker is off
                                            ; 0-------    Disable noise canceler
                                            ; -0------    Capt. on falling edge
                                            ; --0-----    Reserved bit
                                            ; ---01---    For CTC mode
                                            ; -----000    Turn off timer
                            
.EQU TIMER1_TOGGLE_CTR_BITS_A = 0b01000000  ; TCCR1A bitmask when spk is playing
                                            ; 01------    Toggle OC1A cmp match
                                            ; --0000--    No output on OC1B/OC1C
                                            ; ------00    For CTC mode
                            
.EQU TIMER1_TOGGLE_CTR_BITS_B = 0b00001010  ; TCCR1B bitmask when spk is playing
                                            ; 0-------    Disable noise canceler
                                            ; -0------    Capt. on falling edge
                                            ; --0-----    Reserved bit
                                            ; ---01---    For CTC mode
                                            ; -----010    Prescale with clk / 8


; Timer 3 definitions (for CTC compare match interrupts):

.EQU	TIMER3A_ON = 0b00000000		; Turn on timer 3
					                ;  00------  no output on OC1A
					                ;  --00----  no output on OC1B
					                ;  ----00--  reserved
					                ;  ------00  no PWM output

.EQU	TIMER3B_ON = 0b00001001	    ; Turn on timer 3
					                ;  0-------  disable noise canceler
                                    ;  -0------  capture on falling edge
					                ;  --00----  reserved
					                ;  ----1---  clear on compare match
					                ;  -----001  run timer on clk

.EQU	TIMER3RATE = 7999		    ; This is 1 ms assuming 8 MHz clock
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms
                                    
