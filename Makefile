all: main

main : printf.o test.o
	gcc -no-pie test.o printf.o -o main

printf.o : printf.asm 
	nasm -f elf64 -o printf.o  printf.asm

test.o : test.cpp
	gcc	-c test.cpp -o test.o
	
clear:
	rm *.o
