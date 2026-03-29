/*
 * ef9367.h
 * 
 * a library of primitives for the thompson ef9367 card. 
 * 
 * notes:
 *  partner mixes text and graphics in a non-conventional way. images from 
 *  both sources are mixed on display, but remain independent of each other 
 *  i.e. clear screen in text mode will remove text from the display, 
 *  but leave all the graphics. and vice versa. 
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 04.04.2021   tstih
 * 
 */
#ifndef __EF9367_H__
#define __EF9367_H__

#include <std.h>

/* hires mode screen size */
#define EF9367_HIRES_WIDTH      1024
#define EF9367_HIRES_HEIGHT     512
#define EF9367_LORES_WIDTH      1024
#define EF9367_LORES_HEIGHT     256

/* initializes gdp, enter hires (1024x512) mode */
extern void _ef9367_init();

/* clear screen and goto 0,0 */
extern void _ef9367_cls();

/* put pixel at x,y using drawing mode */
extern void _ef9367_put_pixel();

/* draw fast line */ 
extern void _ef9367_draw_line(
    unsigned int x0, 
    unsigned int y0, 
    unsigned int x1,
    unsigned int y1);  

/* set display page */
extern void _ef9367_set_dpage(int page);

/* set write page */
extern void _ef9367_set_wpage(int page);

/* set line style */
extern void _ef9367_set_lstyle(uint8_t ls);

/* set resolution...0=hires, 1=lores */
extern void _ef9367_set_res(uint8_t res);

#endif /* __EF9367_H__ */