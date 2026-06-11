# zed-benthos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Zed extension that provides syntax highlighting for Bloblang `.blobl` files and for Bloblang `#!blobl` mapping blocks embedded in Benthos/Redpanda Connect YAML configs.

**Architecture:** A standard Zed language extension. `extension.toml` registers two pinned Tree-sitter grammars (Bloblang + YAML). Two languages are auto-discovered from `languages/*/config.toml`: `Bloblang` (`.blobl` files) and `Benthos` (Benthos config filenames, using the YAML grammar plus an `injections.scm` that embeds Bloblang into `#!blobl` block scalars).

**Tech Stack:** Zed extension manifest (TOML), Tree-sitter grammars (`EmilLaursen/tree-sitter-bloblang`, `tree-sitter-grammars/tree-sitter-yaml`), Tree-sitter query files (`.scm`).

---

## Notes on verification

Zed extensions have **no automated unit-test harness for queries**. Verification in this plan is therefore two-layered:

- **Structural checks** after each file: TOML parses (`python3 -c "import tomllib; tomllib.load(open(f,'rb'))"`), and `.scm` files have balanced parentheses (`python3` one-liner provided in Task steps).
- **Functional check** (Task 7): install as a Zed dev extension and eyeball the example fixtures.

There is no TDD red/green cycle here because there is no code to assert against — the artifacts are declarative config + queries. Each task creates a file, runs the structural check, and commits.

## Scope decision baked into this plan

`${! … }` **interpolation** highlighting from the VS Code extension is **NOT implemented**. tree-sitter-yaml treats a scalar as one opaque string and cannot inject a substring; injecting the whole scalar would hand the `${!`/`}` delimiters to the Bloblang parser, which rejects them. Only the `#!blobl` block-scalar injection is implemented. This is documented as a known limitation in the README (Task 6).

## File Structure

```
zed-benthos/
  extension.toml                 # Task 1 — manifest + grammar pins
  LICENSE                        # Task 1
  .gitignore                     # Task 1
  languages/
    bloblang/
      config.toml                # Task 2
      highlights.scm             # Task 2 — copied from upstream
    benthos/
      config.toml                # Task 3
      highlights.scm             # Task 3 — YAML highlighting
      injections.scm             # Task 4 — #!blobl injection
  examples/
    sample.blobl                 # Task 5
    benthos.yaml                 # Task 5
  README.md                      # Task 1 (skeleton), Task 6 (final)
```

---

### Task 1: Repository scaffolding and manifest

**Files:**
- Create: `extension.toml`
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `README.md` (skeleton; finalized in Task 6)

- [ ] **Step 1: Write `extension.toml`**

```toml
id = "benthos"
name = "Benthos"
description = "Syntax highlighting for Benthos / Redpanda Connect and the Bloblang language."
version = "0.1.0"
schema_version = 1
authors = ["Tiago Peczenyj <tpeczenyj@weborama.com>"]
repository = "https://github.com/tpeczenyj/zed-benthos"

[grammars.bloblang]
repository = "https://github.com/EmilLaursen/tree-sitter-bloblang"
rev = "5b34098ec446caadcec0bf667bade2b8551ecb21"

[grammars.benthos_yaml]
repository = "https://github.com/tree-sitter-grammars/tree-sitter-yaml"
rev = "a1c4812a73ec5e089de8e441fdea3a921e8d5079"
```

- [ ] **Step 2: Write `.gitignore`**

```gitignore
# Zed extension build artifacts
grammars/
*.wasm
target/
```

- [ ] **Step 3: Write `LICENSE` (MIT)**

```
MIT License

Copyright (c) 2026 Tiago Peczenyj

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Write `README.md` skeleton (placeholder line, finalized in Task 6)**

```markdown
# zed-benthos

