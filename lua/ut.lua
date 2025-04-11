local M = {}

---@param msg string
---@param debug boolean
M.Debug_print = function(msg, debug)
    if debug then
        print(msg)
    end
end

return M
