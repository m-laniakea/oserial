open Lwt.Infix

let port = "/dev/pts/19"
let baud_rate = 115200

let () =
	Lwt_main.run begin
		Serial.connect_exn ~port ~baud_rate >>= fun connection ->
		Lwt_io.printl "Awaiting input. Enter 'quit' when done..." >>= fun () ->
		Serial.io_loop connection (Some "quit")
	end
