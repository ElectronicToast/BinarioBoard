;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              eeromsoundinit.asm                            ;
;                     EEROM/Speaker Initialization Functions                 ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the necessary procedures to 
;                   initialize the I/O ports, timers, and SPI bus on the 
;                   ATmega64 in order to use the sound and EEROM reading 
;                   procedures for the EE 10b Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Port initialization:
;           InitEEROMSpkPorts()         Initializes Port B for EEROM, speaker 
;       Timer initialization:
;           InitSpkTimer()              Set up Timer 1 for use in playing tones
;                                       Turn off sound when called.
;       SPI initialization:
;           InitEEROM()                 Set up the SPI control registers for 
;                                       communicating with the 93C46A EEPROM
;
; Revision History:
;    6/01/18    Ray Sun         Initial revision.
;    6/10/18    Ray Sun         Moved speaker timer initialization function to 
;                               common timer initialization file. Updated 
;                               description.



; local include files
;.include  "gendefines.inc"
;.include  "iodefines.inc"
;.include  "eeromdefines.inc"
;.include  "sounddefines.inc"



; ################################ CODE SEGMENT ################################
.cseg



; InitEEROMSpkPorts():
;
; Description           This procedure initializes I/O port B appropriately for 
;                       controlling the speaker and reading/writing to the SPI 
;                       lines.
;
; Operation             The ports in Port B are initialized so that the speaker 
;                       line (PB5) is output and the SPI lines are set so that 
;                       the ATmega64 is the SPI master: !SS (PB0), SCK (PB1),
;                       and MOSI (PB2) are outputs, while MISO (PB3) is an 
;                       input. All outputs are initialized to off.
;
; Arguments             None.
; Return Values         None.
;   
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
;   
; Inputs                None.
; Outputs               All outputs of Port B are initialized to off.
;   
; Error Handling        None.
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R16
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/01/2018  


InitEEROMSpkPorts:
    LDI     R16, EEROM_SPK_DATA_DIR     ; Set up the Port B DDR with appropriate
    OUT     EEROM_SPK_DDR, R16          ; I/O directions for speaker, SPI lines
    CLR     R16                         ; Clear all outputs and turn off 
    OUT     EEROM_SPK_PORT, R16         ; internal pullups for inputs 
    ;RJMP    EndInitEEROMSpkPorts        ; and return
    
EndInitEEROMSpkPorts:       
    RET                                 ; Done, so return



; InitEEROM()
;
; Description           This procedure initializes the SPI bus on the ATmega64 
;                       in order to read from the serial EEROM (93C46A serial 
;                       EEPROM chip). The ATmega64 is set as the SPI master.
; 
; Operation             The SPRC (SPI control) and SPSR (SPI status)
;                       registers are set appropriately to set up the 
;                       ATmega64 as the SPI master. The leading edge is the 
;                       rising edge of SCK (SCK is low when idle), and sampling
;                       occurs on the leading edge of SCK.
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
; Algorithms            None.
; Data Structures       None.
;   
; Limitations           None.
; Known Bugs            None.
; Special Notes         None.
;
; Registers Changed     R16
; Stack Depth           0 bytes
;
; Author                Ray Sun
; Last Modified         06/01/2018  


InitEEROM:
    LDI     R16, SPCR_MASTER            ; Write the SPRC and SPSR registers to 
    OUT     SPCR, R16                   ; set up the ATmega64 as the SPI master,
    ;RJMP    EndInitEEROM                ; and we are done 
    
EndInitEEROM:
    RET                                 ; We are done, so return
    