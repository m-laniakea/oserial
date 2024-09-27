open Lwt.Infix

type t =
	{ baud_rate : int
	(** Baud rate of connection. Usually one of [9600; 115200] *)
	; channel_in : Lwt_io.input Lwt_io.channel
	(** Channel for reading lines from the device *)
	; channel_out : Lwt_io.output Lwt_io.channel
	(** Channel for writing lines to the device *)
	; fd : Lwt_unix.file_descr
	(** File descriptor for the opened serial port *)
	; port : string
	(** Location of opened serial port *)
	}

let baud_rate connection = connection.baud_rate
let port connection = connection.port

let setup_fd baud_rate fd =
	(* First get the current attributes, then set them
	 * with baud rate changed *)
	Lwt_unix.tcgetattr fd >>= fun attr ->
	Lwt_unix.tcsetattr fd Unix.TCSANOW
		{ attr with c_ibaud = baud_rate
		; c_obaud = baud_rate
		; c_echo = false
		; c_icanon = false
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

let line_read state = Lwt_io.read_line state.channel_in
let line_write state = Lwt_io.fprintl state.channel_out

let rec io_loop state until =

	(* Reads a line from device and outputs to stdout
	 * Keyword is not accepted when received from device; always returns [`Continue] *)
	let read_to_stdin () =
		line_read state >>= fun line ->
		Lwt_io.printl line >|= fun () ->
		`Continue
	in

	(* Reads from stdin and writes to device
	 * If keyword is entered, returns [`Terminate] instead of [`Continue] *)
	let write_from_stdin () =
		Lwt_io.(read_line stdin) >>= function
			| line when Some line = until -> Lwt.return `Terminate
			| line ->
				line_write state line >|= fun () ->
				`Continue
	in

	(* Take result of first function to complete, and cancel the others *)
	Lwt.pick [read_to_stdin (); write_from_stdin ()] >>= function
	| `Continue -> io_loop state until
	| `Terminate -> Lwt.return ()

let rec wait_for_line state to_wait_for =
	(* Read from the device until [Some line] is equal to [to_wait_for] *)
	line_read state >>= function
	| line when line = to_wait_for -> Lwt.return ()
	| _ -> wait_for_line state to_wait_for

module Make (T : Serial_intf.Config_T) = struct
	let port = T.port
	let baud_rate = T.baud_rate

	module Private = struct

		let fd = Lwt_main.run begin
			setup ~port:T.port ~baud_rate:T.baud_rate
		end

		let in_channel = Lwt_io.of_fd fd ~mode:Lwt_io.input
		let out_channel = Lwt_io.of_fd fd ~mode:Lwt_io.output

		let state =
			{ baud_rate
			; channel_in = in_channel
			; channel_out = out_channel
			; fd
			; port
			}
	end

	let read_line () = line_read Private.state

	let write_line = line_write Private.state

	let wait_for_line = wait_for_line Private.state

	(* {{{ IO Loop *)
	let io_loop = io_loop Private.state

end
