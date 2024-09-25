open Lwt.Infix

module Make (T : Serial_intf.Config_T) = struct
	let port = T.port
	let baud_rate = T.baud_rate

	module Private = struct

		let fd = Lwt_main.run begin
			Lwt_unix.openfile port [Unix.O_RDWR; Unix.O_NONBLOCK] 0o000
			(* Here the file permissions are 000 because no file should be created *)
		end

		let in_channel = Lwt_io.of_fd fd ~mode:Lwt_io.input
		let out_channel = Lwt_io.of_fd fd ~mode:Lwt_io.output

		let set_baud_rate baud_rate =
			(* First get the current attributes, then set them
			 * with baud rate changed *)
			Lwt_unix.tcgetattr fd >>= fun attr ->
			Lwt_unix.tcsetattr fd Unix.TCSANOW
				{ attr with c_ibaud = baud_rate
				; c_obaud = baud_rate
				; c_echo = false
				; c_icanon = false
				}
	end

	(* Initialize with desired baud rate *)
	let () = Lwt_main.run begin
		Private.set_baud_rate baud_rate
	end

	let read_line () =
		Lwt_io.read_line Private.in_channel

	let write_line l =
		Lwt_io.fprintl Private.out_channel l

	let wait_for_line to_wait_for =
		(* Read from the device until [Some line] is equal to [to_wait_for] *)
		let rec loop = function
		| Some line when line = to_wait_for ->
				Lwt.return ()
		| _ ->
			read_line () >>= fun line ->
			loop (Some line)
		in
		loop None

	(* {{{ IO Loop *)
	let rec io_loop until =

		(* Reads a line from device and outputs to stdout
		 * Keyword is not accepted when received from device; always returns [`Continue] *)
		let read_to_stdin () =
			read_line () >>= fun line ->
			Lwt_io.printl line >>= fun () ->
			Lwt.return `Continue
		in

		(* Reads from stdin and writes to device
		 * If keyword is entered, returns [`Terminate] instead of [`Continue] *)
		let write_from_stdin () =
			Lwt_io.(read_line stdin) >>= function
				| line when Some line <> until ->
						write_line line >>= fun () ->
						Lwt.return `Continue
				| line when Some line = until -> Lwt.return `Terminate
				| _ -> assert false
		in

		(* Take result of first function to complete, and cancel the others *)
		Lwt.pick [read_to_stdin (); write_from_stdin ()] >>= function
		| `Continue -> io_loop until
		| `Terminate -> Lwt.return ()
	(* }}} *)

end
