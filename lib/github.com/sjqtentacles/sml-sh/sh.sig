signature SH =
sig
  (* A parsed command line. Built-ins `echo`/`cd`, pipelines (`|`), logical
     `&&`/`||`, and `;` sequencing. Arbitrary external commands are captured as
     `Echo`-like word lists via `Command`. *)
  datatype cmd =
      Echo of string list             (* echo <args...>                 *)
    | Cd of string option             (* cd [dir]                       *)
    | Command of string * string list (* external: program + args       *)
    | Pipe of cmd * cmd               (* left | right                   *)
    | And of cmd * cmd                (* left && right                  *)
    | Or of cmd * cmd                 (* left || right                  *)
    | Seq of cmd * cmd                (* left ; right                   *)

  (* `tokenize s` splits a command line into words and operator tokens,
     honoring single quotes ('...'), double quotes ("..."), and backslash
     escapes. Operators (| || && ;) are returned as their literal strings. *)
  val tokenize : string -> string list

  (* `parseLine s` parses a command line into a `cmd`. Precedence (loosest
     first): `;`, then `&&`/`||` (left-associative, equal precedence), then `|`.
     An empty line parses to `Echo []`. *)
  val parseLine : string -> cmd
end
