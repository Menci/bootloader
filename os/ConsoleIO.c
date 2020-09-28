#include "ConsoleIO.h"

#include "IO.h"
#include "Memory.h"

struct CursorPosition {
    i8 row, column;
} currentCursorPosition = { 0, 0 };

const i8 SCREEN_WIDTH = 80;
const i8 SCREEN_HEIGHT = 25;
u16 *const TEXT_MODE_BUFFER = (u16 *)0xB8000;

u16 GetScreenPositionIndex(i8 row, i8 column) {
    return (u16)row * SCREEN_WIDTH + column;
}

u16 CombineCharacterWithMode(char ascii, u8 mode) {
    return ((u16)mode << 8) | ascii;
}

void WriteCharacterToScreenMemory(i8 row, i8 column, char ascii, u8 mode) {
    u16 index = GetScreenPositionIndex(row, column);
    TEXT_MODE_BUFFER[index] = CombineCharacterWithMode(ascii, mode);
}

void ClearScreen() {
    FillMemory16(
        TEXT_MODE_BUFFER,
        (size_t)SCREEN_WIDTH * SCREEN_HEIGHT,
        CombineCharacterWithMode(' ', 0x07)
    );
}

void SetCursorPosition(i8 row, i8 column) {
    u16 index = GetScreenPositionIndex(row, column);
 
    WritePortRegister8(0x3D4, 0x0F);
    WritePortRegister8(0x3D5, index & 0xFF);
    WritePortRegister8(0x3D4, 0x0E);
    WritePortRegister8(0x3D5, (index >> 8) & 0xFF);

    currentCursorPosition.row = row;
    currentCursorPosition.column = column;
}

void ScrollUpScreen() {
    // Move everything in the buffer except the last line
    MoveMemory(
        TEXT_MODE_BUFFER,                // Buffer address from 0-th line
        TEXT_MODE_BUFFER + SCREEN_WIDTH, // Buffer address from 1-st line
        (size_t)SCREEN_WIDTH * (SCREEN_HEIGHT - 1) * sizeof(u16)
    );

    // Fill the last line
    FillMemory16(
        TEXT_MODE_BUFFER + (size_t)SCREEN_WIDTH * (SCREEN_HEIGHT - 1),
        SCREEN_WIDTH,
        CombineCharacterWithMode(' ', 0x07)
    );
}

void MoveToNewLine() {
    if (currentCursorPosition.row == SCREEN_HEIGHT - 1) {
        ScrollUpScreen();
        SetCursorPosition(SCREEN_HEIGHT - 1, 0);
    } else {
        SetCursorPosition(currentCursorPosition.row + 1, 0);
    }
}

void OutputAsciiCharacter(char ascii, u8 mode) {
    switch (ascii) {
    case '\n':
        // Newline
        MoveToNewLine();
        break;
    case '\t':
        // Tab
        for (size_t i = 0; i < 8 - (currentCursorPosition.column % 8); i++)
            OutputAsciiCharacter(' ', mode);
        break;
    default:
        WriteCharacterToScreenMemory(currentCursorPosition.row, currentCursorPosition.column, ascii, mode);
        if (currentCursorPosition.column == SCREEN_WIDTH - 1)
            MoveToNewLine();
        else
            SetCursorPosition(currentCursorPosition.row, currentCursorPosition.column + 1);
    }
}

void OutputAsciiString(const char *string, u8 mode) {
    for (const char *p = string; *p; p++) {
        OutputAsciiCharacter(*p, mode);
    }
}
