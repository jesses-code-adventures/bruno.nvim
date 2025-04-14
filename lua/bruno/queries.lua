local M = {}

---@param prereq string
function M._check_cli_prereq(prereq)
    if not prereq:sub(1, 1) == "!" then
        prereq = "!" .. prereq
    end
    local cmd = prereq:sub(2)
    local handle = io.popen("which " .. cmd)
    if handle == nil then
        vim.notify(M.plugin_name .. " requires " .. cmd .. " to be installed")
        return false
    end
    local result = handle:read("*a")
    handle:close()
    if result == "" then
        vim.notify(M.plugin_name .. " requires " .. cmd .. " to be installed")
        return false
    end
    return true
end

M._verify_prereqs = function()
    vim.schedule(function()
        M._print("verifying prereqs")
        M._check_cli_prereq("!bru")
    end)
end

---@param filepath string
---@return boolean
function M._is_bru_file(filepath)
    local extension = vim.fn.fnamemodify(filepath, ":e")
    if extension ~= "bru" then
        return false
    end
    return true
end

---@param filepath string
function M.set_collection_from_query(filepath)
    local parent = vim.fn.fnamemodify(filepath, ":h")
    while parent ~= "/" do
        M._print("trying to find collection.bru in " .. parent)
        local stat = vim.loop.fs_stat(vim.fs.joinpath(parent, "collection.bru"))
        if stat and stat.type == "file" then
            M._collection_dir = parent
            return
        end
        parent = vim.fn.fnamemodify(parent, ":h")
    end
    error("collection.bru not found")
end

--- query the current file, if it's a .bru file
function M.query_file()
    local current_file = vim.fn.expand("%:p")
    if not M._is_bru_file(current_file) then
        M._print("not a .bru file")
        return
    end

    M.set_collection_from_query(current_file)

    M._create_response_window()
    vim.schedule(function()
        local args = M._cmd_bru_run(current_file)
        M._print("making query from cwd " ..
        M._collection_dir .. " with file " .. current_file .. " and args " .. vim.inspect(args))
        local resp = M.utils.Syscall(args, { cwd = M._collection_dir }, function() end)
        M._render_response(resp)
    end)
end

---@param filepath string can be a .bru file or directory of .bru files
function M._cmd_bru_run(filepath)
    local args = {
        "bru",
        "run",
        filepath,
        "--env",
        M._selected_env_name,
    }
    return args
end

---@param msg string
M._print = function(msg)
    M.utils.Print(M, msg)
end

--- set the current window and buffer for the query
--- @param buf number
--- @param win number
function M._set_response_bufwin(buf, win)
    M._query_buf = buf
    M._query_win = win
end

function M._create_response_window()
    local buf = vim.api.nvim_create_buf(false, true) -- false = listed, true = scratch
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    ---@type vim.api.keyset.win_config
    local win_opts = {
        split = "right",
    }
    local win = vim.api.nvim_open_win(buf, false, win_opts)
    M._set_response_bufwin(buf, win)
end

function M._write_to_locked_buffer(buf, lines)
    vim.bo[buf].modifiable = true
    vim.bo[buf].readonly = false
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
end

function M._render_response(resp)
    local output_string = ""
    if resp.code ~= 0 then
        output_string = output_string ..
        "[FAILED]: Resp code - [" .. resp.code .. "]\n" .. (resp.stderr or "unknown error") .. "\n"
    end
    output_string = output_string .. resp.stdout
    M._write_to_locked_buffer(M._query_buf, vim.split(output_string, "\n"))
end

function M.get_dbg()
    return M.dbg
end

---@param opts bruno.setup.opts
---@return self
function M.setup(opts)
    M.mod_name = "QUERIES"
    M.utils = require("bruno.utils")
    M = M.utils.Setup_module(M, opts)
    M._selected_env_name = opts._selected_env_name or "localdev"

    M._query_args = {}
    M._print("initializing queries")
    M._print("utils ---> " .. vim.inspect(M.utils))
    M.data_dir = vim.fn.stdpath("data")
    M.nvim_config_dir = vim.fn.stdpath("config")
    M.local_treesitter_repo_dir = M.data_dir .. "/" .. (opts._local_treesitter_repo_name or "bruno-treesitter")
    M.plugin_name = opts._plugin_name or "bruno.nvim"
    M.language_name = opts._language_name or "bruno"
    M.extension = opts._extension or "bru"
    M._verify_prereqs()
    return M
end

return M
