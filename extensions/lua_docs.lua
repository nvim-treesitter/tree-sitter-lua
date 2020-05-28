vim.treesitter.require_language("lua", "./build/parser.so", true)

local lua_docs = {}

lua_docs.get_text_from_node = function(lua_lines, node)
  local row, col, _ = node:start()
  local end_row, end_col, _ = node:end_()

  if row == end_row then
    return string.sub(lua_lines[row + 1], col + 1, end_col)
  end

  local text = {}
  for i = row + 1, end_row + 1 do
    if i == end_row + 1 then
      table.insert(text, string.sub(lua_lines[i], 1, end_col))
    elseif i == row + 1 then
      table.insert(text, string.sub(lua_lines[i], col))
    else
      table.insert(text, lua_lines[i])
    end
  end

  return vim.trim(table.concat(text, "\n"))
end

local VAR_NAME_CAPTURE = 'var'
local PARAMETER_NAME_CAPTURE = 'parameter_name'
local PARAMETER_DESC_CAPTURE = 'parameter_description'

lua_docs.get_documentation = function(lua_string, query_string)
  local lua_lines = vim.split(lua_string, "\n")
  local parser = vim.treesitter.create_str_parser('lua')

  local tree = parser:parse_str(lua_string)
  local root = tree:root()

  local query = vim.treesitter.parse_query("lua", query_string)

  -- for match_id, node in query:iter_captures(root, -1, 1, -1) do
  --   print(match_id, node:type(), lua_docs.get_text_from_node(lua_lines, node))
  -- end

  local gathered_results = {}
  for _, match in query:iter_matches(root, 0, 1, -1) do
    local temp = {}
    for match_id, node in ipairs(match) do
      local capture_name = query.captures[match_id]
      local text = lua_docs.get_text_from_node(lua_lines, node)

      temp[capture_name] = text
    end

    table.insert(gathered_results, temp)
  end

  local results = {}
  for _, match in ipairs(gathered_results) do
    local name = match[VAR_NAME_CAPTURE]
    local paramater_name = match[PARAMETER_NAME_CAPTURE]
    local parameter_description = match[PARAMETER_DESC_CAPTURE]

    if results[name] == nil then
      results[name] = {}
    end

    local res = results[name]

    if res.params == nil then
      res.params = {}
    end

    table.insert(res.params, { name = paramater_name, desc = parameter_description })
  end

  print(vim.inspect(results))
end

local read = function(f)
  local fp = assert(io.open(f))
  local contents = fp:read("all")
  fp:close()

  return contents
end


local contents = read("/home/tj/tmp/small.lua")

local query_string = read("./queries/lua_documentation.scm")
lua_docs.get_documentation(contents, query_string)

if false then

  print("MOD")
  local mod_string = read("./queries/module_return.scm")
  lua_docs.get_documentation(contents, mod_string)

  print("VAR")
  local var_string = read("./queries/variable.scm")
  lua_docs.get_documentation(contents, var_string)
end


return lua_docs
