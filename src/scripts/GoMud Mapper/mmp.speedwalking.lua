function mmp.gotoRoom(where, dashtype, gotoType)
  mmp.speedWalk.type = gotoType or "room"
  if not where or not tonumber(where) then
    mmp.echo("Where do you want to go to?")
    return
  end
  if tonumber(where) == mmp.currentroom then
    mmp.echo("We're already at " .. where .. "!")
    raiseEvent("mmapper arrived")
    return
  end
  -- allow mapper 'addons' to link their own exits in
  raiseEvent("mmp link externals")
  -- if getPath worked, then the dirs and room #'s tables were populated for us
  if not mmp.getPath(mmp.currentroom, tonumber(where)) then
    mmp.echo("Don't know how to get there (" .. tostring(where) .. ") from here :(")
    mmp.speedWalkPath = {}
    mmp.speedWalkDir = {}
    mmp.speedWalkCounter = 0
    raiseEvent("mmapper failed path")
    if mmp.settings.shackle then
      expandAlias("wear shackle")
    end
    -- allow mapper 'addons' to unlink their special exits
    raiseEvent("mmp clear externals")
    return
  end
  doSpeedWalk(dashtype)
  -- allow mapper 'addons' to unlink their special exits
  raiseEvent("mmp clear externals")
end

function mmp.gotoArea(where, number, dashtype, exact)
  mmp.speedWalk.type = "area"
  if not where or type(where) ~= "string" then
    mmp.echo("Where do you want to go to?")
    return
  end
  local where = where:lower()
  number = tonumber(number)
  local tmp = getRoomUserData(1, "gotoMapping")
  if not tmp or tmp == '' then
    tmp = "[]"
  end
  local temp, maptable = yajl.to_value(tmp), {}
  for k, v in pairs(temp) do
    maptable[k:lower()] = v
  end
  local destinationRoom = maptable[where]
  if destinationRoom then
    mmp.gotoRoom(destinationRoom, dashtype)
    return
  end
  local areaid, msg, multiples = mmp.findAreaID(where, exact)
  if areaid then
    mmp.gotoAreaID(areaid)
  elseif not areaid and #multiples > 0 then
    if number and number <= #multiples then
      mmp.gotoArea(multiples[number], nil, dashtype, true)
      return
    end
    mmp.echo("Which area would you like to go to?")
    fg("DimGrey")
    for key, areaname in ipairs(multiples) do
      echo("  ")
      echoLink(
        key .. ") ",
        'mmp.gotoArea("' ..
        areaname ..
        '", nil, ' ..
        (dashtype and '"' .. dashtype .. '"' or "nil") ..
        ', true)',
        "Click to go to " .. areaname,
        true
      )
      setUnderline(true)
      echoLink(
        areaname,
        'mmp.gotoArea("' ..
        areaname ..
        '", nil, ' ..
        (dashtype and '"' .. dashtype .. '"' or "nil") ..
        ', true)',
        "Click to go to " .. areaname,
        true
      )
      setUnderline(false)
      echo("\n")
    end
    resetFormat()
    return
  else
    mmp.echo(string.format("Don't know of any area named '%s'.", where))
    return
  end
end

--- DOES NOT ACCOUNT FOR CHANGING THE MAP YET (within a profile load), because we don't know when it happens
local getpathcache = {}
--setmetatable(getpathcache, {__mode = "kv"}) -- weak keys/values = it'll periodically get cleaned up by gc

function mmp.getPath(from, to)
  assert(tonumber(from) and tonumber(to), "mmp.getPath: both from and to have to be room IDs")
  local key = string.format("%s_%s", from, to)
  local resulttbl = getpathcache[key]
  -- not in cache?
  if not resulttbl then
    mmp.computeGetPath = mmp.computeGetPath or createStopWatch()
    startStopWatch(mmp.computeGetPath)
    local boolean = getPath(from, to)
    if mmp.debug then
      mmp.echo(
        "a new getPath() from " ..
        from ..
        " to " ..
        to ..
        " took " ..
        stopStopWatch(mmp.computeGetPath) ..
        "s."
      )
    end
    -- save it into the cache & send away
    getpathcache[key] = {boolean, speedWalkDir, speedWalkPath}
    return boolean
  end
  -- or if it is, retrieve & send away
  speedWalkDir = resulttbl[2]
  speedWalkPath = resulttbl[3]
  return resulttbl[1]
