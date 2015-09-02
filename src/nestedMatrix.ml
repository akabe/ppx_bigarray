(* ppx_bigarray --- A PPX extension for providing big array literals in OCaml

   Copyright (C) 2015 Akinori ABE
   This software is distributed under MIT License
   See LICENSE.txt for details. *)

module List =
struct
  include List

  let init n f =
    let rec aux acc i = if i < 0 then acc else aux (f i :: acc) (i - 1) in
    aux [] (n - 1)

  let make n x = init n (fun _ -> x)

  let take n l =
    let rec aux acc n l = match n, l with
      | 0, _ -> List.rev acc
      | _, hd :: tl -> aux (hd :: acc) (n - 1) tl
      | _ -> failwith "List.take"
    in
    aux [] n l
end

type ('a, 'b) t =
  | Leaf of 'a * 'b
  | Node of 'a * ('a, 'b) t list

let merge_sizes xs ys =
  let rec aux acc xs ys = match xs, ys with
    | [], [] -> List.rev acc
    | x :: xs', y :: ys' -> aux (max x y :: acc) xs' ys'
    | [], x :: xs' | x :: xs', [] -> aux (x :: acc) [] xs'
  in
  aux [] xs ys

let rec size = function
  | Leaf _ -> []
  | Node (_, children) ->
    children
    |> List.map size
    |> List.fold_left merge_sizes []
    |> (fun xs -> List.length children :: xs)

let check_rect size root =
  let rec aux size errors node = match size, node with
    | [], Leaf _ -> errors
    | n :: _, Leaf _ -> (n, node) :: errors
    | [], Node _ -> (-1, node) :: errors
    | m :: size', Node (_, children) ->
      let errors' = List.fold_left (aux size') errors children in
      let n = List.length children in
      if m = n then errors' else (m, node) :: errors'
  in
  aux size [] root

let string_of_size size =
  size
  |> List.map string_of_int
  |> String.concat "x"

let make_padding x y =
  let rec aux = function
    | [] -> Leaf (x, y)
    | n :: size -> Node (x, List.init n (fun _ -> aux size))
  in
  aux

