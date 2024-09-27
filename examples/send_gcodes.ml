open Lwt.Infix

let port = "/dev/ttyUSB0"
let baud_rate = 115200

let send_command connection c =
	Serial.line_write connection c >>= fun () ->
	Serial.wait_for_line connection "ok" ~timeout_s:(Some  5.) >>= function
	| Serial.Received -> Lwt_io.printlf "ok received for %S" c
	| Serial.TimedOut -> Lwt_io.printlf "didn't hear back in time for %S" c

let demo connection =
	let commands =
		[ "G28"; "G0 Z60"; "M81"; "G4 S1"
		; "G0 Z50"; "G4 P200"; "G0 Z40"
		]
	in

	Lwt_io.printl "Starting demo...." >>= fun () ->
	Lwt_list.iter_s (send_command connection) commands >>= fun () ->
	Lwt_io.printl "Commands sent."

let () =
	Lwt_main.run begin
		Serial.connect ~port ~baud_rate >>= function
		| Ok connection -> demo connection
		| Error e -> Shared.print_exn_conn e
	end
