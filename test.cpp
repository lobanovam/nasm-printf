#include <stdio.h>
extern "C" void _my_print(const char * str, ...);

int main() {
    _my_print("Уважаемый %s, сейчас %d:%d ночи, я написал уже %b строк этого грёбаного кода "
    "и останавливаться не собираюсь. Я умею выводить hex: %x, oct: %o, char: %c, и dec: %d\n", "Дед", 3, 15, 8, 0xabcd, 7, 'F', -123);
    return 0;
}
