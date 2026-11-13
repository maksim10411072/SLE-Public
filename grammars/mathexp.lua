return function(lib)
local g = {} 
g._nt = lib._nt
g._t  = lib._t

g:_t("num-term", "(-?%d+%.?%d*)", "%d")
g:_t("name-term", "(%a+)", "%s")
g:_nt("value3", {"&(", "value0", "&)"}, function(body)
  return body[2]
end, function(data)
  return {nil, data, nil}
end)
g:_nt("value3", "num-term", function(body)
  return {type = "number", value = tonumber(body[1])}
end, function(data)
  if data.type ~= 'number' then return false end
  return {data.value}
end)
g:_nt("value2", {"name-term", "value2"}, function(body)
  return {type = "function", name = body[1], value = body[2]}
end, function(data)
  if data.type ~= 'function' then return false end
  return {data.name, data.value}
end)
g:_nt("value2", "value3")
g:_nt("value1", {"value1", "operator1", "value2"}, function(body)
  return {type = "expression", left = body[1], right = body[3], operator = body[2]}
end, function(data)
  if data.type ~= 'expression' then return false end
  return {data.left, data.operator, data.right}
end)
g:_nt("value1", "value2")
g:_nt("value0", {"value0", "operator0", "value1"}, function(body)
  return {type = "expression", left = body[1], right = body[3], operator = body[2]}
end, function(data)
  if data.type ~= 'expression' then return false end
  return {data.left, data.operator, data.right}
end)
g:_nt("value0", "value1")
local function opser(str)
  return function(data)
    if data == str then return {data} end return false
  end
end
g:_nt("operator0", "&+", nil, opser('+'))
g:_nt("operator0", "&-", nil, opser('-'))
g:_nt("operator1", "&*", nil, opser('*'))
g:_nt("operator1", "&/", nil, opser('/'))

g.operators = {
  ["+"] = function(x, y) return x + y end,
  ["*"] = function(x, y) return x * y end,
  ["-"] = function(x, y) return x - y end,
  ["/"] = function(x, y) return x / y end,
}

setmetatable(g,{
  __index = function(this, key)
    if type(key) == 'string' then
      local a,b,match = key:match("^&(.)")
      if a then
        local vars = {lib.terminal("(%"..a..")", a)}
        this[key] = vars
        return this[key]
      end
    end
  end
})

g.functions = setmetatable({
}, {
  __index = math
})

function g.eval(tree, ops, fns)
  if not tree then print "got nil" return nil end
  ops = ops or g.operators
  fns = fns or g.functions
  if tree.type == "number" then
    return tree.value
  elseif tree.type == "expression" then
    local first, second = g.eval(tree.left, ops), g.eval(tree.right, ops)
    return ops[tree.operator](first, second)
  elseif tree.type == "function" then
    local value = g.eval(tree.value)
    local f = fns[tree.name]
    return f and f(value) or 0
  end
end
function g.tostr(tree)
  local str = "nil"
  if tree.type == "number" then
    str = tostring(tree.value)
  elseif tree.type == "expression" then
    local first, second = g.tostr(tree.left), g.tostr(tree.right)
    str = '('..first..tree.operator..second..')'
  elseif tree.type == "function" then
    local value = g.tostr(tree.value)
    str = tree.name..'('..value..')'
  end
  return str
end
return g
end