end

function mmp.clearpathcache()
  if mmp.debug then
    mmp.echo("path cache cleared")
  end
  getpathcache = {}
end

registerAnonymousEventHandler("mmapper updated map","mmp.clearpathcache")

function mmp.showpathcache()
  return getpathcache
end

function mmp.setmovetimer(time, ignoreLatency)
  if mmp.movetimer then
    killTimer(mmp.movetimer)
  end
  if mmp.settings.slowwalk and not mmp.hasty then
    return
  end
  local laglevel = mmp.settings.laglevel or 1
  time = time or mmp.lagtable[laglevel].time
  local latency = ignoreLatency and 0 or getNetworkLatency()
  if mmp.debug then
    mmp.echo(f'setting move timer according to time {time} and latency {latency}')
  end
  mmp.movetimer =
    tempTimer(
      latency + time,
      function()
        if mmp.debug then
          mmp.echo('move timer fired')
        end
        mmp.movetimer = false
        mmp.move()
      end
    )
end

-- moves to the next room we need to.

function mmp.move()
  if mmp.paused or not mmp.autowalking or mmp.movetimer or not mmp.canmove() then
    return
  end
  -- sometimes it's 0 - default to 1
  if mmp.speedWalkCounter == 0 then
    mmp.speedWalkCounter = 1
  end
  local cmd
  if mmp.settings["caravan"] then
    cmd = "lead caravan " .. mmp.speedWalkDir[mmp.speedWalkCounter]
  else
    cmd = mmp.speedWalkDir[mmp.speedWalkCounter]
  end
  cmd = cmd or ''
  -- timeout before loadstring, so it can set its own if it would like to.
  mmp.setmovetimer()
  if string.starts(cmd, "script:") then
    cmd = string.gsub(cmd, "script:", "")
    loadstring(cmd)()
    if mmp.settings.showcmds and not mmp.hasty then
      cecho(
        string.format(
          "<red>(<maroon>%d - <dark_slate_grey>%s<red>)",
          #mmp.speedWalkDir - mmp.speedWalkCounter + 1,
          "<script>"
        )
      )
    end
    mmp.hasty = false
  else
    send(cmd, false)
    if mmp.settings.showcmds and not mmp.hasty then
      cecho(
        string.format(
          "<red>(<maroon>%d - <dark_slate_grey>%s<red>)",
          #mmp.speedWalkDir - mmp.speedWalkCounter + 1,
          cmd
        )
      )
    end
    mmp.hasty = false
  end
end

function mmp.swim()
  -- not going anywhere? don't do anything
  if not mmp.speedWalkDir[mmp.speedWalkCounter] then
    return
  end
  send(
    "swim " ..
    mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
      "runaway ", ""
    ),
    false
  )
  if mmp.settings.showcmds then
    cecho(
      string.format(
        "<red>(<maroon>%d - <dark_slate_grey>swim %s<red>)",
        #mmp.speedWalkDir - mmp.speedWalkCounter + 1,
        mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
          "runaway ", ""
        )
      )
    )
  end
  mmp.hasty = true
  mmp.setmovetimer(2.5)
end

function mmp.enterGrate()
  -- not going anywhere? don't do anything
  if not mmp.speedWalkDir[mmp.speedWalkCounter] then
    return
  end
  send("enter grate " .. mmp.speedWalkDir[mmp.speedWalkCounter], false)
  if mmp.settings.showcmds then
    cecho(
      string.format(
        "<red>(<maroon>%d - <dark_slate_grey>enter grate %s<red>)",
        #mmp.speedWalkDir - mmp.speedWalkCounter + 1,
        mmp.speedWalkDir[mmp.speedWalkCounter]
      )
    )
  end
  mmp.hasty = true
  mmp.setmovetimer(2.5)
