
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

let run () =
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
  va Cgi.http_request_method;
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

