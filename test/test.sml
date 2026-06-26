structure Tests = struct open Harness structure S = Sh
fun run () = let
  val () = section "tokenize"
  val () = checkStringList "plain words" (["echo","hi"], S.tokenize "echo hi")
  val () = checkStringList "collapses spaces" (["a","b"], S.tokenize "  a   b ")
  val () = checkStringList "double quotes group" (["echo","hello world"], S.tokenize "echo \"hello world\"")
  val () = checkStringList "single quotes group" (["echo","a b c"], S.tokenize "echo 'a b c'")
  val () = checkStringList "operators are tokens" (["a","|","b"], S.tokenize "a | b")
  val () = checkStringList "andor operators" (["a","&&","b","||","c"], S.tokenize "a && b || c")
  val () = checkStringList "semicolon token" (["a",";","b"], S.tokenize "a ; b")
  val () = checkStringList "operator without spaces" (["a","|","b"], S.tokenize "a|b")
  val () = checkStringList "escaped space" (["a b"], S.tokenize "a\\ b")

  val () = section "basic builtins"
  val () = checkEq "echo" (S.Echo ["hi"], S.parseLine "echo hi")
  val () = checkEq "echo multi" (S.Echo ["a","b","c"], S.parseLine "echo a b c")
  val () = checkEq "cd dir" (S.Cd (SOME "/tmp"), S.parseLine "cd /tmp")
  val () = checkEq "cd none" (S.Cd NONE, S.parseLine "cd")
  val () = checkEq "empty -> Echo []" (S.Echo [], S.parseLine "")
  val () = checkEq "quoted arg" (S.Echo ["hello world"], S.parseLine "echo \"hello world\"")

  val () = section "external command"
  val () = checkEq "ls -l" (S.Command ("ls", ["-l"]), S.parseLine "ls -l")
  val () = checkEq "bare program" (S.Command ("pwd", []), S.parseLine "pwd")

  val () = section "pipe"
  val () = checkEq "echo | cat"
             (S.Pipe (S.Echo ["hi"], S.Command ("cat", [])), S.parseLine "echo hi | cat")

  val () = section "logical operators"
  val () = checkEq "a && b"
             (S.And (S.Command ("a", []), S.Command ("b", [])), S.parseLine "a && b")
  val () = checkEq "a || b"
             (S.Or (S.Command ("a", []), S.Command ("b", [])), S.parseLine "a || b")
  (* left-associative, equal precedence: a && b || c = (a && b) || c *)
  val () = checkEq "a && b || c assoc"
             (S.Or (S.And (S.Command ("a", []), S.Command ("b", [])), S.Command ("c", [])),
              S.parseLine "a && b || c")

  val () = section "sequence is loosest"
  val () = checkEq "echo a ; cd /"
             (S.Seq (S.Echo ["a"], S.Cd (SOME "/")), S.parseLine "echo a ; cd /")
  (* ; binds looser than && : a && b ; c = (a && b) ; c *)
  val () = checkEq "a && b ; c precedence"
             (S.Seq (S.And (S.Command ("a", []), S.Command ("b", [])), S.Command ("c", [])),
              S.parseLine "a && b ; c")

  val () = section "pipe binds tighter than &&"
  (* a | b && c = (a | b) && c *)
  val () = checkEq "a | b && c precedence"
             (S.And (S.Pipe (S.Command ("a", []), S.Command ("b", [])), S.Command ("c", [])),
              S.parseLine "a | b && c")
in Harness.run () end end
