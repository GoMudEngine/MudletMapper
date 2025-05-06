function mmp.filterRooms(rooms, area)
  local unassignedRooms = {}
  local areaRooms = {}
  for roomnum, roomname in pairs(rooms) do
    local roomarea = getRoomUserData(roomnum, "Game Area")
    if roomarea == "" then
      unassignedRooms[roomnum] = roomname
    elseif roomarea == area then
      areaRooms[roomnum] = roomname
    end
  end
  return next(areaRooms) and areaRooms or unassignedRooms
end

-- for a given room name, we'll echo all the vnums

function mmp.echonums(roomname, area)
  local t = mmp.searchRoomExact(roomname)
  if area then
    t = mmp.filterRooms(t, area)
  end
  if not next(t) then
    echo("?")
    return nil
  end
  -- transform the kv table into a table of tables for cleaner code.
  -- + perhaps Mudlet in future will give this us anyway, sorted by relevancy
  local dt = {}
  for roomid, room in pairs(t) do
    dt[#dt + 1] = {name = room, id = roomid}
  end
  -- we can have nothing if we asked for exact match
  if not dt[1] then
    echo("?---")
    return
  end
  -- display first three ids. Can't really nicely table.concat them.
  cechoLink(
    "<" .. mmp.settings.echocolour .. ">" .. dt[1].id,
    'mmp.gotoRoom(' .. dt[1].id .. ')',
    string.format("Go to %s (%s)", dt[1].id, dt[1].name),
    true
  )
  if not dt[2] then
    return
  end
  echo(", ")
  cechoLink(
    "<" .. mmp.settings.echocolour .. ">" .. dt[2].id,
    'mmp.gotoRoom(' .. dt[2].id .. ')',
    string.format("Go to %s (%s)", dt[2].id, dt[2].name),
    true
  )
  if not dt[3] then
    return
  end
  echo(", ")
  cechoLink(
    "<" .. mmp.settings.echocolour .. ">" .. dt[3].id,
    'mmp.gotoRoom(' .. dt[3].id .. ')',
    string.format("Go to %s (%s)", dt[3].id, dt[3].name),
    true
  )
  if not dt[4] then
    return
  end
  echo(", ...")
end

function mmp.roomEcho(query)
  local result = mmp.searchRoom(query)
  if not tonumber(select(2, next(result))) then
    for roomid, roomname in pairs(result) do
      roomid = tonumber(roomid)
      cecho("<DarkSlateGrey> (")
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. roomid,
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho("<DarkSlateGrey>)")
    end
  else
    for roomname, roomid in pairs(result) do
      roomid = tonumber(roomid)
      cecho("<DarkSlateGrey> (")
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. roomid,
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho("<DarkSlateGrey>)")
    end
  end
end

function mmp.locateAndEcho(room, person, area)
  local t = mmp.searchRoomExact(room)
  if area then
    t = mmp.filterRooms(t, area)
  end
  echo("  (")
  mmp.echonums(room, area)
  echo(")")
  -- lowercase results
  for k, v in pairs(t) do
    if tonumber(k) then
      t[k] = v:lower()
    else
      t[k:lower()] = v
    end
  end
  if not (t[room:lower()] or table.contains(t, room:lower())) then
    return
  end
  echo("\n")
  if table.size(t) == 1 then
    local k, v = next(t)
    cecho(
      "<red>From your knowledge, that room is in <orange_red>" ..
      mmp.cleanAreaName(mmp.areatabler[getRoomArea(type(k) == "number" and k or v)] or "?") ..
      "<red>."
    )
  else
    local k, v = next(t)
    local areas = {}
    if type(k) == "number" then
      for k, _ in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    else
      for _, k in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    end
    local flattened_areas = {}
    for k, _ in pairs(areas) do
      if k ~= "" then
        flattened_areas[#flattened_areas + 1] = mmp.cleanAreaName(k)
      end
    end
    cecho(
      "<red>From your knowledge, that room might be in <orange_red>" ..
      table.concat(flattened_areas, ", or ") ..
      "<red>."
    )
  end
  if person then
    mmp.pdb[person] = room
    mmp.pdb_lastupdate[person] = true
    raiseEvent("mmapper updated pdb")
  end
end

function mmp.locateAndEchoSide(room, person)
  local t = mmp.searchRoomExact(room)
  echo("  (")
  mmp.echonums(room)
  echo(")")
  -- lowercase results
  for k, v in pairs(t) do
    if tonumber(k) then
      t[k] = v:lower()
    else
      t[k:lower()] = v
    end
  end
  if not (t[room:lower()] or table.contains(t, room:lower())) then
    return
  end
  --echo"\n"
  if table.size(t) == 1 then
    local k, v = next(t)
    cecho(
      "<red>  (" ..
      mmp.cleanAreaName(mmp.areatabler[getRoomArea(type(k) == "number" and k or v)] or "?") ..
      ")"
    )
  else
    local k, v = next(t)
    local areas = {}
    if type(k) == "number" then
      for k, _ in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    else
      for _, k in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    end
    local flattened_areas = {}
    for k, _ in pairs(areas) do
      if k ~= "" then
        flattened_areas[#flattened_areas + 1] = mmp.cleanAreaName(k)
      end
    end
    cecho("<red> (" .. table.concat(flattened_areas, ", ") .. ")")
  end
  if person then
    mmp.pdb[person] = room
    mmp.pdb_lastupdate[person] = true
    raiseEvent("mmapper updated pdb")
  end
end

function mmp.locateAndEchoInternal(room, person)
  local t = mmp.searchRoomExact(room)
  -- lowercase results
  for k, v in pairs(t) do
    if tonumber(k) then
      t[k] = v:lower()
    else
      t[k:lower()] = v
    end
  end
  if not (t[room:lower()] or table.contains(t, room:lower())) then
    return
  end
  --echo"\n"
  if table.size(t) == 1 then
    local k, v = next(t)
    cecho(
      "<red> in " ..
      mmp.cleanAreaName(mmp.areatabler[getRoomArea(type(k) == "number" and k or v)] or "?") ..
      "."
    )
  else
    local k, v = next(t)
    local areas = {}
    if type(k) == "number" then
      for k, _ in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    else
      for _, k in pairs(t) do
        areas[mmp.areatabler[getRoomArea(k)] or "?"] = true
      end
    end
    local flattened_areas = {}
    for k, _ in pairs(areas) do
      if k ~= "" then
        flattened_areas[#flattened_areas + 1] = mmp.cleanAreaName(k)
      end
    end
    cecho("<red> in " .. table.concat(flattened_areas, ", ") .. ".")
  end
  echo("  (")
  mmp.echonums(room, true)
  echo(")")
  if person then
    mmp.pdb[person] = room
    mmp.pdb_lastupdate[person] = true
    raiseEvent("mmapper updated pdb")
  end
end