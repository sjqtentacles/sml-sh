signature SH =
sig
  datatype cmd = Echo of string list | Cd of string option | Seq of cmd * cmd
  val parseLine : string -> cmd
end