end

function mmp.openDoor()
  -- not going anywhere? don't do anything
  if not mmp.speedWalkDir[mmp.speedWalkCounter] then
    return
  end
  send(
    "open door " ..
    mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
      "runaway ", ""
    ),
    false
  )
  if mmp.settings.showcmds then
    cecho(
      string.format(
        "<red>(<maroon>%d - <dark_slate_grey>open door %s<red>)",
        #mmp.speedWalkDir - mmp.speedWalkCounter + 1,
        mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
          "runaway ", ""
        )
      )
    )
end
  mmp.hasty = true
  mmp.setmovetimer(getNetworkLatency())
end

function mmp.unlockDoor()
  -- not going anywhere? don't do anything
  if not mmp.speedWalkDir[mmp.speedWalkCounter] then
    return
  end
  send(
    "unlock door " ..
    mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
      "runaway ", ""
    ),
    false
  )
  if mmp.settings.showcmds then
    cecho(
      string.format(
        "<red>(<maroon>%d - <dark_slate_grey>unlock door %s<red>)",
        #mmp.speedWalkDir - mmp.speedWalkCounter,
        mmp.speedWalkDir[mmp.speedWalkCounter]:gsub("sprint ", ""):gsub("dash ", ""):gsub("gallop ", ""):gsub(
          "runaway ", ""
        )
      )
    )
  end
  mmp.hasty = true
  mmp.setmovetimer(getNetworkLatency())
end

function mmp.customwalkdelay(delay)
  mmp.setmovetimer(getNetworkLatency() + delay)
end

function mmp.stop()
  mmp.speedWalkPath = {}
  mmp.speedWalkDir = {}
  mmp.speedWalkCounter = 0
  stopStopWatch(mmp.speedWalkWatch)
  --if mmp.movetimer then killTimer( mmp.movetimer ) end
  mmp.autowalking = false
  -- clear all the temps we've got
  for trigger, ID in pairs(mmp.specials) do
    killTrigger(ID)
  end
  mmp.specials = {}
  mmp.echo("Stopped walking.")
  raiseEvent("mmapper stopped")
  if mmp.settings.shackle then
    expandAlias("wear shackle")
  end
end

-- Aetolia and Lusternia support showing balances in GMCP. This is easy to support, so we do!
-- if we can't move, setup a polling timer to prompt walking when we can again.
-- popular systems that expose balance & equilibrium values can be added here as well, perhaps though a similarly-named function.

function mmp.canmove(fromtimer)
  if mmp.mapperCanMove and mmp.mapperCanMove() then
    if fromtimer then
      mmp.move()
    else
      return true
    end
  elseif mmp.mapperCanMove then
    tempTimer(0.2, [[mmp.canmove(true)]])
    return false
  end
  if not gmcp.Char then
    return true
  end
  -- Achaea
  -- Lusternia
 if
    (
      gmcp.Char and
      (not gmcp.Char.Vitals.bal or gmcp.Char.Vitals.bal == "1") and
      (not gmcp.Char.Vitals.eq or gmcp.Char.Vitals.eq == "1") and
      (not gmcp.Char.Vitals.balance or gmcp.Char.Vitals.balance == "1") and
      (not gmcp.Char.Vitals.equilibrium or gmcp.Char.Vitals.equilibrium == "1") and
      (not gmcp.Char.Vitals.right_arm or gmcp.Char.Vitals.right_arm == "1") and
      (not gmcp.Char.Vitals.left_arm or gmcp.Char.Vitals.left_arm == "1") and
      (not gmcp.Char.Vitals.right_leg or gmcp.Char.Vitals.right_leg == "1") and
      (not gmcp.Char.Vitals.left_leg or gmcp.Char.Vitals.left_leg == "1") and
      (not gmcp.Char.Vitals.psisuper or gmcp.Char.Vitals.psisuper ~= "0") and
      (not gmcp.Char.Vitals.psisub or gmcp.Char.Vitals.psisub ~= "0") and
      (not gmcp.Char.Vitals.psiid or gmcp.Char.Vitals.psiid ~= "0") and
      (not gmcp.Char.Balance or gmcp.Char.Balance.List.balance == "1") and
      (not gmcp.Char.Balance or gmcp.Char.Balance.List.equilibrium == "1") and
      (not gmcp.Char.Balance or gmcp.Char.Balance.List.rarm == "1") and
      (not gmcp.Char.Balance or gmcp.Char.Balance.List.larm == "1") and
      (not gmcp.Char.Balance or gmcp.Char.Balance.List.legs == "1") and
      (not gmcp.Char.Vitals.prone or (gmcp.Char.Vitals.prone == "0" or gmcp.Char.Vitals.prone == 0)
    ))
  then
    if fromtimer then
      mmp.move()
    else
      return true
    end
  else
    tempTimer(0.2, [[mmp.canmove(true)]])
    return false
  end
