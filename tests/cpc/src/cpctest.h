/* Phase markers for the CPC scenario runner.
 *
 * A scenario halts between phases. The runner screenshots at every HALT,
 * steps past it, and stops when cpc_finished is set. That is the same
 * protocol the Partner GDP suite uses.
 */
#ifndef CPCTEST_H
#define CPCTEST_H

#include "libgpx.h"

extern uint8_t cpc_finished;

#define cpc_phase()  __asm__("halt")
#define cpc_finish() do { cpc_finished = 1; __asm__("halt"); } while (0)

#endif
