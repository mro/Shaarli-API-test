
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
  let op = fun (resp,_) -> resp |> Response.status |> Cohttp.Code.code_of_status |> string_of_int |> return
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
  Lwt.pick [
    (Lwt_unix.sleep timeout) >>= (fun () -> "Timeout" |> return);
    promise
  ]

let test_get () =
  let ret = "https://mro.name/pin4sha" |> Uri.of_string |> do_get |> Lwt_main.run in
  assert("302" = ret)

let test_get_timeout () =
  let ret = "https://mro.name/pin4sha" |> Uri.of_string |> do_get |> timeout_promise 0.001 |> Lwt_main.run in
  assert("Timeout" = ret)

let () =
  test_get ();
  test_get_timeout ()

