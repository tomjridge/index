include Mmap_private.Make_2(struct 
    let int_size_is_geq_63 = (Sys.int_size >= 63)
    let mmap_increment_size = 10_000 (* 10k *)
  end)
