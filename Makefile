hd:loader mbr
	dd if=boot/mbr.bin of=boot/hd60M.img bs=512 count=1 conv=notrunc
	dd if=boot/loader.bin of=boot/hd60M.img bs=512 seek=2 conv=notrunc
loader:boot/loader.S
	nasm -I boot/include -o boot/loader.bin boot/loader.S
mbr:boot/mbr.S
	nasm -I boot/include -o boot/mbr.bin boot/mbr.S
kernel:kernel/main.c
	cd kernel && gcc -m32 -c -o main.o main.c && \
	objcopy -R .note.gnu.property main.o && \
	ld -m elf_i386 main.o -Ttext 0xc0001500 -e main -o kernel.bin && \
	dd if=kernel.bin of=../boot/hd60M.img bs=512 count=200 seek=9 conv=notrunc && \
	cd -
clean:
	rm boot/{loader.bin,mbr.bin}
	rm kernel/{main.o,kernel.bin}
