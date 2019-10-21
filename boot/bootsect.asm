; bootsect.s
; =============================================================================
; load system
;
; =============================================================================
;
;
;
; memory allocation
;
;
;       0x7c00(boot)                                     0x90000(new boot)
;        /                                                /
;       / 0x10000                                        / 0x90200(setup)
;      | /                                              | /
;      ||<--    sys    -->|                             ||
;      ||                 |                             ||
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
; |     |                 |                             |                                         |
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
; \                                                \                                               \
;  \                                                \                                               \
; 0x00000                                         0x7ffff                                         0xfffff
;
;
;
;
; =============================================================================



; define global constants
SYSSIZE		EQU 0x30000
SETUPLEN	EQU 4
BOOTSEG		EQU 0x07c0
INITSEG		EQU 0x9000
SETUPSEG	EQU 0x9020
SYSSEG		EQU 0x1000
ENDSEG		EQU SYSSEG + SYSSIZE


entry:
		jmp near start

; program start here
start:
; 拷贝bootsect程序到新的位置继续执行
		mov ax, BOOTSEG
		mov ds, ax
		mov ax, INITSEG
		mov es, ax
		mov cx, 256
		sub si, si
		sub di, di
		rep movsw
		jmp INITSEG:go 		; 段间跳转
go:		mov ax, INITSEG 	; 在0x9000:go处执行该程序
		mov ds, ax
		mov es, ax
; 设置堆栈， 0x9ff00，接近64KB堆栈空间
; 保持在0xa0000内（可用内存），尽可能大
		mov ss, ax
		mov sp, 0xff00

; 加载init程序到0x90200开始的内存中
load_setup:
		mov dx, 0x0000		; drive 0, head 0
		mov cx, 0x0002		; sector 2, track 0 读取第2~5个扇区
		mov bx, 0x0200		; es:bx缓冲区地址
		mov ax, 0x0200+SETUPLEN
		int 0x13			; 读取setup程序
		jnc ok_load_setup
; 读取失败，复位磁盘，重新读取
		mov dx, 0x0000
		mov ax, 0x0000
		int 0x13
		jmp near load_setup
; 读取驱动器参数
ok_load_setup:
		mov dl, 0x00
		mov ax, 0x0800		; AH=0x08
		int 0x13
		mov ch, 0x00
		mov ax, INITSEG
		mov es, ax

; 打印简单信息
		mov ah, 0x03		; 读取光标
		xor bh, bh			
		int 0x10

		mov cx, 24
		mov bx, 0x0004
		mov bp, msg1
		mov ax, 0x1301
		int 0x10


msg1:
		db 0x0d, 0x0a
		db "Loading system..."
		db 0x0d, 0x0a, 0x0d, 0x0a

end:
		times 510-($-$$) db 0
		db 0x55, 0xaa


