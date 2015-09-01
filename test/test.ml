open OUnit
open Bigarray

let test_array1_int_c () =
  let mk arr = Array1.of_array int c_layout arr in
  "0" @? (mk [||] = [%bigarray1.int.c [||]]);
  "1" @? (mk [|42|] = [%bigarray1.int.c [|42|]]);
  "3" @? (mk [|11; 12; 13|] = [%bigarray1.int.c [|11; 12; 13|] ])

let test_array1_int_fortran () =
  let mk arr = Array1.of_array int fortran_layout arr in
  "0" @? (mk [||] = [%bigarray1.int.fortran [||]]);
  "1" @? (mk [|42|] = [%bigarray1.int.fortran [|42|]]);
  "3" @? (mk [|11; 12; 13|] = [%bigarray1.int.fortran [|11; 12; 13|] ])

let test_array2_int_c () =
  let mk arr = Array2.of_array int c_layout arr in
  "1x1" @? (mk [|[|42|]|] = [%bigarray2.int.c [|[|42|]|]]);
  "0x0" @? (mk [||] = [%bigarray2.int.c [||]]);
  "2x0" @? (mk [|[||]; [||]|] = [%bigarray2.int.c [|[||]; [||]|]]);
  "2x3" @? (mk [|[|11; 12; 13|]; [|21; 22; 23|]|]
            = [%bigarray2.int.c [|[|11; 12; 13|]; [|21; 22; 23|]|] ])

let test_array2_int_fortran () =
  let mk arr = Array2.of_array int fortran_layout arr in
  "1x1" @? (mk [|[|42|]|] = [%bigarray2.int.fortran [|[|42|]|]]);
  "0x0" @? (mk [||] = [%bigarray2.int.fortran [||]]);
  "2x0" @? (mk [|[||]; [||]|] = [%bigarray2.int.fortran [|[||]; [||]|]]);
  "2x3" @? (mk [|[|11; 12; 13|]; [|21; 22; 23|]|]
            = [%bigarray2.int.fortran [|[|11; 12; 13|]; [|21; 22; 23|]|] ])

let test_array3_int_c () =
  let mk arr = Array3.of_array int c_layout arr in
  "1x1x1" @? (mk [|[|[|42|]|]|] = [%bigarray3.int.c [|[|[|42|]|]|]]);
  "0x0x0" @? (mk [||] = [%bigarray3.int.c [||]]);
  "2x0x0" @? (mk [|[||]; [||]|] = [%bigarray3.int.c [|[||]; [||]|]]);
  "2x3x0" @?
  (mk [|[|[||]; [||]; [||]|]; [|[||]; [||]; [||]|]|]
   = [%bigarray3.int.c [|[|[||]; [||]; [||]|]; [|[||]; [||]; [||]|]|] ]);
  "2x3x3" @?
  (mk [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 132; 133|]|];
        [|[|211; 212; 213|]; [|221; 222; 223|]; [|231; 232; 233|]|]|]
   = [%bigarray3.int.c
     [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 132; 133|]|];
       [|[|211; 212; 213|]; [|221; 222; 223|]; [|231; 232; 233|]|]|] ])

let test_array3_int_fortran () =
  let mk arr = Array3.of_array int fortran_layout arr in
  "1x1x1" @? (mk [|[|[|42|]|]|] = [%bigarray3.int.fortran [|[|[|42|]|]|]]);
  "0x0x0" @? (mk [||] = [%bigarray3.int.fortran [||]]);
  "2x0x0" @? (mk [|[||]; [||]|] = [%bigarray3.int.fortran [|[||]; [||]|]]);
  "2x3x0" @?
  (mk [|[|[||]; [||]; [||]|]; [|[||]; [||]; [||]|]|]
   = [%bigarray3.int.fortran [|[|[||]; [||]; [||]|]; [|[||]; [||]; [||]|]|] ]);
  "2x3x3" @?
  (mk [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 132; 133|]|];
        [|[|211; 212; 213|]; [|221; 222; 223|]; [|231; 232; 233|]|]|]
   = [%bigarray3.int.fortran
     [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 132; 133|]|];
       [|[|211; 212; 213|]; [|221; 222; 223|]; [|231; 232; 233|]|]|] ])

let test_padding_c () =
  let mk arr = Array3.of_array int c_layout arr in
  "2x3x3" @?
  (mk [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 0; 0|]|];
        [|[|211; 212; 213|]; [|221; 222;   0|]; [|  0; 0; 0|]|]|]
   = [%bigarray3.int.c
     [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131;         |]|];
       [|[|211; 212; 213|]; [|221; 222;    |];                |]|]
       [@bigarray.padding 0] ])
let test_padding_fortran () =
  let mk arr = Array3.of_array int fortran_layout arr in
  "2x3x3" @?
  (mk [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131; 0; 0|]|];
        [|[|211; 212; 213|]; [|221; 222;   0|]; [|  0; 0; 0|]|]|]
   = [%bigarray3.int.fortran
     [|[|[|111; 112; 113|]; [|121; 122; 123|]; [|131;         |]|];
       [|[|211; 212; 213|]; [|221; 222;    |];                |]|]
       [@bigarray.padding 0] ])

let suite =
  "ppx_bigarray" >::: [
    "array1,kind=int,layout=C" >:: test_array1_int_c;
    "array1,kind=int,layout=Fortran" >:: test_array1_int_fortran;
    "array2,kind=int,layout=C" >:: test_array2_int_c;
    "array2,kind=int,layout=Fortran" >:: test_array2_int_fortran;
    "array3,kind=int,layout=C" >:: test_array3_int_c;
    "array3,kind=int,layout=Fortran" >:: test_array3_int_fortran;
    "padding,layout=C" >:: test_padding_c;
    "padding,layout=Fortran" >:: test_padding_fortran;
  ]

let () = run_test_tt_main suite |> ignore
(*
let f : type c. (int, _, c) Bigarray.Genarray.t -> unit
  = fun x -> match Bigarray.Genarray.layout x with
  | Bigarray.C_layout ->
    Format.printf "C_layout:@.";
    for i = 0 to 1 do
      for j = 0 to 2 do
        for k = 0 to 2 do
          Format.printf "  x.{%d,%d,%d} = %d@." i j k
            (Bigarray.Genarray.get x [|i;j;k|])
        done
      done
    done
  | Bigarray.Fortran_layout ->
    Format.printf "Fortran_layout:@.";
    for i = 1 to 2 do
      for j = 1 to 3 do
        for k = 1 to 3 do
          Format.printf "x.{%d,%d,%d} = %d@." i j k
            (Bigarray.Genarray.get x [|i;j;k|])
        done
      done
    done

let () = f x
*)
