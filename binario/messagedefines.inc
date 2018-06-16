;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              messagedefines.inc                            ;
;                  Scrolling Message / Animations Definitions                ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This include file contains definitions related to displaying
;                   scrolling messages and animations on the EE 10b Binario 
;                   board.
;
; Table of Contents:
;   
;   Message / animation table lengths 
;   Message / animation delays between frames 
;   Message table width 
;
; Revision History:
;    6/15/18    Ray Sun         Initial revision.



; Message / animation table lengths 

.EQU    MSG_WELCOME_LEN     = 60        
.EQU    MOV_STARBURST_LEN   = 7

; Delays between frames in scrolling or in animations

.EQU    MSG_SCROLL_DELAY    = 10        ; Delay between scrolls of display 
                                        ; in tens of ms
.EQU    MOV_DELAY           = 25        ; Delay between images in animation
                                        ; in tens of ms
           
; Table widths:
           
.EQU    MSG_TAB_WIDTH       = 2         ; Width of a scrolling message table (B)