Benthos / Redpanda Connect and Bloblang support for the Zed editor.
```

- [ ] **Step 5: Verify `extension.toml` parses**

Run: `python3 -c "import tomllib; tomllib.load(open('extension.toml','rb')); print('ok')"`
Expected: `ok`

- [ ] **Step 6: Commit**

```bash
git add extension.toml LICENSE .gitignore README.md
git commit -m "Add extension manifest, license, and scaffolding"
```

---

### Task 2: Bloblang language (`.blobl` files)

**Files:**
- Create: `languages/bloblang/config.toml`
- Create: `languages/bloblang/highlights.scm`

- [ ] **Step 1: Write `languages/bloblang/config.toml`**

```toml
name = "Bloblang"
grammar = "bloblang"
path_suffixes = ["blobl"]
line_comments = ["# "]
autoclose_before = ",)]}"
brackets = [
  { start = "{", end = "}", close = true, newline = true },
  { start = "[", end = "]", close = true, newline = true },
  { start = "(", end = ")", close = true, newline = true },
  { start = "\"", end = "\"", close = true, newline = false },
  { start = "'", end = "'", close = true, newline = false },
]
```

- [ ] **Step 2: Write `languages/bloblang/highlights.scm`** (copied verbatim from the upstream grammar's `queries/highlights.scm`; all captures are Zed-supported)

```scheme
; keywords
[
  "map"
  "match"
  "if"
  "else"
  "import"
  "let"
  "meta"
  ( root )
  ( this )
] @keyword

; operators
[
  "-"
  "!"
  "!="
  "*"
  "/"
  "&&"
  "%"
  "+"
  "->"
  "<"
  "<="
  "=>"
  "="
  "=="
  ">"
  ">="
  "|"
  "||"
] @operator

; identifiers
(variable) @variable
(pathSegment) @property

; function and method calls

(functionExpression name: (functionName) @function)
((argName) @variable.parameter)

[
  ","
  "."
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

; literals

; must go before the string query below
((object key: ((_) @property)))

[
 (tripleQuotedString)
 (quotedString)
] @string

(number) @number

[
 (bool)
 (null)
] @constant.builtin


(comment) @comment
```

- [ ] **Step 3: Verify the config parses and the query has balanced parens**

Run:
```bash
python3 -c "import tomllib; tomllib.load(open('languages/bloblang/config.toml','rb')); print('toml ok')"
python3 -c "s=open('languages/bloblang/highlights.scm').read(); assert s.count('(')==s.count(')'), 'unbalanced parens'; print('scm ok')"
```
Expected: `toml ok` then `scm ok`

- [ ] **Step 4: Commit**

```bash
git add languages/bloblang/config.toml languages/bloblang/highlights.scm
git commit -m "Add Bloblang language for .blobl files"
```

---

### Task 3: Benthos language config and YAML highlighting

**Files:**
- Create: `languages/benthos/config.toml`
- Create: `languages/benthos/highlights.scm`

- [ ] **Step 1: Write `languages/benthos/config.toml`** (`path_suffixes` match the end of the file path, so `benthos.yaml` also covers `*.benthos.yaml`)

```toml
name = "Benthos"
grammar = "benthos_yaml"
path_suffixes = ["benthos.yaml", "benthos.yml", "connect.yaml", "connect.yml"]
line_comments = ["# "]
tab_size = 2
hard_tabs = false
brackets = [
  { start = "{", end = "}", close = true, newline = true },
  { start = "[", end = "]", close = true, newline = true },
  { start = "\"", end = "\"", close = true, newline = false },
  { start = "'", end = "'", close = true, newline = false },
]
```

- [ ] **Step 2: Write `languages/benthos/highlights.scm`** (standard tree-sitter-yaml highlighting; unknown captures like `@label`/`@attribute` are harmless — Zed ignores captures it has no theme entry for)

```scheme
(boolean_scalar) @boolean

(null_scalar) @constant.builtin

[
  (double_quote_scalar)
  (single_quote_scalar)
  (block_scalar)
  (string_scalar)
] @string

[
  (integer_scalar)
  (float_scalar)
] @number

(comment) @comment

[
  (anchor_name)
  (alias_name)
] @label

(tag) @type

[
  (yaml_directive)
  (tag_directive)
  (reserved_directive)
] @attribute

(block_mapping_pair
  key: (flow_node
    [
      (double_quote_scalar)
      (single_quote_scalar)
    ] @property))

(block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @property)))

(flow_mapping
  (_
    key: (flow_node
      [
        (double_quote_scalar)
        (single_quote_scalar)
      ] @property)))

(flow_mapping
  (_
    key: (flow_node
      (plain_scalar
        (string_scalar) @property))))

[
  ","
  "-"
  ":"
  ">"
  "?"
  "|"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "*"
  "&"
  "---"
  "..."
] @punctuation.special
```

- [ ] **Step 3: Verify**

Run:
```bash
python3 -c "import tomllib; tomllib.load(open('languages/benthos/config.toml','rb')); print('toml ok')"
python3 -c "s=open('languages/benthos/highlights.scm').read(); assert s.count('(')==s.count(')'), 'unbalanced parens'; print('scm ok')"
```
Expected: `toml ok` then `scm ok`

- [ ] **Step 4: Commit**

```bash
git add languages/benthos/config.toml languages/benthos/highlights.scm
git commit -m "Add Benthos language with YAML highlighting"
```

---

### Task 4: Bloblang injection into `#!blobl` block scalars

