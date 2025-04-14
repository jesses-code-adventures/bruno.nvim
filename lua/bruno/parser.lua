local M = {}

---@class bruno.parser.dictionary_entry
---@field key string
---@field value string
---@field disabled boolean

---@class bruno.parser.array_entry
---@field value string
---@field disabled boolean

---@class bruno.parser.request
---@field method string
---@field url string
---@field body string?
---@field auth string?

--- actual bruno types

---@class bruno.parser.meta
---@field name string
---@field type string?
---@field seq number -- sort order

---@class bruno.parser.bru_file_contents
---@field meta bruno.parser.meta?
---@field get bruno.parser.request?
---@field post bruno.parser.request?
---@field put bruno.parser.request?
---@field delete bruno.parser.request?
---@field options bruno.parser.request?
---@field trace bruno.parser.request?
---@field connect bruno.parser.request?
---@field head bruno.parser.request?
---@field query bruno.parser.dictionary_entry[]? params:query
---@field path bruno.parser.dictionary_entry[]? params:path
---@field headers bruno.parser.dictionary_entry[]?
---@field body table?
---@field body_text string? treat as text
---@field body_xml table?
---@field body_form-urlencoded bruno.parser.dictionary_entry[]?
---@field body_multipart-form-data bruno.parser.dictionary_entry[]?
---@field body_graphql table?
---@field body_graphql_vars table?
---@field script_pre-request string? -- javascript
---@field script_post-post-response string? -- javascript
---@field test string? -- test

local test_data = [[
    meta {
      name: Create a magic link
      type: http
      seq: 4
    }

    post {
      url: {{baseUrl}}/api/v3/{{id}}/link
      body: none
      auth: none
    }

    params:query {
      ~destination_url:
    }

    params:path {
      firm_id:
    }


    tests {
      test("status must be 200", function() {
          expect(res.status).to.eql(200);
      });

      test("expiry time is valid", function() {
        // Check that property exists and is not empty
      });

      test("url is properly formatted", function() {
        expect(res.body).to.have.property('url').that.is.not.empty;
      });
    }
]]

---@param content string[]
---@return bruno.parser.bru_file_contents
function M.parse_bru_content(content)
    -- TODO: reimplement this using treesitter

    ---@type bruno.parser.bru_file_contents
    local result = {}
    local current_block = nil

    for _, line in ipairs(content) do
        line = line:match("^%s*(.-)%s*$") -- trim

        if line == "" then goto continue end

        if line == "}" then
            current_block = nil
            goto continue
        end

        local block = line:match("^(%w+)%:?%w*%s*%{$")
        if block and block ~= "tests" then
            current_block = block
            result[current_block] = result[current_block] or {}
            goto continue
        elseif block == "tests" then
            current_block = "skip"
            goto continue
        end

        -- key: value
        if current_block and current_block ~= "skip" then
            local k, v = line:match("^(.-):%s*(.-)%s*$")
            if k and v then
                result[current_block][k] = v
            end
        end

        ::continue::
    end

    return result
end

function M.get_dbg()
    return M.dbg
end

function M._print(msg)
    M.utils.Print(M, msg)
end

---@param bru_file bruno.parser.bru_file_contents
---@return string[]
function M.generate_curl_command(bru_file)
    local args = { "curl" }

    -- method
    local method = bru_file.get and "get" or bru_file.post and "post" or bru_file.put and "put" or
    bru_file.delete and "delete" or bru_file.options and "options" or bru_file.head and "head" or "get"
    table.insert(args, "-X")
    table.insert(args, method:upper())

    -- headers
    if bru_file.headers then
        for _, header in ipairs(bru_file.headers) do
            if not header.disabled then
                table.insert(args, "-H")
                table.insert(args, header.key .. ": " .. header.value)
            end
        end
    end

    -- url and query params
    local url = bru_file[method] and bru_file[method].url or ""
    url = M.format_url(url)
    if bru_file.query then
        local query_params = {}
        for _, param in ipairs(bru_file.query) do
            if not param.disabled then
                table.insert(query_params, param.key .. "=" .. param.value)
            end
        end
        if #query_params > 0 then
            url = url .. "?" .. table.concat(query_params, "&")
        end
    end
    table.insert(args, url)

    -- body
    if bru_file.post and bru_file.post.body or bru_file.put and bru_file.put.body then
        local content_type = ""
        local data = ""

        if bru_file["body_form-urlencoded"] then
            content_type = "application/x-www-form-urlencoded"
            local form_data = {}
            for _, item in ipairs(bru_file["body_form-urlencoded"]) do
                if not item.disabled then
                    table.insert(form_data, item.key .. "=" .. item.value)
                end
            end
            data = table.concat(form_data, "&")
        elseif bru_file.body_text then
            content_type = "text/plain"
            data = bru_file.body_text
        elseif bru_file.body_xml then
            content_type = "application/xml"
            data = bru_file.body_xml -- TODO: serialize xml
        elseif bru_file["body_multipart-form-data"] then
            -- TODO: implement
        elseif bru_file.body_graphql then
            -- TODO: implement
        elseif bru_file.body then
            content_type = "application/json"
            data = vim.json.encode(bru_file.body)
        end

        if content_type ~= "" then
            table.insert(args, "-H")
            table.insert(args, "content-type: " .. content_type)
        end

        if data ~= "" then
            table.insert(args, "--data")
            table.insert(args, data)
        end
    end

    print("generated curl command args --->", vim.inspect(args))
    return args
end

---@param env_file string
function M.parse_bru_environment_vars(env_file)
    M._selected_env_variables = {}
    local env = M.parse_bru_content(vim.fn.readfile(env_file))
    for k, v in pairs(env) do
        if k == "vars" then
            for key, value in pairs(v) do
                M._selected_env_variables[key] = value
            end
        end
    end
    return M._selected_env_variables
end

---@param opts bruno.setup.opts
---@param format_url function(string): string
---@return self
function M.setup(opts, format_url)
    M.mod_name = "PARSER"
    M.utils = require("bruno.utils")
    M = M.utils.Setup_module(M, opts)

    M.format_url = format_url
    return M
end

return M
