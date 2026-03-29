/*
 * std.c
 *
 * standard library definitions to make libgpx independent
 *
 * MIT License (see: LICENSE)
 * copyright (c) 2021 tomaz stih
 *
 * 09.08.2021   tstih
 *
 */

int _abs (int i) { return i < 0 ? -i : i; }