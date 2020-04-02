
(*
 * https://tools.ietf.org/html/rfc1738
 *)

type scheme = Scheme of string
type uid    = Uid    of string
type pwd    = Pwd    of string
type host   = Host   of string
type port   = Port   of string
type path   = Path   of string
type name   = Name   of string
type value  = Value  of string

type par    = {
  name     : name ;
  value    : value ;
} 

type t = {
  scheme   : scheme ;
  uid      : uid ;
  pwd      : pwd ;
  host     : host ;
  port     : port ;
  path     : path ;
  query    : par list ;
  (* no fragment *)
}

module P = struct
  open Tyre

  let scheme' =
    let to_ s = Scheme s
    and of_ (Scheme o) = o in
    conv to_ of_ (pcre "https?")

  let uid' =
    let to_ s = Uid s
    and of_ (Uid o) = o in
    conv to_ of_ (pcre "[^:]*")

  let pwd' =
    let to_ s = Pwd s
    and of_ (Pwd o) = o in
    conv to_ of_ (pcre "[^@]*")

  let host' =
    let to_ s = Host s
    and of_ (Host o) = o in
    conv to_ of_ (pcre "[^:/?]*")

  let port' =
    let to_ s = Port s
    and of_ (Port o) = o in
    conv to_ of_ (pcre "[0-9]+")

  let path' =
    let to_ s = Path s
    and of_ (Path o) = o in
    conv to_ of_ (pcre "[^?&]*")

  let name' =
    let to_ s = Name s
    and of_ (Name o) = o in
    conv to_ of_ (pcre "[^=&]+")

  let value' =
    let to_ s = Value s
    and of_ (Value o) = o in
    conv to_ of_ (pcre "[^&]*")

  let par' =
    let to_ (name, value) = {name; value}
    and of_ {name; value} = (name, value)
    in
    conv to_ of_ (str "&" *> name' <&> str "=" *> value')

  let query' =
    list par'

  (* https://gabriel.radanne.net/papers/tyre/tyre_paper.pdf#page=9 *)
  let full =
    let to_ ((scheme, ((uid, pwd), (host, port))), (path, query)) =
      {scheme; uid; pwd; host; port; path; query}
    and of_ {scheme; uid; pwd; host; port; path; query} =
      ((scheme, ((uid, pwd), (host, port))), (path, query))
    in
    conv to_ of_ (
      (scheme' <* char ':' <* str "//" <&>
       ((uid' <* char ':' <&> pwd' <* char '@') <&>
       (host' <* char ':' <&> port'))) <&>
       (path' <&> query') <*
       stop)

  let full' = compile full
end

let parse str : t =
  match Tyre.exec P.full' str with
  | Error _ -> failwith "gibt's nicht."
  | Ok n -> n

