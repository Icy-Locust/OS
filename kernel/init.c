#include "init.h"
#include "print.h"
#include "interrupt.h"
#include "../device/timer.h"
#include "memory.h"

extern void idt_init();
void init_all() {
	put_str("init_all\n");
	idt_init();
	mem_init();
	timer_init();
}
