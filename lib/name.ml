(*
 * What is in a name?
 *
 * /some/dir/2019-12-31-173519-MyFooBar_--_sometag_anothertag.a.b.gz
 * |--dirs--||---datetime----| |title-|    |-tag-| |--tag---||exts-|
 *
 * dirs     ^([^/]*/)*
 * datetime ((\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})-)?
 * title    (.*?)
 * tags     (_--(_[^_.]+)* )?
 * ext      (\.[^.]* )*$
 *)

type dir = Dir of string

type title = Title of string

type tag = Tag of string

type ext = Ext of string

(* A tuple would suffice because everything is semantically strict typed. *)
type parsed_name = {
  dirs : dir list;
  datetime : Datetime.t option;
  title : title;
  tags : tag list;
  exts : ext list;
}

(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

module P = struct
  open Tyre

  let dir' =
    let to_ s = Dir s and of_ (Dir o) = o in
    conv to_ of_ (pcre "[^/]*/")

  let dirs' = list dir'

  let datetime =
    let to_ (((((dy, dm), dd), th), tm), ts) =
      Datetime.create (int_of_string dy) (int_of_string dm) (int_of_string dd)
        (int_of_string th) (int_of_string tm) (int_of_string ts)
    and of_ ((dy, dm, dd), (th, tm, ts)) =
      let dy' = match dy with Datetime.Year x -> string_of_int x
      and dm' = match dm with Datetime.Month x -> string_of_int x
      and dd' = match dd with Datetime.Day x -> string_of_int x
      and th' = match th with Datetime.Hour x -> string_of_int x
      and tm' = match tm with Datetime.Minute x -> string_of_int x
      and ts' = match ts with Datetime.Second x -> string_of_int x in
      (((((dy', dm'), dd'), th'), tm'), ts')
    in
    conv to_ of_
      ( pcre "[0-9]{4}" <* char '-'
      <&> pcre "01|02|03|04|05|06|07|08|09|10|11|12"
      <* char '-' <&> pcre "[0-3][0-9]" <* char '-' <&> pcre "[0-2][0-9]"
      <&> pcre "[0-5][0-9]" <&> pcre "[0-5][0-9]" )

  (* brings the trailing - *)
  let string_of_datetime ((dy, dm, dd), (th, tm, ts)) =
    let dy' = match dy with Datetime.Year x -> x
    and dm' = match dm with Datetime.Month x -> x
    and dd' = match dd with Datetime.Day x -> x
    and th' = match th with Datetime.Hour x -> x
    and tm' = match tm with Datetime.Minute x -> x
    and ts' = match ts with Datetime.Second x -> x in
    Format.sprintf "%04d-%02d-%02d-%02d%02d%02d-" dy' dm' dd' th' tm' ts'

  let tit' =
    let to_ s = Title s and of_ (Title o) = o in
    conv to_ of_ (pcre "[^/]*?")

  let tag' =
    let to_ s = Tag s and of_ (Tag o) = o in
    conv to_ of_ (pcre "[^_.]+")

  let sep' = "_"

  let sep = "_--"

  let tags' = str sep *> list (str sep' *> tag')

  let ext' =
    let to_ s = Ext s and of_ (Ext o) = o in
    conv to_ of_ (pcre "[.][^.]*")

  let exts' = list ext'

  (* https://gabriel.radanne.net/papers/tyre/tyre_paper.pdf#page=9 *)
  let full =
    let to_ (dirs, (datetime, ((title, ta), exts))) =
      let tags = match ta with None -> [] | Some t -> t in
      { dirs; datetime; title; tags; exts }
    and of_ { dirs; datetime; title; tags; exts } =
      let ta = match tags with [] -> None | t -> Some t in
      (dirs, (datetime, ((title, ta), exts)))
    in
    conv to_ of_
      ( dirs'
      <&> (opt (datetime <* char '-') <&> (tit' <&> opt tags' <&> exts') <* stop)
      )

  let full' = compile full
end

let parse str : parsed_name =
  match Tyre.exec P.full' str with
  | Error _ -> failwith "gibt's nicht."
  | Ok n -> n

let unparse p : string =
  (* Tyre.eval P.full p *)
  let dt =
    match p.datetime with None -> "" | Some dt -> P.string_of_datetime dt
  and tagpart =
    match p.tags with
    | [] -> ""
    | t ->
        t
        |> List.map (function Tag o -> o)
        |> List.cons P.sep |> String.concat P.sep'
  in
  p.exts
  |> List.map (function Ext o -> o)
  |> List.cons tagpart
  |> List.cons (match p.title with Title t -> t)
  |> List.cons dt
  |> List.append (p.dirs |> List.map (function Dir o -> o))
  |> String.concat ""
