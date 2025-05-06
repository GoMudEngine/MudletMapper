do
local oldlockExit = lockExit
local oldhasExitLock = hasExitLock

local exitmap = {
  n = 1,
  north = 1,
  ne = 2,
  northeast = 2,
  nw = 3,
  northwest = 3,
  e = 4,
  east = 4,
  w = 5,
  west = 5,
  s = 6,
  south = 6,
  se = 7,
  southeast = 7,
  sw = 8,
  southwest = 8,
  u = 9,
  up = 9,
  d = 10,
  down = 10,
  ["in"] = 11,
  out = 12
}

function mmp.lockExit(from, direction, status)
  if type(direction) == "string" and not exitmap[direction] then return false end

  return oldlockExit(from, type(direction) == "string" and exitmap[direction] or direction, status)
end

function mmp.hasExitLock(from, direction)
  if type(direction) == "string" and not exitmap[direction] then return false end

  return oldhasExitLock(from, type(direction) == "string" and exitmap[direction] or direction)
end
end