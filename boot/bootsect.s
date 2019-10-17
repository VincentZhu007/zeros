; bootsect.s
; =============================================================================
; load system from hard disk.
;
; keep system size in 0x30000 (192k).
; (1) load system code to the memory.
; (2) jump to system header.
; =============================================================================

entry:
	jmp near start

BOOTSEG		EQU 0x07c0
SYSSEG		EQU 0x9000
SZ		EQU 0x3000

VIDEOSEG	EQU 0xb800
start:
	; set data segment
	mov ax, BOOTSEG
	mov ds, ax
	
	; set stack	
	mov ax, 0x0000
	mov ss, ax
	mov sp, 512	; stack size = 512B

	; print load system ...

; -----------------------------------------------------------------------------
; print string end with '\0'
;
; input arg:	ax string header address

println:
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	push si
	push di

	mov ds, ax
	mov ax, VIDEOSEG
	mov es, ax
	xor si, si
	
	; read cursor

	; print normal msg

	; left return and switch line

	; set cursor
	

msg0:	db "load system ...", 0x00
msg1:	db "finished", 0x00

	times 510-($-$$) db 0
	db 0x55, 0xaa

	
	


