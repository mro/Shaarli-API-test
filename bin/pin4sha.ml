let () =
  let status =
    match Lib.Cgi.request_from_env () |> Lib.Cgi.consolidate with
    | Ok req -> Cgi.handle req
    | Error _ -> Sys.argv |> Array.to_list |> Shell.exec
  in
  exit status
