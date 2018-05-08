@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "E:\RaySun\hw2test\labels.tmp" -fI -W+ie -o "E:\RaySun\hw2test\hw2test.hex" -d "E:\RaySun\hw2test\hw2test.obj" -e "E:\RaySun\hw2test\hw2test.eep" -m "E:\RaySun\hw2test\hw2test.map" "E:\RaySun\hw2test\hw2test.asm"
