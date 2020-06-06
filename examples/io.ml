module Serial_config = struct
  let port = "/dev/pts/9"
end

module Serial0 = Serial.Make(Serial_config)

let () =
  Lwt_main.run begin
    Serial0.io_loop (Some "quit")
  end
