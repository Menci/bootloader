#include "ConsoleIO.h"

void Main() {
    OutputAsciiString("Hello, World!\nMenci~ qwqwqwqwqwqwqwqwqwqwqwqwq\n", 0x07);
}

_Noreturn void SystemMain() {
    ClearScreen();
    SetCursorPosition(0, 0);

    Main();

    while (1);
}
