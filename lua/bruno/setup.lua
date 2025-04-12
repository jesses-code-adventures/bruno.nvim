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

function M._verify_prereqs()
    vim.schedule(function()
        M._print("verifying prereqs")
        M._check_prereq("nvim-treesitter")
        M._check_prereq("nvim-treesitter.parsers")
        M._check_cli_prereq("!git")
        M._print("verified prereqs")
    end)
end

function M.on_exit(_)
end

function M.debug_state()
    local debug = M.debug
    M.debug = true
    M._print("debug state")
    M._print("plugin_name: " .. M.plugin_name)
    M._print("language_name: " .. M.language_name)
    M._print("extension: " .. M.extension)
    M._print("debug: " .. tostring(M.debug))
    M._print("data_dir: " .. M.data_dir)
    M._print("repo_dir: " .. M.local_treesitter_repo_name)
    M._print("treesitter_author: " .. M.treesitter_author)
    M._print("treesitter_url: " .. M.treesitter_url)
    M.debug = debug
end

function M._sync_repo()
    M.utils.Syscall({ "mkdir", "-p", M.local_treesitter_repo_name }, {}, M.on_exit)
    if vim.fn.isdirectory(M.local_treesitter_repo_name .. "/.git") == 0 then
        M._print("cloning " .. M.treesitter_url .. " to " .. M.local_treesitter_repo_name)
        M.utils.Syscall({ "git", "clone", "--depth", "1", M.treesitter_url, "." }, { cwd = M.local_treesitter_repo_name },
            M.on_exit)
    else
        M._print("pulling from " .. M.treesitter_url)
        M.utils.Syscall({ "git", "-C", M.local_treesitter_repo_name, "pull" }, { cwd = M.local_treesitter_repo_name }, M
            .on_exit)
    end
    if vim.fn.isdirectory(M.local_treesitter_repo_name .. "/queries") == 0 then
        error("queries directory not found in " .. M.local_treesitter_repo_name)
    end
    M.utils.Syscall({ "tree-sitter", "generate" }, { cwd = M.local_treesitter_repo_name }, M.on_exit)
    M.utils.Syscall({ "tree-sitter", "test" }, { cwd = M.local_treesitter_repo_name }, M.on_exit)
end

function M._setup_queries()
    -- TODO: work out how to use a different dir, so the user's config isn't modified
    local target_queries_dir = M.nvim_config_dir .. "/after/queries/bruno"
    M.utils.Syscall({ "mkdir", "-p", target_queries_dir }, {}, M.on_exit)
    local src_queries_dir = M.local_treesitter_repo_name .. "/queries"
    local files = vim.fn.globpath(src_queries_dir, "*", false, true)
    for _, filepath in ipairs(files) do
        M.utils.Syscall({ "cp", filepath, target_queries_dir }, {}, M.on_exit)
    end
    vim.cmd('runtime! after/**/*.vim')
end

function M._clone_and_sync()
    M._print("in clone and sync queries")
    M._sync_repo()
    M._setup_queries()
    M._print("finished clone and sync queries")
end

function M._setup_treesitter()
    M._print("setting up treesitter " .. M.language_name .. " parser")
    M.parsers = require("nvim-treesitter.parsers")

    ---@class parser_configs
    local parser_configs = M.parsers.get_parser_configs() or {}
    parser_configs.bruno = {
        install_info = {
            url = M.local_treesitter_repo_name,
            files = M.treesitter_files,
            author = M.treesitter_author,
        },
        filetype = M.extension,
    }

    vim.treesitter.language.register(M.language_name, M.extension)
    local language_fts = vim.treesitter.language.get_filetypes(M.language_name)
    if #language_fts == 0 then
      vim.cmd("TSInstall " .. M.language_name)
    end
    M._print("finished setting up treesitter " .. M.language_name .. " parser")
end

---@param msg string
M._print = function(msg)
    if M.dbg == nil then
        return
    end
    M.dbg.Print("[SETUP]: " .. msg, M.debug)
end


M._set_nvim_treesitter_dir = function()
    -- check lazy
    local lazy_path = M.data_dir .. "/lazy/nvim-treesitter"
    if vim.fn.isdirectory(lazy_path) == 1 then
        M._print("found treesitter in lazy path: " .. lazy_path)
        M.nvim_treesitter_dir = lazy_path
        return
    end

    -- check pack
    local data_path = M.data_dir .. "/site/pack/*/start/nvim-treesitter"
    local data_matches = vim.fn.glob(data_path, false, true)
    if #data_matches > 0 then
        M._print("found treesitter in data path: " .. data_matches[1])
        M.nvim_treesitter_dir = data_matches[1]
        return
    end

    error("Could not find nvim-treesitter installation")
