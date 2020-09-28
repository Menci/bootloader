.intel_syntax noprefix

.code16
.globl _start
_start:
    # Use address from 0x7e00 (608 KB available)
    mov ax, 0x07e0
    mov ds, ax
    
    # Disk data from is read to memory region from ds:0
    mov si, 0

    # Read the sector 1 for metadata
    push si
    push 0x00
    push 0x01
    call read_disk_sector

    # The first 4 bytes is the starting sector number, store it to bx:ax
    mov ax, word ptr ds:[si + 0]
    mov bx, word ptr ds:[si + 2]

    # The following 4 bytes is the byte count, since it < 2048, just store the low word to cx
    mov cx, word ptr ds:[si + 4]
    mov dx, cx

    # Read code by sector to memory region from ds:0 (overwritting the metadata sector just read)
.read_code:
    # If the remaining bytes count to read is less than or equal to 0, the read is finished
    cmp cx, 0
    jle .read_finished

    push si
    push bx
    push ax
    call read_disk_sector

    # Decrease the remaining bytes count to read
    sub cx, 512
    # Inscrease the current write address
    add si, 512
    # Increase the sector ID
    add ax, 1 # Use add instead of inc since inc doesn't set CF
    adc bx, 0 # Do carry

    jmp .read_code # Loop

.read_finished:
    push word ptr 0x07e0
    push word ptr 0x0000
    push dx
    call execute_in_protected_mode

# push write address (ds:[write address])
# push LBA hiword
# push LBA loword
read_disk_sector:
    push bp
    mov bp, sp

    # Save registers
    push ax
    push dx
    push cx
    push si

    # word ptr ss:[bp + 2] return address
    # byte ptr ss:[bp + 4] LBA 0  ~ 7  bits
    # byte ptr ss:[bp + 5] LBA 8  ~ 15 bits
    # byte ptr ss:[bp + 6] LBA 16 ~ 23 bits
    # byte ptr ss:[bp + 7] LBA 24 ~ 27 bits (low 4 bits)
    # word ptr ss:[bp + 8] write address

    # Write 1 to primary's sector count register (0x1f2)
    mov dx, 0x1f2
    mov al, 1
    out dx, al

    # Write LBA 0 ~ 7 bits to primary's LBA low register (0x1f3)
    mov dx, 0x1f3
    mov al, byte ptr ss:[bp + 4]
    out dx, al

    # Write LBA 8 ~ 15 bits to primary's LBA mid register (0x1f4)
    mov dx, 0x1f4
    mov al, byte ptr ss:[bp + 5]
    out dx, al

    # Write LBA 16 ~ 23 bits to primary's LBA high register (0x1f5)
    mov dx, 0x1f5
    mov al, byte ptr ss:[bp + 6]
    out dx, al

    # Write LBA 24 ~ 27 bits to primary's device register (0x1f5)'s low 4 bits
    # Write 4 constant bits to primary's device register (0x1f5)'s high 4 bits
    mov dx, 0x1f6
    # LBA 24 ~ 27 bits are on the low 4 bits of ss:[bp + 7]
    mov al, byte ptr ss:[bp + 7]
    # Clear high 4 bits of al
    and al, 0b00001111
    #        -------- 7-th bit: Fixed 1
    #        |
    #        |------- 6-th bit: LBA is 1
    #        ||
    #        ||------ 5-th bit: Fixed 1
    #        |||
    #        |||----- 4-th bit: Primary disk is 0
    #        ||||
    or al, 0b11100000
    out dx, al

    # Write read (0x20) command to the command/status register (0x1f7)
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

    # Poll the command/status register (0x1f7)
    mov dx, 0x1f7
.poll_status:
    in al, dx
    and al, 0x88     # Preseve only "busy" or "ready" bit
    cmp al, 0x08     # Ready?
    jne .poll_status # If not equal to ready 0x08, continue to poll

    # Now the device is ready, read it
    # Load the write address
    mov di, word ptr ss:[bp + 8]
    # Repeat 512 / 2 = 256 times
    mov cx, 256
    # Read the data register (0x1f0)
    mov dx, 0x1f0
.read_loop:
    in ax, dx
    mov word ptr ds:[di], ax
    add di, 2
    loop .read_loop

    # Restore registers
    pop si
    pop cx
    pop dx
    pop ax

    # Return
    mov sp, bp
    pop bp
    ret 6

# Enter protected mode
# Then copy the code in a address range to 0x100000
# And execute the code in protected mode
#
# push code address segment
# push code address
# push code length
execute_in_protected_mode:
    # No need to `push bp` and save registers since we'll never return
    mov bp, sp

    # word ptr ss:[bp + 0] return address
    # word ptr ss:[bp + 2] code length
    # word ptr ss:[bp + 4] code address
    # word ptr ss:[bp + 6] code address segment

    # Read parameters into registers since we can't use the old segments once
    # entered protected mode.
    mov di, word ptr ss:[bp + 6] # code address segment
    mov si, word ptr ss:[bp + 4] # code address
    mov cx, word ptr ss:[bp + 2] # code length

    # Clear the Interrupt Flag to disable interrupts
    cli
    
    # Load the Global Descriptor Table
    lgdt cs:.gdt_info

    # Enable the A20 line (set 1-th bit of port register 0x92)
    mov dx, 0x92
    in al, dx
    or al, 0b10
    out dx, al

    # Enter protected mode (set 0-th bit of cr0)
    mov eax, cr0
    or eax, 0b1
    mov cr0, eax

    # Long jump to flush CPU cache (0b1000 is code segment)
    .byte 0x66, 0xea            # ljmp
    .long .protected_mode_start # offset
    .word 0b1000                # segment

