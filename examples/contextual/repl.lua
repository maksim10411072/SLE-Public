local pl = require 'parserlib2'
local grammar = require 'examples.contextual.grammar'(pl)
local util = require 'util'

print(
[[This is a REPL for a simple list language.
Values is literals A and B, and lists.
There is two types of lists: with square braces and with curly braces. They have no real difference except style.
B is an evil racist value that hates square braces. It will never parse succesfully if it is inside square list, regardless of depth.
This is not a semantical analysis after parsing. Since parserlib2 uses functions as rules, rule-function for symbol B seeks square-bracketed lists in ancestors and fails if there is any.
Examples:
- A
- B
- {ABABAB ABABAB}
- {{{{AB}}}}
- {ABA [A] {B}}
- {ABA [AB]} (will fail)
- [AA {{B}}] (will fail too)
"quit" or "exit" to leave.]])
while true do
  io.write'>'
  local inp = io.read("l")
  if util.contained(inp, {"quit", "exit"}) then break end
  local razbor = pl.try(grammar, "value", inp)
  if #razbor == 0 then
    print("Failed to parse.")
  elseif #razbor == 1 then
    print("Parsed succesfully!")
    util.spt(razbor[1].data)
  else
    print("Parsed super-succesfully. Wtf? Did you modified grammar? If not, this is a bug.")
    for i,v in pairs(razbor) do
      print("Variant #"..tostring(i))
      util.spt(v.data)
    end
    end
end
print "Goodbye!"
