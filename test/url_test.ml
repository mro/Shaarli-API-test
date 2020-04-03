
open Lib.Url

let test_full () =
  let raw = "https://uid:pwd@example.com:123/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(Scheme "https"       = url.scheme);
  assert(Uid    "uid"         = (Option.get url.auth).uid);
  assert(Pwd    "pwd"         = (Option.get url.auth).pwd);
  assert(Host   "example.com" = url.host);
  assert(Port   123           = Option.get url.port);
  assert(Path   "/a/b.c/d.e"  = url.path);
  assert(                   3 = List.length url.query);
  let p0 = List.hd url.query in
  assert(Name   "foo"         = p0.name);
  assert(Value  "bar"         = p0.value)

let test_noauth () =
  let raw = "https://example.com:123/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(None                 = url.auth);
  assert(Host   "example.com" = url.host);
  assert(Port   123           = Option.get url.port);
  assert(Path   "/a/b.c/d.e"  = url.path);
  assert(                   3 = List.length url.query);
  let p0 = List.hd url.query in
  assert(Name   "foo"         = p0.name);
  assert(Value  "bar"         = p0.value)

let test_noport () =
  let raw = "https://uid:pwd@example.com/a/b.c/d.e?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(Uid    "uid"         = (Option.get url.auth).uid);
  assert(Pwd    "pwd"         = (Option.get url.auth).pwd);
  assert(Host   "example.com" = url.host);
  assert(None                 = url.port);
  assert(Path   "/a/b.c/d.e"  = url.path);
  assert(                   3 = List.length url.query);
  let p0 = List.hd url.query in
  assert(Name   "foo"         = p0.name);
  assert(Value  "bar"         = p0.value)

let test_nopath () =
  let raw = "https://example.com?foo=bar&bar=baz&foo=bar" in
  let url = Result.get_ok (parse raw) in
  assert(https                = url.scheme);
  assert(None                 = url.auth);
  assert(Host   "example.com" = url.host);
  assert(None                 = url.port);
  assert(Path   ""            = url.path);
  assert(                   3 = List.length url.query);
  let p0 = List.hd url.query in
  assert(Name   "foo"         = p0.name);
  assert(Value  "bar"         = p0.value)

let test_noquery () =
  let raw = "http://example.com/a/b.c/d.e" in
  let url = Result.get_ok (parse raw) in
  assert(Scheme "http"        = url.scheme);
  assert(Host   "example.com" = url.host);
  assert(Path   "/a/b.c/d.e"  = url.path);
  assert(                   0 = List.length url.query)

let () =
  test_full ();
  test_noauth ();
  test_noport ();
  (* TODO: test_noquery (); *)
  test_nopath ()

