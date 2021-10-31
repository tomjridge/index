(** Quick test of O_DIRECT *)


[@@@warning "-33"]

open Optint


let t = ()

let _ = 
  Index_unix.Syscalls.openfile_unbuffered "test.txt" [O_CREAT;O_RDWR;O_TRUNC] 0o640 |> fun fd ->
  (* Index_unix.Syscalls.openfile_buffered "test.txt" [O_CREAT;O_RDWR;O_TRUNC] 0o640 |> fun fd ->  *)
  Printf.printf "Opened\n%!";
  Unix.ftruncate fd 8192;
  Unix.write fd (Bytes.create 4096) 0 4096 |> fun n ->
  (* Index_unix.Syscalls.pwrite ~fd ~fd_offset:(Int63.of_int 0) ~buffer:(Bytes.create 4096) ~buffer_offset:0 ~length:4096 |> fun n -> *)
  assert(n=4096);
  Printf.printf "wrote 4096 bytes\n%!";
  Unix.write fd (Bytes.create 4095) 0 4095 |> fun n -> 
  assert(n=4095);
  Printf.printf "wrote 4095 bytes\n%!";
  ()
  
  
  
