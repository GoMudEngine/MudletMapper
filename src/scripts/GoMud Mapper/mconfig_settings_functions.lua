function mmp.doLock(what, lock, filter)
  if what then mmp.echo(string.format("%s all %s...", (lock and "Locking" or "Unlocking"), what)) end
  local c = 0

  local getAreaRooms, getSpecialExits, lockSpecialExit, next = getAreaRooms, getSpecialExits, lockSpecialExit, next
  for _, area in pairs(getAreaTable()) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)

       if exits and next(exits) then
         for exit, cmd in pairs(exits) do
           if type(cmd) == "table" then cmd = next(cmd) end

           if (not filter and not (cmd:lower():find("pathfind", 1, true) or cmd:lower():find("worm warp", 1, true) or cmd:lower():find("enter grate", 1, true))) or (filter and cmd:lower():find(filter, 1, true)) then
             lockSpecialExit(rooms[i], exit, cmd, lock)
             c = c + 1
           end
         end
       end
    end
  end

  if what then mmp.echo(string.format("%s %s known %s.", (lock and "Locked" or "Unlocked"), c, what)) end
  return c
end

function mmp.changeEchoColour()
    mmp.echo("Now displaying echos in <"..mmp.settings.echocolour..">"..mmp.settings.echocolour )
end

function mmp.changeLaglevel()
    local laglevel = mmp.settings.laglevel
    local laginfo = mmp.lagtable[laglevel]
    mmp.echo(string.format("Lag level set to [%d]: %s (%ss timer)", laglevel, laginfo.description, tostring(laginfo.time)))
end

function mmp.verifyLaglevel(value)
  if mmp.lagtable[value] then return true end
  return false
end

function mmp.lockPathways()
  local lock = mmp.settings.lockpathways and true or false
  mmp.doLock("pathways", lock, "pathfind")
end

function mmp.lockSewers()
  local lock = mmp.settings.locksewers and true or false
  return mmp.doLock("sewer grates", lock, "enter grate")
end

function mmp.lockWormholes()
  local lock = mmp.settings.lockwormholes and true or false
  return mmp.doLock("wormholes", lock, "worm warp")
end
tempTimer(0, function() if mmp.firstRun then mmp.lockWormholes() end end)

function mmp.lockPebble()
  local disabled = (not mmp.settings.pebble) and true or false
  mmp.doLock(nil, disabled, "touch 116998")
  mmp.doLock(nil, disabled, "touch 277930")

  mmp.echo(string.format("Use of pebble %s.", disabled and "disabled" or "enabled"))
end

function mmp.lockSpecials()
  local lock = mmp.settings.lockspecials and true or false
  mmp.doLock("special exits", lock)
end


function mmp.changeMapSource()
  local use = mmp.settings.crowdmap and true or false
  if use and not (mmp.game == "achaea" or mmp.game == "starmourn" or mmp.game == "lusternia" or mmp.game == "stickmud" or mmp.game == "imperian" or mmp.game == "aetolia") then
    mmp.echo("Sorry - the crowdsourced map is only available for use in Achaea, Starmourn, Lusternia, StickMUD. If you'd like to help start one for your game, please post at http://forums.mudlet.org/viewtopic.php?f=13&t=1696. If you are playing one of the games, then it is likely that you just downloaded the script - and it doesn't know what you are playing. Reconnect and it'll know.")
    mmp.settings.crowdmap = false
  elseif use and not loadMap then
   mmp.echo("Sorry - your Mudlet is too old and can't load maps. Please update: http://forums.mudlet.org/viewtopic.php?f=5&t=1874")
   mmp.settings.crowdmap = false
  elseif use then
    mmp.echo("Will use the crowdsourced map for updates instead!")
    mmp.checkforupdate()
  else
    mmp.echo("Will use the default game map for updates.")
  end
end

function mmp.setWingsLanguage()
  mmp.echo("Alright, will say Duanathar and Duanathar in "..mmp.settings.winglanguage:title()..".")
end

function mmp.setWingsRemoval()
  mmp.echo("Okay - "..(mmp.settings.removewings and "will" or "won't").." remove wings after using them.")
end

function mmp.setSlowWalk()
  if mmp.settings.slowwalk then
    mmp.echo("Will walk 'slowly' - that is, only try to move in a direction once per room, and move again once we've arrived. This will make us better walkers when it's very laggy, as we won't spam directions unnecessarily and miss certain turns - but it does mean that if we fail to move for some reason, we won't retry again either at all.")
  else
    mmp.echo("Will walk as quick as we can!")
  end
end

function mmp.disableWaterWalk()
  local c = 0
  local getRoomEnv, setRoomWeight = getRoomEnv, setRoomWeight
  for roomid, roomname in pairs(getRooms()) do
    if mmp.waterenvs[getRoomEnv(roomid)] then
      setRoomWeight(roomid, 3)
      c = c + 1
    end
  end

  return c
end

function mmp.enableWaterWalk()
  local c = 0
  local getRoomEnv, setRoomWeight = getRoomEnv, setRoomWeight
  for roomid, roomname in pairs(getRooms()) do
    if mmp.waterenvs[getRoomEnv(roomid)] then
      setRoomWeight(roomid, 1)
      c = c + 1
    end
  end

  return c
end

function mmp.setWaterWalk()
  if mmp.settings.waterwalk then
    mmp.echo("Enabled waterwalk for "..mmp.enableWaterWalk().." rooms - so we'll be treating land and water rooms the same now in terms of traverse speed over them.")
  else
    mmp.echo("Disabled waterwalk for "..mmp.disableWaterWalk().." rooms - so we'll be preferring land rooms over water ones wherever it's quicker.")
  end
end

function mmp.setOrb(city)
  if mmp.settings["orb"..city:lower()] then
    mmp.echo("<green>Okay, we won't use wings in <white>" .. city:title().."<green>!")
  else
    mmp.echo("<green>Okay, we will use wings in <white>" .. city:title().."<green>!")
  end
end
