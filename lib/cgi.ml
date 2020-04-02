
let http_request_method = "REQUEST_METHOD"

(* https://github.com/rixed/ocaml-cgi/blob/master/cgi.ml#L169 *)
let getenv_safe ?default s =
  try
    Sys.getenv s
  with Not_found ->
    match default with
    | Some d -> d
    | None   -> failwith ("Cgi: the environment variable " ^ s ^ " is not set")

