SHELL := /bin/bash
CFLAGS := -std=gnu11 -O2 -nostdlib -masm=intel -m32 -march=i386 -mno-red-zone -fno-stack-protector -ffreestanding -fno-pie -ffunction-sections

OS_SRC := ${wildcard os/*.c}
OS_OBJ := ${patsubst os/%.c, build/%.o, $(OS_SRC)}

# Modify this to set the start sector number of code to be loaded
CODE_STARTING_SECTOR := 20

.PHONY: all
all: build/disk.img
	qemu-system-i386 build/disk.img

.PHONY: debug
debug: build/disk.img
	qemu-system-i386 -S -s build/disk.img

.PHONY: clean
clean:
	rm -rf build/*

build/bootloader.o: bootloader/bootloader.s
	as -o build/bootloader.o bootloader/bootloader.s

build/mbr.sectors.bin: build/bootloader.o
	ld -Ttext=0x7c00 --oformat=binary -o build/mbr.sectors.bin build/bootloader.o

$(OS_OBJ): build/%.o : os/%.c
	$(CC) $(CFLAGS) -c $^ -o $@

build/os.o: $(OS_OBJ)
	ld -m elf_i386 -e Main --script=C.ld $(OS_OBJ) -o build/os.o

build/os.sectors.bin: build/os.o
	objcopy -j .text -j .data -O binary build/os.o build/os.sectors.bin
	# Align to 512 byte sectors
	truncate build/os.sectors.bin --size=$$(((($$(wc -c < build/os.sectors.bin) + 512 - 1) / 512) * 512))

build/code_len.bin: build/os.sectors.bin
	xxd -r -g0 <<< "0: $$(printf "%.8x" $$(wc -c < build/os.sectors.bin) | tac -rs .. | echo "$$(tr -d '\n')")" > build/code_len.bin

build/meta.sectors.bin: build/code_len.bin
	# Write binary format CODE_STARTING_SECTOR
	xxd -r -g0 <<< "0: $$(printf "%.8x" ${CODE_STARTING_SECTOR} | tac -rs .. | echo "$$(tr -d '\n')")" > build/meta.sectors.bin
	# Write how many bytes
	cat build/code_len.bin >> build/meta.sectors.bin
	# Fill the remaining 512 - 8 bytes
	dd if=/dev/zero of=build/meta.sectors.bin bs=1 count=$$((512 - 8)) seek=8

build/disk.img: build/mbr.sectors.bin build/os.sectors.bin build/meta.sectors.bin
	cat build/mbr.sectors.bin build/meta.sectors.bin > build/disk.img
	dd if=build/os.sectors.bin of=build/disk.img seek=${CODE_STARTING_SECTOR}
