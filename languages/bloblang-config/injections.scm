; Inject Bloblang into YAML block scalars that open with the #!blobl pragma,
; e.g.  mapping: |
;          #!blobl
;          root.foo = this.bar
(
  (block_scalar) @injection.content
  (#match? @injection.content "^[|>][-+0-9]*\\s*\\n\\s*#!\\s*blobl")
  (#set! injection.language "bloblang")
)