**Files:**
- Create: `languages/benthos/injections.scm`

- [ ] **Step 1: Write `languages/benthos/injections.scm`**

A YAML `block_scalar` node's text includes the block indicator and all content lines. We inject the whole node as Bloblang when its content starts (after the `|`/`>` indicator and newline) with the `#!blobl` pragma. The regex tolerates the indicator chars (`|`, `>`, `-`, `+`, digits) and leading whitespace before the pragma.

```scheme
; Inject Bloblang into YAML block scalars that open with the #!blobl pragma,
; e.g.  mapping: |
;          #!blobl
;          root.foo = this.bar
(
  (block_scalar) @injection.content
  (#match? @injection.content "^[|>][-+0-9]*\\s*\\n\\s*#!\\s*blobl")
  (#set! injection.language "bloblang")
)
```

- [ ] **Step 2: Verify balanced parens**

Run: `python3 -c "s=open('languages/benthos/injections.scm').read(); assert s.count('(')==s.count(')'), 'unbalanced parens'; print('scm ok')"`
Expected: `scm ok`

- [ ] **Step 3: Commit**

```bash
git add languages/benthos/injections.scm
git commit -m "Inject Bloblang into #!blobl YAML block scalars"
```

---

### Task 5: Example fixtures for manual verification

**Files:**
- Create: `examples/sample.blobl`
- Create: `examples/benthos.yaml`

- [ ] **Step 1: Write `examples/sample.blobl`**

```blobl
# Example Bloblang mapping
map process_pet {
  root.name = this.
    (fullName | nickName).
    not_empty().
    catch(err -> "failed to get pet name: %s".format(err))

  root.sound = if this.type == "cat" {
    this.cat.meow
  } else if this.type == "dog" {
    this.dog.woof.uppercase()
  } else {
    "sweet sweet silence"
  }
}

let count = 1 + 2
root = this.apply("process_pet")
root.meta_value = meta("example")
```

- [ ] **Step 2: Write `examples/benthos.yaml`** (mirrors the VS Code README; the `mapping` block carries the `#!blobl` pragma)

```yaml
pipeline:
  processors:
    - mapping: |
        #!blobl
        root.name = this.
          (fullName | nickName).
          not_empty().
          catch(err -> "failed to get pet name: %s".format(err))

        root.sound = if this.type == "cat" {
          this.cat.meow
        } else if this.type == "dog" {
          this.dog.woof.uppercase()
        } else {
          "sweet sweet silence"
        }
    - log:
        level: ${LOG_LEVEL:INFO}
        message: '${! this.name } sounds like ${! this.sound.or("nothing") }'
```

- [ ] **Step 3: Verify the YAML fixture is well-formed**

Run: `python3 -c "import yaml; yaml.safe_load(open('examples/benthos.yaml')); print('yaml ok')" 2>/dev/null || echo "pyyaml not installed — skip (fixture validity confirmed visually)"`
Expected: `yaml ok` (or the skip message)

- [ ] **Step 4: Commit**

```bash
git add examples/sample.blobl examples/benthos.yaml
git commit -m "Add example fixtures for manual verification"
```

---

### Task 6: Finalize README

**Files:**
- Modify: `README.md` (replace the skeleton from Task 1)

- [ ] **Step 1: Overwrite `README.md`**

````markdown
# zed-benthos

