
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let print_version () =
  let exe = Filename.basename Sys.executable_name in
  Printf.printf "%s: https://mro.name/%s/v%s, built: %s\n" exe "pin4sha" Version.git_sha Version.date;
  0

let print_help () =
  let exe = Filename.basename Sys.executable_name in
  Printf.printf "
If run as a CGI: expose the local shaarli via pinboard.in/api.

If run from commandline: Access a shaarli as if it had the pinboard.in/api.

SYNOPSIS

  $ %s -v

  $ %s -h

  $ %s --doap

  $ %s 'https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/pin4sha.cgi/v1/posts/get?url=http://sebsauvage.net/wiki/doku.php?id=php:shaarli'

" exe exe exe exe;
  0

let err i msgs =
  let exe = Filename.basename Sys.executable_name in
  msgs
    |> List.cons exe
    |> String.concat ": "
    |> prerr_endline;
  i

open Lib.Url

(* May be a candidate for Shaarli.ml *)
let pin_posts_get_url _ u =
  Error ["not implemented yet"; u]

let exec_posts_get ep q =
  match Lib.Pinboard.get_params q (Ok Lib.Pinboard.empty_par) with
  | Error e -> Error e
  | Ok p'   -> match p'.url with
    | None   -> Error ["I need the url parameter"]
    | Some u -> pin_posts_get_url ep u

let exec_url url =
  let url' : Lib.Url.t = url in
  let htap = List.rev url'.path in
  let tl   = List.tl htap in
  match List.hd tl with
  | Dir "/posts" -> 
    begin match List.hd htap with
    | Dir "/get" -> exec_posts_get {url with path = tl |> List.tl |> List.rev ; query = []} url.query
    | Dir verb   -> Error ["unknown verb"; verb]
    end
  | Dir noun     -> Error ["unknown noun"; noun]

let exec args =
  match args |> List.tl with
  | []  -> err 2 ["get help with -h"]
  | arg -> match List.hd arg with
    | "-h"
    | "--help"    -> print_help ()
    | "-v"
    | "--version" -> print_version ()
    | "--doap"    -> Printf.printf "%s" Lib.Res.doap_rdf; 0
    | url         -> match url |> Lib.Url.parse with
      | Error _   -> err 3 ["Couldn't parse url"]
      | Ok url'   -> match url' |> exec_url with
        | Error e -> err 4 e
        | Ok c    -> c

