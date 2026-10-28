local util = require 'util'
local pl = require 'parserlib2'
pl.debug = false
local g = require 'examples.mathexp.grammar'(pl)

print(
[[Welcome to Mathexp REPL.
> quit/exit to leave.
> debug to switch debug logging.
> wtf for quick reference of Mathexp.]])
while true do
  io.write("> ")
  local ins = io.read("l")
  if ins == "debug" then
    pl.debug = not pl.debug
    print('switched pl.debug: '..tostring(pl.debug))
  elseif ins == "wtf" then
    print(
    [[Mathexp is a simple math expression language subset. It uses left grouping.
operator precedence:
1. + and -
2. * and /
3. () and function call
Functions from lua standard library 'math' is included. Function call does not support multiple arguments (this is a challenge for you to implement this).
Since function call has highest priority, it will steal numbers from unparenthised expressions:
 - sin 67 + 67 = (sin 67) + 67
 - sin (67 + 67) = sin (67+67)
 - log (1337+228) = log (1337 + 228)
 - 42 / cos69 + 88 = (42 / (cos 69)) + 88
(Yes, there is no exponentiation. This is a challenge too.)]])
  elseif util.contained(ins, {"exit", "quit"}) then
    print('goodbye!')
    break
  else
    local razbor, stats = pl.try(g, 'value0', ins)
    print 'statistics:'
    print('iterations, errors, branchings')
    print(stats[1], stats[2], stats[3])
    print('finishes, disfinishes, waits, resurrects')
    print(stats[4], stats[5], stats[6], stats[7])
    print('results:')
    local texts = {}
    for i,v in ipairs(razbor) do
      local dadded, eval = g.tostr(v.data), g.eval(v.data)
      print(tostring(i)..': '..dadded..' = '..tostring(eval))
      local program = io.popen("qalc -t '"..dadded.." = "..tostring(eval).."'", "r")
      local out = program:read("a"):gsub("\n+", ""):gsub("−", "-")
      program:close()
      print("qalc verdict: "..out) --..", fair: "..tostring(out == tostring(eval)))
      texts[#texts+1] = g.tostr(v.data)
    end
    local eq = 0
    local eql = {}
    for i,v in ipairs(texts) do
      for j,d in ipairs(texts) do
        if i ~= j and not eql[i] then
          if v == d then eq = eq+1 eql[j] = {d, i} end
        end
      end
    end
    print('redundant: '..eq)
    for i, v in pairs(eql) do
      print(tostring(i)..': '..v[1]..' for '..v[2]..', distance: '..(i-v[2]))
    end
  end
end
