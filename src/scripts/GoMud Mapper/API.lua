-------------------------------------------------
-- This script lists some of the API functions available from the IRE mudlet-mapper
-- not all functions that are available are included here, however.

function mmp.echo(what)
  what = what or ""
  moveCursorEnd("main") if getCurrentLine() ~= "" then echo"\n" end
  decho("<112,229,0>(<73,149,0>mapper<112,229,0>): <255,255,255>")
  cecho(tostring(what))
  echo("\n")
end

function mmp.echon(what)
  moveCursorEnd("main") if getCurrentLine() ~= "" then echo"\n" end
  decho("<112,229,0>(<73,149,0>mapper<112,229,0>): <255,255,255>")
  cecho(tostring(what))
end

function mmp.deleteLineP()
  deleteLine()
  tempLineTrigger(1,1,[[
    if isPrompt() then deleteLine() end
  ]])
end

function mmp.pause(what)
  assert(what == nil or what == "on" or what == "off", "mmp.pause wants 'on', 'off' or nothing as an argument")

  if what == "on" or (what == nil and not mmp.paused) then
    mmp.paused = true
  elseif  what == "off" or (what == nil and mmp.paused) then
    mmp.paused = false
  end

  mmp.echo("Speedwalking " .. (mmp.paused and "paused" or "unpaused") .. ".")
  if not mmp.paused then mmp.move() end
end

function mmp.mapLook(roomid, delay)
  centerview(roomid)
  if mmp.maplooktimer then killTimer(mmp.maplooktimer) end
  mmp.maplooktimer = tempTimer(tonumber(delay) or 4, [[centerview(mmp.currentroom); mmp.maplooktimer = nil]])
end

