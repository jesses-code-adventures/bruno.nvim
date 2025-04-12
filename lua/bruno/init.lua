-- bruno.nvim
-- @author: Jesse Williams

local M = {}
local setup = require("bruno.setup")

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
    setup.setup(opts or {})
    setup.sync({ skip_if_installed = true })

    vim.api.nvim_create_autocmd("User", {
        pattern = { "TSUpdateSync", "TSUpdate" },
        callback = function(ev)
            if ev.data == nil or ev.data.lang == "bruno" then
                setup.sync()
            end
        end
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

return M
