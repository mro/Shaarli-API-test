let camel = "🐫"

open Lib
open Lib.Cgi

let w s =
  print_string s;
  print_string "\n"

let print_request req' =
  let req : Cgi.req_raw = req' in
  let cwd = Sys.getcwd () in
  Printf.printf "HTTP/1.1 %d %s\n" 202 "Accepted";
  w "Content-type: text/html; charset=utf-8";
  w "";
  w
    "<html>\n\
     <head><title>Hello, Worλd</title></head>\n\
     <body>\n\
     <h1>OCaml, where art thou 🐫!</h1>\n\
     <p>";
  w cwd;
  w "</p>\n<ul>";
  Printf.printf "<li>%s: %s</li>\n" "HTTPS" req.scheme;
  Printf.printf "<li>%s: %s</li>\n" "HTTP_COOKIE" req.http_cookie;
  Printf.printf "<li>%s: %s</li>\n" "HTTP_HOST" req.host;
  Printf.printf "<li>%s: %s</li>\n" "PATH_INFO" req.path_info;
  Printf.printf "<li>%s: %s</li>\n" "QUERY_STRING" req.query_string;
  Printf.printf "<li>%s: %s</li>\n" "REQUEST_METHOD" req.request_method;
  Printf.printf "<li>%s: %s</li>\n" "REQUEST_URI" req.request_uri;
  Printf.printf "<li>%s: %s</li>\n" "SERVER_PORT" req.server_port;
  let parts = String.split_on_char '?' req.request_uri in
  let endp =
    [
      req.scheme;
      "://";
      req.host;
      ":";
      req.server_port;
      List.hd parts;
      "/../../../../";
      "index.php";
    ]
    |> String.concat ""
  in
  (* we need the authentication info either from the query string (auth_token) or preauthenticated basic auth. *)
  Printf.printf "<li>shaarli: %s</li>\n" endp;
  w "</ul>\n</body>\n</html>";
  0

let handle req =
  if "GET" <> req.request_method then error 405 "Method Not Allowed"
  else
    match req.path_info with
    | "" -> [ req.request_uri; "/"; "about" ] |> String.concat "" |> redirect
    | "/" -> [ req.request_uri; "about" ] |> String.concat "" |> redirect
    | "/about" -> dump_clob "text/xml" Res.doap_rdf
    | "/doap2html.xslt" -> dump_clob "text/xml" Res.doap2html_xslt
    | "/LICENSE" -> dump_clob "text/plain; charset=utf-8" Res._LICENSE
    | "/README.md" -> dump_clob "text/plain; charset=utf-8" Res._README_md
    | "/v1" -> "about" |> redirect
    | "/v1/openapi.yaml" ->
        dump_clob "application/vnd.oai.openapi;version=3.0.1"
          Res.V1.openapi_yaml
    | "/v1/user/api_token" -> error 501 "Not Implemented"
    | "/v1/posts/add" -> error 501 "Not Implemented"
    | "/v1/posts/get" -> print_request req
    | _ -> error 404 "Not Found"
