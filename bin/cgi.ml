
open Lib

let w s =
  print_string s;
  print_string "\n"

let va n =
  print_string "<li>";
  print_string n;
  print_string ": ";
  let v = Cgi.getenv_safe ~default:"-" n in
    (* TODO: escape *)
    print_string v;
  print_string "</li>";
  print_string "\n"

let dump_headers_all () =
  w "HTTP/1.1 200 Ok";
  w "Content-type: text/html; charset=utf-8";
  w "";
  w "<html>
<head><title>Hello, Worλd</title></head>
<body>
<h1>OCaml, where art thou 🐫!</h1>
<p>";
  let cwd = Sys.getcwd () in
    w cwd;
  w "</p>
<ul>";
  va "HOME";
  va "HTTPS";
  va "HTTP_HOST";
  va "HTTP_COOKIE";
  va "HTTP_ACCEPT";
  va "REMOTE_ADDR";
  va "REMOTE_USER";
  va "REQUEST_METHOD" ;
  va "REQUEST_URI";
  va "PATH_INFO";
  va "QUERY_STRING";
  va "SERVER_NAME";
  va "SERVER_PORT";
  va "SERVER_SOFTWARE";
  w "</ul>
</body>
</html>";
  0

let camel = "🐫"

open Lib.Cgi

let redirect url =
  Printf.printf "HTTP/1.1 %d %s\n" 302 "Found";
  Printf.printf "Location: %s\n" url ;
  Printf.printf "\n" ;
  0

let error status reason =
  Printf.printf "HTTP/1.1 %d %s\n" status reason;
  Printf.printf "Content-type: text/plain; charset=utf-8\n" ;
  Printf.printf "\n" ;
  Printf.printf "%s %s.\n" camel reason ;
  0


let print_request req' =
  let req : Cgi.req_raw = req' in
  let cwd = Sys.getcwd () in
  Printf.printf "HTTP/1.1 %d %s\n" 202 "Accepted";
  w "Content-type: text/html; charset=utf-8" ;
  w "" ;
  w "<html>
<head><title>Hello, Worλd</title></head>
<body>
<h1>OCaml, where art thou 🐫!</h1>
<p>" ;
  w cwd ;
  w "</p>
<ul>";
  Printf.printf "<li>%s: %s</li>\n" "HTTPS"           req.scheme ;
  Printf.printf "<li>%s: %s</li>\n" "HTTP_COOKIE"     req.http_cookie ;
  Printf.printf "<li>%s: %s</li>\n" "HTTP_HOST"       req.http_host ;
  Printf.printf "<li>%s: %s</li>\n" "PATH_INFO"       req.path_info ;
  Printf.printf "<li>%s: %s</li>\n" "QUERY_STRING"    req.query_string ;
  Printf.printf "<li>%s: %s</li>\n" "REQUEST_METHOD"  req.request_method ;
  Printf.printf "<li>%s: %s</li>\n" "REQUEST_URI"     req.request_uri ;
  Printf.printf "<li>%s: %s</li>\n" "SERVER_NAME"     req.server_name ;
  Printf.printf "<li>%s: %s</li>\n" "SERVER_PORT"     req.server_port ;
  let parts = String.split_on_char '?' req.request_uri in
  let endp = [ req.scheme; "://"; req.server_name; ":"; req.server_port; List.hd parts; "/../../../../"; "index.php" ] |> String.concat "" in
  (* we need the authentication info either from the query string (auth_token) or preauthenticated basic auth. *)
  Printf.printf "<li>shaarli: %s</li>\n" endp ;
  w "</ul>
</body>
</html>";
  0


let handle req =
  if "GET" <> req.request_method
  then error 405 "Method Not Allowed"
  else match req.path_info with
    | ""                    -> [req.request_uri; "about"] |> String.concat "/" |> redirect
    | "/"                   -> [req.request_uri; "about"] |> String.concat "/" |> redirect
    | "/about"              -> print_request req (* doap *)
    | "/v1/openapi.yaml"    -> print_request req
    | "/v1/user/api_token"  -> error 501 "Not Implemented"
    | "/v1/posts/get"       -> print_request req
    | "/v1/posts/add"       -> error 501 "Not Implemented"
    | "/dump"               -> dump_headers_all ()
    | _                     -> error 404 "Not Found"

