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
    if #this ~= #that then return false end
    for k,v in pairs(this) do
      if not util.teq(that[k], v) then return false end
    end
    return true
  else
    return this == that
  end
end

function util.ftab(tab, ml, delim) -- format table
  ml = ml or 30
  delim = delim or ' '
  local columns = {}
  local function standard(tx, l)
    return tx..(' '):rep(l-#tx)
  end
  for k,v in pairs(tab) do
    local ks, vs = tostring(k), tostring(v)
    local l = math.max(#ks, #vs)
    columns[#columns+1] = {
      name = standard(ks, l),
      value = standard(vs, l),
      length = l
    }
  end
  local rows, buffs, acc, rpos, pos = {}, {{},{}}, 0, 1, 1
  while columns[pos] do
    local v = columns[pos]
    if acc + v.length > ml and #buffs[1] > 0 then
      rows[rpos*2-1] = table.concat(buffs[1], delim)
      rows[rpos*2] = table.concat(buffs[2], delim)
      buffs = {{},{}}
      rpos = rpos+1
      acc = 0
    else
      buffs[1][#buffs[1]+1] = v.name
      buffs[2][#buffs[2]+1] = v.value
      acc= acc + v.length
      pos= pos + 1 
    end
  end
  rows[rpos*2-1] = table.concat(buffs[1], delim)
  rows[rpos*2] = table.concat(buffs[2], delim)
  local s = table.concat(rows, '\n')
  return s
end

return util
