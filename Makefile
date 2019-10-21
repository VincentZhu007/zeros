# Makefile for zeros 
# A runnable reimplement of linux-0.11.
# ----------------------------------------------------------

NASM	= nasm -f bin
AS	= as
LD	= ld
CC 	= gcc -mcpu=i386
CFLAGS	= -Wall -O2 -fomit-frame-pointer
LDFLAGS = -m elf_i386 -e startup_32

all : img

%.bin : %.asm
	$(NASM) -l $*.lst -o $*.bin $<

.c.s:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -S -o $*.s $<

.s.o:
	$(AS) -o $*.o $<

.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

img : boot/bootsect.bin boot/bootsect.lst
	mkdir -p out
	dd bs=512  count=1 if=boot/bootsect.bin of=out/zeros.img

.PHONY : clean
clean :
	rm -rf *.bin *.lst *.o *.img ./out
