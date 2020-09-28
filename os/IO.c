#include "IO.h"

u32 IOReadPortRegister32(u16 port) {
    u32 result;

    asm(
        "mov dx, %1\n"
        "in eax, dx\n"
        "mov %0, eax\n"
      : "=r"(result)
      : "r"(port)
      : "dx", "eax"
    );

    return result;
}

void WritePortRegister32(u16 port, u32 value) {
    asm(
        "mov dx, %0\n"
        "mov eax, %1\n"
        "out dx, eax\n"
      :
      : "r"(port), "r"(value)
      : "dx", "eax"
    );
}

u16 IOReadPortRegister16(u16 port) {
    u16 result;

    asm(
        "mov dx, %1\n"
        "in ax, dx\n"
        "mov %0, ax\n"
      : "=r"(result)
      : "r"(port)
      : "dx", "ax"
    );

    return result;
}

void WritePortRegister16(u16 port, u16 value) {
    asm(
        "mov dx, %0\n"
        "mov ax, %1\n"
        "out dx, ax\n"
      :
      : "r"(port), "r"(value)
      : "dx", "ax"
    );
}

u8 IOReadPortRegister8(u16 port) {
    u8 result;

    asm(
        "mov dx, %1\n"
        "in al, dx\n"
        "mov %0, al\n"
      : "=r"(result)
      : "r"(port)
      : "dx", "al"
    );

    return result;
}

void WritePortRegister8(u16 port, u8 value) {
    asm(
        "mov dx, %0\n"
        "mov al, %1\n"
        "out dx, al\n"
      :
      : "r"(port), "r"(value)
      : "dx", "al"
    );
}
