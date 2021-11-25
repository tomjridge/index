(* The MIT License

   Copyright (c) 2021 Clément Pascutto <clement@tarides.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software. *)

(** Extensible buffers with non-allocating access to the buffer's contents. *)

(* FIXME question: the buffer is supposed to allow writing out entries
   "in one go", to avoid problems with crashes in the middle of
   writing (!) but clearly if we handle short writes by repeatedly
   issuing write calls, this can't succeed in its aims.

The point is: short read/writes mean that read/writes are not atomic,
   regardless of whether they go via a buffer. *)

type t
(** The type of buffers. The implementation is a record of a mutable
   bytes, and a mutable "position" at which to add new bytes. *)

val create : int -> t
(** [create n] is a fresh buffer with initial size [n]; the position is set to 0. *)

val length : t -> int
(** [length b] is the number of bytes contained in the buffer (before
   the current position). *)

val is_empty : t -> bool
(** [is_empty t] iff [t] contains 0 characters iff the position is 0. *)

val clear : t -> unit
(** [clear t] clears the data contained in [t] (by setting the
   position to 0). It does not reset the buffer to its initial
   size. *)

val add_substring : t -> string -> off:int -> len:int -> unit
(** [add_substring t s ~off ~len] appends the substring
    [s.(off) .. s.(off + len - 1)] at the end of [t], resizing [t] if necessary. *)

val add_string : t -> string -> unit
(** [add_string t s] appends [s] at the end of [t], resizing [t] if necessary. *)

val write_with : (string -> int -> int -> unit) -> t -> unit
(** [write_with writer t] uses [writer] to write the contents of
   [t]. [writer] takes a string to write, an offset and a length. It
   is called on the underlying buffer, with offset 0 and
   length=position. *)

val blit : src:t -> src_off:int -> dst:bytes -> dst_off:int -> len:int -> unit
(** [blit] copies [len] bytes from the buffer [src], starting at
   offset [src_off], into the supplied bytes [dst], starting at offset
   [dst_off]. Requires that src_off+len <= src.position. *)