end

local oldnum

function mmp.speedwalking(event, num)
  local num = tonumber(num) or tonumber(gmcp.Room.Info.num)
  if num ~= mmp.currentroom then
    mmp.previousroom = mmp.currentroom
  end
  mmp.currentroom = num
  mmp.currentroomname = getRoomName(num)
  -- Try to track if we're flying or not, for Imperian wings
  -- This is to avoid being "off path" if we FLY due to wings.
  local madeflight = false
  if gmcp.Room then
    local flying = false
    if string.find(gmcp.Room.Info.name, "^flying above") then
      flying = true
    end
    if mmp.flying and not flying then
      -- We were flying, and now we are not. Gravity!
      mmp.flying = false
    elseif not mmp.flying and flying then
      -- We were not flying and now we are.
      madeflight = true
      mmp.flying = true
    elseif not flying then
      mmp.flying = false
    end
  else
    mmp.flying = false
  end
  -- track if we're inside or outside, if possible
  if gmcp.Room then
    local areaID = getRoomArea(mmp.currentroom)
    if
      mmp.inside and
      not (
        table.contains(gmcp.Room.Info.details, "indoors") or
        table.contains(gmcp.Room.Info.details, "considered indoors")
      )
    then
      mmp.inside = false
      raiseEvent("mmapper went outside")
    elseif
      not mmp.inside and
      (
        table.contains(gmcp.Room.Info.details, "indoors") or
        table.contains(gmcp.Room.Info.details, "considered indoors"))
    then
      mmp.inside = true
      raiseEvent("mmapper went inside")
    end
    if
      #table.n_union(
        mmp.getareacontinents(getRoomArea(mmp.previousroom)),
        mmp.getareacontinents(getRoomArea(num))
      ) ~= #mmp.getareacontinents(getRoomArea(num))
    then
      raiseEvent("mmapper changed continent")
    end
    -- the event could cancel speedwalking - in this case quit
    if mmp.ignore_speedwalking then
      mmp.ignore_speedwalking = nil
      return
    end
  end
  if oldnum == num then
    return
  else
    oldnum = num
  end
  if not mmp.autowalking then
    return
  end
  if mmp.movetimer then
    killTimer(mmp.movetimer)
    mmp.movetimer = false
  end
  if num == mmp.speedWalkPath[#mmp.speedWalkPath] then
    local walktime = stopStopWatch(mmp.speedWalkWatch)
    mmp.echo(string.format("We've arrived! Took us %.1fs.\n", walktime))
    raiseEvent("mmapper arrived")
    if mmp.settings.shackle then
      expandAlias("wear shackle")
    end
    mmp.speedWalkPath = {}
    mmp.speedWalkDir = {}
    mmp.speedWalkCounter = 0
    mmp.autowalking = false
  elseif mmp.speedWalkPath[mmp.speedWalkCounter] == num then
    mmp.speedWalkCounter = mmp.speedWalkCounter + 1
    tempPromptTrigger(mmp.move, 1)
  elseif mmp.game == "imperian" and madeflight then
    mmp.echo("We began flying!")
    tempPromptTrigger(mmp.move, 1)
  elseif
    #mmp.speedWalkPath > 0 and
    not mmp.ferry_rooms[num] and
    not (gmcp.Room.Info.details and table.contains(gmcp.Room.Info.details, "ferry"))
  then
    -- ended up somewhere we didn't want to be, and this isn't a ferry room?
    speedWalkMoved = false
    -- re-calculate path then
    mmp.echo("Ended up off the path, recalculating a new path...")
    local destination = mmp.speedWalkPath[#mmp.speedWalkPath]
    if not mmp.getPath(num, destination) then
      mmp.echo(
        string.format(
          "Don't know how to get to %d (%s) anymore :( Move into a room we know of to continue",
          destination,
          getRoomName(destination)
        )
      )
    else
      mmp.gotoRoom(destination)
    end
  end
end

-- doSpeedWalk is used by the mudlet mapping script and should not be changed
function doSpeedWalk(dashtype)
  mmp.speedWalkDir = mmp.deepcopy(speedWalkDir)
  mmp.speedWalkPath = mmp.deepcopy(speedWalkPath)
  speedWalkDir, speedWalkPath = {}, {}
  resetStopWatch(mmp.speedWalkWatch)
  startStopWatch(mmp.speedWalkWatch)
  if
    mmp.settings["gallop"] or
    mmp.settings["dash"] or
    mmp.settings.sprint or
    mmp.settings.runaway or
    dashtype
  then
    mmp.fixPath(
      mmp.currentroom,
      mmp.speedWalkPath[#mmp.speedWalkPath],
      (mmp.settings["gallop"] and "gallop") or
      (mmp.settings["dash"] and "dash") or
      (mmp.settings.sprint and "sprint") or
      (mmp.settings.runaway and "runaway") or
      dashtype
    )
  end
  mmp.fixSpecialExits(mmp.speedWalkDir)
  if #mmp.speedWalkPath == 0 then
    mmp.autowalking = false
    mmp.echo("Couldn't find a path to the destination :(")
    raiseEvent("mmapper failed path")
    if mmp.settings.shackle then
      expandAlias("wear shackle")
    end
    return
  end
  -- this is a fix: convert nums to actual numbers
  for i = 1, #mmp.speedWalkPath do
    mmp.speedWalkPath[i] = tonumber(mmp.speedWalkPath[i])
  end
  mmp.autowalking = true
  raiseEvent("s")
  if mmp.settings.shackle then
    expandAlias("remove shackle")
  end
  if not mmp.paused then
    mmp.echon("Starting speedwalk from " .. (atcp.RoomNum or gmcp.Room.Info.num) .. " to ")
    cechoLink(
      "<" .. mmp.settings.echocolour .. ">" .. mmp.speedWalkPath[#mmp.speedWalkPath],
      'mmp.gotoRoom "' .. mmp.speedWalkPath[#mmp.speedWalkPath] .. '"',
      'Go to ' .. mmp.speedWalkPath[#mmp.speedWalkPath],
      true
    )
    echo(": ")
    mmp.speedWalkCounter = 1
    if mmp.canmove() then
      mmp.hasty = true
      mmp.setmovetimer(0.1, true)
    else
      echo("(when we get balance back / aren't hindered)")
    end
  else
    mmp.echo(
      "Will go to " ..
      mmp.speedWalkPath[#mmp.speedWalkPath] ..
      " as soon as the mapper is unpaused."
    )
  end
end

function mmp.failpath()
  if mmp.movetimer then
    local walktime = stopStopWatch(mmp.speedWalkWatch)
    mmp.echo(string.format("Can't continue further! Took us %.1fs to get here.\n", walktime))
  end
  mmp.autowalking = false
  if mmp.settings.shackle then
    expandAlias("wear shackle")
  end
  mmp.speedWalkPath = {}
  mmp.speedWalkDir = {}
  mmp.speedWalkCounter = 0
  if mmp.movetimer then
    killTimer(mmp.movetimer)
    mmp.movetimer = nil
  end
  raiseEvent("mmapper failed path")
end

function mmp.changeBoolFunc(name, option)
  local en
  en = option and "will now use" or "will no longer use"
  mmp.echo("<green>Okay, the mapper " .. en .. " <white>" .. name .. "<green>!")
end

function mmp.fixPath(rFrom, rTo, dashtype)
  local currentPath, currentIds = {}, {}
  local dRef = {["n"] = "north", ["e"] = "east", ["s"] = "south", ["w"] = "west"}
  if not getPath(rFrom, rTo) then
    return false
  end
  -- Logic: Look for a direction repeated at least two times.
  -- count the number of times it repeats, then look that many rooms ahead.
  -- if that room also contains the direction we're headed, just travel that many directions.
  -- otherwise, dash.
  local repCount = 1
  local index = 1
  local dashExaust = false
  while mmp.speedWalkDir[index] do
    if not table.contains(getSpecialExits(mmp.speedWalkPath[index]), mmp.speedWalkDir[index]) then
      dashExaust = false
      repCount = 1
      while mmp.speedWalkDir[index + repCount] == mmp.speedWalkDir[index] do
        repCount = repCount + 1
        if repCount == 11 then
          dashExaust = true
          break
        end
      end
      if repCount > 1 then
        -- Found direction repetition. Calculate dash path.
        local exits = getRoomExits(mmp.speedWalkPath[index + (repCount - 1)])
        local pname = ""
        for word in mmp.speedWalkDir[index]:gmatch("%w") do
          pname = pname .. (dRef[word] or word)
        end
        if not exits[pname] or dashExaust then
          -- Final room in this direction does not continue, dash!
          table.insert(currentPath, string.format("%s %s", dashtype, mmp.speedWalkDir[index]))
          currentIds[#currentIds + 1] = mmp.speedWalkPath[index + repCount - 1]
        else
          -- Final room in this direction continues onwards, don't dash unless on achaea
          if mmp.game == "achaea" then
            table.insert(
              currentPath, string.format("%s %s %s", dashtype, mmp.speedWalkDir[index], repCount)
            )
            currentIds[#currentIds + 1] = mmp.speedWalkPath[index + repCount - 1]
          else
            for i = 1, repCount do
              table.insert(currentPath, mmp.speedWalkDir[index])
              currentIds[#currentIds + 1] = mmp.speedWalkPath[index + i - 1]
            end
          end
        end
        index = index + repCount
      else
        -- No repetition, just add the direction.
        table.insert(currentPath, mmp.speedWalkDir[index])
        currentIds[#currentIds + 1] = mmp.speedWalkPath[index]
        index = index + 1
      end
    else
      -- Special exit, skip over this step
      table.insert(currentPath, mmp.speedWalkDir[index])
      currentIds[#currentIds + 1] = mmp.speedWalkPath[index]
      index = index + 1
    end
  end
  mmp.speedWalkDir = currentPath
  mmp.speedWalkPath = currentIds
  return true
end

-- a certain version of the mapper gave us special exits prepended with 0 or 1 in the command
-- depending on if it was locked. Need to remove these before we can use them

function mmp.fixSpecialExits(directions)
  for i = 1, #directions do
    if directions[i]:match("^%d") then
      directions[i] = directions[i]:sub(2)
    end
  end
end

-- cleanup function to remove the temp special exit we made

function mmp.clearspecials(deleterooms)
  local t = getSpecialExits(mmp.currentroom)
  for connectingroom, exits in pairs(t) do
    if table.contains(deleterooms, connectingroom) then
      -- delete the special exits linking to this room
      for command, locked in pairs(exits) do
        removeSpecialExit(mmp.currentroom, command)
      end
    end
  end
end

function mmp.getShortestOfMultipleRooms(possibleRooms)
  local shortestWeight, closestRoom = 10000000, 0
  local checkedsofar, outoftime = 0, false
  local getStopWatchTime, tonumber = getStopWatchTime, tonumber

  -- allocate only 500ms to finding the shortest path, or more if we failed to find anything
  mmp.computeShortestWatch = mmp.computeShortestWatch or createStopWatch()
  startStopWatch(mmp.computeShortestWatch)
  raiseEvent("mmp link externals")

  -- mmp.echo(string.format("Have %s rooms nodes, %ss taken so far...", table.size(possibleRooms), getStopWatchTime(mmp.computeShortestWatch)))
  for _, id in pairs(possibleRooms) do
    local possible, thisWeight = getPath(mmp.currentroom, tonumber(id))
    if possible and thisWeight < shortestWeight then
      shortestWeight = thisWeight
      closestRoom = tonumber(id)
    end
    checkedsofar = checkedsofar + 1
    if (getStopWatchTime(mmp.computeShortestWatch) >= .5) then
      outoftime = true
      break
    end

    -- mmp.echo(string.format("pathed from %s to %s, running time so far: %s", mmp.currentroom, id, getStopWatchTime(mmp.computeShortestWatch)))
  end
  --mmp.echo(string.format("total time took: %s", getStopWatchTime(mmp.computeShortestWatch)))
  stopStopWatch(mmp.computeShortestWatch)
  return closestRoom, outoftime, checkedsofar
end

function mmp.gotoAreaID(areaid, number, dashtype)
  if not areaid or not tonumber(areaid) then
    mmp.echo("To where do you want to go?")
    return
  end
  areaid = tonumber(areaid)
  if not mmp.areatabler[areaid] then
    mmp.echo("Invalid area ID selected")
    return
  end
  local possibleRooms, shortestBorder = {}, 0
  for id,_ in pairs(mmp.getAreaBorders(areaid)) do
    possibleRooms[#possibleRooms+1] = id
  end
  shortestBorder, outoftime, checkedsofar = mmp.getShortestOfMultipleRooms(possibleRooms)
  if shortestBorder == 0 then
    if outoftime then
      mmp.echo(
        string.format(
          "I checked %d of the %d possible exits \"%s\" has, but none of the ways there worked and it was taking too long :( try doing this again?",
          checkedsofar,
          table.size(possibleRooms),
          getRoomAreaName(areaid)
        )
      )
    else
      mmp.echo(
        "Checked " ..
        table.size(possibleRooms) ..
        " exits in that area, and none of them worked :( I Don't know how to get you there."
      )
    end
    mmp.speedWalkPath = {}
    mmp.speedWalkDir = {}
    mmp.speedWalkCounter = 0
    raiseEvent("mmapper failed path")
    raiseEvent("mmp clear externals")
    return
  end
  raiseEvent("mmp clear externals")
  mmp.gotoRoom(shortestBorder, dashtype, "area")
end

function mmp.gotoFeature(partialFeatureName, dashtype)
  local mapFeatures = mmp.getMapFeatures()
  local feature
  if mapFeatures[partialFeatureName:lower()] then
    feature = partialFeatureName:lower()
  else
    for key in pairs(mapFeatures) do
      if key:find(partialFeatureName:lower()) then
        feature = key
        break
      end
    end
  end
  if not feature then
    mmp.echo("No feature like " .. partialFeatureName .. " found.")
    return
  end
  local possibleRooms = searchRoomUserData("feature-" .. feature, "true")
  closestFeature, outoftime, checkedsofar = mmp.getShortestOfMultipleRooms(possibleRooms)
  if closestFeature == 0 then
    if outoftime then
      mmp.echo(
        string.format(
          "I checked %d of the %d possible features \"%s\" has, but none of the ways there worked and it was taking too long :( try doing this again?",
          checkedsofar,
          table.size(possibleRooms),
          partialFeatureName
        )
      )
    else
      mmp.echo(
        "Checked " ..
        table.size(possibleRooms) ..
        " rooms with that feature, and none of them worked :( I Don't know how to get you there."
      )
    end
    mmp.speedWalkPath = {}
    mmp.speedWalkDir = {}
    mmp.speedWalkCounter = 0
    raiseEvent("mmapper failed path")
    raiseEvent("mmp clear externals")
    return
  end
  raiseEvent("mmp clear externals")
  mmp.gotoRoom(closestFeature, dashtype, "room")
end