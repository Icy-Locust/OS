BUILD = ./build
BOOT = ./boot
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/kernel -I lib/ -I kernel/
ASLIB = -I $(BOOT)/include
CFLAGS = -Wall -m32 -c -fno-builtin $(LIB) -fno-stack-protector
ASFLAGS = -f elf $(ASLIB)
LDFLAGS = -Ttext $(ENTRY_POINT) -e main -m elf_i386
BOOT_OBJS = $(BOOT)/mbr.bin $(BOOT)/loader.bin
OBJS = $(BUILD)/main.o $(BUILD)/init.o $(BUILD)/interrupt.o $(BUILD)/kernel.o \
       $(BUILD)/print.o $(BUILD)/timer.o $(BUILD)/debug.o $(BUILD)/memory.o \
       $(BUILD)/bitmap.o $(BUILD)/string.o
all: hd boot 
boot: $(BOOT_OBJS)
	dd if=$(BOOT)/mbr.bin of=hd60M.img \
		bs=512 count=1 conv=notrunc
	dd if=$(BOOT)/loader.bin of=hd60M.img \
		bs=512 seek=2 conv=notrunc
hd: $(BUILD)/kernel.bin
	dd if=$(BUILD)/kernel.bin of=hd60M.img \
		bs=512 count=200 seek=9 conv=notrunc  
clean:
	rm $(OBJS) $(BOOT_OBJS)
build: $(BUILD)/kernel.bin $(BOOT_OBJS)

.PHONY: all
$(BOOT)/loader.bin: $(BOOT)/loader.S
	$(AS) $(ASLIB) $< -o $@
$(BOOT)/mbr.bin: $(BOOT)/mbr.S
	$(AS) $(ASLIB) $< -o $@

$(BUILD)/string.o:lib/string.c lib/string.h kernel/global.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/print.o:lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/kernel.o:kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/bitmap.o:lib/kernel/bitmap.c lib/kernel/bitmap.h \
	lib/stdint.h lib/kernel/print.h kernel/interrupt.h kernel/debug.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/init.o:kernel/init.c kernel/init.h lib/kernel/print.h \
	kernel/interrupt.h device/timer.h kernel/memory.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/main.o:kernel/main.c lib/kernel/print.h kernel/init.h kernel/memory.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/interrupt.o:kernel/interrupt.c kernel/interrupt.h lib/stdint.h \
	kernel/global.h lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/debug.o:kernel/debug.c kernel/debug.h \
	lib/kernel/print.h lib/stdint.h kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/memory.o:kernel/memory.c kernel/memory.h lib/stdint.h \
	lib/kernel/print.h lib/kernel/bitmap.h lib/string.h \
	kernel/debug.h kernel/global.h
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/timer.o:device/timer.c device/timer.h lib/kernel/io.h \
	lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

seq:
	seq 0 32 | xargs  -n 1 printf "VECTOR 0x%02X,ZERO\n"
