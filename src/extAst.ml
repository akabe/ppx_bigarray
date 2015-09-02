(* ppx_bigarray --- A PPX extension for providing big array literals in OCaml

   Copyright (C) 2015 Akinori ABE
   This software is distributed under MIT License
   See LICENSE.txt for details. *)

open Ast_helper
open Asttypes
open Parsetree
open Longident

let lid ?(loc = !default_loc) str =
  { Location.loc; Location.txt = Longident.parse str; }

module Exp =
struct
  include Ast_helper.Exp

  let int ?loc ?attrs n = constant ?loc ?attrs (Const_int n)

  let ident ?loc ?attrs str = ident ?loc ?attrs (lid ?loc str)

  let field ?loc ?attrs expr str = field ?loc ?attrs expr (lid ?loc str)

  let letval ?(loc = !Ast_helper.default_loc) ?attrs str rhs body =
    let pat = Pat.var ~loc { Location.txt = str; Location.loc; } in
    let_ ~loc ?attrs Nonrecursive [Vb.mk ~loc pat rhs] body
end
