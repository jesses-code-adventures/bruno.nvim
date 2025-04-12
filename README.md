# bruno.nvim

Syntax highlighting and filetype injection for `.bru` files in Neovim using [tree-sitter](https://tree-sitter.github.io/tree-sitter/).

## Installation - Lazy

```lua
return { "jesses-code-adventures/bruno.nvim", opts = {}}
```

To install using the original `tree-sitter-bruno` grammar, use the following:

```lua
return {
    "jesses-code-adventures/bruno.nvim",
    opts = {
        _treesitter_repo = "https://github.com/Scalamando/tree-sitter-bruno",
    }
}
```

## What this does

- Clones a repo with a tree-sitter grammar for `.bru` files
- Generates the tree-sitter parser using the tree-sitter cli
- Installs the custom parser using `nvim-treesitter`
- Adds highlight and injection queries to your `/after/queries/bruno` directory

This plugin only exists as `.bru` files are not currently supported by the official `nvim-treesitter` plugin.

By default, it uses a [fork](https://github.com/jesses-code-adventures/tree-sitter-bruno) of [Scalamando](https://github.com/Scalamando)'s [`tree-sitter-bruno`](https://github.com/Scalamando/tree-sitter-bruno) for the tree-sitter grammar. My fork adds support for `params:query` and `params:path` - feel free to use the original if you don't need these, and thanks to Scalamando for the grammar.

## Example

[Screenshot](https://private-user-images.githubusercontent.com/113159758/433022735-6883c242-f07b-48f4-bc1f-fa16dbb52a63.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDQ0NDQ4MDIsIm5iZiI6MTc0NDQ0NDUwMiwicGF0aCI6Ii8xMTMxNTk3NTgvNDMzMDIyNzM1LTY4ODNjMjQyLWYwN2ItNDhmNC1iYzFmLWZhMTZkYmI1MmE2My5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwNDEyJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDQxMlQwNzU1MDJaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yNmZmNTEzMzUzYTU2YTY2MWQ0ZGFmZDEyYWJkMmYwNWI4MDBlYzhhN2FmZTZjOWQ2ZDIzM2U3N2E2OGY2ZjkyJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.5bT1w0OSWGpUYbKt8pP7hr2ycYHrbz3wP27hPeTSA7Y)
