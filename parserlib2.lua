local pl = {}

pl.debug = false
function pl.dprint(...)
  if pl.debug then
    print(...)
  end
end
function pl.sym2str(sym)
  if type(sym) == "table" then
    return tostring(sym.name)..":"..tostring(sym.variant)..(sym.pos and '@'..tostring(sym.startpos)..'-'..tostring(sym.pos) or '&'..tostring(sym.number))..'#'..tostring(sym.id)..'id'
  else
    return tostring(sym)
  end
end
function pl.ensure(t, ...)
  local path = {...}
  local s = t
  for _,v in ipairs(path) do
    local n = s[v] or {}
    s[v] = n
    s = n
  end
  return s
end

function pl.try(ptable, name, text, pos)
  local errors, branches, finishes, iterations, disfinishes = 0,0,0,0,0
  local waits, resurrects = 0,0
  local gid = 0 local function ggid() gid = gid+1 return gid end
  local waitlist = {}
  local faillist = {}
  local worklist = {}
  local function hidad(dad, value, pos)
    return {
      name = dad.name,
      variant = dad.variant,
      parent = dad.parent,
      driver = dad.driver,
      data = {dad.data, value, dad.data[3]+1},
      pos = pos,
      startpos = dad.startpos,
      cache = dad.cache,
      id = dad.id, --ggid(),
    }
  end
  for i,v in ipairs(ptable[name]) do
    worklist[i] = {
      name = name,
      variant = i,
      parent = nil,
      driver = v[1],
      data = {nil,nil,0},
      pos = pos or 1,
      startpos = pos or 1,
      id = ggid(),
    }
  end
  local results = {}
  while #worklist>0 do
    iterations = iterations+1
    pl.dprint('--------------'..iterations)
    pl.dprint('worklist size:',#worklist)
    local newlist = {}
    for _,state in ipairs(worklist) do
      pl.dprint('processing state', _, pl.sym2str(state))
      local ff = state.driver
      local action = {pcall(ff, state, text)}
      if not action[1] then
        pl.dprint('outright error', action[2])
        -- пустота тут оставленно намеренно чтобы нельзя было делать штуки типа error('branch')
        errors = errors+1
      elseif action[2] == 'branch' and action[3] then
        pl.dprint('branch', action[3], 'to', state.pos, 'argc', state.data[3]+1)
        for i,v in ipairs(ptable[action[3]]) do
          local newstate = {
            name = action[3],
            variant = i,
            parent = state,
            driver = v[1],
            data = {nil,nil,0},
            pos = state.pos,
            startpos = state.pos,
            id = ggid(),
          }
          local fl = pl.ensure(faillist, newstate.name, newstate.variant)
          if not fl[newstate.startpos] then
            local flag, prefix = false, state
            while not flag and prefix do
              if newstate.name == prefix.name and newstate.variant == prefix.variant and newstate.startpos == prefix.startpos then
                flag = true
              else
                prefix = prefix.parent
              end
            end
            if flag then
              waits = waits+1
              local wl = pl.ensure(waitlist, newstate.name, newstate.variant, newstate.pos)
              pl.dprint('recursion', pl.sym2str(newstate), #wl+1)
              wl[#wl+1] = state
            else
              branches = branches+1
              pl.dprint('branchoff', pl.sym2str(newstate), #newlist+1)
              newlist[#newlist+1] = newstate
            end
          end
        end
      elseif action[2] == 'finish' then
        pl.dprint('finish', action[3], action[4])
        pl.dprint("trying to restore from", pl.sym2str(state))
        pl.dprint("vars: "..tostring(state.name)..", "..tostring(state.variant)..", "..tostring(state.startpos))
        local wl = pl.ensure(waitlist, state.name, state.variant, state.startpos)
        for i,v in ipairs(wl) do
          local flag = true
          local tp = state.parent
          local op = v.parent
          while tp and op and flag do
            flag = tp == op
            tp = tp.parent
            op = op.parent
          end
          if flag then
            resurrects = resurrects+1
            pl.dprint('restoring', pl.sym2str(v))
            local nv = hidad(v, action[3], action[4])
            pl.dprint('restored', pl.sym2str(nv), #newlist+1)
            newlist[#newlist+1] = nv
          end
        end
        pl.dprint('end restoration')
        local dad = state.parent
        if dad then
          local out = hidad(dad, action[3], action[4])
          pl.dprint('usual', pl.sym2str(dad), 'to', pl.sym2str(out), #newlist+1)
          finishes = finishes+1
          newlist[#newlist+1] = out
        elseif state.pos > #text then -- remove condition here to allow for incomplete parsing
          -- daddy issues
          pl.dprint('success #'..tostring(#results+1))
          results[#results+1] = {data = action[3], pos = action[4]}
        end
      else
        pl.dprint('bullshit', action[2])
        disfinishes = disfinishes+1
        local fl = pl.ensure(faillist, state.name, state.variant)
        fl[state.startpos] = true
      end
    end
    pl.dprint("newlist size", #newlist)
    worklist = newlist
  end
  pl.dprint'-------------------'
  pl.dprint('#results:', #results)
  return results, {iterations, errors, branches, finishes, disfinishes, waits, resurrects}
end

function pl.stry(ptable, name, cdata, opts)
  local errors, branches, finishes, iterations, disfinishes = 0,0,0,0,0
  local waits, resurrects = 0,0
  local gid = 0 local function ggid() gid = gid+1 return gid end
  local waitlist = {}
  local faillist = {}
  local worklist = {}
  local function hidad(dad, value)
    return {
      name = dad.name,
      variant = dad.variant,
      parent = dad.parent,
      driver = dad.driver,
      data = {dad.data, value, dad.data[3]+1},
      value = dad.value,
      cache = dad.cache,
      id = dad.id,
      number = dad.number
    }
  end
  for i,v in ipairs(ptable[name]) do
    worklist[i] = {
      name = name,
      variant = i,
      parent = nil,
      driver = v[2],
      data = {nil,nil,0},
      value = cdata,
      id = ggid(),
      number = 0
    }
  end
  local results = {}
  while #worklist>0 do
    iterations = iterations+1
    pl.dprint('--------------'..iterations)
    pl.dprint('worklist size:',#worklist)
    local newlist = {}
    for _,state in ipairs(worklist) do
      pl.dprint('processing state', _, pl.sym2str(state))
      local ff = state.driver
      local action = {pcall(ff, state, opts)}
      if not action[1] then
        pl.dprint('outright error', action[2])
        errors = errors+1
      elseif action[2] == 'branch' and action[3] then
        pl.dprint('branch', action[3], 'argc', state.data[3]+1)
        for i,v in ipairs(ptable[action[3]]) do
          local newstate = {
            name = action[3],
            variant = i,
            parent = state,
            driver = v[2],
            data = {nil,nil,0},
            value = action[4],
            id = ggid(),
            number = state.data[3]
          }
          branches = branches+1
          pl.dprint('branchoff', pl.sym2str(newstate), #newlist+1)
          newlist[#newlist+1] = newstate
        end
      elseif action[2] == 'finish' then
        pl.dprint('finish')
        pl.dprint("trying to restore from", pl.sym2str(state))
        pl.dprint("vars: "..tostring(state.name)..", "..tostring(state.variant)..", "..tostring(state.startpos))
        local dad = state.parent
        if dad then
          local out = hidad(dad, action[3], state.pos)
          pl.dprint('usual', pl.sym2str(dad), 'to', pl.sym2str(out), #newlist+1)
          finishes = finishes+1
          newlist[#newlist+1] = out
        else
          -- daddy issues (unparsing edition)
          pl.dprint('success #'..tostring(#results+1), table.concat(action[3]))
          results[#results+1] = action[3]
        end
      else
        pl.dprint('bullshit', action[2])
        disfinishes = disfinishes+1
      end
    end
    pl.dprint("newlist size", #newlist)
    worklist = newlist
  end
  pl.dprint'-------------------'
  pl.dprint('#results:', #results)
  return results, {iterations, errors, branches, finishes, disfinishes, waits, resurrects}
end

function pl.appendlines(body, bindent, lines)
  local indent = lines[0] or ''
  lines[#lines] = lines[#lines] == '' and '' or lines[#lines] .. indent:sub(#lines[#lines]+1, #indent)
  body[#body] = (body[#body] == '' and bindent or body[#body]) .. lines[1]
  for i = 2, #lines do
    body[#body+1] = lines[i] == '' and '' or bindent..lines[i]
  end
  return bindent..indent
end

function pl._nt(this, name, rightside, ending, genesis, decorator)
  local vs = this[name] or {}
  vs[#vs+1] = pl.nonterminal(rightside, ending, genesis, decorator)
  this[name] = vs
end

function pl.nonterminal(rightside, ending, genesis, decorator)
  ending = ending or function(body) return body[1] end
  genesis = genesis or function(data)
    return {data}
  end
  rightside = type(rightside) == "table" and rightside or {rightside}
  local out = {function(state, text)
    if state.data[3] < #rightside then
      return 'branch', rightside[state.data[3]+1]
    else
      local syms = {}
      local storage = state.data
      while storage[3] > 0 do
        syms[storage[3]] = storage[2]
        storage = storage[1]
      end
      return 'finish', ending(syms), state.pos
    end
  end, function(state, opts)
    state.cache = state.cache or genesis(state.value, opts)
    if type(state.cache) == 'table' then
      if state.data[3] < #rightside then
        return 'branch', rightside[state.data[3]+1], state.cache[state.data[3]+1]
      else
        local dindent = ''
        local linebuf = {}
        local stg = state.data
        while stg[3]>0 do
          linebuf[stg[3]] = stg[2]
          stg = stg[1]
        end
        if decorator then decorator(linebuf, opts) end
        local body = {''}
        for _,v in ipairs(linebuf) do dindent = pl.appendlines(body, dindent, v) end
        body[0] = dindent
        return 'finish', body
      end
    end
  end}
  return out
end

function pl._t(this, name, pattern, genesis)
  local vs = this[name] or {}
  vs[#vs+1] = pl.terminal(pattern, genesis)
  this[name] = vs
end

function pl.terminal(pattern, genesis)
  genesis = genesis or pattern
  pattern = pl.surround[pattern]
  local out = {function(state, text)
    local first, bound, value = string.find(text, pattern, state.pos)
    --pl.dprint('term', first, bound, value, state.pos)
    if first ~= state.pos or not value then return end
    --pl.dprint('term', bound, value)
    return 'finish', value, bound+1
  end, function(state, opts)
    local result = {string.format(genesis, state.value)}
    result[0] = ''
    return 'finish', result
  end}
  return out
end

pl.surround = setmetatable({},{
  __index = function(this, key)
    this[key] = '%s*'..key..'%s*'
    return this[key]
  end,
  __call = function(this, key)
    return this[key]
  end
})

return pl
