# Assembly Electric Meter
This is a program I wrote for my computer architecture class. It takes inputs (electric line readings) from files and generates an output based on their content.

### DISCLAIMER
Absolutely **DO NOT** refer to this for any good practice in ASM programming. This is the first time I ever wrote something in assembly language and I still have **a lot** to improve on. It's also written in an outdated architecture (8086) and uses DOS interruptions.

## Objective
The main objective for this program is to read a text file that contains several lines with voltage readings and count how many are good, bad, or low.

* Example input file:
```
120, 	130,	127
121,	119,	125
123,	124,	128
fim
```
* A line is considered GOOD if all it's 3 values difference to the -v parameter is not greater than 10.
* A line is considered BAD if any of it's 3 values difference to the -v parameter is greater than 10.
* A line is considered LOW if ALL of it's 3 values are below 10.
<sub> Note that the file may, or may not, end with the word 'fim'. </sub>

To do this, the user calls the program via command line, informing the following parameters:
* -v: voltage; It's the value the program is going to take as a reference to tell if a reading is good or not. <sub> -v Can ONLY be 127 or 220. </sub>
* -i: input file; It's path for the file that contains all the voltages.
* -o: output file; It's the path for the file that's going to be generated (or written on) and contain the output.

Example of program call:
```
trab_intel.exe -i in1.txt -o out1.txt -v 220
```
All the arguments are optional, as the program has default values for all of them, but if an user informs an empty parameter, the program doesn't run and informs the user that one of the parameters is missing.
```
C:trab_intel -v 220 -i -o output_file.out
Opcao [-i] sem parametro.
```
It will do the same if the user informs anything through the -v parameter that's different from 127 and 220:
```
C:trab_intel -v 444 -i in1.txt -o output_file.out
Opcao [-v] deve ser 127 ou 220.
```
Before generating the output, though, the program verifies if any of the lines are invalid. A line is considered invalid if it contains any of the following:
* Space between numbers ```120, 1 30,	127```
* Missing commas ```123, 131  118```
* Missing numbers ```217, 220,   ```
* Numbers bigger than 499 ```500, 220, 220```

In case the input file has invalid lines, all those must be printed and the output file must not be generated:
```
Linha invalida 1: 120, 1 30,	127
Linha invalida 2: 123, 131  118`
Linha invalida 44: 217, 220,   
linha invalida 85: 500, 220, 220
```
The program also works for systems that end text lines with CR, LF or CRLF.

## Example of execution
For the following input file:
```
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
5,5,5
5,5,5
5,5,5
5,5,5
5,5,5
5,5,5
5,5,5
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
220,220,220
fim
```
This output is generated:
```
-i in7.txt
-o a.out
-v 220
Tempo de leitura: 0:0:26
Tempo com tensao de qualidade: 0:0:19
Tempo sem tensao: 0:0:7
```

