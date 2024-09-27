(** Given a Serial_config struct,
creates a new module with a newly opened Serial connection.
Most programs using the {!Serial} module start with something like:
{[
module Serial_config = struct
	let port = "/dev/ttyUSB0"
	let baud_rate = 115200
end

module Serial0 = Serial.Make(Serial_config)
]}
*)
module Make (T : Serial_intf.Config_T) : Serial_intf.T

type t

val connect : port:string -> baud_rate:int -> (t, exn) Lwt_result.t
val connect_exn : port:string -> baud_rate:int -> t Lwt.t
val io_loop : t -> string option -> unit Lwt.t
val wait_for_line : t -> string -> unit Lwt.t
val line_write : t -> string -> unit Lwt.t
val line_read : t -> string Lwt.t
