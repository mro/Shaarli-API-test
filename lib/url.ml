
(*
 * https://tools.ietf.org/html/rfc1738
 *)

type scheme = Scheme of string
let  https  = Scheme "https"
let  http   = Scheme "http"

type uid    = Uid    of string
type pwd    = Pwd    of string
type host   = Host   of string
type port   = Port   of int
let  p_https= Port 443
let  p_http = Port 80

type dir    = Dir    of string
type name   = Name   of string
type value  = Value  of string

type auth    = {
  uid      : uid ;
  pwd      : pwd ;
}

type par    = {
  name     : name ;
  value    : value ;
} 

type t = {
  scheme   : scheme ;
  auth     : auth option ;
  host     : host ;
  port     : port option ;
  path     : dir list ;
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

  let auth' =
    let to_ (uid, pwd) = {uid; pwd}
    and of_ {uid; pwd} = (uid, pwd)
    in
    conv to_ of_ (uid' <* char ':' <&> pwd' <* char '@')

  let host' =
    let to_ s = Host s
    and of_ (Host o) = o in
    conv to_ of_ (pcre "[^:/&?]*")

  let port' =
    let to_ s = Port (int_of_string s)
    and of_  (Port o) = string_of_int o in
    conv to_ of_ (pcre "[0-9]+")

  let dir' =
    let to_ s = Dir s
    and of_ (Dir o) = o in
    conv to_ of_ (pcre "/[^/?&]*")

  let path' =
    list dir'

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
    conv to_ of_ (name' <&> char '=' *> value')

  let query' =
    (* TODO: allow also the empty string. *)
    char '?' *> separated_list ~sep:(char '&') par'

  (* https://gabriel.radanne.net/papers/tyre/tyre_paper.pdf#page=9 *)
  let full =
    let to_ ((scheme, (auth, (host, port))), (path, query)) =
      {scheme; auth; host; port; path; query}
    and of_ {scheme; auth; host; port; path; query} =
      ((scheme, (auth, (host, port))), (path, query))
    in
    conv to_ of_ (
      (scheme' <* char ':' <* str"//" <&>
       (opt auth' <&>
       (host' <&> opt (char ':' *> port')))) <&>
       (path' <&> query') <*
       stop)

  let full' = compile full
end

let parse str =
  Tyre.exec P.full' str

