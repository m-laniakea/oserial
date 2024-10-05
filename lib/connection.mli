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
