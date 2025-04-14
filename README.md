# bruno.nvim

Syntax highlighting and filetype injection for `.bru` files in Neovim using [tree-sitter](https://tree-sitter.github.io/tree-sitter/).

## Installation - Lazy

```lua
return {
    "jesses-code-adventures/bruno.nvim",
    opts = {},
    keys = {
        { "<leader>r", function() require("bruno").query_current_file(); end, mode = "n", desc = "Test the current query with the results in a scratch buffer." },
    },
    lazy = false,
}
```

To install using the original `tree-sitter-bruno` grammar, use the following:

```lua
return {
    "jesses-code-adventures/bruno.nvim",
    opts = {
        _treesitter_repo = "https://github.com/Scalamando/tree-sitter-bruno",
    },
    lazy = false,
}
```

## What this does

- Clones a repo with a tree-sitter grammar for `.bru` files
- Generates the tree-sitter parser using the tree-sitter cli
- Installs the custom parser using `nvim-treesitter`
- Adds highlight and injection queries to your `/after/queries/bruno` directory

This plugin only exists as `.bru` files are not currently supported by the official `nvim-treesitter` plugin.

By default, it uses a [fork](https://github.com/jesses-code-adventures/tree-sitter-bruno) of [Scalamando](https://github.com/Scalamando)'s [`tree-sitter-bruno`](https://github.com/Scalamando/tree-sitter-bruno) for the tree-sitter grammar. My fork adds support for `params:query` and `params:path` - feel free to use the original if you don't need these, and thanks to Scalamando for the grammar.
