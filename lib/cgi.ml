
type req_raw = {
  scheme         : string ;
  http_cookie    : string ;
  http_host      : string ;
  path_info      : string ;
  request_method : string ;
  request_uri    : string ;
  query_string   : string ;
  server_name    : string ;
  server_port    : int ;
}

(* https://tools.ietf.org/html/rfc7231#section-6 *)

(* https://github.com/rixed/ocaml-cgi/blob/master/cgi.ml#L169 *)
let getenv_safe ?default s =
  try
    Sys.getenv s
  with Not_found ->
    match default with
    | Some d -> d
    | None   -> failwith ("Cgi: the environment variable " ^ s ^ " is not set")

let request_from_env () =
  try
    let ret = {
      http_cookie    = Sys.getenv "HTTP_COOKIE" ;
      http_host      = Sys.getenv "HTTP_HOST" ;
      path_info      = Sys.getenv "PATH_INFO" ;
      query_string   = Sys.getenv "QUERY_STRING" ;
      request_method = Sys.getenv "REQUEST_METHOD" ;
      request_uri    = Sys.getenv "REQUEST_URI" ;
      scheme         = (match Sys.getenv "HTTPS" with "on" -> "https" | _ -> "http") ;
      server_name    = Sys.getenv "SERVER_NAME" ;
      server_port    = Sys.getenv "SERVER_PORT" |> int_of_string ;
    } in
    Ok ret
  with Not_found ->
    Error "Not Found."

