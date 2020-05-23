type get_par = { url : string option }

let empty_par : get_par = { url = None }

let rec get_params pars re' =
  (* railway *)
  match re' with
  | Error _ -> re'
  | Ok _ -> (
      match pars with
      | [] -> re'
      | _ -> (
          let p : Url.par = List.hd pars in
          match p with
          | { name = Name "url"; value = Value x } -> Ok { url = Some x }
          | { name = Name _; value = _ } ->
              re'
              (* Just go on, rather than Error ["unexpected parameter"; n] *)
              |> get_params (List.tl pars) ) )
