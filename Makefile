BUILD = ./build
BOOT = ./boot
ENTRY_POINT = 0xc0001500
AS = nasm
CC = gcc
LD = ld
LIB = -I lib/kernel -I lib/ -I kernel/
ASLIB = -I $(BOOT)/include
CFLAGS = -m32 -c -fno-builtin $(LIB) -fno-stack-protector
ASFLAGS = -f elf $(ASLIB)
LDFLAGS = -Ttext $(ENTRY_POINT) -e main -m elf_i386
BOOT_OBJS = $(BOOT)/mbr.bin $(BOOT)/loader.bin
OBJS = $(BUILD)/main.o $(BUILD)/init.o $(BUILD)/interrupt.o $(BUILD)/kernel.o \
       $(BUILD)/print.o
$(BOOT)/loader.bin: $(BOOT)/loader.S
	$(AS) $(ASLIB) $< -o $@
$(BOOT)/mbr.bin: $(BOOT)/mbr.S
	$(AS) $(ASLIB) $< -o $@

$(BUILD)/print.o:lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/kernel.o:kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD)/main.o:kernel/main.c lib/kernel/print.h kernel/init.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/interrupt.o:kernel/interrupt.c kernel/interrupt.h kernel/global.h \
	lib/kernel/io.h lib/kernel/print.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/init.o:kernel/init.c kernel/init.h lib/kernel/print.h \
	kernel/interrupt.h
	$(CC) $(CFLAGS) $< -o $@
$(BUILD)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

boot: $(BOOT_OBJS)
	dd if=$(BOOT)/mbr.bin of=hd60M.img \
		bs=512 count=1 conv=notrunc
	dd if=$(BOOT)/loader.bin of=hd60M.img \
		bs=512 seek=2 conv=notrunc
hd: $(BUILD)/kernel.bin
	dd if=$(BUILD)/kernel.bin of=hd60M.img \
		bs=512 count=200 seek=9 conv=notrunc  
clean:
	cd $(BUILD) && rm -f ./* && cd -
	cd $(BOOT) && rm -f ./*.bin && cd -
build: $(BUILD)/kernel.bin $(BOOT_OBJS)
all: clean hd boot 

.PHONY: all
seq:
	seq 0 32 | xargs  -n 1 printf "VECTOR 0x%02X,ZERO\n"
