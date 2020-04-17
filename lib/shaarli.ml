open Soup (* https://aantron.github.io/lambdasoup/ *)
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let comb_title soup =
  match soup |> select_one "html > body form[name='configform'] input[name='title'][type='text']" with 
  | None   -> None
  | Some n -> attribute "value" n

let comb_linkform soup =
  soup
    |> select "html > body form[name='linkform'] input"
    |> fold (fun li no -> match attribute "type" no with
      | Some "submit" -> li
      | Some "hidden" 
      | Some "text"   -> begin match attribute "name" no with
        | None        -> li
        | Some na     -> let va = match attribute "value" no with
          | None      -> ""
          | Some v    -> v
        in li |> List.cons (na, va)
      end
      | _             -> li
    ) []
    |> List.rev

