-- bruno.nvim
-- @author: Jesse Williams

local M = {}
local has_setup_run = false
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
    has_setup_run = true
    setup.setup(opts or {})

    vim.api.nvim_create_autocmd("User", {
        pattern = { "TSUpdateSync", "TSUpdate" },
        callback = function(ev)
            print("in bruno.nvim autocmd from TSUpdate")
            if ev.data == nil or ev.data.lang == "bruno" then
                setup.sync()
            end
        end
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "bruno", "bru" },
        callback = function()
            setup.sync({ skip_if_installed = true })
        end,
        desc = "bruno.nvim: sync after filetype",
    })
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

-- auto-run setup with defaults if it's not been set up by the user
if not has_setup_run then
  M.setup({})
end

return M
