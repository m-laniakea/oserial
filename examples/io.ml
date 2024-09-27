open Lwt.Infix

module S = Shared

let port = "/dev/pts/19"
let baud_rate = 115200

let () =
	Lwt_main.run begin
		Serial.connect ~port ~baud_rate >>= function
		| Ok connection ->
			Lwt_io.printl "Awaiting input. Enter 'quit' when done..." >>= fun () ->
			Serial.io_loop connection (Some "quit")
		| Error e -> S.print_exn_conn e
	end
