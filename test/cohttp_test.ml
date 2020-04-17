
(*
 * https://github.com/hammerlab/ketrew/blob/8940d48fbe174709f076b7130974ecd0ed831d58/src/lib/client.ml#L86
 * Cohttp_lwt_unix.Client.call
 *
 * https://github.com/mirage/ocaml-cohttp#client-tutorial
 *)

open Lwt
open Cohttp_lwt_unix
(*
open Cohttp

let body =
  Client.get (Uri.of_string "https://www.reddit.com/") >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  Printf.printf "Body of length: %d\n" (String.length body);
  body

let test_cohttp () =
  let body = Lwt_main.run body in
  assert(555444 < (body |> String.length))
*)

let do_get dst =
  (* let op = fun (_, body) -> body |> Cohttp_lwt.Body.to_string *)
  let op = fun (resp,_) -> resp
    |> Response.status
    |> Cohttp.Code.code_of_status
    |> string_of_int
    |> return
  (* bind an operation returning a Lwt promise.
   * https://ocsigen.org/lwt/5.2.0/manual/manual
   * https://mirage.io/wiki/tutorial-lwt *)
  in Client.get dst >>= op

(* Thank you https://github.com/dkim/rwo-lwt#timeouts-cancellation-and-choices
 *
 * I am not sure if this really is idiomatic, network-friendly timeout handling,
 * (not setting it on the socket SO_RCVTIMEO) - but does the job. Hopefully.
 *)
let timeout_promise timeout promise =
  Lwt.pick [ promise; (Lwt_unix.sleep timeout) >>= (fun () -> "Timeout" |> return) ]

let test_get () =
  let ret = "https://mro.name/pin4sha"
    |> Uri.of_string
    |> do_get
    |> Lwt_main.run
  in assert("302" = ret)

let test_get_timeout () =
  let ret = "https://mro.name/pin4sha"
    |> Uri.of_string
    |> do_get
    |> timeout_promise 0.001
    |> Lwt_main.run
  in assert("Timeout" = ret)

let v1_posts_get_param_url_to_post uri =
  (* https://mirage.github.io/ocaml-uri/uri/Uri/ *)
  match Uri.get_query_param uri "url" with
  | None     -> Error "get param 'url' required"
  | Some url ->
    let u1 = None |> Uri.with_userinfo uri in
    (* be opaque and strip all parameters *)
    let u2 = [("post", url)] |> Uri.with_query' u1 in
    let ret = (u2 |> Uri.path) ^ "/../../../../"
      |> Uri.with_path u2
      |> Uri.canonicalize in
    Ok ret

let test_v1_posts_get_param_url_to_post () =
  match "https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/pin4sha.cgi/v1/posts/get?url=http://sebsauvage.net/wiki/doku.php?id=php:shaarli"
    |> Uri.of_string
    |> v1_posts_get_param_url_to_post
  with
  | Error _ -> assert(false)
  | Ok u    ->
    assert (Some "https" = Uri.scheme u);
    assert (None = Uri.user u);
    assert (None = Uri.password u);
    assert (Some "demo.0x4c.de" = Uri.host u);
    assert (None = Uri.port u);
    assert ("/shaarli-v0.41b/" = Uri.path u);
    assert (Some "http://sebsauvage.net/wiki/doku.php?id=php:shaarli" = Uri.get_query_param u "post");
    assert ("https://demo.0x4c.de/shaarli-v0.41b/?post=http://sebsauvage.net/wiki/doku.php?id=php:shaarli" = Uri.to_string u)

(*
 * Take a complete command uri incl. endpoint and credentials like
 *
 * https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/pin4sha.cgi/v1/posts/get?url=http://sebsauvage.net/wiki/doku.php?id=php:shaarli
 *
 * and return the form data as required for Client.post_form
 *)
let shaarli_get _ =
  Ok [ ("key", "value") ]

(*
 * the main functions for mere posting are
 * - probe credentials without changing state of the server
 * - authenticated get
 * - authenticated add
 *)
let test_get_shaarli () =
  (*
   * https://demo:demodemodemo@demo.0x4c.de/shaarli-v0.41b/pin4sha.cgi/v1/posts/get?url=http://sebsauvage.net/wiki/doku.php?id=php:shaarli
   *
   * https://demo.0x4c.de/shaarli-v0.41b/?post=http%3A%2F%2Fsebsauvage.net%2Fwiki%2Fdoku.php%3Fid%3Dphp%3Ashaarli
   *
   * - GET and follow all redirects until we hit a page with the login_form
   * - fill in uid + pwd
   * - POST it and again follow all redirects until we find the link_form
   * - keep cookie/session and form for following POST
   *
   * see post_form at https://mirage.github.io/ocaml-cohttp/cohttp-mirage/Client/
   * or https://mirage.github.io/ocaml-cohttp/cohttp-lwt-unix/Cohttp_lwt_unix/Client/
   *)
  let ret = "https://demo.0x4c.de/shaarli-v0.41b?post=http%3A%2F%2Fsebsauvage.net%2Fwiki%2Fdoku.php%3Fid%3Dphp%3Ashaarli"
    |> Uri.of_string
    |> do_get
    |> timeout_promise 4.
    |> Lwt_main.run
  in assert("Timeout" <> ret)


let () =
  test_v1_posts_get_param_url_to_post ();
  test_get ();
  test_get_timeout ();
  test_get_shaarli ()

