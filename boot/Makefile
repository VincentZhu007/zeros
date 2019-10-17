# Makefile for boot module

obj-boot = bootsect.bin

all : $(obj-boot)

%.bin : %.s
	nasm -f bin -o $@ $<

.PHONY : clean
clean :
	rm -rf *.bin

