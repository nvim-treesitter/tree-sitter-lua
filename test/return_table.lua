local x = {}

--- hello world
--@param y: add 1
x.my_func = function(y)
  return y + 1
end

--- hello world
--@param wow: another value
x.other_func = function(wow)
  return wow + 2
end

RandomVal = function() end

local my_val = 5

function X()
  local should_not_see = 7
end

return {
  something = x,
  RandomVal = RandomVal,
  exported_value = my_val,
}
