ppx_bigarray
============

[![Build Status](https://travis-ci.org/akabe/ppx_bigarray.svg?branch=master)](https://travis-ci.org/akabe/ppx_bigarray)

This PPX extension provides
[big array](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.html)
literals in [OCaml](http://ocaml.org).

Install
-------

```
opam install ppx_bigarray
```

or

```
./configure
make
make install
```

Usage
-----

### Compile

```
ocamlfind ocamlc -package ppx_bigarray -linkpkg foo.ml
```

`ppx_bigarray` outputs code that depends on `Ppx_bigarray` module, so that
you need to link it in addition to option `-ppx`. `ocamlfind`
is useful for passing suitable compiler options.

### Example

`x` is a two-dimensional big array that has size 3-by-4, kind `Bigarray.int`,
and layout `Bigarray.c_layout`.

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23; 24];
            [31; 32; 33; 34];
          ]
        ] in
print_int x.{1,2} (* print "23" *)
```

In this code, elements of a big array are given as a list of lists, but
you can use an array of arrays:

```OCaml
let x = [%bigarray2.int.c
          [|
            [|11; 12; 13; 14|];
            [|21; 22; 23; 24|];
            [|31; 32; 33; 34|];
          |]
        ] in
print_int x.{1,2} (* print "23" *)
```

`[%bigarray2.int.c ELEMENTS]` is a syntax of big array literals. `ELEMENTS`
must have a syntax of a list literal (`[...]`) or an array literal (`[|...|]`).
You cannot give an expression that returns a list or an array (such as
`let x = [...] in [%bigarray2.int.c x]`) since `[%bigarray2.int.c ...]` is NOT
the function that converts a list or an array into a big array.

### Basic syntax

- `[%bigarray1.KIND.LAYOUT ELEMENTS]` is a one-dimensional big array
  (that has type `Bigarray.Array1.t`). `ELEMENTS` is a list or an array.
- `[%bigarray2.KIND.LAYOUT ELEMENTS]` is a two-dimensional big array
  (that has type `Bigarray.Array2.t`). `ELEMENTS` is a list of lists or
  an array of arrays.
- `[%bigarray3.KIND.LAYOUT ELEMENTS]` is a three-dimensional big array
  (that has type `Bigarray.Array3.t`). `ELEMENTS` is a list of lists of lists or
  an array of arrays of arrays.
- `[%bigarray.KIND.LAYOUT ELEMENTS]` is a multi-dimensional big array
  (that has type `Bigarray.Genarray.t`). `ELEMENTS` is a nested list or
  a nested array.

You can specify the following identifiers as `KIND` and `LAYOUT`:

| `KIND`                       | Corresponding big array kind                            |
|------------------------------|---------------------------------------------------------|
| `int8_signed` or `sint8`     | `Bigarray.int8_signed`                                  |
| `int8_unsigned` or `uint8`   | `Bigarray.int8_unsigned`                                |
| `int16_signed` or `sint16`   | `Bigarray.int16_signed`                                 |
| `int16_unsigned` or `uint16` | `Bigarray.int16_unsigned`                               |
| `int32`                      | `Bigarray.int32`                                        |
| `int64`                      | `Bigarray.int64`                                        |
| `int`                        | `Bigarray.int`                                          |
| `nativeint`                  | `Bigarray.nativeint`                                    |
| `float32`                    | `Bigarray.float32`                                      |
| `float64`                    | `Bigarray.float64`                                      |
| `complex32`                  | `Bigarray.complex32`                                    |
| `complex64`                  | `Bigarray.complex64`                                    |
| `char`                       | `Bigarray.char`                                         |
| otherwise                    | (to refer the variable that has a given name as a kind) |

| `LAYOUT`                      | Corresponding big array layout                            |
|-------------------------------|-----------------------------------------------------------|
| `c` or `c_layout`             | `Bigarray.c_layout`                                       |
| `fortran` or `fortran_layout` | `Bigarray.fortran_layout`                                 |
| otherwise                     | (to refer the variable that has a given name as a layout) |

### Padding

By default, `ppx_bigarray` warns non-rectangular big array literals in compile time,
and lacked elements are uninitialized.
While, you can inhibit the warning by using `[@bigarray.padding EXPRESSION]`:

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23];
            [31; 32];
          ] [@bigarray.padding 0]
        ]
```

In this case, lacked elements are initialized by `0`.
