# zed-bloblang

Syntax highlighting for the [Bloblang](https://docs.redpanda.com/connect/guides/bloblang/about/)
language — and for embedded Bloblang inside
[Benthos / Redpanda Connect](https://docs.redpanda.com/connect/components/about) YAML configs — in the
[Zed](https://zed.dev) editor. This is a port of the
[`vscode-benthos`](https://github.com/benthosdev/vscode-benthos) extension.

> Unofficial — not affiliated with or endorsed by Redpanda Data. "Redpanda Connect" and
> "Benthos" are names of their respective projects.

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

The `Bloblang Config` language is applied automatically to files ending in `benthos.yaml`,
`benthos.yml`, `connect.yaml`, or `connect.yml` (so `benthos.yaml`, `my.benthos.yaml`,
`connect.yaml`, etc.).

To treat other YAML files as Benthos / Redpanda Connect configs, add them to your Zed
`settings.json`:

```json
{
  "file_types": {
    "Bloblang Config": ["**/config/*.yaml", "pipeline.yaml"]
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
