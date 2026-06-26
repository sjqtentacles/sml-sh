# sml-sh

[![CI](https://github.com/sjqtentacles/sml-sh/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-sh/actions/workflows/ci.yml)

A small POSIX-ish shell **line parser** for Standard ML. Turns a command line
into a command AST covering the `echo`/`cd` built-ins, external commands,
pipelines (`|`), logical `&&`/`||`, and `;` sequencing, with a tokenizer that
honors single/double quotes and backslash escapes.

## API

```sml
datatype cmd =
    Echo of string list
  | Cd of string option
  | Command of string * string list
  | Pipe of cmd * cmd
  | And of cmd * cmd
  | Or of cmd * cmd
  | Seq of cmd * cmd

val tokenize  : string -> string list
val parseLine : string -> cmd
```

### Tokenizing

```sml
Sh.tokenize "echo \"hello world\""   (* ["echo", "hello world"]  *)
Sh.tokenize "a 'b c' d"              (* ["a", "b c", "d"]        *)
Sh.tokenize "a|b && c"               (* ["a", "|", "b", "&&", "c"] *)
```

### Parsing

```sml
Sh.parseLine "echo hello world"   (* Echo ["hello", "world"]                         *)
Sh.parseLine "cd /tmp"            (* Cd (SOME "/tmp")                                *)
Sh.parseLine "ls -l"             (* Command ("ls", ["-l"])                          *)
Sh.parseLine "echo hi | cat"      (* Pipe (Echo ["hi"], Command ("cat", []))         *)
Sh.parseLine "a && b || c"        (* Or (And (..a.., ..b..), ..c..)                  *)
Sh.parseLine "echo a ; cd /"      (* Seq (Echo ["a"], Cd (SOME "/"))                 *)
```

Operator precedence, loosest first: `;`, then `&&`/`||` (left-associative, equal
precedence), then `|` (tightest).

## Scope and limitations

- Built-ins recognized are `echo` and `cd`; every other leading word becomes an
  external `Command (prog, args)`. Redirections (`>`, `<`, `>>`), subshells
  (`(...)`), background `&`, and here-docs are not parsed.
- Quoting handles `'...'`, `"..."`, and `\` escapes, but there is no variable
  (`$VAR`) expansion, command substitution, or globbing (see `sml-shglob` /
  `sml-glob`).
- A parser only — it produces an AST and does not execute anything.

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-sh
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-sh/sh.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-sh/
  sh.sig
  sh.sml       quote-aware tokenizer + pipe/&&/||/; parser
  sh.mlb
test/
  test.sml     tokenize, quotes, builtins, pipe, &&/||, precedence
```

## License

MIT. See [LICENSE](LICENSE).
