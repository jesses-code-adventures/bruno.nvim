-- bruno.nvim
-- @author: Jesse Williams

local M = {}
local utils = require("bruno.utils")
local setup = require("bruno.setup")

vim.filetype.add({
    extension = {
        bru = "bruno",
    },
})

---@class bruno.setup.opts?
---@field _local_treesitter_repo_name string?
---@field _treesitter_url string?
---@field _treesitter_files string[]?
---@field _treesitter_author string?
---@field _debug boolean?
---@field _plugin_name string?
---@field _language_name string?
---@field _extension string?

---@param opts bruno.setup.opts?
M.setup = function(opts)
    M.utils = utils
    M.mod_name = "INIT"
    M = utils.Setup_module(M, opts)

    M._print("setting up bruno.nvim")
    M.queries = require("bruno.queries").setup(opts or {})
    setup.setup(opts or {})

    vim.api.nvim_create_autocmd("User", {
        pattern = { "TSUpdateSync", "TSUpdate" },
        callback = function(ev)
            if ev.data == nil or ev.data.lang == "bruno" then
                setup.sync()
            end
        end
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "bru" },
        callback = function()
            setup.sync({ skip_if_installed = true })
        end,
        desc = "bruno.nvim: sync after filetype",
    })

    M._print("finished setting up bruno.nvim")
end

function M.query_current_file()
    M.queries.query_file()
end

M.sync = function()
    setup.sync()
end

M.debug_setup = function()
    setup.debug_state()
end

M.teardown = function()
    setup.teardown()
end

function M.get_dbg()
    return M.dbg
end

function M._print(msg)
    M.utils.Print(M, msg)
end

return M
