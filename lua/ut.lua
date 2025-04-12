local M = {}

---@param msg string
---@param debug boolean
M.Debug_print = function(msg, debug)
    if debug then
        print(msg)
    end
end

---@param cb function
M.Syscall_must_succeed = function(cb)
    local r = cb()
    if r.code ~= 0 then
        error("command failed: " .. (r.stderr or "unknown error"))
    end
    return r
end

return M
