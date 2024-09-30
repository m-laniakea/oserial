open Lwt.Infix

let port = "/dev/pts/19"
let baud_rate = 115200


let demo =
	let commands =
		[ "G28"; "G0 Z60"; "M81"; "G4 S1"
		; "G0 Z50"; "G4 P200"; "G0 Z40"
		]
	in

	Serial.connect_exn ~port ~baud_rate >>= fun connection ->
	let module Serial0 = (val Serial.make connection) in

	let send_command c =
		Serial0.write_line c >>= fun () ->
		Serial0.wait_for_line "ok" ~timeout_s:(Some 5.) >>= fun () ->
		Lwt_io.printlf "ok received for %S" c
	in

	Lwt_io.printl "Starting demo...." >>= fun () ->
	Lwt_list.iter_s send_command commands >>= fun () ->
	Lwt_io.printl "Commands sent."

let () = Lwt_main.run demo
