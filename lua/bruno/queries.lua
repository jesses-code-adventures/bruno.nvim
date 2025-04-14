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

---@param dir string
function M._set_collection_dir(dir)
    M._collection_dir = dir
    -- TODO: remove this
    M._sync_environment()
end

---@param filepath string
function M.set_collection_from_query(filepath)
    local parent = vim.fn.fnamemodify(filepath, ":h")
    while parent ~= "/" do
        M._print("trying to find collection.bru in " .. parent)
        local stat = vim.loop.fs_stat(vim.fs.joinpath(parent, "collection.bru"))
        if stat and stat.type == "file" then
            M._set_collection_dir(parent)
            return
        end
        parent = vim.fn.fnamemodify(parent, ":h")
    end
    error("collection.bru not found")
end

function M.query_file()
    local current_file = vim.fn.expand("%:p")
    if not M._is_bru_file(current_file) then
        M._print("not a .bru file")
        return
    end

    M.set_collection_from_query(current_file)

    if not M._query_win or not vim.api.nvim_win_is_valid(M._query_win) then
        M._create_response_window()
    end

    local file_contents = M.parser.parse_bru_content(vim.fn.readfile(current_file))
    local args = M.parser.generate_curl_command(file_contents)
    M._print("making query from cwd " ..
        M._collection_dir .. " with file " .. current_file .. " and args " .. vim.inspect(args))
    vim.schedule(function()
        local resp = M.utils.Syscall(args, { cwd = M._collection_dir }, function() end)
        M._render_response(resp)
    end)
end

--- query the current file, if it's a .bru file
function M.bru_run_file()
    local current_file = vim.fn.expand("%:p")
    if not M._is_bru_file(current_file) then
        M._print("not a .bru file")
        return
    end

    M.set_collection_from_query(current_file)

    if not M._query_win or not vim.api.nvim_win_is_valid(M._query_win) then
        M._create_response_window()
    end
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

function M._create_response_window()
    if not (M._query_buf and vim.api.nvim_buf_is_valid(M._query_buf)) then
        local buf = vim.api.nvim_create_buf(false, true) -- false = listed, true = scratch
        vim.bo[buf].modifiable = false
        vim.bo[buf].readonly = true
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        M._query_buf = buf
    end

    ---@type vim.api.keyset.win_config
    local win_opts = {
        split = "right",
    }
    local win = vim.api.nvim_open_win(M._query_buf, false, win_opts)
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    M._query_win = win
end

function M._write_to_response_window(lines)
    if not (M._query_buf and vim.api.nvim_buf_is_valid(M._query_buf)) then
        return
    end
    vim.bo[M._query_buf].modifiable = true
    vim.bo[M._query_buf].readonly = false
    vim.api.nvim_buf_set_lines(M._query_buf, 0, -1, false, lines)
    vim.bo[M._query_buf].readonly = true
    vim.bo[M._query_buf].modifiable = false
end

function M._render_response(resp)
    local output_string = ""
    if resp.code ~= 0 then
        output_string = output_string ..
            "[FAILED]: Resp code - [" .. resp.code .. "]\n" .. (resp.stderr or "unknown error") .. "\n"
    end
    output_string = output_string .. resp.stdout
    M._write_to_response_window({})
    M._write_to_response_window(vim.split(output_string, "\n"))
end

---@param url string
---@return string
function M.format_url(url)
    local resp = url:gsub("{{(.-)}}", function(key)
        return M._selected_env_variables[key] or error("missing var: " .. key)
    end)
    return resp
end

function M.get_dbg()
    return M.dbg
end

---@return string[]
function M.get_environments()
    if not M._collection_dir then
        M._print("collection_dir not set")
        return {}
    end
    local envs = M.utils.Syscall({ "ls", "environments" }, { cwd = M._collection_dir }, function() end)
    if envs.code ~= 0 then
        M._print("error getting environments")
        return {}
    end
    local env_list = {}
    for env in string.gmatch(envs.stdout, "[^\r\n]+") do
        table.insert(env_list, env)
    end
    return env_list
end

function M._set_environment(env)
    M._selected_env_name = env
    M._sync_environment()
end

function M._sync_environment()
    if not M._collection_dir then
        M._print("collection_dir not set")
        return
    end
    M._print("syncing environment " .. M._selected_env_name)
    local env = M._selected_env_name
    local env_file = vim.fs.joinpath(M._collection_dir, "environments", env .. ".bru")
    if not vim.loop.fs_stat(env_file) then
        M._print("environment file " .. env_file .. " does not exist")
        return
    end
    M._selected_env_variables = M.parser.parse_bru_environment_vars(env_file)
end

function M._debug_queries()
    M._print("selected env: " .. M._selected_env_name)
    M._print("selected env variables: " .. vim.inspect(M._selected_env_variables))
    M._print("collection dir: " .. (M._collection_dir or ""))
    M._print("query args: " .. vim.inspect(M._query_args))
    M._print("query win: " .. vim.inspect(M._query_win))
    M._print("response win: " .. vim.inspect(M._response_win))
    M._print("response buf: " .. vim.inspect(M._response_buf))
    if not M._response_buf then
        M._print("response buf not set")
        return
    end
    M._print("response buf lines: " .. vim.inspect(vim.api.nvim_buf_get_lines(M._response_buf, 0, -1, false)))
end

---@param opts bruno.setup.opts
---@return self
function M.setup(opts)
    M.mod_name = "QUERIES"
    M.utils = require("bruno.utils")
    M = M.utils.Setup_module(M, opts)

    M.parser = require("bruno.parser").setup(opts, M.format_url)
    M._set_environment(opts._selected_env_name or "localdev")

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
