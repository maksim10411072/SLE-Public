local util = {}

function util.contained(val, list)
  for _,v in pairs(list) do
    if val == v then return v end
  end
end

function util.spt(value, prefix) -- shitprint
  local function p2str(prefix)
    local arr = {}
    for _, v in ipairs(prefix[2] and p2str(prefix[2]) or {}) do
      arr[#arr+1] = v
    end
    arr[#arr+1] = prefix[1] and tostring(prefix[1])
    return arr
  end
  prefix = prefix or {}
  if type(value) == "table" then
    local keys = {}
    for k,_ in pairs(value) do
      keys[#keys+1] = k
    end
    table.sort(keys, function(l, b)
      if type(l) ~= type(b) then
        return type(l) < type(b)
      else
        return l < b
      end
    end)
    for i,v in ipairs(keys) do
      local new_pref = {v, prefix}
      util.spt(value[v], new_pref)
    end
  else
    print((table.unpack or unpack)(p2str({value, prefix})))
  end
end

function util.teq(this, that) -- table equality
  if type(this) == 'table' and type(that) == 'table' then
    if #this ~= #that then print'fimoz' return false end
    for k,v in pairs(this) do
      if not util.teq(that[k], v) then return false end
    end
    return true
  else
    return this == that
  end
end

return util
