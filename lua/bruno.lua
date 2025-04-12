local M = {}


---@class bruno.setup.opts?
---@field _inner_data_dir string?
---@field _treesitter_url string?
---@field _treesitter_files string[]?
---@field _treesitter_author string?
---@field _debug boolean?
---@field _plugin_name string?
---@field _language_name string?
---@field _extension string?


---@param opts bruno.setup.opts?
M.setup = function(opts)
    require("setup").run(opts or {})
end


M.sync = function()
    require("setup").sync()
end


return M
