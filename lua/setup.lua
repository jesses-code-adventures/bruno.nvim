local M = {}


---@param prereq string
function M._check_prereq(prereq)
    local exists, _ = pcall(require, prereq)
    if not exists then
        vim.notify(M.plugin_name .. " requires " .. prereq .. " to be installed")
        return false
    end
    return true
end


---@param prereq string
function M._check_cli_prereq(prereq)
    if prereq:sub(1, 1) == "!" then
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
    else
        local exists, _ = pcall(require, prereq)
        if not exists then
            vim.notify(M.plugin_name .. " requires " .. prereq .. " to be installed")
            return false
        end
    end
    return true
end


function M.verify_prereqs()
    M._print("verifying prereqs")
    M._check_prereq("nvim-treesitter")
    M._check_prereq("nvim-treesitter.parsers")
    M._check_cli_prereq("git")
    M._print("verified prereqs")
end


function M.on_exit(obj)
   M._print(obj.code)
   M._print(obj.signal)
   M._print(obj.stdout)
   M._print(obj.stderr)
 end

 function M._debug_state()
    M._print("debug state")
    M._print("plugin_name: " .. M.plugin_name)
    M._print("language_name: " .. M.language_name)
    M._print("extension: " .. M.extension)
    M._print("debug: " .. tostring(M.debug))
    M._print("data_dir: " .. M.data_dir)
    M._print("repo_dir: " .. M.repo_dir)
    M._print("treesitter_author: " .. M.treesitter_author)
    M._print("treesitter_url: " .. M.treesitter_url)
 end


-- clones or updates the bruno repo and syncs queries to a canonical location
function M.clone_and_sync()
    M._debug_state()

    M._print("in clone and sync queries")
    vim.system({ "mkdir", "-p", M.repo_dir }, {}, M.on_exit):wait()

    if vim.fn.isdirectory(M.repo_dir .. "/.git") == 0 then
        M._print("cloning " .. M.treesitter_url .. " to " .. M.repo_dir)
        vim.system({ "git", "clone", "--depth", "1", M.treesitter_url, "." }, { cwd = M.repo_dir }, M.on_exit):wait()
    else
        M._print("pulling from " .. M.treesitter_url)
        vim.system({ "git", "-C", M.repo_dir, "pull" }, {cwd = M.repo_dir }, M.on_exit):wait()
    end

    if vim.fn.isdirectory(M.repo_dir .. "/queries") == 0 then
        error("queries directory not found in " .. M.repo_dir)
    end

    vim.system({ "tree-sitter", "generate" }, { cwd = M.repo_dir }, M.on_exit):wait()
    vim.system({ "tree-sitter", "test" }, { cwd = M.repo_dir }, M.on_exit):wait()

    local queries_dir = M.config_dir .. "/after/queries/bruno"
    vim.system({ "mkdir", "-p", queries_dir })
    vim.system({ "cp", "-r", (M.repo_dir .. "/queries/*"), queries_dir })

    vim.opt.runtimepath:append(queries_dir)
    M._print("finished clone and sync queries")
end


function M._treesitter()
    M._print("setting up treesitter " .. M.language_name .. " parser")
    local parsers = require("nvim-treesitter.parsers")

    ---@class parser_configs
    local parser_configs = parsers.get_parser_configs() or {}
    parser_configs.bruno = {
        install_info = {
            url = M.repo_dir,
            files = M.treesitter_files,
            author = M.treesitter_author,
        },
        filetype = M.extension,
    }

    vim.treesitter.language.register(M.language_name, M.extension)
    M._print("finished setting up treesitter " .. M.language_name .. " parser")
end


---@param msg string
M._print = function(msg)
    require("ut").Debug_print("[SETUP]: " .. msg, M.debug)
end


---@param opts bruno.setup.opts
M.run = function(opts)
    M._print("executing run() in debug mode")
    M.plugin_name = opts._plugin_name or "bruno.nvim"
    M.verify_prereqs()
    M.language_name = opts._language_name or "bruno"
    M.extension = opts._extension or "bru"
    M.debug = opts._debug or false
    M.data_dir = vim.fn.stdpath("data")
    M.repo_dir = M.data_dir .. "/" .. (opts._inner_data_dir or "bruno-treesitter")
    M.config_dir = vim.fn.stdpath("config")
    M.treesitter_author = opts._treesitter_author or "Scalamando"
    M.treesitter_url = opts._treesitter_url or "https://github.com/Scalamando/tree-sitter-bruno.git"
    M.treesitter_files = opts._treesitter_files or { "src/parser.c", "src/scanner.c" }
    M.clone_and_sync()
    M._treesitter()
    M._print("finished executing run() in debug mode")
end


return M
