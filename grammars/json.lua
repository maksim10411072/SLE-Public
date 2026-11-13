return function(lib)
local g = {}
g._nt = lib._nt
g._t  = lib._t

g:_t("str_t", '"([^"]*)"', '"%s"')
g:_t("num_t", "(-?%d+%.?%d*)")
g:_t("bool_t", "([TtFf][RrAa][UuLl][EeSs][Ee]?)", "%w")
g:_t("arr_sep_t", "(,)", ", ")
g:_t("arr_start_t", "(%[)", "[")
g:_t("arr_end_t", "(%])", "]")
g:_t("dict_sep_t", "(%:)", ":")
g:_t("dict_start_t", "({)", "{")
g:_t("dict_end_t", "(})", "}")
g:_nt("str", "str_t")
g:_nt("num", "num_t")
g:_nt("bool","bool_t")
g:_nt("value","str")
g:_nt("value","num")
g:_nt("value","bool")
g:_nt("value","array")
g:_nt("value","dict")
g:_nt("array_body", {"value", "arr_sep_t", "array_body"}, function(body)
  local arr = {}
  arr[1] = body[1]
  for i,v in ipairs(body[3]) do
    arr[i+1] = v
  end
  return arr
end)
g:_nt("array_body", "value", function(body)
  return body
end)
g:_nt("array", {"arr_start_t", "array_body", "arr_end_t"}, function(body)
  return body[2]
end)
g:_nt("array", {"arr_start_t", "arr_end_t"}, function(body)
  return {}
end)
g:_nt("entry", {"str", "dict_sep_t", "value"}, function(body)
  return {key = body[1], value = body[3]}
end)
g:_nt("dict_body", {"entry", "arr_sep_t", "dict_body"}, function(body)
  local dict = {}
  dict[body[1].key] = body[1].value
  for k,v in pairs(body[3]) do
    dict[k] = v
  end
  return dict
end)
g:_nt("dict_body", "entry", function(body)
  local dict = {}
  dict[body[1].key] = body[1].value
  return dict
end)
g:_nt("dict", {"dict_start_t", "dict_body", "dict_end_t"}, function(body)
  return body[2]
end)
g:_nt("dict", {"dict_start_t", "dict_end_t"}, function(body)
  return {}
end)
return g
end