end

---@param opts bruno.setup.opts
M._init = function(opts)
    M.data_dir = vim.fn.stdpath("data")
    M.nvim_config_dir = vim.fn.stdpath("config")
    M.local_treesitter_repo_name = M.data_dir .. "/" .. (opts._local_treesitter_repo_name or "bruno-treesitter")
    M.plugin_name = opts._plugin_name or "bruno.nvim"
    M.language_name = opts._language_name or "bruno"
    M.extension = opts._extension or "bru"
    M.treesitter_author = opts._treesitter_author or "Scalamando"
    M.treesitter_url = opts._treesitter_url or "https://github.com/jesses-code-adventures/tree-sitter-bruno.git"
    M.treesitter_files = opts._treesitter_files or { "src/parser.c", "src/scanner.c" }
    M._set_nvim_treesitter_dir()
    M.treesitter_parser_file = M.nvim_treesitter_dir .. "/parser/" .. M.language_name .. ".so"
    M.treesitter_parser_info_file = M.nvim_treesitter_dir .. "/parser-info/" .. M.language_name .. ".revision"
end

---@param opts bruno.setup.opts
M.setup = function(opts)
    M.debug = opts._debug or false
    if M.debug then
        M.dbg = require("bruno.debug")
    end
    M._print("initializing variables and verifying prereqs [setup()] in debug mode")

    M.utils = require("bruno.utils")
    M._init(opts)
    M._verify_prereqs()

    M._print("finished initializing variables and verifying prereqs [setup()] in debug mode")
end

---@class bruno.sync.opts?
---@field skip_if_installed boolean?

---@param opts bruno.sync.opts?
M.sync = function(opts)
    local skip_if_installed = opts and opts.skip_if_installed or false
    M._setup_treesitter()
    M._print("In M.sync(), with skip_if_installed: " .. tostring(skip_if_installed))
    M._print("Available parsers: " .. vim.inspect(M.parsers.available_parsers()))
    if M.parsers.has_parser(M.language_name) and skip_if_installed then
        M._print("parser already installed, skipping sync")
        return
    end
    M._print("executing sync() in debug mode")
    M._clone_and_sync()
    M._print("finished executing sync() in debug mode")
end

M.teardown = function()
    if not M.local_treesitter_repo_name or M.local_treesitter_repo_name == "" then
        error("repo_dir is empty or nil, refusing to proceed")
    end

    if not M.nvim_config_dir or M.nvim_config_dir == "" then
        error("config_dir is empty or nil, refusing to proceed")
    end

    vim.cmd("TSUninstall " .. M.language_name)

    if vim.fn.isdirectory(M.local_treesitter_repo_name) == 1 then
        M.utils.Syscall({ "rm", "-rf", M.local_treesitter_repo_name }, {}, M.on_exit)
    end

    local target_queries_file = M.nvim_config_dir .. "/after/queries/bruno"
    if vim.fn.filereadable(target_queries_file) == 1 then
        M.utils.Syscall({ "rm", target_queries_file }, {}, M.on_exit)
    end

    local parser_file = M.nvim_treesitter_dir .. "/parser/" .. M.language_name .. ".so"
    M._print("===== deleting parser file =====: " .. M.treesitter_parser_info_file)

    if vim.fn.filereadable(parser_file) == 1 then
        M.utils.Syscall({ "rm", parser_file }, {}, M.on_exit)
    else
        M._print(M.language_name .. " parser not installed, skipping and continuing teardown")
    end

    M._print("===== deleting parser_info_file =====: " .. M.treesitter_parser_info_file)
    if vim.fn.filereadable(M.treesitter_parser_info_file) == 1 then
        M.utils.Syscall({ "rm", M.treesitter_parser_info_file }, {}, M.on_exit)
    else
        M._print(M.language_name .. " parser-info not installed, skipping and continuing teardown")
    end

    ---@class parser_configs
    local parser_configs = M.parsers.get_parser_configs()
    parser_configs.bruno = nil
    -- M.parsers.list.bruno = nil

    package.loaded["nvim-treesitter"] = nil
    package.loaded["nvim-treesitter.parsers"] = nil
    M.parsers = require("nvim-treesitter.parsers")
end

return M
