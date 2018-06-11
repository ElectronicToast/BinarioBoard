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
;       Timer 1 (Speaker)
;           Timer 1 control registers for normal mode (speaker off) and 
;               CTC output compare toggle mode (speaker on)
;       Timer 2 (Encoder/switch reading, display multiplexing - CTC compare):
;           Timer 2 control register pattern for CTC output compare mode 
;           Timer 2 output compare top value
;
; Revision History:
;    6/10/18    Ray Sun         Initial revision.



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


; Timer 2 definitions (for CTC compare match interrupts):

.EQU    TIMER2_ON   = 0b01000011
                    ;   0-------    Do not force output compare match 
                    ;   -10-----    CTC output compare mode 
                    ;   ---00---    No output on OC2
                    ;   -----011    Prescale by a factor of 64 
                    
.EQU    TIMER2RATE  = 124           ; This is 1 ms assuming 8 MHz clock and 
                                    ; a prescale of 64. 
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms  

; Timer 3 definitions (for CTC compare match interrupts):
                                    
;.EQU    TIMER3A_ON  = 0b00000000    ; Turn on timer 3
                                    ;  00------  no output on OC3A
                                    ;  --00----  no output on OC3B
                                    ;  ----00--  reserved
                                    ;  ------00  no PWM output
                                    
;.EQU    TIMER3B_ON  = 0b0000100     ; Turn on timer 3
                                    ;  0-------  disable noise canceler
                                    ;  -0------  capture on falling edge
                                    ;  --00----  reserved
                                    ;  ----1---  clear on compare match
                                    ;  -----001  run timer on clk

;.EQU    TIMER3RATE  = 7999          ; This is 1 ms assuming 8 MHz clock
                                    ;    Note: the timer resets on the clock
                                    ;    after the compare match so this count
                                    ;    needs to be one less than clocks/ms   
