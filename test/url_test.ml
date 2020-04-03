
open Lib.Url

let test_full () =
  let raw = "https://uid:pwd@example.com:123/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(Scheme "https"       = url.scheme);
  assert(Uid    "uid"         = (Option.get url.auth).uid);
  assert(Pwd    "pwd"         = (Option.get url.auth).pwd);
  assert(Host   "example.com" = url.host);
  assert(Port   123           = Option.get url.port);
  assert(url.path = List.map (function s -> Dir s)
    ["/a"; "/b.c"; "/d.e"]);
  assert(url.query = List.map (function (k,v) -> {name = Name k; value = Value v})
    [("foo","bar");("bar","baz");("foo","bar");])

let test_noauth () =
  let raw = "https://example.com:123/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(None                 = url.auth);
  assert(Host   "example.com" = url.host);
  assert(Port   123           = Option.get url.port);
  assert(url.path = List.map (function s -> Dir s)
    ["/a"; "/b.c"; "/d.e"]);
  assert(url.query = List.map (function (k,v) -> {name = Name k; value = Value v})
    [("foo","bar");("bar","baz");("foo","bar");])

let test_noport () =
  let raw = "https://uid:pwd@example.com/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(Uid    "uid"         = (Option.get url.auth).uid);
  assert(Pwd    "pwd"         = (Option.get url.auth).pwd);
  assert(Host   "example.com" = url.host);
  assert(None                 = url.port);
  assert(url.path = List.map (function s -> Dir s)
    ["/a"; "/b.c"; "/d.e"]);
  assert(url.query = List.map (function (k,v) -> {name = Name k; value = Value v})
    [("foo","bar");("bar","baz");("foo","bar");])

let test_nopath () =
  let raw = "https://example.com?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(None                 = url.auth);
  assert(Host   "example.com" = url.host);
  assert(None                 = url.port);
  assert([]                   = url.path);
  assert(url.query = List.map (function (k,v) -> {name = Name k; value = Value v})
    [("foo","bar");("bar","baz");("foo","bar");])

let test_noquery () =
  let raw = "http://example.com/a/b.c/d.e" in
  let url = Result.get_ok (parse raw) in
  assert(Scheme "http"        = url.scheme);
  assert(Host   "example.com" = url.host);
  assert(url.path = List.map (function s -> Dir s)
    ["/a"; "/b.c"; "/d.e"]);
  assert([]                   = url.query)

let () =
  test_full ();
  test_noauth ();
  test_noport ();
  (* TODO: test_noquery (); *)
  test_nopath ()

