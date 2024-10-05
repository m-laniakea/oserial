(**
You'll probably want to use [make] below.
*)
module Make (T : Serial_intf.Config_T) : Serial_intf.T
module type T = Serial_intf.T

(**
	Create a module using Connection.t
	{[
		let module DaytimeSerial = (val Serial.make connection)
	]}
*)
val make : Connection.t -> (module T)

val baud_rate : Connection.t -> int

(**
	Create a connection. Returns a [connection Lwt_result.t].
	{[
		Serial.connect ~port ~baud_rate >>= function
		| Ok connection ->
			Lwt_io.printl "Awaiting input. Enter 'quit' when done..." >>= fun () ->
			Serial.io_loop connection (Some "quit")
		| Error _ -> Lwt.return () (* TODO: handle exception *)
	]}
*)
val connect : port:string -> baud_rate:int -> (Connection.t, exn) Lwt_result.t

(**
	Create a connection. May raise an exception (e.g. port not found).
	{[
		Serial.connect_exn ~port ~baud_rate >>= fun connection ->
		Lwt_io.printl "Awaiting input. Enter 'quit' when done..." >>= fun () ->
		Serial.io_loop connection (Some "quit")
	]}
*)
val connect_exn : port:string -> baud_rate:int -> Connection.t Lwt.t

(**
	Enters a loop reading from serial -> stdout, stdin -> serial.
	Optionally exit loop when [$TERMINATOR] is entered.
	{[ io_loop connection (Some "done!")
	]}
*)
val io_loop : Connection.t -> string option -> unit Lwt.t
val read_line : Connection.t -> string Lwt.t
val write_line : Connection.t -> string -> unit Lwt.t

(** Unlike [write_line], [write] does not terminate the string with a newline *)
val write : Connection.t -> string -> unit Lwt.t
val port : Connection.t -> string

(**
	Waits for a keyword with optional timeout.
	{[
		wait_for_line connection "wait for me!" ~timeout_s:(Some 8.)
		wait_for_line connection "wait for me!" ~timeout_s:None
	]}

	Returns either [Received] or [TimedOut].
	{[
		wait_for_line connection "ok" ~timeout_s:(Some  5.) >>= function
		| Received -> Lwt_io.printlf "ok received for %S" c
		| TimedOut -> Lwt_io.printlf "didn't hear back in time for %S" c
	]}
*)
val wait_for_line : Connection.t -> string -> timeout_s:(float option) -> Wait_for.t Lwt.t
