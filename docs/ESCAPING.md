# VSL escaping examples

- [Context](#context)
- [Helpers](#helpers)
- [1. Simple bare words stay bare](#1-simple-bare-words-stay-bare)
- [2. Windows paths with backslashes do not need escaping by themselves](#2-windows-paths-with-backslashes-do-not-need-escaping-by-themselves)
- [3. Whitespace requires quoting](#3-whitespace-requires-quoting)
- [4. Single quotes are a readable wrapper when the word is fully literal](#4-single-quotes-are-a-readable-wrapper-when-the-word-is-fully-literal)
- [5. Double quotes keep variables expandable while preserving spaces](#5-double-quotes-keep-variables-expandable-while-preserving-spaces)
- [6. Inside double quotes, escape a literal double quote with backtick](#6-inside-double-quotes-escape-a-literal-double-quote-with-backtick)
- [7. Inside double quotes, escape a literal backtick with backtick](#7-inside-double-quotes-escape-a-literal-backtick-with-backtick)
- [8. In a bare word, backtick is just a literal character](#8-in-a-bare-word-backtick-is-just-a-literal-character)
- [9. To suppress `${...}` expansion, quote the literal form](#9-to-suppress--expansion-quote-the-literal-form)
- [10. Variables and literals can be concatenated into one bare word](#10-variables-and-literals-can-be-concatenated-into-one-bare-word)
- [11. Expandable terms without spaces stay bare](#11-expandable-terms-without-spaces-stay-bare)
- [12. Subshells can be concatenated with literals in one bare word](#12-subshells-can-be-concatenated-with-literals-in-one-bare-word)
- [13. A literal backtick can appear immediately before an expandable variable](#13-a-literal-backtick-can-appear-immediately-before-an-expandable-variable)
- [14. Single quotes inside double quotes are ordinary characters](#14-single-quotes-inside-double-quotes-are-ordinary-characters)
- [15. For `cmd /c`, keep the inner Windows quoting and then escape the whole payload as one literal](#15-for-cmd-c-keep-the-inner-windows-quoting-and-then-escape-the-whole-payload-as-one-literal)


## Context

VSL (the Value Shell Language) is how you fetch and run **values** with the
`get-object`, `get-asset`, and `run-object` commands you write in `dk.u`, in
distribution scripts (`dist-*/run.u`), and in the precommands of `.values.jsonc` files.
Often arguments to value commands like `get-object` have spaces, quotes,
backticks, and other special characters.

This guide will help you write or understand the value commands that have
special characters in their arguments.

The general rules for special characters are:

- bare words may contain literal backticks
- inside double quotes, backtick **escapes** a literal double quote or a literal backtick
- variables and subshells stay expandable unless you deliberately **quote** a literal

The examples below show how to apply those general rules in specific situations.

## Helpers

A few helpers render the example results as Markdown tables so the output is
easy to read.


```ocaml
(* >>> *) let ctx =
  MlFront_Thunk.ThunkExecutionContext.create_literal
    ~created_for:"ESCAPING.md" ()
```


```text
val ctx : MlFront_Thunk.ThunkExecutionContext.t = <abstr>
```



```ocaml
(* >>> *) let roundtrip s =
  MlFront_Thunk.ThunkCommand.parse_evalableterm ~on_warning:ignore ctx s
  |> Result.map MlFront_Thunk.ThunkCommand.evalable_term_to_valueshell
```


```text
val roundtrip : string -> (string, string) result = <fun>
```



```ocaml
(* >>> *) let quote_expandable =
  MlFront_Thunk.ThunkLexers.ValueShellLexer.Token.quote_bareword_if_needed
```


```text
val quote_expandable : String.t -> String.t = <fun>
```



```ocaml
(* >>> *) let quote_literal =
  MlFront_Thunk.ThunkLexers.ValueShellLexer.Token.quote_literal_if_needed
```


```text
val quote_literal : String.t -> String.t = <fun>
```



```ocaml
(* >>> *) let code s =
  let max_backticks =
    let max_run = ref 0 in
    let current_run = ref 0 in
    String.iter
      (fun c ->
        if c = '`' then (
          incr current_run;
          max_run := max !max_run !current_run)
        else current_run := 0)
      s;
    !max_run
  in
  let fence = String.make (max_backticks + 1) '`' in
  fence ^ s ^ fence
```


```text
val code : string -> string = <fun>
```



```ocaml
(* >>> *) let print_table rows =
  Format.printf "%s@." {|\markdown\;|};
  Format.printf "| Field | Value |@.";
  Format.printf "| --- | --- |@.";
  List.iter (fun (field, value) ->
    Format.printf "| %s | %s |@." field value) rows
```


```text
val print_table : (string * string) list -> unit = <fun>
```



```ocaml
(* >>> *) let show_quote ~scenario ~input ~helper ~notes quote =
  let output = quote input in
  print_table
    [
      ("**Scenario**", scenario);
      ("**Helper**", code helper);
      ("**Raw Text**", code input);
      ("**Escaped VSL**", code output);
      ("**How To Escape**", notes);
    ]
```


```text
val show_quote :
  scenario:string ->
  input:string -> helper:string -> notes:string -> (string -> string) -> unit =
  <fun>
```



```ocaml
(* >>> *) let show_roundtrip ~scenario ~input ~notes =
  match roundtrip input with
  | Ok output ->
      print_table
        [
          ("**Scenario**", scenario);
          ("**Helper**", code "parse_evalableterm -> evalable_term_to_valueshell");
          ("**Raw Text**", code input);
          ("**Escaped VSL**", code output);
          ("**How To Escape**", notes);
        ]
  | Error err ->
      print_table
        [
          ("**Scenario**", scenario);
          ("**Helper**", code "parse_evalableterm -> evalable_term_to_valueshell");
          ("**Raw Text**", code input);
          ("**Error**", code err);
          ("**How To Escape**", notes);
        ]
```


```text
val show_roundtrip : scenario:string -> input:string -> notes:string -> unit =
  <fun>
```


## 1. Simple bare words stay bare


```ocaml
(* >>> *) show_quote
  ~scenario:"Simple bare words stay bare"
  ~input:{|clang.exe|}
  ~helper:"quote_bareword_if_needed"
  ~notes:"Escaping not needed."
  quote_expandable
```


| Field | Value |
| --- | --- |
| **Scenario** | Simple bare words stay bare |
| **Helper** | `quote_bareword_if_needed` |
| **Raw Text** | `clang.exe` |
| **Escaped VSL** | `clang.exe` |
| **How To Escape** | Escaping not needed. |

## 2. Windows paths with backslashes do not need escaping by themselves


```ocaml
(* >>> *) show_quote
  ~scenario:"Windows path without spaces"
  ~input:{|C:\temp\a.exe|}
  ~helper:"quote_bareword_if_needed"
  ~notes:"Escaping not needed; bare backslashes are literal."
  quote_expandable
```


| Field | Value |
| --- | --- |
| **Scenario** | Windows path without spaces |
| **Helper** | `quote_bareword_if_needed` |
| **Raw Text** | `C:\temp\a.exe` |
| **Escaped VSL** | `C:\temp\a.exe` |
| **How To Escape** | Escaping not needed; bare backslashes are literal. |

## 3. Whitespace requires quoting


```ocaml
(* >>> *) show_quote
  ~scenario:"Whitespace forces quoting"
  ~input:{|with space|}
  ~helper:"quote_bareword_if_needed"
  ~notes:"Wrap the whole text in single quotes."
  quote_expandable
```


| Field | Value |
| --- | --- |
| **Scenario** | Whitespace forces quoting |
| **Helper** | `quote_bareword_if_needed` |
| **Raw Text** | `with space` |
| **Escaped VSL** | `'with space'` |
| **How To Escape** | Wrap the whole text in single quotes. |

## 4. Single quotes are a readable wrapper when the word is fully literal


```ocaml
(* >>> *) show_quote
  ~scenario:"Literal Windows path with spaces"
  ~input:{|C:\My Documents|}
  ~helper:"quote_bareword_if_needed"
  ~notes:"Wrap the whole literal path in single quotes."
  quote_expandable
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal Windows path with spaces |
| **Helper** | `quote_bareword_if_needed` |
| **Raw Text** | `C:\My Documents` |
| **Escaped VSL** | `'C:\My Documents'` |
| **How To Escape** | Wrap the whole literal path in single quotes. |

## 5. Double quotes keep variables expandable while preserving spaces


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Keep ${CONFIG} expandable inside spaced path"
  ~input:{|"${CONFIG}\Floor Plans\Master Bedroom.rvt"|}
  ~notes:"Use double quotes so spaces stay intact and ${CONFIG} still expands."
```


| Field | Value |
| --- | --- |
| **Scenario** | Keep ${CONFIG} expandable inside spaced path |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | `"${CONFIG}\Floor Plans\Master Bedroom.rvt"` |
| **Escaped VSL** | `"${CONFIG}\Floor Plans\Master Bedroom.rvt"` |
| **How To Escape** | Use double quotes so spaces stay intact and ${CONFIG} still expands. |

## 6. Inside double quotes, escape a literal double quote with backtick


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Literal double quote inside double-quoted text"
  ~input:{|"say `"hello`" loudly"|}
  ~notes:"Inside VSL double quotes, escape each literal double quote with backtick."
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal double quote inside double-quoted text |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | ``"say `"hello`" loudly"`` |
| **Escaped VSL** | `'say "hello" loudly'` |
| **How To Escape** | Inside VSL double quotes, escape each literal double quote with backtick. |

## 7. Inside double quotes, escape a literal backtick with backtick


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Literal backtick inside double quotes"
  ~input:{|"two `` backticks"|}
  ~notes:"Inside VSL double quotes, write two backticks for one literal backtick."
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal backtick inside double quotes |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | ```"two `` backticks"``` |
| **Escaped VSL** | ``'two ` backticks'`` |
| **How To Escape** | Inside VSL double quotes, write two backticks for one literal backtick. |

## 8. In a bare word, backtick is just a literal character


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Literal backtick in a bare Windows path"
  ~input:{|C:\temp\`cache|}
  ~notes:"Wrap the whole word in single quotes to keep the bare backtick literal."
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal backtick in a bare Windows path |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | ``C:\temp\`cache`` |
| **Escaped VSL** | ``'C:\temp\`cache'`` |
| **How To Escape** | Wrap the whole word in single quotes to keep the bare backtick literal. |

## 9. To suppress `${...}` expansion, quote the literal form


```ocaml
(* >>> *) show_quote
  ~scenario:"Literal ${...} text"
  ~input:{|${SLOT.Release.Agnostic}|}
  ~helper:"quote_literal_if_needed"
  ~notes:"Wrap the whole text in single quotes so ${...} stays literal."
  quote_literal
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal ${...} text |
| **Helper** | `quote_literal_if_needed` |
| **Raw Text** | `${SLOT.Release.Agnostic}` |
| **Escaped VSL** | `'${SLOT.Release.Agnostic}'` |
| **How To Escape** | Wrap the whole text in single quotes so ${...} stays literal. |

## 10. Variables and literals can be concatenated into one bare word


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Literal text around an expandable variable"
  ~input:{|foo${SLOT.Baz}bar|}
  ~notes:"Escaping not needed; a whitespace-free variable-plus-literal word can stay bare."
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal text around an expandable variable |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | `foo${SLOT.Baz}bar` |
| **Escaped VSL** | `foo${SLOT.Baz}bar` |
| **How To Escape** | Escaping not needed; a whitespace-free variable-plus-literal word can stay bare. |

## 11. Expandable terms without spaces stay bare


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"The `-f ${SLOT.File.Darwin_arm64}/dk` output path stays bare"
  ~input:{|${SLOT.File.Darwin_arm64}/dk|}
  ~notes:"Escaping not needed; keep `${SLOT.File.Darwin_arm64}/dk` bare after `-f`."
```


| Field | Value |
| --- | --- |
| **Scenario** | The `-f ${SLOT.File.Darwin_arm64}/dk` output path stays bare |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | `${SLOT.File.Darwin_arm64}/dk` |
| **Escaped VSL** | `${SLOT.File.Darwin_arm64}/dk` |
| **How To Escape** | Escaping not needed; keep `${SLOT.File.Darwin_arm64}/dk` bare after `-f`. |

## 12. Subshells can be concatenated with literals in one bare word


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Subshell plus literal suffix"
  ~input:{|$(get-object SomeLib_Std.Thing@1.0.0 -s Release.Agnostic -d :)/filename|}
  ~notes:"Use double quotes so the subshell expands and the suffix stays in the same word."
```


| Field | Value |
| --- | --- |
| **Scenario** | Subshell plus literal suffix |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | `$(get-object SomeLib_Std.Thing@1.0.0 -s Release.Agnostic -d :)/filename` |
| **Escaped VSL** | `"$(get-object SomeLib_Std.Thing@1.0.0 -s Release.Agnostic -d :)/filename"` |
| **How To Escape** | Use double quotes so the subshell expands and the suffix stays in the same word. |

## 13. A literal backtick can appear immediately before an expandable variable


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Literal backtick before ${SLOT.Speedy}"
  ~input:{|C:\`${SLOT.Speedy}|}
  ~notes:"Use double quotes, and inside them write two backticks before ${SLOT.Speedy}."
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal backtick before ${SLOT.Speedy} |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | ``C:\`${SLOT.Speedy}`` |
| **Escaped VSL** | ```"C:\``${SLOT.Speedy}"``` |
| **How To Escape** | Use double quotes, and inside them write two backticks before ${SLOT.Speedy}. |

## 14. Single quotes inside double quotes are ordinary characters


```ocaml
(* >>> *) show_roundtrip
  ~scenario:"Single quote inside double quotes"
  ~input:{|"it's `${SLOT.Speedy}"|}
  ~notes:"Use double quotes; no extra escaping is needed for the single quote."
```


| Field | Value |
| --- | --- |
| **Scenario** | Single quote inside double quotes |
| **Helper** | `parse_evalableterm -> evalable_term_to_valueshell` |
| **Raw Text** | ``"it's `${SLOT.Speedy}"`` |
| **Escaped VSL** | `"it's ${SLOT.Speedy}"` |
| **How To Escape** | Use double quotes; no extra escaping is needed for the single quote. |

## 15. For `cmd /c`, keep the inner Windows quoting and then escape the whole payload as one literal

When building a single `cmd /c` argument that itself contains quoted paths,
prefer the Windows `cmd.exe` convention of doubled outer double-quotes around
the inner command string. A concise explanation is in
[this Stack Overflow answer](https://stackoverflow.com/a/12892791).

If you are writing `function.commands` in a values file, prefer the
`["--cmd.exe", "/c", "<string>"]` special form documented in
the [SPECIFICATION](/specification/); this section is only for places where you must still
hand-author one literal `cmd /c` payload string.


```ocaml
(* >>> *) show_quote
  ~scenario:"Literal cmd /c payload with quoted paths"
  ~input:{|cmd /c ""c:\Program Files\demo1.cmd" & "c:\Program Files\demo2.cmd""|}
  ~helper:"quote_literal_if_needed"
  ~notes:"Keep cmd.exe's doubled double-quotes, then wrap the whole payload in single quotes for VSL."
  quote_literal
```


| Field | Value |
| --- | --- |
| **Scenario** | Literal cmd /c payload with quoted paths |
| **Helper** | `quote_literal_if_needed` |
| **Raw Text** | `cmd /c ""c:\Program Files\demo1.cmd" & "c:\Program Files\demo2.cmd""` |
| **Escaped VSL** | `'cmd /c ""c:\Program Files\demo1.cmd" & "c:\Program Files\demo2.cmd""'` |
| **How To Escape** | Keep cmd.exe's doubled double-quotes, then wrap the whole payload in single quotes for VSL. |
