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

# open one using Serial, the other using socat
(or two connections via this library!):

socat - /dev/pts/14,raw,echo=0
```

**Supplied Functions**

The function returns are wrapped in `Lwt.t`, so please read up on [Lwt](https://ocsigen.org/lwt/5.2.0/manual/manual) should you be unfamiliar with the library.
```ocaml
read_line : connection -> unit -> string Lwt.t
write_line : connection -> string -> unit Lwt.t
write : connection -> string -> unit Lwt.t

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

## Usage (module-based)
Once you have a `connection` record, you can create module:
```ocaml
let module DaytimeSerial = (val Serial.make connection) 
```

Use the created module
```ocaml
DaytimeSerial.write_line "Regresaré como lo que soy: como una reina." >>= fun () ->
DaytimeSerial.io_loop (Some "Siniestra belleza")
```

### Modules or Records?
It's up to you. The functions are 1:1 equivalent.
Side by side:
```ocaml
MySerial.write "Enamórate de ti. De la vida. Y luego de quien tú quieras."
Serial.write connection "Enamórate de ti. De la vida. Y luego de quien tú quieras."
```