let pad size root x y =
  let rec aux size node = match size, node with
    | m :: size', Node (z, children) ->
      let children' = List.map (aux size') children in
      let n = List.length children in
      if m = n then Node (z, children')
      else if m < n then Node (z, List.take m children')
      else Node (z, children' @ List.make (m - n) (make_padding x y size'))
    | _ -> node
  in
  aux size root

(** {2 Conversion from OCaml expressions} *)

open Asttypes
open Parsetree
open Longident

(** [get_elements expr] obtains a list of elements of a big array literal from
    expression [expr]. If [expr] is NOT a list, an array or a tuple, [None] is
    returned. *)
let get_elements =
  let rec from_list acc = function
    | { pexp_desc = Pexp_construct ({ txt = Lident "[]"; _ }, None); _ } ->
      Some (List.rev acc)
    | { pexp_desc = Pexp_construct
            ({ txt = Lident "::"; _ },
             Some ({ pexp_desc = Pexp_tuple ([hd; tl]); _ })); _ } ->
      from_list (hd :: acc) tl
    | _ -> None
  in
  function
  | { pexp_desc = Pexp_array exprs; _ } -> Some exprs
  | expr -> from_list [] expr

let rec of_expression expr = match get_elements expr with
  | None -> Leaf (expr.pexp_loc, expr)
  | Some exprs -> Node (expr.pexp_loc, List.map of_expression exprs)

(** {2 Conversion into OCaml expressions} *)

open Ast_helper

type bigarray_type =
  | Array1
  | Array2
  | Array3
  | Genarray

type bigarray_kind =
  | Float32
  | Float64
  | Int8_signed
  | Int8_unsigned
  | Int16_signed
  | Int16_unsigned
  | Int32
  | Int64
  | Int
  | Nativeint
  | Complex32
  | Complex64
  | Char
  | Dynamic of string

let string_of_bigarray_kind = function
  | Float32 -> "Bigarray.float32"
  | Float64 -> "Bigarray.float64"
  | Int8_signed -> "Bigarray.int8_signed"
  | Int8_unsigned -> "Bigarray.int8_unsigned"
  | Int16_signed -> "Bigarray.int16_signed"
  | Int16_unsigned -> "Bigarray.int16_unsigned"
  | Int32 -> "Bigarray.int32"
  | Int64 -> "Bigarray.int64"
  | Int -> "Bigarray.int"
  | Nativeint -> "Bigarray.nativeint"
  | Complex32 -> "Bigarray.complex32"
  | Complex64 -> "Bigarray.complex64"
  | Char -> "Bigarray.char"
  | Dynamic s -> s

type bigarray_layout =
  | C_layout
  | Fortran_layout

let string_of_bigarray_layout = function
  | C_layout -> "Bigarray.c_layout"
  | Fortran_layout -> "Bigarray.fortran_layout"

module Exp =
struct
  include Ast_helper.Exp

  let int ?loc ?attrs n = constant ?loc ?attrs (Const_int n)

  let ident ?(loc = !Ast_helper.default_loc) ?attrs str =
    ident ~loc ?attrs { Location.loc; Location.txt = Longident.parse str; }

  let letval ?(loc = !Ast_helper.default_loc) ?attrs str rhs body =
    let pat = Pat.var ~loc { Location.txt = str; Location.loc; } in
    let_ ~loc ?attrs Nonrecursive [Vb.mk ~loc pat rhs] body

  (** Create expressions related to big arrays *)
  module Ba =
  struct
    let array1_create ?loc ?attrs kind layout dim =
      let kind = ident ?loc (string_of_bigarray_kind kind) in
      let layout = ident ?loc (string_of_bigarray_layout layout) in
      let dim = int ?loc dim in
      let f = ident ?loc "Bigarray.Array1.create" in
      apply ?loc ?attrs f [(Compat.nolabel, kind); (Compat.nolabel, layout);
                           (Compat.nolabel, dim)]

    let array1_set ?loc ?attrs ba index rhs =
      let index = int ?loc index in
      let f = ident ?loc "Bigarray.Array1.unsafe_set" in
      apply ?loc ?attrs f [(Compat.nolabel, ba); (Compat.nolabel, index);
                           (Compat.nolabel, rhs)]

    let array1_set_all ?loc ?attrs ~ret ba vals =
      vals
      |> List.rev
      |> List.map (fun (i, rhs) -> array1_set ~loc:rhs.pexp_loc ba i rhs)
      |> List.fold_left (fun acc expr -> sequence ?loc ?attrs expr acc) ret

    let genarray_of_array1 ?loc ?attrs ba =
      let f = ident ?loc "Bigarray.genarray_of_array1" in
      apply ?loc ?attrs f [(Compat.nolabel, ba)]

    let reshape_1 ?loc ?attrs ba size =
      let n = match size with
        | [] -> 0
        | [n] -> n
        | _ -> Error.exnf ?loc
                 "Error: @[This literal expects 1-dimensional big array@\n\
                  but the size is %s@." (string_of_size size) () in
      let f = ident ?loc "Bigarray.reshape_1" in
      apply ?loc ?attrs f [(Compat.nolabel, ba); (Compat.nolabel, int ?loc n)]

    let reshape_2 ?loc ?attrs ba size =
      let (m, n) = match size with
        | [] -> (0, 0)
        | [m] -> (m, 0)
        | [m; n] -> (m, n)
        | _ -> Error.exnf ?loc
                 "Error: @[This literal expects 2-dimensional big array@\n\
                  but the size is %s@." (string_of_size size) () in
      let f = ident ?loc "Bigarray.reshape_2" in
      apply ?loc ?attrs f [(Compat.nolabel, ba); (Compat.nolabel, int ?loc m);
                           (Compat.nolabel, int ?loc n)]

    let reshape_3 ?loc ?attrs ba size =
      let (m, n, k) = match size with
        | [] -> (0, 0, 0)
        | [m] -> (m, 0, 0)
        | [m; n] -> (m, n, 0)
        | [m; n; k] -> (m, n, k)
        | _ -> Error.exnf ?loc
                 "Error: @[This literal expects 3-dimensional big array@\n\
                  but the size is %s@." (string_of_size size) () in
      let f = ident ?loc "Bigarray.reshape_3" in
      apply ?loc ?attrs f [(Compat.nolabel, ba); (Compat.nolabel, int ?loc m);
                           (Compat.nolabel, int ?loc n);
                           (Compat.nolabel, int ?loc k)]

    let reshape ?loc ?attrs ba size =
      let f = ident ?loc "Bigarray.reshape" in
      let dims = array ?loc (List.map (int ?loc ?attrs:None) size) in
      apply ?loc ?attrs f [(Compat.nolabel, ba); (Compat.nolabel, dims)]
  end
end

let calc_c_index size indices =
  List.fold_left2 (fun acc n i -> n * acc + i) 0 size indices

let calc_fortran_index size indices =
  List.fold_right2 (fun n i acc -> n * acc + i) size indices 0 + 1

let serialize layout size root =
  let calc_index = match layout with
    | C_layout -> calc_c_index size
    | Fortran_layout -> calc_fortran_index size
  in
  let rec aux indices node = match node with
    | Leaf (_, expr) -> [(calc_index (List.rev indices), expr)]
    | Node (_, children) ->
      List.mapi (fun i -> aux (i :: indices)) children
      |> List.flatten
  in
  aux [] root

let to_expression ?(loc = !default_loc) ?attrs ba_type kind layout size mat =
  let name = "$ppx_ba" in
  let var = Exp.ident ~loc name in
  let dim = List.fold_left ( * ) 1 size in
  let arr1 = Exp.Ba.array1_create ~loc kind layout dim in
  let genarr = Exp.Ba.genarray_of_array1 ~loc var in
  let retarr = match ba_type with
    | Array1 -> Exp.Ba.reshape_1 ~loc genarr size
    | Array2 -> Exp.Ba.reshape_2 ~loc genarr size
    | Array3 -> Exp.Ba.reshape_3 ~loc genarr size
    | Genarray -> Exp.Ba.reshape ~loc genarr size in
  mat
  |> serialize layout size
  |> Exp.Ba.array1_set_all ~loc ~ret:retarr var
  |> Exp.letval ~loc ?attrs name arr1
