local util = require 'util'
local pl = require 'parserlib2'
local g = require 'examples.json.grammar' (pl)

local args = {...}
local path = args[1]
local file = io.open(path)
if not file then
  print "Cannot open file!"
  do return end
end
local text = file:read('a')
file:close()
pl.debug = args[2] == 'debug'

local razbor, stats = pl.try(g, 'value', text)
print 'statistics:'
print('iterations, errors, branchings')
print(stats[1], stats[2], stats[3])
print('finishes, disfinishes, waits, resurrects')
print(stats[4], stats[5], stats[6], stats[7])

if #razbor > 1 then
  print "Unambigous grammar. Wtf? This should be a bug."
  do return end
elseif #razbor == 0 then
  print "Can't parse file. Could be a bug."
  do return end
end

util.spt(razbor[1].data)
