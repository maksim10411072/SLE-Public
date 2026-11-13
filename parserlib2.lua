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

function pl.driver(unparse, ptable, name, first, second, extras)
  extras = extras or {}
  local text, pos, data, opts
  if unparse then
    data, opts = first, second
  else
    text, pos = first, second
  end
  local errors, branches, returns, iterations, nonreturns, prevented = 0,0,0,0,0,0
  local waits, resurrects = 0,0
  local gid = 0 local function ggid() gid = gid+1 return gid end
  local waitlist = {}
  local faillist = {}
  local worklist = {}
  local function hidad(dad, value, pos)
    local n = {
      name = dad.name,
      variant = dad.variant,
      parent = dad.parent,
      driver = dad.driver,
      data = {dad.data, value, dad.data[3]+1},
      cache = dad.cache,
      id = dad.id, --ggid(),
    }
    if unparse then
      n.value = dad.value
    else
      n.startpos = dad.startpos
      n.pos = pos
    end
    return n
  end
  if not ptable[name] then
    error 'invalid root symbol.'
  end
  for i,v in ipairs(ptable[name]) do
    worklist[i] = {
      name = name,
      variant = i,
      parent = nil,
      driver = v[1],
      data = {nil,nil,0},
      id = ggid(),
    }
    if unparse then
      worklist[i].driver = v[2]
      worklist[i].value = data
    else
      worklist[i].driver = v[1]
      worklist[i].startpos = pos or 1
      worklist[i].pos = pos or 1
    end
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
      local arg
      if unparse then arg = opts else arg = text end
      local action = {pcall(ff, state, arg)}
      if not action[1] then
        pl.dprint('outright error', action[2])
        errors = errors+1
      elseif action[2] == 'branch' and action[3] then
        pl.dprint('branch', action[3], 'to', state.pos, 'argc', state.data[3]+1)
        if not ptable[action[3]] then error('requested branch for invalid symbol'..tostring(action[3])) end
        for i,v in ipairs(ptable[action[3]]) do
          local newstate = {
            name = action[3],
            variant = i,
            parent = state,
            data = {nil,nil,0},
            id = ggid(),
          }
          local should = true
          if unparse then
            newstate.driver = v[2]
            newstate.value = action[4]
          else
            newstate.driver = v[1]
            newstate.startpos = state.pos
            newstate.pos = state.pos
            local fl = pl.ensure(faillist, newstate.name, newstate.variant)
            should = not fl[newstate.startpos]
          end
          if should then
            local flag, prefix = false, state
            if not unparse then
              while not flag and prefix do
                if newstate.name == prefix.name and newstate.variant == prefix.variant and newstate.startpos == prefix.startpos then
                  flag = true
                else
                  prefix = prefix.parent
                end
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
          else
            prevented = prevented+1
          end
        end
      elseif action[2] == 'return' then
        pl.dprint('return', action[3], action[4])
        if not unparse then
          pl.dprint("trying to restore from", pl.sym2str(state))
          pl.dprint("vars: "..tostring(state.name)..", "..tostring(state.variant)..", "..tostring(state.sp_val))
          local wl = pl.ensure(waitlist, state.name, state.variant, state.startpos)
          for i,v in ipairs(wl) do
            if state.parent == v.parent then
              resurrects = resurrects+1
              pl.dprint('restoring', pl.sym2str(v))
              local nv = hidad(v, action[3], action[4])
              pl.dprint('restored', pl.sym2str(nv), #newlist+1)
              newlist[#newlist+1] = nv
            end
          end
          pl.dprint('end restoration')
        end
        local dad = state.parent
        if dad then
          local out = hidad(dad, action[3], action[4])
          pl.dprint('usual', pl.sym2str(dad), 'to', pl.sym2str(out), #newlist+1)
          returns = returns+1
          newlist[#newlist+1] = out
        elseif unparse 
          or (extras.allow_incomplete or state.pos > #text) then
          -- daddy issues
          pl.dprint('success #'..tostring(#results+1))
          local result = {data = action[3], pos = action[4]}
          if extras.yield_results and coroutine.isyieldable() then
            coroutine.yield(result)
          else
            results[#results+1] = result
          end
          if extras.single_output then
            break
          end
        end
      else
        pl.dprint('bullshit', action[2])
        nonreturns = nonreturns+1
        if not unparse then
          local fl = pl.ensure(faillist, state.name, state.variant)
          fl[state.startpos] = true
        end
      end
    end
    pl.dprint("newlist size", #newlist)
    worklist = newlist
  end
  pl.dprint'-------------------'
  pl.dprint('#results:', #results)
  return results, 
    {iterations = iterations, errors = errors, branches = branches,
    returns = returns, nontreturns = nonreturns, waits = waits,
    resurrects = resurrects}
end

function pl.try(ptable, name, text, pos, extras)
  return pl.driver(false, ptable, name, text, pos, extras)
end

function pl.stry(ptable, name, data, opts, extras)
  return pl.driver(true, ptable, name, data, opts, extras)
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
      return 'return', ending(syms), state.pos
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
        return 'return', body
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
    if first ~= state.pos or not value then return end
    return 'return', value, bound+1
  end, function(state, opts)
    local result = {string.format(genesis, state.value)}
    result[0] = ''
    return 'return', result
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
