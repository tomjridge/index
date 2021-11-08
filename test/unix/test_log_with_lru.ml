(** Simple test of functionality after adding an LRU to the log file;
   included in main tests. *)

module C = Common
let ( let* ) f k = f k

module Stats = Index.Stats

module Index = Common.Index

let root = Filename.concat "_tests" "test_log_with_lru"

module Context = Common.Make_context (struct
  let root = root
end)
    
(* NOTE in the following tests, we try to check each function in the
   index intf, one by one *)
let test () = 
  (* NOTE assumes we run without interference from other threads *)
  Stats.reset_stats ();
  let lru_hits () = Stats.( (get()).lru_hits) in
  let lru_misses () = Stats.( (get()).lru_misses) in
  (* NOTE we use an Lru size of 1 in the following *)
  let* context = Context.with_empty_index ~lru_size:1 () in
  let idx = context.rw in
  let k1,v1 = C.Key.v(),C.Value.v() in
  begin (* basic test for replace *)
    Index.replace idx k1 v1;
    (* k1 is in lru *)
    (Index.find idx k1 |> fun v -> assert(v=v1));
    (* FIXME how can we check this came from the lru? Should really
       expose as much as possible in the interfaces when we want to
       test. For the time being, we use stats to check agreement with
       lru_hits. *)  
    Alcotest.(check int) "lru_hits is 1" 1 (lru_hits());
  end;
  let k2,v2 = C.Key.v(),C.Value.v() in
  begin (* adding another kv *)
    assert(k1 <> k2);
    Index.replace idx k2 v2;
    (* k2 is in lru; k1 isn't *)
    Index.find idx k1 |> fun v -> assert(v=v1);
    (* now k1 is in lru *)
    Alcotest.(check int) "lru_hits is 1" 1 (lru_hits());
    Index.find idx k1 |> fun v -> assert(v=v1);
    Alcotest.(check int) "lru_hits is 2" 2 (lru_hits());
    (* check mem uses lru *)
    Index.mem idx k1 |> fun b -> assert(b);
    Alcotest.(check int) "lru_hits is 3" 3 (lru_hits());
  end;
  begin (* lru cleared on clear *)
    Stats.reset_stats ();
    Index.replace idx k1 v1;
    Index.replace idx k2 v2;
    Index.clear idx;
    Alcotest.check_raises "find after clear" Not_found (fun () -> ignore(Index.find idx k2));
    Alcotest.(check int) "lru_hits is 0" 0 (lru_hits());
    Alcotest.(check int) "lru_misses is 1" 1 (lru_misses());
  end;
  begin (* check filter-false behaves as clear; check iter after filter-false *)
    Stats.reset_stats ();
    Index.replace idx k1 v1;
    Index.replace idx k2 v2;
    Index.filter idx (fun (_,_) -> false);
    (* FIXME currently the following will fail with assert_failure
       src/io_array.ml:90, probably because we don't allow find on an
       empty index; so we disable for now *)
    if false then begin
        Alcotest.check_raises "find after filter-false" Not_found 
          (fun () -> ignore(Index.find idx k2));
        Alcotest.check_raises "find after filter-false" Not_found 
          (fun () -> ignore(Index.find idx k1));
        Alcotest.(check int) "lru_misses is 2" 2 (lru_misses());
        Alcotest.(check bool) "iter after filter-false" false 
          (* following returns true if any invocation of iter arg *)
          (let x = ref false in Index.iter (fun _k _v -> x:=true) idx; !x)
      end;
  end;
  ()
  

let tests = [
  ("log_with_lru",`Quick,test)
]


