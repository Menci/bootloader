#include "Memory.h"

void FillMemory8(void *destination, size_t count, u8 value) {
    u8 *u8Destination = (u8 *)destination;
    for (size_t i = 0; i < count; i++)
        u8Destination[i] = value;
}

void FillMemory16(void *destination, size_t count, u16 value) {
    u16 *u16Destination = (u16 *)destination;
    for (size_t i = 0; i < count; i++)
        u16Destination[i] = value;
}

void FillMemory32(void *destination, size_t count, u32 value) {
    u32 *u32Destination = (u32 *)destination;
    for (size_t i = 0; i < count; i++)
        u32Destination[i] = value;
}

void FillMemory64(void *destination, size_t count, u64 value) {
    u64 *u64Destination = (u64 *)destination;
    for (size_t i = 0; i < count; i++)
        u64Destination[i] = value;
}

void ZeroMemory(void *destination, size_t length) {
    FillMemory8(destination, length, 0);
}

void CopyMemory(void *destination, void *source, size_t length) {
    u8 *u8Destination = (u8 *)destination;
    u8 *u8Source = (u8 *)source;
    for (size_t i = 0; i < length; i++)
        u8Destination[i] = u8Source[i];
}

void MoveMemory(void *destination, void *source, size_t length) {
    u8 *u8Destination = (u8 *)destination;
    u8 *u8Source = (u8 *)source;
    if (destination < source)
        for (size_t i = 0; i < length; i++)
            u8Destination[i] = u8Source[i];
    else
        for (size_t i = 0; i < length; i++)
            u8Destination[length - i - 1] = u8Source[length - i - 1];
}

