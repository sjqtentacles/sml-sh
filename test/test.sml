structure Tests = struct open Harness structure S = Sh
fun run () = let
  val () = section "shell AST"
  val () = checkEq "echo" (S.Echo ["hi"], S.parseLine "echo hi")
  val () = checkEq "cd home" (S.Cd (SOME "/tmp"), S.parseLine "cd /tmp")
  val () = checkEq "cd none" (S.Cd NONE, S.parseLine "cd")
in Harness.run () end end
