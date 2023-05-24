local random
random = math.random
local int = 1 + 4
return {
  key1 = true,
  key2 = 'Yes',
  [false] = '0',
  result = int + 3,
  int = int
}
