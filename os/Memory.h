#ifndef _MENCI_OS_MEMORY_H
#define _MENCI_OS_MEMORY_H

#include "Types.h"

void FillMemory8(void *destination, size_t count, u8 value);

void FillMemory16(void *destination, size_t count, u16 value);

void FillMemory32(void *destination, size_t count, u32 value);

void FillMemory64(void *destination, size_t count, u64 value);

void ZeroMemory(void *destination, size_t length);

void CopyMemory(void *destination, void *source, size_t length);

void MoveMemory(void *destination, void *source, size_t length);

#endif // _MENCI_OS_MEMORY_H
