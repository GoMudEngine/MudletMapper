-- translates n to north and so forth
local temp = {
    n = "north",
    e = "east",
    s = "south",
    w = "west",
    ne = "northeast",
    se = "southeast",
    sw = "southwest",
    nw = "northwest",
    u = "up",
    d = "down",
    i = "in",
    o = "out",
    ["in"] = "in"
}
local anytolongmap = {}
for s, l in pairs(temp) do anytolongmap[l] = l; anytolongmap[s] = l end
function mmp.anytolong(exit)

  return anytolongmap[exit]
end

function mmp.anytoshort(exit)
  local t = {
    n = "north",
    e = "east",
    s = "south",
    w = "west",
    ne = "northeast",
    se = "southeast",
    sw = "southwest",
    nw = "northwest",
    u = "up",
    d = "down",
    ["in"] = "in",
    out = "out"
  }
  local rt = {}
  for s,l in pairs(t) do
    rt[l] = s; rt[s] = s
  end

  return rt[exit]
end


function mmp.ranytolong(exit)
  local t = {
    n = "south",
    north = "south",
    e = "west",
    east = "west",
    s = "north",
    south = "north",
    w = "east",
    west = "east",
    ne = "southwest",
    northeast = "southwest",
    se = "northwest",
    southeast = "northwest",
    sw = "northeast",
    southwest = "northeast",
    nw = "southeast",
    northwest = "southeast",
    u = "down",
    up = "down",
    d = "up",
    down = "up",
    i = "out",
    ["in"] = "out",
    o = "in",
    out = "in"
  }

  return t[exit]
end

-- returns nil or the room number relative to this one
function mmp.relativeroom(from, dir)
  if not mmp.roomexists(from) then return end

  local exits = getRoomExits(tonumber(from))
  return exits[mmp.anytolong(dir)]
end
