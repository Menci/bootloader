#ifndef _MENCI_OS_IO_H
#define _MENCI_OS_IO_H

#include "Types.h"

u32 IOReadPortRegister32(u16 port);

void WritePortRegister32(u16 port, u32 value);

u16 IOReadPortRegister16(u16 port);

void WritePortRegister16(u16 port, u16 value);

u8 IOReadPortRegister8(u16 port);

void WritePortRegister8(u16 port, u8 value);

#endif // _MENCI_OS_IO_H
