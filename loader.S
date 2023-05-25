%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

GDT_BASE:
	dd 0x00000000
	dd 0x00000000
CODE_DESC:
	dd 0x0000ffff
	dd DESC_CODE_HIGH4
DATA_STACK_DESC:
	dd 0x0000ffff
	dd DESC_DATA_HIGH4
VIDEO_DESC:
	dd 0x80000007
	dd DESC_VIDEO_HIGH4
	GDT_SIZE equ $ - GDT_BASE
	GDT_LIMIT equ GDT_SIZE - 1
	times 60 dq 0
	SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
	SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
	SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

	gdt_ptr dw GDT_LIMIT
	dd GDT_BASE
	myloader db 'HCB in REAL'
loader_start:
	mov sp,LOADER_BASE_ADDR
	mov bp,myloader
	mov cx,11
	mov ax,0x1301
	mov bx,0x001f
	mov dx,0x0100
	int 0x10

	in al,0x92
	or al,0000_0010b
	out 0x92,al
	lgdt [gdt_ptr]
	mov eax,cr0
	or eax,0x00000001
	mov cr0, eax
	jmp dword SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
	mov ax,SELECTOR_DATA
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov esp,LOADER_STACK_TOP
	mov ax,SELECTOR_VIDEO
	mov gs,ax

	mov byte[gs:320],'H'
	mov byte[gs:321],0xA4
	mov byte[gs:322],'C'
	mov byte[gs:323],0xA4
	mov byte[gs:324],'B'
	mov byte[gs:325],0xA4
	mov byte[gs:326],' '
	mov byte[gs:327],0xA4
	mov byte[gs:328],'i'
	mov byte[gs:329],0xA4
	mov byte[gs:330],'n'
	mov byte[gs:331],0xA4
	mov byte[gs:332],' '
	mov byte[gs:333],0xA4
	mov byte[gs:334],'P'
	mov byte[gs:335],0xA4
	mov byte[gs:336],'R'
	mov byte[gs:337],0xA4
	mov byte[gs:338],'O'
	mov byte[gs:339],0xA4
	mov byte[gs:340],'T'
	mov byte[gs:341],0xA4
	mov byte[gs:342],'E'
	mov byte[gs:343],0xA4
	mov byte[gs:344],'C'
	mov byte[gs:345],0xA4
	mov byte[gs:346],'T'
	mov byte[gs:347],0xA4

	jmp $
