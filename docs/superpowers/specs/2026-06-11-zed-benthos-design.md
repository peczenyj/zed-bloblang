# zed-benthos — Design

Date: 2026-06-11

## Goal

Port the [`vscode-benthos`](https://github.com/benthosdev/vscode-benthos) extension's
syntax highlighting to [Zed](https://zed.dev). Provide:

1. Syntax highlighting for standalone Bloblang files (`.blobl`).
2. Bloblang highlighting embedded inside Benthos/Redpanda Connect YAML config files —
   both `${! … }` interpolations and `#!blobl` mapping blocks.

No language server, diagnostics, completion, or formatting. Highlighting only, matching
the scope of the source VS Code extension.

## Key constraint: Zed uses Tree-sitter, not TextMate

The VS Code extension is built on TextMate grammars (`.tmLanguage.json`) and injects
Bloblang into the global `source.yaml` scope, so it lights up *every* YAML file
automatically. Zed has no TextMate support — highlighting and injection are driven by
Tree-sitter grammars plus `.scm` query files. Two consequences:

- We need a Tree-sitter grammar for Bloblang. One exists:
  [`EmilLaursen/tree-sitter-bloblang`](https://github.com/EmilLaursen/tree-sitter-bloblang).
  We reuse it, pinned to a commit (we do not control it; pin protects us from breakage).
- A third-party extension cannot cleanly augment the **built-in** YAML language's
  injection queries. So the YAML feature is delivered as a **separate `Benthos` language**
  that pairs a YAML grammar with our own injection queries, applied only to Benthos config
  files (not all `.yaml`).

## Architecture

A standard Zed language extension:

```
zed-benthos/
  extension.toml                 # manifest: 2 grammars, 2 languages
  languages/
    bloblang/
      config.toml                # .blobl files
      highlights.scm             # adapted from EmilLaursen's queries
    benthos/
      config.toml                # benthos.yaml, connect.yaml, *.benthos.yaml
      highlights.scm             # YAML highlighting
      injections.scm             # inject bloblang into YAML
  examples/
    sample.blobl                 # mirrors README mapping example
    benthos.yaml                 # mirrors README config example
  README.md
  LICENSE
```

### Grammars (registered in `extension.toml`, pinned)

| Grammar id | Repository | Pinned rev |
|---|---|---|
| `bloblang` | `https://github.com/EmilLaursen/tree-sitter-bloblang` | `5b34098ec446caadcec0bf667bade2b8551ecb21` |
| `benthos_yaml` | `https://github.com/tree-sitter-grammars/tree-sitter-yaml` | `a1c4812a73ec5e089de8e441fdea3a921e8d5079` |

(Revs are current HEADs as of 2026-06-11; verified via `git ls-remote`.)

### Language 1 — Bloblang

`languages/bloblang/config.toml`:
- `name = "Bloblang"`, `grammar = "bloblang"`
- `path_suffixes = ["blobl"]`
- `line_comments = ["# "]`
- brackets / autoclose pairs mirrored from the VS Code `language-configuration.json`
  (`{}`, `[]`, `()`, `""`, `''`).

`highlights.scm`: adapted from EmilLaursen's `queries/highlights.scm`. Its captures are all
standard Tree-sitter names that Zed supports directly: `@keyword`, `@operator`,
`@variable`, `@property`, `@function`, `@variable.parameter`, `@punctuation.delimiter`,
`@punctuation.bracket`, `@string`, `@number`, `@constant.builtin`, `@comment`. Adaptation
is expected to be light (drop/rename anything Zed does not recognize).

### Language 2 — Benthos

`languages/benthos/config.toml`:
- `name = "Benthos"`, `grammar = "benthos_yaml"`
- claims Benthos config filenames by default so highlighting is automatic for common cases
  without hijacking plain YAML. Default associations: `benthos.yaml`, `connect.yaml`, and
  the suffix `*.benthos.yaml`. Users associate additional files via Zed's `file_types`
  setting (documented in the README).
- `line_comments = ["# "]`, YAML-style brackets.

`highlights.scm`: YAML syntax highlighting (sourced from the standard tree-sitter-yaml /
Zed YAML queries, kept minimal).

`injections.scm`: the embedding logic.
- **Mapping blocks (`#!blobl`)**: a YAML block scalar whose content begins with the
  `#!blobl` pragma is injected wholesale as `bloblang`. Tree-sitter injects a whole node,
  which fits this case exactly — the entire block scalar *is* Bloblang. Gated with a
  `#match?` predicate on the leading `#!blobl`.
- **Interpolations (`${! … }`)**: injected best-effort. See limitations.

### Examples / manual test fixtures

`examples/sample.blobl` and `examples/benthos.yaml` reproduce the README snippets from the
VS Code extension so highlighting can be eyeballed after `zed: install dev extension`.

## Known limitations (documented in README)

1. **Interpolation highlighting is best-effort.** Tree-sitter injects a *whole node* as
   another language; it cannot inject just the `${! … }` substring out of a larger YAML
   scalar like `'${! this.name } sounds like ${! this.sound }'`. The VS Code TextMate
   grammar can match arbitrary substrings; Zed cannot. We inject Bloblang for scalars that
   are *entirely* an interpolation where feasible, and otherwise leave the surrounding YAML
   string highlighting intact rather than mis-highlighting literal text. Exact behavior is
   pinned down during implementation against the tree-sitter-yaml node types.
2. **YAML highlighting is opt-in by file association**, not global. It applies to the
   default Benthos filenames plus whatever the user adds via `file_types`. It does not
   light up every `.yaml` file the way the VS Code extension does.
3. **No language server** — highlighting only, by design.

## Testing strategy

Zed extensions have no unit-test harness for queries. Verification is:
- The upstream grammar carries its own corpus tests (not our concern).
- Manual: install as a dev extension (`zed: install dev extension`), open
  `examples/sample.blobl` and `examples/benthos.yaml`, and confirm highlighting matches the
  VS Code screenshots — `.blobl` keywords/strings/functions, the `#!blobl` block, and
  interpolations.

## Out of scope

- Language server / diagnostics / completion / formatting.
- Bloblang execution or evaluation.
- Modifying or replacing Zed's built-in YAML language for non-Benthos files.
