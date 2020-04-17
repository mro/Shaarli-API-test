
let test_comb_title () = 
  let fo = Soup.read_file "configure.1.html" |> Soup.parse |> Lib.Shaarli.comb_title in
  assert(Some "Shaarli v0.41 🚀" = fo)

let test_comb_linkform () =
  let fo = Soup.read_file "post.1.html" |> Soup.parse |> Lib.Shaarli.comb_linkform in
  let f' = [
	  ("lf_linkdate",    "20110914_190000");
	  ("lf_url",         "http://sebsauvage.net/wiki/doku.php?id=php:shaarli");
	  ("lf_title",       "Shaarli - sebsauvage.net");
	  (* ("lf_description", "Welcome to Shaarli ! This is a bookmark. To edit or * delete me, you must first login."); *)
    ("lf_tags",        "opensource software");
    ("lf_private",     Lib.Shaarli.checkbox_unchecked);
    ("token",          "6bce07d8e940f7a937cee85354c3cccc00c6d852");
    ("returnurl",      "https://demo.0x4c.de/shaarli-v0.41b/?do=addlink");
  ] in
  assert (f' = fo);
  assert (7 = List.length fo)

let () = 
  Unix.chdir "../../../test/data/shaarli_test/";
  test_comb_title ();
  test_comb_linkform ()

