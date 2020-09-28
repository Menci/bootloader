SECTIONS
{
    . = 0x100000;
    .text :
    {
        *(.text.SystemMain);
        *(.text*);
    }
    .data :
    {
        *(.data*);
        *(.bss*);
        *(.rodata*);
        *(*);
    }
}
