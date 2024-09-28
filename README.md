# OSerial
OCaml Serial Module

## Installation
```
opam install serial
```
If using dune, add `serial` to the `libraries` stanza.

## Usage
```ocaml
open Lwt.Infix

let port = "/dev/pts/19" in
let baud_rate = 115200 in

Serial.connect ~port ~baud_rate >>= function
| Ok connection ->
	Lwt_io.printl "Awaiting input. Enter 'quit' when done..." >>= fun () ->
	Serial.io_loop connection (Some "quit")

| Error e -> Lwt_io.printlf "Error connecting: %s" (Printexc.to_string e)
```

See [examples](https://github.com/m-laniakea/oserial/tree/dev/examples) for more.

#### No serial device to play around with?
```bash
socat -d -d pty,raw,echo=0 pty,raw,echo=0

# first two lines may be something like:
# "... N PTY is /dev/pts/14"
# "... N PTY is /dev/pts/19"

# open one using Serial, the other using socat:

socat - /dev/pts/14,raw,echo=0
```

**Supplied Functions**

The function returns are wrapped in `Lwt.t`, so please read up on [Lwt](https://ocsigen.org/lwt/5.2.0/manual/manual) should you be unfamiliar with the library.
```ocaml
line_read : connection -> unit -> string Lwt.t
line_write : connection -> string -> unit Lwt.t

baud_rate : connection -> int
port : connection -> string
```
```ocaml
wait_for_line : connection -> string -> timeout_s:float option -> unit Lwt.t

open Lwt.Infix

wait_for_line connection "ok" ~timeout_s:(Some  5.) >>= function
| Received -> Lwt_io.printlf "ok received for %S" c
| TimedOut -> Lwt_io.printlf "didn't hear back in time for %S" c

```
Waits for a keyword with optional timeout. Passing `None` to timeout_s means this can wait forever.
```ocaml
io_loop : connection -> string option -> unit Lwt.t
```
Opens a two-way communication channel between stdin and the serial device. \
Usage: `io_loop connection (Some "quit")`. \
If `None` is supplied instead, does not exit for any keyword.

## [Deprecated] Usage
Create a Serial_config module
```ocaml
module Serial_config = struct
    let port = "/dev/ttyUSB0"
    let baud_rate = 115200
end
```

Open the port
```ocaml
module Serial0 = Serial.Make(Serial_config)
```

Use the created module
```ocaml
Serial0.io_loop (Some "i quit")
```

**Supplied Functions**
The function returns are wrapped in `Lwt.t`, so please read up on [Lwt](https://ocsigen.org/lwt/5.2.0/manual/manual) should you be unfamiliar with the library.
```ocaml
read_line : unit -> string Lwt.t
write_line : string -> unit Lwt.t
```
```ocaml
wait_for_line : string -> timeout_s:float option -> unit Lwt.t
```
Usage: `wait_for_line "READY"`.
If `timeout_s` is `None`, waits forever.
```ocaml
io_loop : string option -> unit Lwt.t
```
Opens a two-way communication channel between stdin and the serial device.
Usage: `io_loop (Some "quit")`. \
If `None` is supplied instead, does not exit for any keyword.
