# sml-sh

[![CI](https://github.com/sjqtentacles/sml-sh/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-sh/actions/workflows/ci.yml)

A tiny POSIX-ish shell **line parser** for Standard ML. Turns a command line
into a small command AST covering `echo`, `cd`, and `;`-separated sequences.

## API

```sml
datatype cmd = Echo of string list
             | Cd of string option
             | Seq of cmd * cmd

Sh.parseLine "echo hello world"   (* Echo ["hello", "world"] *)
Sh.parseLine "cd /tmp"            (* Cd (SOME "/tmp") *)
Sh.parseLine "cd"                 (* Cd NONE *)
Sh.parseLine "echo a ; cd /"      (* Seq (Echo ["a"], Cd (SOME "/")) *)
```

## Scope and limitations

- Recognizes the built-ins `echo` and `cd`, and the `;` sequence operator only.
  Arbitrary external commands, pipes (`|`), redirections (`>`, `<`), `&&`/`||`,
  subshells, and background `&` are not parsed.
- Whitespace-separated tokenization: no quoting (`'`/`"`), escaping, variable
  (`$VAR`) expansion, or globbing (see `sml-shglob` / `sml-glob`).
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
  sh.sml       echo / cd / sequence line parser
  sh.mlb
test/
  test.sml     echo args, cd with/without path, sequences
```

## License

MIT. See [LICENSE](LICENSE).
