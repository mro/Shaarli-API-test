
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

open Lib.Cgi
open Lib.Url

let url_from_req req' =
  let req : Cgi.req_raw = req' in
  from_parts req.scheme req.server_name req.server_port req.path_info req.query_string

let print_request req' = 
  let req : Cgi.req_raw = req' in
  let cwd = Sys.getcwd () in
  Printf.printf "Status: %d\n" 202 ;
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
  Printf.printf "<li>%s: %d</li>\n" "SERVER_PORT"     req.server_port ;
  w "</ul>
</body>
</html>";
  0

let handle req = 
  if false
  then dump_headers_all ()
  else print_request req

