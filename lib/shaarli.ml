open Soup (* https://aantron.github.io/lambdasoup/ *)
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let sift_title soup =
  match soup |> select_one "html > body form[name='configform'] input[name='title'][type='text']" with
  | None   -> None
  | Some n -> attribute "value" n

let checkbox_unchecked = "off"
let checkbox_checked   = "checked"

let sift_linkform soup =
  let form_name = "linkform" in
  soup
    (* I want the form fields appear in order, that's why the complexity
     * is in the fold rather than css selectors. *)
    |> select ("html > body form[name='" ^ form_name ^ "'] *[name]")
    |> fold (fun li no -> match attribute "name" no with
      | None        -> li (* cannot happen, see CSS selector *)
      | Some na     -> match name no with
        | "textarea" -> let va = no |> texts |> String.concat " " in
          li |> List.cons (na, va)
        | "input" -> begin match attribute "type" no with
          | Some "checkbox" -> let va = match attribute "checked" no with
            (* https://code.mro.name/mro/ShaarliOS/src/master/swift4/ShaarliOS/HtmlFormParser.swift#L111 *)
            (* obscure: https://html.spec.whatwg.org/multipage/input.html#checkbox-state-(type=checkbox) *)
            | Some "off"
            | None      -> checkbox_unchecked
            | _         -> checkbox_checked
            in li |> List.cons (na, va)
          | Some "hidden"
          | Some "text"   -> let va = match attribute "value" no with
            | None      -> ""
            | Some v    -> v
            in li |> List.cons (na, va)
          | Some "submit"
          | _             -> li
          end
        | _               -> li
    ) []
    |> List.rev