.code32
.protected_mode_start:
    # Here we are in protected mode!

    # Set up segment registers (except cs, which will be set via a jmp)
    mov ax, 0b10000 # 2-nd segment for data (and stack)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    # Initialization the stack
    mov esp, 0x7c00
    
    # Copy the code into 0x100000

    # The original code is located at di:si
    movzx edi, di
    movzx esi, si
    shl edi, 4 # edi *= 16
    add esi, edi

    # The original code is located at esi
    # The destination address should be edi
    mov edi, 0x100000

    # The bytes to copy should be ecx
    movzx ecx, cx

    # Copy code
    cld
    rep movsb

    # Execute the code
    jmp 0x100000


# The Global Descriptor Table
.gdt_start:
    # A leading empty segment:
    # 8 zero bytes
    .int 0
    .int 0

    # Code segment:
    # limit (0 ~ 15 bits): the highest page (when grows up) or lowest page (when grows down) of the segment
    .short 0b1111111111111111 # Specify the highest page to 1 M since it grows up
    # base (0 ~ 23 bites): 32-bit offset for the segment
    .short 0b0000000000000000
    .byte 0b00000000
    # flags -------- Pr: Present = 1 (present)
    #       |
    #       |------- Privi: Descriptor Privilege Level = 00 (Ring 0)
    #       |||
    #       |||----- S: Descriptor Type = 1 (non-system)
    #       ||||
    #       ||||---- Ex: Execuate = 1 (executable)
    #       |||||
    #       |||||--- DC: Conforming = 0 (may NOT be called from less-privileged levels directly)
    #       ||||||
    #       ||||||-- RW: Read = 1 (readable via code)
    #       |||||||
    #       |||||||- Ac: Accessed = 0 (set by CPU when segment accessed)
    #       ||||||||
    #       PPrSXCRA
    .byte 0b10011010
    # The high 4 bit is `flags`. The low 4 bits are 16 ~ 23 bits of `limit`
    # flags -------- Gr: Granularity = 1 (4 KiB per page)
    #       |
    #       |------- Sz: Size = 1 (32-bit code)
    #       ||
    #       ||------ L: L = 0 (NOT 64-bit code)
    #       |||
    #       |||----- Sz: (reserved for future use)
    #       ||||
    # limit ||||---- 16 ~ 19 bits of `limit`
    #       ||||||||
    .byte 0b11001111
    # base (16 ~ 23 bites): 32-bit offset for the segment
    .byte 0b00000000

    # Data (and stack) segment:
    # limit (0 ~ 15 bits): the highest page (when grows up) or lowest page (when grows down) of the segment
    .short 0b0000000000000000 # Specify the lowest page to 0 since it grows down
    # base (0 ~ 23 bites): 32-bit offset for the segment
    .short 0b0000000000000000
    .byte 0b00000000
    # flags -------- Pr: Present = 1 (present)
    #       |
    #       |------- Privi: Descriptor Privilege Level = 00 (Ring 0)
    #       |||
    #       |||----- S: Descriptor Type = 1 (non-system)
    #       ||||
    #       ||||---- Ex: Execuate = 1 (executable)
    #       |||||
    #       |||||--- DC: Direction = 1 (may NOT be called from less-privileged levels directly)
    #       ||||||
    #       ||||||-- RW: Write = 1 (writable)
    #       |||||||
    #       |||||||- Ac: Accessed = 0 (set by CPU when segment accessed)
    #       ||||||||
    #       PPrSXDWA
    .byte 0b10010110
    # The high 4 bit is `flags`. The low 4 bits are 16 ~ 23 bits of `limit`
    # flags -------- Gr: Granularity = 1 (4 KiB per page)
    #       |
    #       |------- Sz: Size = 1 (data for 32-bit code, e.g. push/pop uses esp instead of sp)
    #       ||
    #       ||------ L: L = 0 (reserved)
    #       |||
    #       |||----- Sz: (reserved for future use)
    #       ||||
    # limit ||||---- 16 ~ 19 bits of `limit`
    #       ||||||||
    .byte 0b11000000
    # base (16 ~ 23 bites): 32-bit offset for the segment
    .byte 0b00000000
.gdt_end:

# Information to be loaded into the GDT register (48 bits)
.gdt_info:
    # First 16 bits: GDT's length - 1
    .short .gdt_end - .gdt_start - 1
    # Following 32 bits: The address of GDT
    .int .gdt_start

.org 510
.word 0xAA55
