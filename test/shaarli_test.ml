open Soup (* https://aantron.github.io/lambdasoup/ *)
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let comb_title soup =
  match soup |> select_one "html > body form[name='configform'] input[name='title'][type='text']" with 
  | None   -> None
  | Some n -> attribute "value" n

let test_comb_title () = 
  let fo = read_file "configure.1.html" |> parse |> comb_title in
  assert(Some "Shaarli v0.41 🚀" = fo)

let () = 
  Unix.chdir "../../../test/data/shaarli_test/";
  test_comb_title ()

