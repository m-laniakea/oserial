(** Configuration for opening a Serial connection *)
module type Config_T = sig
	val connection : Connection.t
end

(** Main module *)
module type T = sig
	(** Location of opened serial port *)
	val port : string

	(** Connection Baud rate *)
	val baud_rate : int

	(** Submodule for values that should not be used externally *)
	module Private : sig
		val state : Connection.t
	end

	val read_line : unit -> string Lwt.t
	val write_line : string -> unit Lwt.t

	(** Wait for the specified string to be received. *)
	val wait_for_line : string -> timeout_s:(float option) -> unit Lwt.t

	(** Open two-way communication between std(i/o) and the Serial device.

	Supply [Some "$KEYWORD"] to exit the loop upon entering the specified
	line in stdin. Supplying [None] causes this function to loop indefinitely. *)
	val io_loop : string option -> unit Lwt.t
end
