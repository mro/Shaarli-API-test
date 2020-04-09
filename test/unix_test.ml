
(*
 * have a look at grassroot networking - http on sockets.
 *
 * http://rosettacode.org/wiki/Web_Scraping/OCaml
 *)

let init_socket addr port =
  let inet_addr = (Unix.gethostbyname addr).Unix.h_addr_list.(0) in
  let sockaddr = Unix.ADDR_INET (inet_addr, port) in
  let suck = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.connect suck sockaddr;
  let outchan = Unix.out_channel_of_descr suck in
  let inchan = Unix.in_channel_of_descr suck in
  (inchan, outchan)

let serialize ~post_data =
  String.concat "&"
    (List.map (fun (key, var) -> key ^ "=" ^ var) post_data)

type request = GET | HEAD | POST of (string * string) list

let submit_request ~address ~port ~kind ~path ~referer ~user_agent =
  let req_tag, post_data =
    match kind with
    | GET -> "GET", None
    | HEAD -> "HEAD", None
    | POST data -> "POST", Some data
  in
  let request =
    (Printf.sprintf "%s %s HTTP/1.0\r\n" req_tag path) ^
    (Printf.sprintf "Host: %s\r\n" address) ^
    (match user_agent with None -> "" | Some ua -> Printf.sprintf "User-Agent: %s\r\n" ua) ^
    (match referer with None -> "" | Some referer -> Printf.sprintf "Referer: %s\r\n" referer) ^
    (match post_data with None -> ""
     | Some post_data -> let post_data = serialize ~post_data in
         "Content-type: application/x-www-form-urlencoded\r\n" ^
         "Content-length: "^ string_of_int(String.length post_data) ^"\r\n" ^
         "Connection: close\r\n" ^
         "\r\n" ^
         post_data
    ) ^
    ("\r\n")
  in
  let (inchan, outchan) = init_socket address port in
  output_string outchan request;
  flush outchan;
  (inchan, outchan)

let rec lines acc ic =
  try
    let line = ic |> input_line |> String.trim in
    lines (acc |> List.cons line) ic
  with End_of_file -> acc

let test_http_get () =
  let (inchan, _) = submit_request ~address:"l.mro.name" ~port:80 ~kind:GET ~path:"/" ~referer:None ~user_agent:None in
  let cont = lines [] inchan in
  close_in inchan;
  cont |> List.rev |> String.concat "\n" |> Printf.printf "Response: '%s'\n";
  assert (1 < List.length cont)

let () =
  test_http_get ()

