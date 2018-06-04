;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW4TEST                                  ;
;                            Homework #4 Test Code                           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #4.  The function makes a
; number of calls to the PlayNote and ReadEEROM functions to test them.  The
; functions included are:
;    EEROMSoundTest - test the homework sound and EEROM functions
;
; Revision History:
;    5/31/18  Glen George               initial revision




; chip definitions
;.include  "m64def.inc"

; local include files
;    none




.cseg




; EEROMSoundTest
;
; Description:       This procedure tests the sound and EEROM functions.  It
;                    first loops calling the PlayNote function.  Following
;                    this it makes a number of calls to ReadEEROM.  A tone is
;                    output while testing EEROM.  The tone increases in pitch
;                    as the tests are done.  If a test fails a low tone is
;                    output and the LEDs are red.  At the end the start of the
;                    Twilight Zone theme is played and the LEDs are green if
;                    the tests pass.  The function never returns.
;
; Operation:         The arguments to call each function with are stored in
;                    tables.  The function loops through the tables making the
;                    appropriate function calls.  Delays are done after calls
;                    to PlayNote so the sound can be heard.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20         - test counter.
;                    Z (ZH | ZL) - test table pointer.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            The LED display is set to all red or all green.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18, R19, R20, X (XH | XL), Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       unknown (at least 7 bytes)
;
; Author:            Glen George
; Last Modified:     May 31, 2018

EEROMSoundTest:

TestSetup:
	LDI	R16, 0xFF		;will be using LEDs, set up direction
	OUT	DDRA, R16
	OUT	DDRC, R16
	OUT	DDRD, R16
					;copy EEROM data from code to data
	LDI	ZL, LOW(2 * EEROMDataTab)	;start at the beginning of the
	LDI	ZH, HIGH(2 * EEROMDataTab)	;   EEROM data table
	LDI	XL, LOW(CompareBuffer)		;buffer with expected data
	LDI	XH, HIGH(CompareBuffer)
	LDI	R16, 128		;128 bytes to transfer

CopyLoop:
	LPM	R0, Z+			;get EEROM data
	ST	X+, R0			;store in compare buffer
	DEC	R16			;update loop counter
	BRNE	CopyLoop		;and loop while still have bytes to copy
	;BREQ	PlayNoteTests		;otherwise start the tests


PlayNoteTests:				;do some tests of PlayNote only
	LDI	ZL, LOW(2 * TestPNTab)	;start at the beginning of the
	LDI	ZH, HIGH(2 * TestPNTab)	;   PlayNote test table
	LDI	R20, 8			;get the number of tests

PlayNoteTestLoop:
	LPM	R16, Z+			;get the PlayNote argument from the
	LPM	R17, Z+			;   table

	PUSH	ZL			;save registers around PlayNote call
	PUSH	ZH
	PUSH	R20
	RCALL	PlayNote		;call the function
	POP	R20			;restore the registers
	POP	ZH
	POP	ZL

	LDI	R16, 200		;delay for 2 seconds
	RCALL	Delay16			;and do the delay

	DEC	R20			;update loop counter
	BRNE	PlayNoteTestLoop	;and keep looping if not done
	;BREQ	ReadEEROMTests    	;otherwise test ReadEEROM function


ReadEEROMTests:				;do the SetCursor tests
	LDI	ZL, LOW(2 * TestRdTab)	;start at the beginning of the
	LDI	ZH, HIGH(2 * TestRdTab)	;   ReadEEROM test table
	LDI	R20, 9			;get the number of tests

ReadEEROMTestLoop:

	LPM	R16, Z+			;get sound to play while testing EEROM
	LPM	R17, Z+			;   reads

	PUSH	ZL			;save registers around PlayNote call
	PUSH	ZH
	PUSH	R20
	RCALL	PlayNote		;call the function
	POP	R20			;restore the registers
	POP	ZH
	POP	ZL

	LPM	R16, Z+			;now get the ReadEEROM arguments from
	LPM	R17, Z+			;   the table
	LDI	YL, LOW(ReadBuffer)	;buffer to read data into
	LDI	YH, HIGH(ReadBuffer)

	PUSH	ZL			;save registers around ReadEEROM call
	PUSH	ZH
	PUSH	R20
	PUSH	R17
	PUSH	R16
	RCALL	ReadEEROM		;call the function
	POP	R16			;restore the registers
	POP	R17
	POP	R20
	POP	ZH
	POP	ZL

CheckData:				;check the data read
	LDI	YL, LOW(ReadBuffer)	;buffer with data read
	LDI	YH, HIGH(ReadBuffer)
	LDI	XL, LOW(CompareBuffer)	;buffer with expected data
	LDI	XH, HIGH(CompareBuffer)

	ADD	XL, R17			;get the pointer to data actually read
	LDI	R17, 0
	ADC	XH, R17

CheckDataLoop:				;now loop checking the bytes
	LD	R18, Y+			;get read data
	LD	R19, X+			;get compare data
	CP	R18, R19		;check if the same
	BRNE	PlayFailure		;if not, failure
	DEC	R16			;otherwise decrement byte count
	BRNE	CheckDataLoop		;and check all the data

	LDI	R16, 35			;read worked - let the note play for
	RCALL	Delay16			;   350 milliseconds

	DEC	R20			;update loop counter
	BRNE	ReadEEROMTestLoop	;and keep looping if not done
	;BREQ	PlaySuccess	    	;if done - everything worked, play success tune


PlaySuccess:				;play the tune indicating success

	LDI	R16, 0xFF		;turn LEDs all green
	OUT	PORTA, R16
	LDI	R16, 0
	OUT	PORTD, R16
	LDI	R16, 0xFF
	OUT	PORTC, R16

	LDI	ZL, LOW(2 * SuccessTab)	;start at the beginning of the
	LDI	ZH, HIGH(2 * SuccessTab);   special success tune table
	LDI	R20, 16			;get the number of notes

