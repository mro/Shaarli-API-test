open Soup (* https://aantron.github.io/lambdasoup/ *)

(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let () = assert (1 = 1)

let () = assert (1 + 1 = 2)

let test_configure_find_title () =
  let soup = read_file "configure.1.html" |> parse in
  let ti = soup $ "html > head > title" |> R.leaf_text in
  (* ti |> print_endline; *)
  assert (ti = "Shaarli v0.41 🚀")

let () =
  Unix.chdir "../../../test/data/soup_test/";
  test_configure_find_title ()
