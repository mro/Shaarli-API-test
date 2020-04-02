
open Lib.Url

let () =
  let raw = "https://uid:pwd@example.com:123/a/b.c/d.e&foo=bar&bar=baz&foo=bar" in
  let url = parse raw in
  assert(Scheme "https"       = url.scheme);
  assert(Uid    "uid"         = url.uid);
  assert(Pwd    "pwd"         = url.pwd);
  assert(Host   "example.com" = url.host);
  assert(Port   "123"         = url.port);
  assert(Path   "/a/b.c/d.e"  = url.path);
  assert(                   3 = List.length url.query);
  let p0 = List.hd url.query in
  assert(Name   "foo"         = p0.name);
  assert(Value  "bar"         = p0.value);

