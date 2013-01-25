all: j1 j1.bin

j1: j1.c
	gcc -g -o j1 j1.c

j1.bin: *.fs
	gforth -e 'include main.fs bye'
