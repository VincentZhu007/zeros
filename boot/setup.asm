;
; setup.asm
;
; 执行系统初始化工作：
; (1) 从BIOS读取硬件参数，存到bootsect位置
; (2) 将system移动到0x0000处
; (3) 设置gdt和idt，进入保护模式
;
; 朱国栋 2020-1-19
;

INITSEG  EQU 0x9000
SETUPSEG EQU 0x9020
SYSSEG   EQU 0x1000

start:
; ---------------------------------------------------------
; 从BIOS读取一些硬件参数，供系统启动时使用
; 存放在0x90000开始的位置
; +---------+---+------------+
; | 0x90000 | 2 | 光标位置    |
; +---------+---+------------+
; | 0x90002 | 2 | 扩展内存大小 |
; +---------+---+------------+
; | 0x9000C | 2 | 显卡参数    |
; +---------+---+------------+
	mov ax, INITSEG ; 将硬件参数存放到bootblock位置
	mov ds, ax
; 读取光标位置
	mov ah, 0x03
	xor bh, bh
	int 0x10
	mov [0], dx
; 读取扩展内存大小
	mov ah, 0x88
	int 0x15
	mov [2], ax
; 读取显示参数
	mov ah, 0x0f
	int 0x10
	mov [4], bx ; bh 当前页数
	mov [6], ax ; al 显示模式，ah 字符列数
; 还可以读取一些其它参数，此处省略...

; ---------------------------------------------------------
; 移动system模块
	cli ; 关闭中断，因为system模块移到0地址时，会覆盖BIOS中断向量表
 
; 首先将system移到合适的位置:由0x10000移到0x00000
	mov ax, SYSSEG
	mov ds, ax
	xor bx, bx
	mov es, bx
	cld
do_move:
	cmp ax, 0x9000
	je end_move
	xor si, si
	xor di, di
	mov cx, 0x8000 ; 每次循环拷贝0x10000个字符
	rep movsw
	add ax, 0x1000
	mov ds, ax
	add bx, 0x1000
	mov es, bx
	jmp do_move

; ---------------------------------------------------------
; 进入保护模式:设置GDT和IDT
end_move:
	mov ax, SETUPSEG
	mov ds, ax
	lidt [idt_48] ; 为什么是访问idt_48处对内容，而不是地址？
	lgdt [gdt_48]

; 使能A20地址线，这样才能访问超出1MB的内存
; 可以改用fast a20寄存器
enable_a20:
	call empty_8042 ; 检查键盘输入是否为空
	mov al, 0xd1 ; 写命令
	out 0x64, al
	call empty_8042
	mov al, 0xdf ; A20已使能
	out 0x60, al
	call empty_8042

; ---------------------------------------------------------
; 对中断控制器8259重新初始化
; 将中断号0x20-0x2f设置给中断控制器8259
	mov al, 0x11 ; 初始化序列
	out 0x20, al ; 8259-1
	nop
	out 0xa0, al ; 8259-2
	nop
	mov al, 0x20 ; 8259-1起始中断号为0x20
	out 0x21, al
	nop
	mov al, 0x28 ; 8259-2起始中断号为0x28
	out 0xa1, al
	nop
	mov al, 0x04 ; 8289-1为主芯片
	out 0x21, al
	nop
	mov al, 0x02 ; 8259-2为从芯片
	out 0xa1, al
	nop
	mov al, 0x01 ; 8086模式
	out 0x21, al
	nop
	out 0xa1, al
	nop
	mov al, 0xff ; 暂时屏蔽所有中断
	out 0x21, al
	nop
	out 0xa1, al
	nop

; ---------------------------------------------------------
; 最后跳转到setup继续执行
ok_setup:
	mov ax, 0x0001 ; 保护模式位置1
	lmsw ax ; 加载机器状态字，设置CR0[0]-PE=1，后面必须接一条立即跳转指令，清空指令流水线
	jmp dword 8:0 ; 跳转到gdt[8]基址+0


; =========================================================
; 检查键盘序列的例程
; 此例程检查键盘命令序列为空，如果缓冲不为空，无法设置A20
empty_8042:
	nop
	in al, 0x64
	test al, 2
	jnz empty_8042
	ret
; =========================================================
; 定义全局描述符表
gdt:
	dw 0,0,0,0 ; null描述符,p=0段不存在

	dw 0x07ff ; 8MB limit=2047 (2048*4096=8MB)
	dw 0x0000 ; 基址0x0000
	dw 0x9a00 ; 代码段：只读
	dw 0x00c0 ; 粒度=4096

	dw 0x07ff ; 8MB limit=2047 (2048*4096=8MB)
	dw 0x0000 ; 基址0x0000
	dw 0x9200 ; 数据段：向上扩展，可写
	dw 0x00c0 ; 粒度=4096
; 定义中断描述符表寄存器内容
idt_48:
	dw 0	; 限制0，空表
	dw 0, 0 ; idt基址 0L
; 定义全局描述符表内容
gdt_48:
	dw 0x800 ; 限制为2048，最多256个表项
	dw 512+gdt, 0x9 ; 段基址 0x90200+gdt

empty:
    times 4*512-($-$$) db 0

