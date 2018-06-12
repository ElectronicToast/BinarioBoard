;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                iodefines.inc                               ;
;                         Binario Game I/O Definitions                       ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains general-purpose and hardware
;                   specific definitions for the ATmega64 timers for
;                   the EE 10b Binario board, related to the peripherals on 
;                   the board (rotary encoder switches, 8x8 red/green LED 
;                   display, speaker, EEROM).
;
; Table of Contents:
;
;   Timer definitions
;       Timer 0 (Encoder/switch reading, display multiplexing - CTC compare):
;           Timer 0 control register pattern for CTC output compare mode 
;           Timer 0 output compare top value
;       Timer 1 (Speaker)
;           Timer 1 control registers for normal mode (speaker off) and 
;               CTC output compare toggle mode (speaker on)
;
; Revision History:
;    6/10/18    Ray Sun         Initial revision.



; Timer 0 definitions (for CTC compare match interrupts):

.EQU    TIMER0_ON   = 0b00001110  ; TCCR2 bitmask for CTC output compare mode
                    ;   0-------    Do not force output compare match 
                    ;   -0--1---    CTC output compare mode 
                    ;   --00----    No output on OC2
                    ;   -----110    Prescale by a factor of 256
                    
.EQU    TIMER0RATE  = 31            ; This is ~1 ms assuming 8 MHz clock and 
                                    ; a prescale of 256.
                                    ; System clk / (1000 * prescale) =
                                    ; TIMER2RATE clocks per 1 ms
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms 
                                    
; Speaker timer (Timer 1) control register bitmasks:

.EQU    TIMER1A_OFF = 0b00000000    ; TCCR1B bitmask when speaker is off
                    ;   00------    No output on OC1A 
                    ;   --00----    No output on OC1B
                    ;   ----00--    No output on OC1C
                    ;   ------00    Normal operation
                            
.EQU    TIMER1B_OFF = 0b00001000    ; TCCR1B bitmask when speaker is off
                    ;   0-------    Disable noise canceler
                    ;   -0------    Capt. on falling edge
                    ;   --0-----    Reserved bit
                    ;   ---01---    For CTC mode
                    ;   -----000    Turn off timer
                            
.EQU    TIMER1A_ON  = 0b01000000    ; TCCR1A bitmask when spk is playing
                    ;   01------    Toggle OC1A cmp match
                    ;   --0000--    No output on OC1B/OC1C
                    ;   ------00    For CTC mode
                            
.EQU    TIMER1B_ON  = 0b00001010    ; TCCR1B bitmask when spk is playing
                    ;   0-------    Disable noise canceler
                    ;   -0------    Capture on falling edge
                    ;   --0-----    Reserved bit
                    ;   ---01---    For CTC mode
                    ;   -----010    Prescale with clk / 8

; Timer 3 definitions (for CTC compare match interrupts):
                                    
;.EQU    TIMER3A_ON  = 0b00000000    ; Turn on timer 3
                                    ;  00------  no output on OC3A
                                    ;  --00----  no output on OC3B
                                    ;  ----00--  reserved
                                    ;  ------00  no PWM output
                                    
;.EQU    TIMER3B_ON  = 0b00001001    ; Turn on timer 3
                                    ;  0-------  disable noise canceler
                                    ;  -0------  capture on falling edge
                                    ;  --00----  reserved
                                    ;  ----1---  clear on compare match
                                    ;  -----001  run timer on clk

;.EQU    TIMER3RATE  = 7999          ; This is 1 ms assuming 8 MHz clock
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms   
