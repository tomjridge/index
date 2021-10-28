/*
 * Copyright (C) 2012-2013 Citrix Inc
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#define _GNU_SOURCE

#include <sys/types.h>
#include <sys/stat.h>

#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/signals.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/bigarray.h>

/* ocaml/ocaml/unixsupport.c */
extern void uerror(char *cmdname, value cmdarg);
#define Nothing ((value) 0)

#ifndef O_NONBLOCK
#define O_NONBLOCK O_NDELAY
#endif
#ifndef O_DSYNC
#define O_DSYNC 0
#endif
#ifndef O_SYNC
#define O_SYNC 0
#endif
#ifndef O_RSYNC
#define O_RSYNC 0
#endif

static int open_flag_table[15] = {
  O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK, O_APPEND, O_CREAT, O_TRUNC, O_EXCL,
  O_NOCTTY, O_DSYNC, O_SYNC, O_RSYNC,
  0, /* O_SHARE_DELETE, Windows-only */
  0, /* O_CLOEXEC, treated specially */
  0  /* O_KEEPEXEC, treated specially */
};

CAMLprim value stub_openfile_direct(value filename, value flags, value perm){
  CAMLparam3(filename, flags, perm);
  CAMLlocal1(result);
  int fd;
#ifdef _WIN32
  caml_failwith("O_DIRECT is not supported on Win32");
#else
  const char *filename_c = strdup(String_val(filename));

  int open_flags = caml_convert_flag_list(flags, open_flag_table);

  enter_blocking_section();
#ifdef O_DIRECT
  int flags_o = O_DIRECT;
#else
  int flags_o = 0;
#endif
  open_flags |= flags_o;
  fd = open(filename_c, open_flags, Int_val(perm));
  int ret = 0;
#ifndef O_DIRECT
  ret = fcntl(fd, F_NOCACHE);
#endif
  leave_blocking_section();

  free((void*)filename_c);

  if (fd == -1) uerror("open", filename);
  if (ret < 0)  uerror("open", filename);
  CAMLreturn(Val_int(fd));
#endif /* _WIN32 */
}
