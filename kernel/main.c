#include "print.h"
#include "init.h"
#include "thread.h"
#include "interrupt.h"
#include "console.h"
#include "ioqueue.h"
#include "keyboard.h"
#include "debug.h"

char char_buf[64];
uint32_t int_buf[2];
int int_nr	= 0;
int count	= 0;

void compare(void *arg);
void char_to_int();
void get_char(void *arg);

int main(void)
{
	put_str("I am kernel\n");
	init_all();

	thread_start("get_char", 31, get_char, NULL);
	thread_start("compare", 4, compare, NULL);
	intr_enable();
	while(1);
	return 0;
}

void get_char(void *arg)
{
	while(1) {
		enum intr_status old_status = intr_disable();
		if (!ioq_empty(&kbd_buf)) {
			char byte = ioq_getchar(&kbd_buf);
			if (byte == 0x8) {		// BS
				count--;
				console_put_char(byte);
			} else if (byte == 0xD) {	// newline
				char_to_int();
				console_put_char(byte);
			} else if (byte >= '0' && byte <= '9') {
				char_buf[count++] = byte;
				console_put_char(byte);
			}
		}
		intr_set_status(old_status);
	}
}

void char_to_int()
{
	ASSERT(count > 0);
	int n = 0, i = 1;
	do {
		n += (char_buf[--count] - '0') * i;
		i *= 10;
	} while (count > 0);
	int_buf[int_nr++] = n;
	ASSERT(count == 0);
}


void compare(void *arg)
{
	while (1) {
		if (int_nr == 2) {
			uint32_t a = int_buf[0];
			uint32_t b = int_buf[1];
			put_str("0x");
			put_int(a);
			if (a > b)
				put_str(" > ");
			else if (a < b)
				put_str(" < ");
			else
				put_str(" = ");
			put_str("0x");
			put_int(b);
			put_str("\n");
			int_nr = 0;
		}
	}
}
