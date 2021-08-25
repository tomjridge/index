module type S = sig
  type t
  val of_fd : Unix.file_descr -> t
  val unsafe_write :
    t ->
    src:string ->
    src_off:int -> dst_off:int -> len:int -> unit
  val unsafe_read :
    t -> src_off:int -> len:int -> buf:bytes -> unit
  val fsync : t -> unit
  val fstat : t -> Unix.stats
  val close : t -> unit
end