Syntax highlighting for [Benthos / Redpanda Connect](https://www.benthos.dev/) and
the [Bloblang](https://www.benthos.dev/docs/guides/bloblang/about) language in the
[Zed](https://zed.dev) editor. This is a port of the
[`vscode-benthos`](https://github.com/benthosdev/vscode-benthos) extension.

## Features

- **Bloblang files** (`.blobl`): full syntax highlighting.
- **Benthos YAML configs**: YAML highlighting plus embedded Bloblang highlighting for
  `mapping`-style blocks that begin with the `#!blobl` pragma.

## Bloblang in YAML

Bloblang highlighting inside YAML is enabled for block scalars whose first line is the
`#!blobl` pragma:

```yaml
pipeline:
  processors:
    - mapping: |
        #!blobl
        root.name = this.name.uppercase()
```

## File associations

The `Benthos` language is applied automatically to files ending in `benthos.yaml`,
`benthos.yml`, `connect.yaml`, or `connect.yml` (so `benthos.yaml`, `my.benthos.yaml`,
`connect.yaml`, etc.).

To treat other YAML files as Benthos configs, add them to your Zed `settings.json`:

```json
{
  "file_types": {
    "Benthos": ["**/config/*.yaml", "pipeline.yaml"]
  }
}
```

## Known limitations

- **Interpolation highlighting is not supported.** The VS Code extension highlights
  Bloblang inside `${! … }` interpolations. Zed's Tree-sitter model injects whole nodes,
  not substrings, and cannot extract the expression out of a surrounding YAML string, so
  interpolations are left with plain YAML string highlighting.
- **YAML highlighting is opt-in by file association**, not applied to every `.yaml` file
  (unlike the VS Code extension, which injects into all YAML globally).
- Highlighting only — no language server, diagnostics, completion, or formatting.

## Installing as a dev extension

1. Clone this repository.
2. In Zed, open the command palette and run `zed: install dev extension`.
3. Select this directory.

## Credits

- Bloblang Tree-sitter grammar: [EmilLaursen/tree-sitter-bloblang](https://github.com/EmilLaursen/tree-sitter-bloblang)
- YAML Tree-sitter grammar: [tree-sitter-grammars/tree-sitter-yaml](https://github.com/tree-sitter-grammars/tree-sitter-yaml)
- Original VS Code extension: [benthosdev/vscode-benthos](https://github.com/benthosdev/vscode-benthos)

## License

MIT
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "Finalize README with usage, file associations, and limitations"
```

---

### Task 7: Functional verification in Zed (manual)

**Files:** none (verification only)

- [ ] **Step 1: Install the dev extension**

In Zed: command palette → `zed: install dev extension` → select `/home/tiago/work/vscode/zed-benthos`. Confirm it builds both grammars without error (watch the Zed log: `zed: open log`).

- [ ] **Step 2: Verify `.blobl` highlighting**

Open `examples/sample.blobl`. Confirm:
- `map`, `if`, `else`, `let`, `root`, `this`, `meta` are highlighted as keywords.
- Function calls (`not_empty`, `catch`, `uppercase`, `format`, `apply`) are highlighted as functions.
- Strings, the `1`/`2` numbers, and the `#` comment are highlighted.

- [ ] **Step 3: Verify Benthos YAML + injection**

Open `examples/benthos.yaml`. Confirm:
- The file is detected as the `Benthos` language (shown in the status bar).
- YAML keys/strings/comments are highlighted.
- Inside the `mapping: |` block (after `#!blobl`), Bloblang highlighting applies — keywords (`if`/`else`), functions, and strings light up the same as in the `.blobl` file.
- The `log` block's `${! … }` interpolations are *not* Bloblang-highlighted (documented limitation).

- [ ] **Step 4: If the injection does not trigger**

The `#match?` regex in `languages/benthos/injections.scm` depends on the exact text span of the `block_scalar` node. If injection does not fire, inspect the node text with Zed's `editor: open syntax tree view` (or `tree-sitter` CLI against the fixture) and adjust the regex anchor accordingly, then re-run `zed: reload extensions` and re-verify. Commit any fix:

```bash
git add languages/benthos/injections.scm
git commit -m "Fix #!blobl injection regex to match block_scalar node text"
```

---

## Self-Review

**Spec coverage:**
- `.blobl` highlighting → Task 2. ✓
- Benthos YAML highlighting → Task 3. ✓
- `#!blobl` mapping injection → Task 4. ✓
- `${! }` interpolation → intentionally dropped (tree-sitter cannot inject substrings); documented in Task 6 + plan scope note. **This narrows the spec's "best-effort interpolation" limitation to "not supported" — flagged to the user for spec update.**
- Grammar pins → Task 1 (both revs from `git ls-remote`). ✓
- File-association strategy (claim filenames + `file_types` opt-in) → Task 3 config + Task 6 README. ✓
- Example fixtures + manual test strategy → Tasks 5 and 7. ✓

**Placeholder scan:** README skeleton in Task 1 is explicitly replaced in Task 6; no other placeholders. Every file step contains complete content.

**Type/name consistency:** grammar ids `bloblang` and `benthos_yaml` are used identically in `extension.toml` (Task 1) and the two `config.toml` files (Tasks 2, 3). Language names `Bloblang`/`Benthos` consistent across config and README.
