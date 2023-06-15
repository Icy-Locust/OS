BUILD = ./build
BOOT = ./boot
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/kernel -I lib/ -I kernel/ -I thread/ -I device/
ASLIB = -I $(BOOT)/include
CFLAGS = -Wall -m32 -c -fno-builtin $(LIB) -fno-stack-protector
ASFLAGS = -f elf $(ASLIB)
LDFLAGS = -Ttext $(ENTRY_POINT) -e main -m elf_i386
BOOT_OBJS = $(BOOT)/mbr.bin $(BOOT)/loader.bin
HEAD_INIT = kernel/init.h
HEAD_DEBUG = kernel/debug.h
HEAD_MEMORY = kernel/memory.h
HEAD_GLOBAL = kernel/global.h
HEAD_INTERRUPT = kernel/interrupt.h
HEAD_IO = lib/kernel/io.h
HEAD_BITMAP = lib/kernel/bitmap.h
HEAD_LIST = lib/kernel/list.h
HEAD_PRINT = lib/kernel/print.h
HEAD_STDINT = lib/stdint.h
HEAD_STRING = lib/string.h
HEAD_TIMER = device/timer.h
HEAD_THREAD = thread/thread.h
OBJS = $(BUILD)/main.o $(BUILD)/init.o $(BUILD)/interrupt.o $(BUILD)/kernel.o \
       $(BUILD)/print.o $(BUILD)/timer.o $(BUILD)/debug.o $(BUILD)/memory.o \
       $(BUILD)/bitmap.o $(BUILD)/string.o $(BUILD)/thread.o $(BUILD)/list.o \
       $(BUILD)/switch.o
.PHONY: all mk_dir clean build boot hd
all: mk_dir build hd
mk_dir:
	if [[ ! -d $(BUILD) ]];then mkdir $(BUILD);fi
clean:
	rm $(OBJS) $(BOOT_OBJS)
build: $(BUILD)/kernel.bin $(BOOT_OBJS)
boot: $(BOOT_OBJS)
	dd if=$(BOOT)/mbr.bin of=hd60M.img \
		bs=512 count=1 conv=notrunc
	dd if=$(BOOT)/loader.bin of=hd60M.img \
		bs=512 seek=2 conv=notrunc
hd: $(BUILD)/kernel.bin
	dd if=$(BUILD)/kernel.bin of=hd60M.img \
		bs=512 count=200 seek=9 conv=notrunc

$(BOOT)/loader.bin: $(BOOT)/loader.S
	$(AS) $(ASLIB) $< -o $@
$(BOOT)/mbr.bin: $(BOOT)/mbr.S
	$(AS) $(ASLIB) $< -o $@

$(BUILD)/print.o:lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/kernel.o:kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/switch.o:thread/switch.S
	$(AS) $(ASFLAGS) $< -o $@


$(BUILD)/string.o:lib/string.c $(HEAD_STRING) $(HEAD_GLOBAL) $(HEAD_DEBUG)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/bitmap.o:lib/kernel/bitmap.c $(HEAD_BITMAP) $(HEAD_STDINT) \
	$(HEAD_STRING) $(HEAD_PRINT) $(HEAD_INTERRUPT) $(HEAD_DEBUG)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/list.o:lib/kernel/list.c $(HEAD_LIST) $(HEAD_INTERRUPT)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/init.o:kernel/init.c $(HEAD_INIT) $(HEAD_PRINT) $(HEAD_INTERRUPT) \
	$(HEAD_TIMER) $(HEAD_MEMORY) $(HEAD_THREAD)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/main.o:kernel/main.c $(HEAD_PRINT) $(HEAD_INIT) \
	$(HEAD_MEMORY) $(HEAD_INTERRUPT)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/interrupt.o:kernel/interrupt.c $(HEAD_INTERRUPT) \
	$(HEAD_STDINT) $(HEAD_GLOBAL) $(HEAD_IO) $(HEAD_PRINT)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/debug.o:kernel/debug.c $(HEAD_DEBUG) $(HEAD_PRINT) $(HEAD_INTERRUPT)
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/memory.o:kernel/memory.c $(HEAD_MEMORY) $(HEAD_STDINT) \
	$(HEAD_PRINT) $(HEAD_BITMAP) $(HEAD_STRING) \
	$(HEAD_DEBUG) $(HEAD_GLOBAL)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/timer.o:device/timer.c $(HEAD_TIMER) $(HEAD_IO) \
	$(HEAD_PRINT) $(HEAD_THREAD) $(HEAD_DEBUG) $(HEAD_INTERRUPT)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/thread.o:thread/thread.c 
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

seq:
	seq 0 32 | xargs  -n 1 printf "VECTOR 0x%02X,ZERO\n"
