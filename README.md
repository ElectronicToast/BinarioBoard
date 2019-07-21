# BinarioBoard
AVR Assembly code for the Binario board project for EE 10b at Caltech

![Binario Board](/img/ee10b_boardl.png)

## About
Binario is a puzzle game that might be likened to binary Soduku. The game is played on a square grid of even size, some positions of which are initially filled in with one of two distinct (and thus "binary") symbols. The objective of the game is to populate the entire grid with symbols such that

1. No more than two of the same symbol aligned are present horizontally or vertically.
2. Every row and column must contain the same number of each symbol.
3. No two rows may be identical. No two columns may be identical.

This repository contains an AVR Studio 4 project comprising Assembly files for an implmentation of Binario on a custom ATmega64-based game board for the Introduction to Digital Logic and Embedded Systems (EE 10b) course at Caltech. The board allows the user to play Binario on an 8-by-8 red/green LED dot matrix. Eight different puzzles are available for play. 

## Building the Game
These instructions explain how to set up the Binario game:

1. Make the board according to the [schematic](http://wolverine.caltech.edu/ee10b/homework/binario/binariosch.pdf). A different AVR with at least 4 kB flash, 211 B SRAM, one 16-bit timer, and one 8-bit timer might be used instead of the ATmega64.
2. For this project, [AVR Studio 4.18](http://www.microchip.com/mplab/avr-support/avr-and-sam-downloads-archive) was used to develop the code.
3. In AVR Studio, configure the ATmega64 to use an external high-speed oscillator and enable all system timers.
4. Code may be uploaded with the JTAG ICE mode and a suitable programmer.

## Playing the Game

Upon powering on, the display will show a starburst animation, followed by a scrolling "Binario" message, and then another starburst animation. Then, a preset starting grid will be shown. The display flashes to indicate the game selection screen. 

Scroll the left/right movement encoder to view the different puzzles available. Press the encoder to select the puzzle and start the game.

During gameplay, scroll the encoders to move the blinking cursor. Pressing the left/right movement encoder will change the color of the selected position, cycling from clear to red to green. The game will play a warning sound should one attempt to change the color of a preset position or fill in the grid incorrectly.

Once the correct solution has been entered, the screen will blink green while a short tune plays. Then the solution is displayed for viewing.

Pressing the up/down encoder switch at any time during gameplay resets the game to the game selection mode.

For more information, please refer to the [functional specification](https://github.com/ElectronicToast/BinarioBoard/blob/master/binario_funcspec.pdf).

## Authors
* Ray Sun - Undergraduate, Electrical Engineering, Caltech, 2020

## Acknowledgments
* [Glen George](https://directory.caltech.edu/personnel/gleng) designed the Binario game board as well as the starting animations.

## Links
* [EE 10b Spring 2018 Course Webpage](http://wolverine.caltech.edu/ee10b/)
* [Binario Board Schematic](http://wolverine.caltech.edu/ee10b/homework/binario/binariosch.pdf)
* [Binario Game - System Requirements & Description](http://wolverine.caltech.edu/ee10b/homework/binario/binariosys.htm)
