local M = {}


---@param cb function
M.Syscall_must_succeed = function(cb)
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
M.Syscall = function(cmd, opts, on_exit)
    opts = opts or {}
    opts.cwd = opts.cwd or nil

    local result = vim.system(cmd, opts, on_exit):wait()
    if result.code ~= 0 then
        error(string.format("Command failed: %s (exit code: %d)", table.concat(cmd, " "), result.code))
    end

    return result
end


return M
