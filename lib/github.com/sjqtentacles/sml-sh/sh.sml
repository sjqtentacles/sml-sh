structure Sh :> SH =
struct
  datatype cmd =
      Echo of string list
    | Cd of string option
    | Command of string * string list
    | Pipe of cmd * cmd
    | And of cmd * cmd
    | Or of cmd * cmd
    | Seq of cmd * cmd

  (* ---- tokenizer ---- *)

  (* Scan a command line into word/operator tokens. Single quotes, double
     quotes, and backslash escapes group characters into a single word. The
     operators | || && ; are emitted as standalone tokens even when adjacent to
     words (e.g. "a|b" -> ["a","|","b"]). *)
  fun tokenize s =
    let
      val cs = String.explode s
      (* flush the current word buffer (reversed) into the token accumulator *)
      fun flush (buf, hasWord, toks) =
        if hasWord then (String.implode (List.rev buf)) :: toks else toks

      (* state: remaining chars, current word buffer (rev), whether a word is in
         progress (so empty quoted strings "" still count), accumulated tokens (rev) *)
      fun go ([], buf, hasWord, toks) =
            List.rev (flush (buf, hasWord, toks))
        | go (#"\\" :: c :: rest, buf, _, toks) =
            go (rest, c :: buf, true, toks)
        | go (#"\\" :: [], buf, hasWord, toks) =
            List.rev (flush (buf, hasWord, toks))
        | go (#"'" :: rest, buf, _, toks) =
            let val (inner, rest') = quoted (#"'", rest, [])
            in go (rest', List.revAppend (inner, buf), true, toks) end
        | go (#"\"" :: rest, buf, _, toks) =
            let val (inner, rest') = quoted (#"\"", rest, [])
            in go (rest', List.revAppend (inner, buf), true, toks) end
        | go (c :: rest, buf, hasWord, toks) =
            if Char.isSpace c then
              go (rest, [], false, flush (buf, hasWord, toks))
            else
              (case opAt (c :: rest) of
                   SOME (opTok, rest') =>
                     go (rest', [], false, opTok :: flush (buf, hasWord, toks))
                 | NONE => go (rest, c :: buf, true, toks))

      (* read up to the matching closing quote; backslash escapes inside double
         quotes only. Returns (chars, remaining). *)
      and quoted (q, [], acc) = (List.rev acc, [])
        | quoted (q, #"\\" :: c :: rest, acc) =
            if q = #"\"" then quoted (q, rest, c :: acc)
            else quoted (q, rest, c :: #"\\" :: acc)
        | quoted (q, c :: rest, acc) =
            if c = q then (List.rev acc, rest)
            else quoted (q, rest, c :: acc)

      (* recognize a shell operator at the head of the char list *)
      and opAt (#"&" :: #"&" :: rest) = SOME ("&&", rest)
        | opAt (#"|" :: #"|" :: rest) = SOME ("||", rest)
        | opAt (#"|" :: rest) = SOME ("|", rest)
        | opAt (#";" :: rest) = SOME (";", rest)
        | opAt _ = NONE
    in
      go (cs, [], false, [])
    end

  (* ---- parser ---- *)

  fun isOp t = t = "|" orelse t = "||" orelse t = "&&" orelse t = ";"

  (* a simple command is a run of words up to the next operator *)
  fun simpleCmd words =
    case words of
        [] => Echo []
      | "echo" :: args => Echo args
      | "cd" :: [] => Cd NONE
      | "cd" :: dir :: _ => Cd (SOME dir)
      | prog :: args => Command (prog, args)

  (* split a token list at the LAST occurrence of one of `ops`, used so that
     left-associative operators fold correctly (parse the left side
     recursively, the right side as the next-tighter level). *)
  fun lastIndexOf (ops, toks) =
    let fun go (_, [], best) = best
          | go (i, t :: rest, best) =
              go (i + 1, rest, if List.exists (fn o' => o' = t) ops then SOME i else best)
    in go (0, toks, NONE) end

  fun take (xs, 0) = []
    | take ([], _) = []
    | take (x :: xs, n) = x :: take (xs, n - 1)
  fun drop (xs, 0) = xs
    | drop ([], _) = []
    | drop (_ :: xs, n) = drop (xs, n - 1)

  fun parseSeq toks =
    case lastIndexOf ([";"], toks) of
        SOME i =>
          let val left = take (toks, i)
              val right = drop (toks, i + 1)
          in if right = [] then parseSeq left
             else Seq (parseSeq left, parseAndOr right)
          end
      | NONE => parseAndOr toks

  and parseAndOr toks =
    case lastIndexOf (["&&", "||"], toks) of
        SOME i =>
          let val op' = List.nth (toks, i)
              val left = take (toks, i)
              val right = drop (toks, i + 1)
              val l = parseAndOr left
              val r = parsePipe right
          in if op' = "&&" then And (l, r) else Or (l, r) end
      | NONE => parsePipe toks

  and parsePipe toks =
    case lastIndexOf (["|"], toks) of
        SOME i =>
          let val left = take (toks, i)
              val right = drop (toks, i + 1)
          in Pipe (parsePipe left, simpleCmd (List.filter (fn t => not (isOp t)) right)) end
      | NONE => simpleCmd toks

  fun parseLine s = parseSeq (tokenize s)
end
