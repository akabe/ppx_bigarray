(* ppx_bigarray --- A PPX extension for providing big array literals in OCaml

   Copyright (C) 2015 Akinori ABE
   This software is distributed under MIT License
   See LICENSE.txt for details. *)

#if OCAML_VERSION >= (4, 03, 0)
  let nolabel = Asttypes.Nolabel
#else
  let nolabel = ""
#endif
