.intel_syntax noprefix

.code16
.globl _start
_start:
    call clear_screen
    call print_message
.end:
    hlt
    jmp .end

clear_screen:
    mov ah, 0x06 # Scroll

    mov al, 0    # Columns

    mov bh, 7    # Color: BG black, FG white

    mov cl, 0    # Left top Row
    mov ch, 0    # Left top Column
    mov dl, 79   # Right bottom Row
    mov dh, 24   # Right bottom Column

    int 0x10

    ret

print_message:
    mov ah, 0x13 # Display string

    mov bh, 0    # Page
    mov bl, 7    # Color: BG black, FG white

    mov dh, 0    # Row
    mov dl, 0    # Column

    # The string should be in es:bp. Our ds has been changed by the bootloader
    # So let es = ds
    push ds
    pop es
    lea bp, message
    mov cx, message_len

    mov al, 1    # Move cursor

    int 0x10

    ret


# Test a big code file
.org 10000

message:
    .ascii "Hello, World!\r\nMenci~ qwqwqwqwqwqwqwqwqwqwqwqwq"
message_len:
    .short . - message
