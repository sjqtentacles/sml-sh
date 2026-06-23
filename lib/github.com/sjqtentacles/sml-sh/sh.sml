structure Sh :> SH =
struct
  datatype cmd = Echo of string list | Cd of string option | Seq of cmd * cmd
  fun words s = String.tokens Char.isSpace s
  fun parseLine s =
    case words s of
        "echo" :: args => Echo args
      | "cd" :: [] => Cd NONE
      | "cd" :: p :: _ => Cd (SOME p)
      | ws => Echo ws
end
