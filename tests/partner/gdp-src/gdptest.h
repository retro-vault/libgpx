/* Shared helpers for Partner GDP scenarios run on the real emulator.
 *
 * The GDP framebuffer is not CPU-visible, so a scenario cannot inspect its
 * own output. Instead it draws, then HALTs; the runner captures the raster
 * at every HALT, steps the CPU past the HALT, and lets it carry on.
 *
 * gdp_phase() ends one phase. gdp_done() ends the last one and sets the
 * sentinel the runner uses to tell "another phase follows" from "finished",
 * so no scenario has to agree with the runner about how many phases it has. */

#ifndef __GDPTEST_H__
#define __GDPTEST_H__

#include "libgpx.h"

#define GDP_FINISHED 0xA5

extern uint8_t gdp_finished;

#define gdp_phase() __asm__("halt")
#define gdp_done()                     \
    do {                               \
        gdp_finished = GDP_FINISHED;   \
        __asm__("halt");               \
    } while (0)

/* One definition per scenario; scenarios are single-file, so this lives in
 * the header and each image gets exactly one copy. */
uint8_t gdp_finished;

#endif /* __GDPTEST_H__ */
