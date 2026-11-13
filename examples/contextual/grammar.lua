return function(lib)
local g = {}
g._t = lib._t
g._nt = lib._nt

g:_t("A'", "(A)")
g:_t("B'", "(B)")
g:_t("square-start'", "(%[)")
g:_t("square-end'", "(%])")
g:_t("curly-end'", "(%})")
g:_t("curly-start'", "(%{)")
g:_nt("square-list", {"square-start'", "body", "square-end'"}, function(body) return body[2] end)
g:_nt("curly-list", {"curly-start'", "body", "curly-end'"}, function(body) return body[2] end)
g:_nt("body", {"value", "body"}, function(body)
  local n = {body[1]}
  for i,v in ipairs(body[2]) do
    n[i+1]=v
  end
  return n
end)
g:_nt("body", {"value"}, function(body)
  return {body[1]}
end)
g:_nt("value", "square-list")
g:_nt("value", "curly-list")
g:_nt("value", "A")
g:_nt("A", "A'")
g:_nt("value", "B")
-- evil racist symbol that hates square lists
g.B = {{function(state, text)
  local parent = state.parent
  while parent do
    if parent.name == "square-list" then
      return
    else
      parent = parent.parent
    end
  end
  if state.data[3] == 0 then
    return "branch", "B'"
  else
    return "return", state.data[2], state.pos
  end
end
}}
-- non-racist B variant
--g:_nt("B", "B'",function(body)return"non-bigoted B"end)

return g
end
