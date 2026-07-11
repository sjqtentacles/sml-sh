(* demo.sml - tokenizing and parsing shell-like command lines with Sh.
   Deterministic: parses fixed sample strings only, never executes anything
   or touches the real filesystem/shell. *)

structure S = Sh

fun cmdToString (S.Echo ws) = "Echo " ^ String.concatWith " " ws
  | cmdToString (S.Cd NONE) = "Cd (none)"
  | cmdToString (S.Cd (SOME d)) = "Cd " ^ d
  | cmdToString (S.Command (p, args)) =
      "Command " ^ p ^ (if null args then "" else " " ^ String.concatWith " " args)
  | cmdToString (S.Pipe (a, b)) = "(" ^ cmdToString a ^ " | " ^ cmdToString b ^ ")"
  | cmdToString (S.And (a, b)) = "(" ^ cmdToString a ^ " && " ^ cmdToString b ^ ")"
  | cmdToString (S.Or (a, b)) = "(" ^ cmdToString a ^ " || " ^ cmdToString b ^ ")"
  | cmdToString (S.Seq (a, b)) = "(" ^ cmdToString a ^ " ; " ^ cmdToString b ^ ")"

fun showTokens line =
  print ("  " ^ line ^ "\n    -> [" ^ String.concatWith ", " (S.tokenize line) ^ "]\n")

fun showParse line =
  print ("  " ^ line ^ "\n    -> " ^ cmdToString (S.parseLine line) ^ "\n")

val () = print "Tokenizing:\n"
val () = app showTokens
  [ "echo hello 'quoted arg' world"
  , "ls -la | grep foo && echo ok"
  ]

val () = print "\nParsing:\n"
val () = app showParse
  [ "cd /tmp; ls | grep txt"
  , "make test && make example || echo failed"
  , "echo one; echo two; echo three"
  ]
