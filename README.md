# bruno.nvim

This plugin automates the following process for `.bru` files:

- Cloning a repo with a treesitter grammar
- Generating the tree-sitter parser
- Installing the custom parser in tree-sitter
- Adding the highlight and injection queries to your `/after/queries/bruno` directory

It only exists as `.bru` files are not supported by the official `nvim-treesitter` plugin.

By default, it uses a [fork](https://github.com/jesses-code-adventures/tree-sitter-bruno) of [Scalamando](https://github.com/Scalamando)'s [`tree-sitter-bruno`](https://github.com/Scalamando/tree-sitter-bruno) for the tree-sitter grammar. My fork adds support for `params:query` and `params:path` - feel free to use the original if you don't need these, and thanks to Scalamando for the grammar.

## Installation - Lazy

```lua
return {
    "jesses-code-adventures/bruno.nvim"
}
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