function mmp.getnums(roomname, exact)
  if tonumber(roomname) then return {roomname} end

  local t = (not exact and mmp.searchRoom or mmp.searchRoomExact)(roomname)

  if not t or not next(t) then
    return nil end

  local result = {}

  if not tonumber(select(2, next(t))) then
    for roomid,_ in pairs(t) do
      if roomid ~= 0 then result[#result+1] = tonumber(roomid) end
    end
  else
    for _,roomid in pairs(t) do
      if roomid ~= 0 then result[#result+1] = tonumber(roomid) end
    end
  end

  return result
end

-- searchRoom with a cache!
local cache = {}
setmetatable(cache, {__mode = "kv"}) -- weak keys/values = it'll periodically get cleaned up by gc

function mmp.searchRoom(what)
  local result = cache[what]
  if not result then
    result = searchRoom(what)
    local realResult = {}
    for key, value in pairs(type(result) == "table" and result or {}) do
        -- both ways, because searchRoom can return either id-room name or the reverse
        if type(key) == "string" then
          realResult[key:ends(" (road)") and key:sub(1, -8) or key] = value
        else
          realResult[key] = value:ends(" (road)") and value:sub(1, -8) or value
        end
    end
    cache[what] = realResult
    result = realResult
  end
  return result
end

local function endswith(s, suffix)
    return s:sub(#s - #suffix + 1) == suffix
end

function mmp.searchRoomExact(what)
  if type(what) ~= 'string' then return end

  local roomTable = mmp.searchRoom(what)
  local realResult = {}
  what = what:lower()
  for key, value in pairs (roomTable) do
    if type(key) == "string" and (key:lower() == what or (endswith(key, '.') and key:sub(1, -2) == what)) then
        realResult[key:ends(" (road)") and key:sub(1, -8) or key] = value
    elseif type(value) == "string" and (value:lower() == what or (endswith(value, '.') and value:sub(1, -2) == what)) then
        realResult[key] = value:ends(" (road)") and value:sub(1, -8) or value
    end
  end
  if (table.is_empty(realResult)) then
    return roomTable
  else
    return realResult
  end
end

function mmp.findAreaID(areaname, exact)
  local areaname = areaname:lower()
  local list = getAreaTable()

  -- iterate over the list of areas, matching them with substring match.
  -- if we get match a single area, then return it's ID, otherwise return
  -- 'false' and a message that there are than one are matches
  local returnid, fullareaname, multipleareas = nil, nil, {}
  for area, id in pairs(list) do
    if (not exact and area:lower():find(areaname, 1, true)) or (exact and areaname == area:lower()) then
      returnid = id; fullareaname = area; multipleareas[#multipleareas+1] = area
    end
  end

  if #multipleareas == 1 then
    return returnid, fullareaname
  else
    return nil, nil, multipleareas
  end
end

function mmp.roomexists(num)
  if not num then return false end
  if roomExists then return roomExists(num) end

  local s,m = pcall(getRoomArea, tonumber(num))
  return (s and true or false)
end

function mmp.getcontinents()
  local tmp = getRoomUserData(1, "areaContinents")
  if tmp == "" then return {} end

  return yajl.to_value(tmp)
end

-- patches welcome to finish this function.
function mmp.removecontinent(area, continent)
  local continents = mmp.getcontinents()

  if not next(continents) then return nil, "no continents are known" end
  if not continents[continent] then return nil, "no such continent is recorded" end

  local index = mmp.indexof_valueonly(continents[continent], area)
  if not index then return nil, "this area is not on that continent" end
  table.remove(continents[continent], index)
  local tmp = yajl.to_string(continents)
  setRoomUserData(1, "areaContinents", tmp)
  return true
end

function mmp.addcontinent(areaid, continent)
  local continents = mmp.getcontinents()

  if not next(continents) then return nil, "no continents are known" end
  if not continents[continent] then continents[continent] = {} end

  local index = mmp.indexof_valueonly(continents[continent], areaid)
  if index then return nil, "this area is already on that continent" end
  continents[continent][#continents[continent] + 1] = areaid
  local tmp = yajl.to_string(continents)
  setRoomUserData(1, "areaContinents", tmp)
  return true
end

function mmp.indexof_valueonly(data, value)
  for i = 1, #data do
    if data[i] == value then return i end
  end

  return false
end

-- checks if given area ID is on the given continent. Returns true only if certainly knows
function mmp.oncontinent(areaid, continent)
  local continents = mmp.getcontinents()
  if not continents[continent] then return nil, "no such continent is recorded" end

  return mmp.indexof_valueonly(continents[continent], areaid)
end

function mmp.getareacontinents(areaid)
  local areaContinents = {}
  for continentName, areas in pairs(mmp.getcontinents()) do
    if mmp.indexof_valueonly(areas, areaid) then
      areaContinents[#areaContinents + 1] = continentName
    end
  end
  return areaContinents
end

-- accepts areaname or ID
function mmp.cleanAreaName(area)
  local areaname = type(area) == "number" and mmp.areatabler[area] or area
  if not areaname then return area end

  -- strip , the
  areaname = areaname:gsub(", the$", '')

  -- strip , the Type of
  areaname = areaname:gsub(", the %w+ of$", '')

  -- strip , the Type of (important)
  areaname = areaname:gsub(", the %w+ of %((.+)%)$", " (%1)")

  -- strip , the (important)
  areaname = areaname:gsub(", the %((.+)%)$", " (%1)")

  return areaname
end

-- if this room is in a unique area, report it. Otherwise gives nil
function mmp.getexactarea(roomname)
  local rooms = mmp.searchRoomExact(roomname)

  if not rooms or not next(rooms) then return nil end

  local areaid
  for roomid, roomname in pairs(rooms) do

    local caid = getRoomArea(roomid)
    if areaid and areaid ~= caid then return nil end
    areaid = caid
  end

  if areaid then return mmp.areatabler[areaid] end
end

-- returns the area name of a room or ?
function mmp.getAreaName(roomid)
   return mmp.areatabler[getRoomArea(roomid)] or '?'
end

-- removes extra prefixes and suffixes that are not part of the actual room name
function mmp.cleanroomname(roomname)
  local starts, ends = string.starts, string.ends

  if starts(roomname, "Flying above ") then
    roomname = string.sub(roomname, -(#roomname-13))
  end
  if starts(roomname, "In the trees above ") then
    roomname = string.sub(roomname, -(#roomname-19))
  end
  if starts(roomname, "The ruins of ") then
    roomname = string.sub(roomname, -(#roomname-13))
  end
  if ends(roomname, ".") then
    roomname = string.sub(roomname, 1, (#roomname-1))
  end
  if ends(roomname, " (road)") then
    roomname = string.sub(roomname, 1, (#roomname-7))
  end
  if ends(roomname, " (indoors)") then
    roomname = string.sub(roomname, 1, (#roomname-10))
  end
  if ends(roomname, " (indoor road)") then
    roomname = string.sub(roomname, 1, (#roomname-14))
  end

  return roomname
end