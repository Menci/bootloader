#ifndef _MENCI_OS_CONSOLE_IO_H
#define _MENCI_OS_CONSOLE_IO_H

#include "Types.h"

void ClearScreen();

void SetCursorPosition(i8 row, i8 column);

void ScrollUpScreen();

void OutputAsciiCharacter(char ascii, u8 mode);

void OutputAsciiString(const char *string, u8 mode);

#endif // _MENCI_OS_CONSOLE_IO_H
