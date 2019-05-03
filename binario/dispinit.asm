;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 dispinit.asm                               ;
;                        Display Initialization Functions                    ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This Assembly file contains the necessary procedures to 
;                   initialize the I/O ports and timers on the ATmega64 in order 
;                   to use the display functions for the EE 10b Binario board.
;
; Table of Contents:
;   
;   CODE SEGMENT 
;       Port initialization:
;           InitDispPorts()             Initializes the ports of the display 
;
; Revision History:
;    5/04/18    Ray Sun         Initial revision.
;    5/05/18    Ray Sun         Removed unnecessary .dseg from file
;    5/14/18    Ray Sun         Renamed `init.asm` to `dispinit.asm` and 
;                               modified `InitPorts` to set the display 
;                               ports as output for HW 3 submission. Also
;                               renamed to `InitDispPorts`
;    5/18/18    Ray Sun         Added TOC.
;    6/10/18    Ray Sun         Removed Timer 3 initialization; moved 
;                               initialization to a common file.
;                               Replaced sdisplay muxing interrupt-generating
;                               timer with Timer 2 instead of Timer 3.



; ################################ CODE SEGMENT ################################
.cseg



; local include files
;.include  "gendefines.inc"
;.include  "iodefines.inc"
;.include  "dispdefines.inc"



; InitDispPorts:
;
; Description           This procedure initializes the I/O ports driving the
;                       display (row output, red column output, green column 
;                       output) as outputs and initializes them as off.
;
; Operation             The constant `OUTDATA`, a byte of 1's to indicate the 
;                       output direction, is loaded into R16 and output to the 
;                       data direction register for the row port and the two
;                       column ports.
;
; Arguments             None.
; Return Values         None.
; 
; Global Variables      None.
; Shared Variables      None.
; Local Variables       None.
; 
; Inputs                None.
; Outputs               The display row port (C) and column ports (A and D) are 
;                       set as output and initialized to off.
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
; Last Modified         05/14/2018


InitDispPorts:                          ; Initialize I/O port directions
        LDI     R16, OUTDATA            ; Initialize all display ports as 
        OUT     ROW_DDR, R16            ; all outputs
        OUT     COL_R_DDR, R16
        OUT     COL_G_DDR, R16
        CLR     R16                     ; And all outputs are low (off)
        OUT     ROW_PORT, R16
        OUT     COL_PORT_R, R16
        OUT     COL_PORT_G, R16
        ;RJMP    EndInitDispPorts        ; Done initializing ports
        
EndInitDispPorts:                       ; Done, so return
        RET
