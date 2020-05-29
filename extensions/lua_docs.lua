local read = function(f)
  local fp = assert(io.open(f))
  local contents = fp:read("all")
  fp:close()

  return contents
end

local get_node_text_from_lines = vim.treesitter.get_node_text_from_lines

vim.treesitter.require_language("lua", "./build/parser.so", true)

local lua_docs = {}

local VAR_NAME_CAPTURE = 'var'
local PARAMETER_NAME_CAPTURE = 'parameter_name'
local PARAMETER_DESC_CAPTURE = 'parameter_description'

lua_docs.get_query_results = function(lua_string, query_string)
  local lua_lines = vim.split(lua_string, "\n")
  local parser = vim.treesitter.create_str_parser('lua')

  local tree = parser:parse_str(lua_string)
  local root = tree:root()

  local query = vim.treesitter.parse_query("lua", query_string)

  local gathered_results = {}
  for _, match in query:iter_str_matches(root, lua_lines, 1, -1) do
    local temp = {}
    for match_id, node in pairs(match) do
      local capture_name = query.captures[match_id]
      local text = get_node_text_from_lines(node, lua_lines)

      temp[capture_name] = text
    end

    table.insert(gathered_results, temp)
  end

  return gathered_results
end

local get_parent_from_var = function(name)
  local colon_start = string.find(name, ":", 0, true)
  local dot_start = string.find(name, ".", 0, true)
  local bracket_start = string.find(name, "[", 0, true)

  local parent = nil
  if (not colon_start) and (not dot_start) and (not bracket_start) then
    parent = name
  elseif colon_start then
    parent = string.sub(name, 1, colon_start - 1)
    name = string.sub(name, colon_start + 1)
  elseif dot_start then
    parent = string.sub(name, 1, dot_start - 1)
    name = string.sub(name, dot_start + 1)
  elseif bracket_start then
    parent = string.sub(name, 1, bracket_start - 1)
    name = string.sub(name, bracket_start)
  end

  return parent, name
end

lua_docs.get_documentation = function(lua_string)
  local query_string = read("./queries/lua_documentation.scm")
  local gathered_results = lua_docs.get_query_results(lua_string, query_string)

  local results = {}
  for _, match in ipairs(gathered_results) do
    local raw_name = match[VAR_NAME_CAPTURE]
    local paramater_name = match[PARAMETER_NAME_CAPTURE]
    local parameter_description = match[PARAMETER_DESC_CAPTURE]

    local parent, name = get_parent_from_var(raw_name)

    local res
    if parent then
      if results[parent] == nil then
        results[parent] = {}
      end

      if results[parent][name] == nil then
        results[parent][name] = {}
      end

      res = results[parent][name]
    else
      if results[name] == nil then
        results[name] = {}
      end

      res = results[name]
    end

    if res.params == nil then
      res.params = {}
    end

    table.insert(res.params, {
      original_parent = parent,
      name = paramater_name,
      desc = parameter_description
    })
  end

  return results
end

lua_docs.get_exports = function(lua_string)
  local return_string = read("./queries/module_return.scm")
  return lua_docs.get_query_results(lua_string, return_string)
end

lua_docs.get_exported_documentation = function(lua_string)
  local documented_items = lua_docs.get_documentation(lua_string)
  local exported_items = lua_docs.get_exports(lua_string)

  local transformed_items = {}
  for _, transform in ipairs(exported_items) do
    if documented_items[transform.defined] then
      transformed_items[transform.exported] = documented_items[transform.defined]

      documented_items[transform.defined] = nil
    end
  end

  for k, v in pairs(documented_items) do
    transformed_items[k] = v
  end

  return transformed_items
end


local contents = read("/home/tj/tmp/small.lua")

print(vim.inspect({lua_docs.get_exported_documentation(contents)}))

return lua_docs
