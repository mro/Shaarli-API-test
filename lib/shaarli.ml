open Soup (* https://aantron.github.io/lambdasoup/ *)
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let comb_title soup =
  match soup |> select_one "html > body form[name='configform'] input[name='title'][type='text']" with 
  | None   -> None
  | Some n -> attribute "value" n

let checkbox_unchecked = "off"
let checkbox_checked   = "checked"

let comb_linkform soup =
  soup
    |> select "html > body form[name='linkform'] input"
    |> fold (fun li no -> match attribute "type" no with
      | Some "submit" -> li
      | Some "checkbox" -> begin match attribute "name" no with
        | None        -> li
        | Some na     -> let va = match attribute "checked" no with
          (* https://code.mro.name/mro/ShaarliOS/src/master/swift4/ShaarliOS/HtmlFormParser.swift#L111 *)
          (* obscure: https://html.spec.whatwg.org/multipage/input.html#checkbox-state-(type=checkbox) *)
          | Some "off"
          | None      -> checkbox_unchecked
          | _         -> checkbox_checked
        in li |> List.cons (na, va)
      end
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

