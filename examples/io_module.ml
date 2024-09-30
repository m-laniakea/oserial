open Lwt.Infix

module S = Shared

let port = "/dev/pts/19"
let baud_rate = 115200

let use_module_somewhere_else (module M : Serial.T) =
	M.write "hello " >>= fun () ->
	M.write_line "from the other side."

let modulify connection =
	let module S0 = (val Serial.make connection) in

	Lwt_io.printl "Writing to serial until 'quit' is entered..." >>= fun () ->
	S0.io_loop (Some "quit") >>= fun () ->
	use_module_somewhere_else (module S0)

let main =
	Serial.connect ~port ~baud_rate >>= function
	| Ok connection -> modulify connection
	| Error e -> S.print_exn_conn e

let () = Lwt_main.run main
