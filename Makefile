#
# Makefile for zeros 
#
# Zeros is a runnable reimplement of linux-0.11.
#

AS	= nasm -f bin
LD	= ld
CC 	= gcc -mcpu=i386
CFLAGS	= -Wall -O2 -fomit-frame-pointer
LDFLAGS = -m elf_i386 -e startup_32


all : img

%.bin : %.asm
	$(AS) -l $*.lst -o $*.bin $<

%.o : %.c
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

img : boot/bootsect.bin boot/setup.bin boot/header.bin
	mkdir -p build
	dd bs=512 if=boot/bootsect.bin of=build/zeros.img
	dd bs=512 count=4 seek=1 if=boot/setup.bin of=build/zeros.img
	dd bs=512 count=384 seek=5 if=boot/header.bin of=build/zeros.img

.PHONY : clean
clean :
	rm -rf boot/*.bin boot/*.lst *.o *.img build/
