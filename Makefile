hd:loader mbr
	dd if=mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc
	dd if=loader.bin of=hd60M.img bs=512 seek=2 conv=notrunc
loader:loader.S
	nasm -o loader.bin loader.S
mbr:mbr.S
	nasm -o mbr.bin mbr.S
