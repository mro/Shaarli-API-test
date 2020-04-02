
type year  = Year  of int
type month = Month of int
type day   = Day   of int
type date  = year * month * day

let create_date y m d =
  (Year y, Month m, Day d)


type hour   = Hour   of int
type minute = Minute of int
type second = Second of int
type time   = hour * minute * second

let create_time h m s =
  (Hour h, Minute m, Second s)


type t = date * time

let create y m d hh mm ss =
  (create_date y m d, create_time hh mm ss)
