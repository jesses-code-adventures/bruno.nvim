local M = {}

---@param cb function
function M.Syscall_must_succeed(cb)
    local r = cb()
    if r.code ~= 0 then
        error("command failed: " .. (r.stderr or "unknown error"))
    end
    return r
end

---@param cmd string[]
---@param opts vim.SystemOpts
---@param on_exit function
---@return vim.SystemCompleted
function M.Syscall(cmd, opts, on_exit)
    opts = opts or {}
    opts.cwd = opts.cwd or nil

    local result = vim.system(cmd, opts, on_exit):wait()
    return result
end

---@param mod table
---@param opts bruno.setup.opts?
---@return table
function M.Setup_module(mod, opts)
    mod.debug = opts and (opts._debug or false) or false
    if mod.debug then
        mod.dbg = require("bruno.debug")
    end
    return mod
end

---@param mod table
---@param msg string
function M.Print(mod, msg)
    local mod_name = mod.mod_name or nil
    if mod_name then
        msg = "[" .. mod_name .. "]: " .. msg
    end
    if mod.dbg then
        mod.get_dbg().Print(msg)
    end
end

return M
