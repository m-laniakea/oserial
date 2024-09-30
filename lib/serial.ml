open Lwt.Infix

module C = Connection

module type T = Serial_intf.T

let baud_rate (connection : C.t) = connection.baud_rate
let port (connection : C.t) = connection.port

let setup_fd baud_rate fd =
	(* First get the current attributes, then set them
	 * with baud rate changed *)
	Lwt_unix.tcgetattr fd >>= fun attr ->
	Lwt_unix.tcsetattr fd Unix.TCSANOW
		{ attr with c_ibaud = baud_rate
		; c_echo = false
		; c_icanon = false
		; c_obaud = baud_rate
		; c_opost = false
		}

let setup ~port ~baud_rate =
	let settings_open =
		Unix.
		[ O_RDWR
		; O_NONBLOCK
		]
	in
	let permissions = 0o000 in (* permissions 0 as no file should be created *)
	Lwt_unix.openfile port settings_open permissions >>= fun fd ->
	setup_fd baud_rate fd >|= fun () ->
	fd

let connect_exn ~port ~baud_rate =
	setup ~port ~baud_rate >|= fun fd ->

	let channel_in = Lwt_io.of_fd fd ~mode:Lwt_io.input in
	let channel_out = Lwt_io.of_fd fd ~mode:Lwt_io.output in

	C.
	{ baud_rate
	; channel_in
	; channel_out
	; fd
	; port
	}

let connect ~port ~baud_rate =
	Lwt.catch
		( fun () -> connect_exn ~port ~baud_rate >>= Lwt_result.return )
		( fun e -> Lwt_result.fail e )

let read_line (connection : C.t) = Lwt_io.read_line connection.channel_in
let write_line (connection : C.t) = Lwt_io.write_line connection.channel_out
let write (connection : C.t) = Lwt_io.write connection.channel_out

let rec io_loop state until =

	(* Reads a line from device and outputs to stdout
	 * Keyword is not accepted when received from device; always returns [`Continue] *)
	let read_to_stdin () =
		read_line state >>= fun line ->
		Lwt_io.printl line >|= fun () ->
		`Continue
	in

	(* Reads from stdin and writes to device
	 * If keyword is entered, returns [`Terminate] instead of [`Continue] *)
	let write_from_stdin () =
		Lwt_io.(read_line stdin) >>= function
		| line when Some line = until -> Lwt.return `Terminate
		| line ->
			write_line state line >|= fun () ->
			`Continue
	in

	(* Take result of first function to complete, and cancel the others *)
	Lwt.pick [read_to_stdin (); write_from_stdin ()] >>= function
	| `Continue -> io_loop state until
	| `Terminate -> Lwt.return ()

let wait_for_line state to_wait_for ~timeout_s =
	(* Read from the device until [Some line] is equal to [to_wait_for] *)
	let rec loop () =
		read_line state >>= function
		| line when line = to_wait_for -> Lwt.return Wait_for.Received
		| _ -> loop ()
	in
	let timeout s =
		Lwt_unix.sleep s >|= fun () ->
		Wait_for.TimedOut
	in

	match timeout_s with
	| None -> loop ()
	| Some s -> Lwt.pick [ loop (); timeout s ]

module Make (T : Serial_intf.Config_T) = struct
	let port = T.connection.port
	let baud_rate = T.connection.baud_rate

	module Private = struct
		let state = T.connection
	end

	let read_line () = read_line Private.state

	let write_line = write_line Private.state
	let write = write Private.state

	let wait_for_line to_wait_for ~timeout_s =
		wait_for_line Private.state to_wait_for ~timeout_s

	(* {{{ IO Loop *)
	let io_loop = io_loop Private.state

end

let make connection =
	let module Config = struct let connection = connection end in
	(module Make(Config) : T)
