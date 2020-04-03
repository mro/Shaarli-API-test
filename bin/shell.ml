
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

open Lib.Url

let exec_posts_get_url _ u =
  Error ["not implemented yet"; u]

let exec_posts_get ep q =
  let p = Lib.Pinboard.get_params q (Ok Lib.Pinboard.empty_par) in
  match p with
  | Error e -> Error e
  | Ok p'   -> match p'.url with
    | None   -> Error ["I need the url parameter"]
    | Some u -> exec_posts_get_url ep u

let exec_posts url verb' =
  match verb' with
  | Dir "/get" -> exec_posts_get url url.query
  | Dir verb   -> Error ["unknown verb"; verb]

let exec_url url =
  let url' : Lib.Url.t = url in
  let htap = List.rev url'.path in
  let verb'= List.hd htap
  and noun'= List.hd (List.tl htap) in
  match noun' with
  | Dir "/posts" -> exec_posts url verb'
  | Dir noun     -> Error ["unknown noun"; noun]

let exec_str str =
  match Lib.Url.parse str with
  | Ok url  -> exec_url url
  | Error _ -> Error ["aua"]

let run () =
  let status = match Sys.argv |> Array.to_list |> List.tl with
  | []  -> err 2 ["get help with -h"]
  | arg ->
    begin match List.hd arg with
    | "-h"
    | "--help"    -> print_help ()
    | "-v"
    | "--version" -> print_version ()
    | url         -> match exec_str url with
      | Ok ret    -> ret
      | Error e   -> err 2 e
    end
  in
  exit status;;

