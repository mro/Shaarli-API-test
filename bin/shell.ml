
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let print_version () =
  let exe = Filename.basename Sys.executable_name in
  Printf.printf "%s: https://mro.name/%s/v%s, %s\n" exe "pin4sha.cgi" Version.git_sha Version.date;
  0

let print_help () =
  let exe = Filename.basename Sys.executable_name in
  Printf.printf "
If run as a CGI: expose the local shaarli via pinboard.in/api.

If run from commandline: Access a shaarli as if it had the pinboard.in/api.

SYNOPSIS

  $ %s -v

  $ %s -h

  $ %s 'https://uid:pwd@my.shaarli.host/posts/get?dt=2011-09-14'

" exe exe exe;
  0

let err i msgs =
  let exe = Filename.basename Sys.executable_name in
  msgs
    |> List.cons exe
    |> String.concat ": "
    |> prerr_endline;
  i

let run () =
  let status = match Sys.argv |> Array.to_list |> List.tl with
  | []  -> err 2 ["get help with -h"]
  | arg ->
    begin match List.hd arg with
    | "-h"
    | "--help"    -> print_help ()
    | "-v"
    | "--version" -> print_version ()
    | n           -> err 2 ["unknown noun"; n]
    end
  in
  exit status;;