PlaySuccessLoop:
	LPM	R16, Z+			;get the PlayNote argument from the
	LPM	R17, Z+			;   table

	PUSH	ZL			;save registers around PlayNote call
	PUSH	ZH
	PUSH	R20
	RCALL	PlayNote		;call the function
	POP	R20			;restore the registers
	POP	ZH
	POP	ZL

	LDI	R16, 35			;each note is 350ms
	RCALL	Delay16			;and do the delay

	DEC	R20			;update loop counter
	BRNE	PlaySuccessLoop		;and keep looping if not done
	BREQ	DoneEEROMSoundTests    	;otherwise done with tests


PlayFailure:				;play the tune indicating failure
	LDI	R16, LOW(261)		;play middle C
	LDI	R17, HIGH(261)
	RCALL	PlayNote

	LDI	R16, 0xFF		;turn LEDs all red
	OUT	PORTD, R16
	LDI	R16, 0
	OUT	PORTA, R16
	LDI	R16, 0xFF
	OUT	PORTC, R16

	LDI	R16, 50			;1/2 second note
	RCALL	Delay16

	LDI	R16, LOW(82)		;play E2
	LDI	R17, HIGH(82)
	RCALL	PlayNote

	LDI	R16, 100		;1 second note
	RCALL	Delay16

	;BREQ	DoneEEROMSoundTests    	;and done with tests


DoneEEROMSoundTests:			;have done all the tests
	LDI	R16, 0			;turn off the sound
	LDI	R17, 0
	RCALL	PlayNote

        RJMP    PC			;and tests are done


        RET	   	                ;should never get here




; Delay16
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units.
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         R16 - 1/80000 the number of CPU clocks to delay.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 6, 2018

Delay16:

Delay16Loop:				;outer loop runs R16 times
	LDI	YL, LOW(20000)		;inner loop is 4 clocks
	LDI	YH, HIGH(20000)		;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:			;do the delay
	SBIW	Y, 1
	BRNE	Delay16InnerLoop

	DEC	R16			;count outer loop iterations
	BRNE	Delay16Loop


DoneDelay16:				;done with the delay loop - return
	RET




; Test Tables


; TestPNTab
;
; Description:      This table contains the values of arguments for testing
;                   the PlayNote function.  Each entry is just a 16-bit
;                   frequency for the note to play.
;
; Author:           Glen George
; Last Modified:    May 31, 2018

TestPNTab:

	.DW	261			;middle C
	.DW	440			;middle A
	.DW	1000
	.DW	0			;turn off output for a bit
	.DW	2000
	.DW	50
	.DW	4000
	.DW	100




; TestRdTab
;
; Description:      This table contains the values of arguments for testing
;                   the ReadEEROM function.  Each entry consists of the note
;                   frequency to play during the test, the number of bytes to
;                   read, and the address from which to read the bytes.
;
; Author:           Glen George
; Last Modified:    May 31, 2018

TestRdTab:
	.DW	146
	.DB	2, 0
	.DW	220
	.DB	10, 6
	.DW	294
	.DB	1, 100
	.DW	370
	.DB	1, 121
	.DW	440
	.DB	2, 93
	.DW	523
	.DB	21, 68
	.DW	622
	.DB	17, 33
	.DW	784
	.DB	64, 63
	.DW	1000
	.DB	128, 0




; SuccessTab
;
; Description:      This table contains the tune to play upon successful
;                   completion of the tests.  Each entry is the frequency of a
;                   note to play.
;
; Author:           Glen George
; Last Modified:    May 31, 2018

SuccessTab:

	.DW	860, 830, 660, 784
	.DW	860, 830, 660, 784
	.DW	860, 830, 660, 784
	.DW	860, 830, 660, 784




; EEROMDataTab
;
; Description:      Table of data to that should be read from the EEROM.
;                   There are 1024 bits (64 16-bit words).
;
; Author:           Glen George
; Last Modified:    May 31, 2018

EEROMDataTab:

	.DW	0x5555, 0xAAAA, 0x55AA, 0xAA55
	.DW	0x1234, 0x5678, 0x9ABC, 0xDEF0
	.DW	0x0102, 0x0408, 0x1020, 0x4080
	.DW	0xFEFD, 0xFBF7, 0xEFDF, 0xBF7F
	.DW	0x1122, 0x3344, 0x5566, 0x7788
	.DW	0x0001, 0x0203, 0x0405, 0x0607
	.DW	0x0809, 0x0A0B, 0x0C0D, 0x0E0F
	.DW	0x1011, 0x1213, 0x1415, 0x1617
	.DW	0x2829, 0x2A2B, 0x2C2D, 0x2E2F
	.DW	0x1819, 0x1A1B, 0x1C1D, 0x1E1F
	.DW	0x2021, 0x2223, 0x2425, 0x2627
	.DW	0x3031, 0x3233, 0x3435, 0x3637
	.DW	0x99AA, 0xBBCC, 0xDDEE, 0xFF00
	.DW	0x4041, 0x4243, 0x4445, 0x4647
	.DW	0x4849, 0x4A4B, 0x4C4D, 0x4E4F
	.DW	0x3839, 0x3A3B, 0x3C3D, 0x3E3F




;the data segment


.dseg


; buffer for data read from the EEROM
ReadBuffer:	.BYTE	128		;EEROM is 1024 bits

; buffer containing the expected data from the EEROM
CompareBuffer:	.BYTE	128		;EEROM is 1024 bits
