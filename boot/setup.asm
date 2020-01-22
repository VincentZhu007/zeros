;
; setup.asm
;
; 执行系统初始化工作
;
; 朱国栋, 2020-1-19
;

SETUPSEG EQU 0x9020
SYSSEG   EQU 0x1000

start:
    mov ax, SETUPSEG
    mov es, ax

; 打印信息
; INT 10h AH=03h 读取光标位置
; BH 需要返回光标的页
; 返回：
; DH 光标行位置;			DL 光标列位置
; CH 光标底部扫描线;		 CL 光标顶部扫描线
	mov	ah, 0x03	; read cursor pos
	xor	bh, bh		; BH=00h 第0页
	int	0x10
; INT 10h AH=13h 写字符串
; ES:BP 指向字符串
; 返回：
; CX 字符长度
; DH 光标行位置；			DL 光标列位置
; BL 显示属性				AL 显示模式 01h 仅字符，更新光标
	mov ax, 0x1301
	mov bp, msg2
	mov cx, 26
	mov bx, 0x0004
	int 0x10

; ---------------------------------------------------------
; 最后跳转到setup继续执行
ok_setup:
	jmp SYSSEG:0x0000

msg2:
    db 13, 10
    db "Setting up system..."
    db 13, 10, 13, 10

empty:
    times 4*512-($-$$) db 0

