;
; bootsect.asm
;
; This program loads "setup" routine to 0x90000 and "system"
; routine to 0x10000. The system size won't exceed 0x80000
; (512KB) in the future.
;

SYSSIZE		EQU	0x3000	; 系统所占的段范围
SETUPLEN	EQU	4	; sector amount of setup on the disk

BOOTSEG		EQU	0x07c0
INITSEG		EQU	0x9000
SETUPSEG	EQU	0x9020
SYSSEG		EQU	0x1000

; ---------------------------------------------------------
start:	
	mov	ax, BOOTSEG
	mov	ds, ax
	mov	ax, INITSEG
	mov	es, ax
	sub	si, si
	sub	di, di
	mov	cx, 0x100	; 512 / 2 = 0x100
	rep movsw
	jmp INITSEG:go
go: 
; 打印信息
; INT 10h AH=03h 读取光标位置
; BH 需要返回光标的页
; 返回：
; DH 光标行位置; DL 光标列位置
; CH 光标底部扫描线; CL 光标顶部扫描线
	mov	ah, 0x03	; read cursor pos
	xor	bh, bh		; BH=00h 第0页
	int	0x10
; INT 10h AH=13h 写字符串
; ES:BP 指向字符串
; 返回：
; CX 字符长度
; DH 光标行位置；DL 光标列位置
; BL 显示属性；AL 显示模式 01h 仅字符，更新光标
	mov ax, 0x1301
	mov bp, msg1
	mov cx, 36
	mov bx, 0x0004
	int 0x10

; ---------------------------------------------------------
; 从磁盘读入setup程序
; BIOS中断调用0x13:低端磁盘服务
; AH=02h 读磁盘
; ES:BX 内存位置
; DH 驱动器号00h/01h; DL 磁头号0~1
; CH 磁道号0-1023, 高两位为CL[8,9]; CL 扇区号1-17
; AL 读取的扇区数量1~80h
; 返回：AL 已经读区的扇区数,AH 0x00 Carry=1无错误
load_setup:
	mov ah, 0x02
	mov al, SETUPLEN
	mov dx, 0x0000
	mov bx, 0x200
	mov cx, 0x0002
	int 0x13
	jz ok_load_setup
bad_rd:
	mov ax, 0x0000		; 复位磁盘
	mov dx, 0x0000
	int 0x13

; ---------------------------------------------------------
; 显示加载系统
ok_load_setup:
	mov ah, 0x03
	xor bh, bh
	int 0x10

	mov ax, 0x1301
	mov bp, msg2
	mov cx, 23
	mov bx, 0x0004
	int 0x10

; ---------------------------------------------------------
; 读取软盘驱动器参数，尤其是扇区数量
; 定义变量
; 保存驱动器参数信息
sectors db 0
heads	db 0
tracks	dw 0

read_para:
	mov ax, INITSEG
	mov ds, ax
	mov ah, 0x08
	mov dl, 0x00
	int 0x13

	mov al, cl
	and al, 0x3f
	mov [sectors], al
	mov [heads], dh
	mov ah, cl
	shr ah, 6
	mov al, ch
	mov [tracks], ax 

; ---------------------------------------------------------
; 继续加载整个系统到0x10000处
sread db 5 ; 本磁道已经读取的扇区数
track db 0 ; 磁道号
head  db 0 ; 磁头号

load_system:
	mov ax, SYSSEG
	mov es, ax		; 初始化es, bx
	xor bx, bx
rp_read:
	mov ax, es
	cmp ax, SYSSEG+SYSSIZE
	je ok_load_system

	xor cx, cx
	mov cl, [sread]
	inc cl 			; 计算下一个要读取的起始扇区
	xor ax, ax
	mov al, [sectors]
	sub al, [sread]		; 计算出本磁道未读取的扇区数 al = sectors - sread
	mov dx, ax
	shl dx, 9
	add dx, bx		; 计算出当前段地址剩余访问范围
	jnc read_track 		; al = (al < (0x10000-bx)) ? al : (0x10000-bx)
	shr dx, 9
	sub al, dl		; 如果当前段访问地址耗尽，需要根据dl=bx+sread-0x10000计算读取的扇区数
read_track:			; al, cl 已经通过前面的计算设置好了。
	mov ah, 0x02
	mov ch, [track]
	xor dx, dx
	mov dh, [head]
	int 0x13
	jnc ok_read_track
bad_read_track:		; 如果读取失败
	mov ax, 0x0000	; 复位磁盘
	mov dx, 0x0000
	int 0x13
	jmp read_track

ok_read_track:
	xor ah, ah
	xor cx, cx
	mov cl, al		; 保存此次成功读取的扇区数
	add al, [sread]
	cmp al, [sectors]
	jne ok1_read		; 不需要更新磁头和磁道
	xor al, al		; 更新sread
	mov dx, 1
	sub dl, [head]		; 更新磁头：1-head(=0)=1, 1-head(=1)=0
	mov [head], dl
	jne ok1_read
	mov ah, [track]
	inc ah			; 更新磁道
	mov [track], ah
ok1_read:
	mov [sread], al		; sread = (al + sread == 0) ? 0 : al + sread
	shl cx, 9
	add bx, cx
	jnc	rp_read
; 更新段地址es
	mov ax, es
	add ax, 0x1000
	mov es, ax
	jmp rp_read

; ---------------------------------------------------------
; 最后跳转到setup继续执行
ok_load_system:
	jmp INITSEG:0x0200


msg1:
	db 13, 10
	db "Running bootsect at 0x90000..."
	db 13, 10, 13, 10

msg2:
	db 13, 10
	db "Loading System..."
	db 13, 10, 13, 10

empty:
	times 510-($-$$) db 0
mbr:
	db 0x55, 0xaa


