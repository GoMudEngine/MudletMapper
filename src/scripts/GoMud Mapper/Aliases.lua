function mmp.roomWhoFind(query)
  if query:ends('.') then
    query = query:sub(1, -2)
  end
  local result = mmp.searchRoomExact(query)
  if type(result) == "string" or not next(result) then
    cecho("<CadetBlue>  You have no recollection of any room with that name.")
    return
  end
  if not tonumber(select(2, next(result))) then
    -- old style
    for roomid, roomname in pairs(result) do
      roomid = tonumber(roomid)
      cecho(string.format("  <LightSlateGray>%s<DarkSlateGrey> (", tostring(roomname)))
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. roomid,
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho(
        string.format(
          "<DarkSlateGrey>) <white>%s<DarkSlateGrey>.\n",
          tostring(mmp.areatabler[getRoomArea(roomid)])
        )
      )
    end
  else
    -- new style
    for roomname, roomid in pairs(result) do
      roomid = tonumber(roomid)
      cecho(string.format("  <LightSlateGray>%s<DarkSlateGrey> (", tostring(roomname)))
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. roomid,
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho(
        string.format(
          "<DarkSlateGrey>) <white>%s<DarkSlateGrey>.\n",
          tostring(mmp.areatabler[getRoomArea(roomid)])
        )
      )
    end
  end
end

function mmp.roomFind(query, lines)
  if query:ends('.') then
    query = query:sub(1, -2)
  end
  local defaultLine = 30 -- this could this to a setting instead of a static number
  local result = mmp.searchRoom(query)
  if lines == 'all' then
    lines = table.size(result)
  end
  lines = (lines ~= '') and tonumber(lines) or defaultLine

  --create a new table (roomsTable) with keys and add areas to the table
  local roomsTable = {}
  for k, v in pairs(result) do
    --not all rooms have an area associated with it in mmp.areatabler so need to either remove those or add one
    local a = mmp.areatabler[getRoomArea(k)] or "unknown"
    roomsTable[#roomsTable + 1] = {num = k, area = a, name = v}
  end
  --sort roomsTable by area name
  table.sort(
    roomsTable,
    function(a, b)
      return a.area < b.area
    end
  )
  --start displaying info
  if type(result) == "string" or not next(result) then
    cecho("<grey>You have no recollection of any room with that name.")
    return
  end
  cecho("<DarkSlateGrey>You know the following relevant rooms:\n")

  local function showmeropis(roomid)
    if mmp.game ~= "achaea" then
      return ''
    end
    return mmp.oncontinent(getRoomArea(roomid), "Main") and '' or ' (Meropis)'
  end

  local i = 1
  if not tonumber(select(2, next(result))) then
    cecho(string.format("<white> %-10s%-40s%s\n", "ROOM ID", "ROOM NAME", "ROOM AREA"))
    for _, v in ipairs(roomsTable) do
      if i > lines then
        break
      end
      roomid = tonumber(v.num)
      roomname = v.name
      roomarea = v.area
      cechoLink(
        string.format("<" .. mmp.settings.echocolour .. "> %-10s", roomid),
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho(string.format("<LightSlateGray>%-40s", string.sub(tostring(roomname), 1, 39)))
      cechoLink(
        string.format(
          "<DarkSlateGrey>%s%s<DarkSlateGrey>\n",
          mmp.cleanAreaName(tostring(mmp.areatabler[getRoomArea(roomid)])),
          showmeropis(roomid)
        ),
        [[mmp.echoPath(mmp.currentroom, ]] .. roomid .. [[)]],
        "Display directions from here to " .. roomname,
        true
      )
      resetFormat()
      i = i + 1
    end
  else
    -- new style
    --- not sure what this new area code is but it doesn't seem to fire
    for roomname, roomid in pairs(result) do
      roomid = tonumber(roomid)
      cecho(string.format("  <LightSlateGray>%s<DarkSlateGrey> (", tostring(roomname)))
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. roomid,
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho(
        string.format(
          "<DarkSlateGrey>) in <LightSlateGray>%s%s<DarkSlateGrey>.",
          mmp.cleanAreaName(tostring(mmp.areatabler[getRoomArea(roomid)])),
          showmeropis(roomid)
        )
      )
      fg("DarkSlateGrey")
      echoLink(
        " > Show path\n",
        [[mmp.echoPath(mmp.currentroom, ]] .. roomid .. [[)]],
        "Display directions from here to " .. roomname,
        true
      )
      resetFormat()
    end
  end
  if table.size(result) <= lines then
    cecho(string.format("<DarkSlateGrey>%d rooms found.\n", table.size(result)))
  else
    lastRoomQuery = query
    cechoLink(
      string.format(
        "<DarkSlateGrey>%d of %d rooms shown. Click to see all rooms.\n", lines, table.size(result)
      ),
      'mmp.roomFind(lastRoomQuery, "all")',
      string.format("Show all %d rooms.", table.size(result)),
      true
    )
  end
end

function mmp.echoRoomList(areaname, exact)
  local areaid, msg, multiples = mmp.findAreaID(areaname, exact)
  if areaid then
    local roomlist, endresult = getAreaRooms(areaid) or {}, {}
    -- obtain a room list for each of the room IDs we got
    local getRoomName = getRoomName
    for _, id in pairs(roomlist) do
      endresult[id] = getRoomName(id)
    end
    -- sort room IDs so we can display them in order
    table.sort(roomlist)
    -- now display something half-decent looking
    cecho(
      string.format(
        "<DarkSlateGrey>List of all rooms in <grey>%s<DarkSlateGrey> (areaid <grey>%s<DarkSlateGrey> - <grey>%d<DarkSlateGrey> rooms):\n",
        msg,
        areaid,
        table.size(endresult)
      )
    )
    local echoLink, sformat, fg, echo = echoLink, string.format, fg, cecho
    -- use pairs, as we can have gaps between room IDs
    for _, roomid in pairs(roomlist) do
      local roomname = endresult[roomid]
      fg("blue")
      cechoLink(
        "<" .. mmp.settings.echocolour .. ">" .. sformat("%6s", roomid),
        'mmp.gotoRoom(' .. roomid .. ')',
        string.format("Go to %s (%s)", roomid, tostring(roomname)),
        true
      )
      cecho(string.format("<DarkSlateGrey>: <LightSlateGray>%s<DarkSlateGrey>.\n", roomname))
    end
  elseif not id and #multiples > 0 then
    mmp.echo("For which area would you want to list rooms for?")
    fg("DimGrey")
    for _, areaname in ipairs(multiples) do
      echo("  ");
      setUnderline(true)
      echoLink(
        areaname,
        'mmp.echoRoomList("' .. areaname .. '", true)',
        "Click to view the room list for " .. areaname,
        true
      )
      setUnderline(false)
      echo("\n")
    end
    resetFormat()
  else
    mmp.echo(string.format("Don't know of any area named '%s'.", areaname))
  end
end

function mmp.echoAreaList()
  local list = getAreaTable()
  local ids, rlist = {}, {}
  local totalroomcount = 0
  for area, id in pairs(list) do
    if id ~= 0 then
      ids[#ids + 1] = id;
      rlist[id] = area
    end
  end
  table.sort(ids)
  -- count the amount of rooms in an area, taking care to count the room in the 0th
  -- index as well if there is one
  -- saves the total room count on the side as well

  local function countrooms(areaid)
    local allrooms = getAreaRooms(areaid) or {}
    local areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
    totalroomcount = totalroomcount + areac
    return areac
  end

  cecho(string.format("<DarkSlateGrey>List of all areas we know of (click to view room list):\n"))
  local getAreaRooms, cecho, fg, echoLink, format, rep =
    getAreaRooms, cecho, fg, echoLink, string.format, string.rep
  for _, id in pairs(ids) do
    cecho(format("<" .. mmp.settings.echocolour .. ">%s%d ", rep(" ", (7 - #tostring(id))), id))
    -- +1 because getAreaRooms starts counting at 0
    fg("DarkSlateGrey")
    echoLink(
      rlist[id] .. (" "):rep(40 - #rlist[id]) .. "(" .. mmp.comma_value(countrooms(id)) .. " rooms)",
      'mmp.echoRoomList("' .. rlist[id] .. '", true)',
      "View the room list for " .. rlist[id],
      true
    )
    echo("\n")
  end
  cecho(
    string.format(
      "<DarkSlateGrey>Total amount of rooms in this map: %s\n", mmp.comma_value(totalroomcount)
    )
  )
end

function mmp.clearLabels(areaid)
  local function clearlabels(areaid)
    local t = getMapLabels(areaid)
    if type(t) ~= "table" then
      return
    end
    for labelid, _ in pairs(t) do
      deleteMapLabel(areaid, labelid)
    end
  end

  if areaid == "map" then
    for areaid in pairs(mmp.areatabler) do
      clearlabels(areaid)
    end
    mmp.echo("Cleared labels in all of the map.")
    return
  end
  clearlabels(areaid)
  mmp.echo(string.format("Cleared all labels in '%s'.", mmp.areatabler[areaid]))
end

function mmp.deleteArea(name, exact)
  local id, fname, ma = mmp.findAreaID(name, exact)
  if id then
    mmp.doareadelete(id)
  elseif next(ma) then
    mmp.echo("Which one of these specifically would you like to delete?")
    fg("DimGrey")
    for _, name in ipairs(ma) do
      echo("  ")
      setUnderline(true)
      echoLink(name, [[mmp.deleteArea("]] .. name .. [[", true)]], "Delete " .. name, true)
      setUnderline(false)
      echo("\n")
    end
    resetFormat()
  else
    mmp.echo("Don't know of that area.")
  end
  raiseEvent("mmp areas changed")
end

-- the function actually doing area deletion

function mmp.doareadelete(areaid)
  mmp.deletingarea = {}
  local t = mmp.deletingarea
  local rooms = getAreaRooms(areaid)
  t.roomcount = table.size(rooms)
  t.roombatches = {}
  t.currentbatch = 1
  t.areaid = areaid
  t.areaname = getAreaTableSwap()[areaid]
  -- delete the area right away if there's nothing in it
  if t.roomcount == 0 then
    deleteArea(t.areaid)
    mmp.echo("All done! The area was already gone/empty.")
  end
  local rooms_per_batch = 100
  -- split up rooms into tables of tables, to be deleted in batches so
  -- that our print statements in between get a chance to be processed
  for batch = 1, t.roomcount, 100 do
    t.roombatches[#t.roombatches + 1] = {}
    local onebatch = t.roombatches[#t.roombatches]
    for inbatch = 1, 100 do
      onebatch[#onebatch + 1] = rooms[batch + inbatch]
    end
  end

  function mmp.deletenextbatch()
    local t = mmp.deletingarea
    if not t then
      return
    end
    local currentbatch = t.roombatches[t.currentbatchi]
    if currentbatch == nil then
      deleteArea(t.areaid)
      mmp.echo("All done! Deleted the '" .. t.areaname .. "' area.")
      mmp.deletingarea = nil
      centerview(mmp.currentroom)
      return
    end
    local deleteRoom = deleteRoom
    for i = 1, #currentbatch do
      deleteRoom(currentbatch[i])
    end
    mmp.echo(
      string.format(
        "Deleted %d batch%s so far, %d left to go - %.2f%% done out of %d needed",
        t.currentbatchi,
        (t.currentbatchi == 1 and '' or 'es'),
        #t.roombatches - t.currentbatchi,
        (100 / #t.roombatches) * t.currentbatchi,
        #t.roombatches
      )
    )
    t.currentbatchi = t.currentbatchi + 1
    tempTimer(0.010, mmp.deletenextbatch)
  end

  t.currentbatchi = 1
  mmp.echo("Prepped room batches, starting deletion...")
  tempTimer(0.010, mmp.deletenextbatch)
end

function mmp.renameArea(name, exact)
  if not (mmp.currentroom or getRoomArea(mmp.currentroom)) then
    mmp.echo("Don't know what area are we in at the moment, to rename it.")
  else
    setAreaName(getRoomArea(mmp.currentroom), name)
    mmp.echo(
      string.format(
        "Renamed %s to %s (%d).",
        mmp.areatabler[getRoomArea(mmp.currentroom)],
        name,
        getRoomArea(mmp.currentroom)
      )
    )
    centerview(mmp.currentroom)
  end
  raiseEvent("mmp areas changed")
end

function mmp.roomArea(otherroom, name, exact)
  local id, fname, ma
  if tonumber(name) then
    id = tonumber(name);
    fname = mmp.areatabler[id]
  else
    id, fname, ma = mmp.findAreaID(name, exact)
  end
  if otherroom ~= "" and not mmp.roomexists(otherroom) then
    mmp.echo("Room id " .. otherroom .. " doesn't seem to exist.")
    return
  elseif otherroom == "" and not mmp.roomexists(mmp.currentroom) then
    mmp.echo("Don't know where we are at the moment.")
    return
  end
  otherroom = otherroom ~= "" and otherroom or mmp.currentroom
  if id then
    setRoomArea(otherroom, id)
    mmp.echo(
      string.format(
        "Moved %s to %s (%d).",
        (getRoomName(otherroom) ~= "" and getRoomName(otherroom) or "''"),
        fname,
        id
      )
    )
    centerview(otherroom)
  elseif next(ma) then
    mmp.echo("Into which area exactly would you like to move the room?")
    fg("DimGrey")
    for _, name in ipairs(ma) do
      echo("  ")
      setUnderline(true)
      echoLink(
        name, [[mmp.roomArea('', "]] .. name .. [[", true)]], "Move the room to " .. name, true
      )
      setUnderline(false)
      echo("\n")
    end
    resetFormat()
  else
    mmp.echo("Don't know of that area.")
  end
end

function mmp.getAreaBorders(areaid)
  if mmp.debug then
    mmp.getAreaBordersTimer = mmp.getAreaBordersTimer or createStopWatch()
    startStopWatch(mmp.getAreaBordersTimer)
  end
  -- make sure we have all exits into the area.
  raiseEvent("mmp link externals")
  local roomlist, endresult = getAreaRooms(areaid), {}
  -- sometimes getAreaRooms can give us no result :(
  if not roomlist then
    mmp.echo(
      "Sorry, seems we can't go there - getAreaRooms(" ..
      areaid ..
      ") didn't give us any results (Mudlet problem - redownloading the map might help fix it)"
    )
    return
  end
  if table.is_empty(roomlist) then
    mmp.echo(
      "Sorry, seems we can't go there - " .. getRoomAreaName(areaid) .. " has no rooms in it."
    )
    return
  end
  -- make a key-value list of room IDs
  local reverselist = {}
  for i = 0, #roomlist do
    reverselist[roomlist[i]] = true
  end
  local getRoomName, contains, pairs = getRoomName, table.contains, pairs
  if getAllRoomEntrances then
    for i = 0, #roomlist do
      local id = roomlist[i]
      local entrancesFrom = getAllRoomEntrances(id)
      for remoteRoomIndex = 1, #entrancesFrom do
        if not reverselist[entrancesFrom[remoteRoomIndex]] then
          endresult[id] = getRoomName(id)
        end
      end
    end
  else
    local getRoomExits, getSpecialExitsSwap = getRoomExits, getSpecialExitsSwap
    -- obtain a room list for each of the room IDs we got
    --for _, id in pairs(roomlist) do
    for i = 0, #roomlist do
      local id = roomlist[i]
      local exits = getRoomExits(id)
      for _, to in pairs(exits) do
        if not reverselist[to] then
          endresult[id] = getRoomName(id)
        end
      end
      local specialexits = getSpecialExitsSwap(id)
      for _, to in pairs(specialexits) do
        if not reverselist[to] then
          endresult[id] = getRoomName(id)
        end
      end
    end
  end
  if mmp.debug then
    mmp.echo(
      "mmp.getAreaBordersTimer() on areaid " ..
      areaid ..
      " took " ..
      stopStopWatch(mmp.getAreaBordersTimer) ..
      "s to run. Returned " ..
      table.size(endresult) ..
      " results."
    )
  end
  -- clean up external exits
  raiseEvent("mmp clear externals")
  return endresult
end

function mmp.viewArea(where, exact)
  if not where or not type(where) == "string" then
    mmp.echo("Which area would you like to view?")
    return
  end
  local areaid, msg, multiples = mmp.findAreaID(where, exact)
  if areaid then
    -- center on the first room ID, which typically is the start of an area
    local rooms = getAreaRooms(areaid) or {}
    if not rooms[1] then
      mmp.echo("The area has no rooms in it.")
    else
      centerview(rooms[1])
    end
  elseif not areaid and #multiples > 0 then
    mmp.echo("Which area would you like to view exactly?")
    fg("DimGrey")
    for _, areaname in ipairs(multiples) do
      echo("  ");
      setUnderline(true)
      echoLink(
        areaname, 'mmp.viewArea("' .. areaname .. '", true)', "Click to view " .. areaname, true
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

-- room label the room I'm in
-- room label 342 this is a label in room 342
-- room label green this is a green label where I'm at
-- room label green black this is a green to black label where I'm at
-- room label 34 green black this is a green to black label at room 34
-- how it works: split input string into tokens by space, then determine
-- what to do by checking first few tokens, and finally call the local
-- function with the proper arguments

function mmp.roomLabel(input)
  if not createMapLabel then
    mmp.echo(
      "Your Mudlet doesn't support createMapLabel() yet - please update to 2.0-test3 or better."
    )
    return
  end
  local tk = input:split(" ")
  local room, fg, bg, message = mmp.currentroom, "yellow", "red", "Some room label"
  -- input always have to be something, so tk[1] at least always exists
  if tonumber(tk[1]) then
    room = tonumber(table.remove(tk, 1))
    -- remove the number, so we're left with the colors or msg
  end
  -- next: is this a foreground color?
  if tk[1] and color_table[tk[1]] then
    fg = table.remove(tk, 1)
  end
  -- next: is this a background color?
  if tk[1] and color_table[tk[1]] then
    bg = table.remove(tk, 1)
  end
  -- the rest would be our message
  if tk[1] then
    message = table.concat(tk, " ")
  end
  -- if we haven't provided a room ID and we don't know where we are yet, we can't make a label
  if not room then
    mmp.echo("We don't know where we are to make a label here.")
    return
  end
  local x, y, z = getRoomCoordinates(room)
  local f1, f2, f3 = unpack(color_table[fg])
  local b1, b2, b3 = unpack(color_table[bg])
  -- finally: do it :)
  local lid = createMapLabel(getRoomArea(room), message, x, y, z, f1, f2, f3, b1, b2, b3)
  mmp.echo(
    string.format(
      "Created new label #%d '%s' in %s.", lid, message, getRoomAreaName(getRoomArea(room))
    )
  )
end

function mmp.areaLabels(where, exact)
  if not getMapLabels then
    mmp.echo(
      "Your Mudlet doesn't support getMapLabels() yet - please update to 2.0-test3 or better."
    )
    return
  end
  if (not where or not type(where) == "string") and not mmp.currentroom then
    mmp.echo("For which area would you like to view labels?")
    return
  end
  if not where then
    exact = true
    where = getRoomAreaName(getRoomArea(mmp.currentroom))
  end
  local areaid, msg, multiples = mmp.findAreaID(where, exact)
  if areaid then
    local t = getMapLabels(areaid)
    if type(t) ~= "table" or not next(t) then
      mmp.echo(string.format("'%s' doesn't seem to have any labels.", getRoomAreaName(areaid)))
      return
    end
    mmp.echo(string.format("Area labels for '%s'", getRoomAreaName(areaid)))
    for labelid, labeltext in pairs(t) do
      fg("DimGrey")
      echo(string.format("  %d) %s (", labelid, labeltext))
      fg("orange_red")
      setUnderline(true)
      echoLink(
        'delete',
        string.format(
          'deleteMapLabel(%d, %d); mmp.echo("Deleted label #' .. labelid .. '")', areaid, labelid
        ),
        "Delete label #" .. labelid .. " from " .. getRoomAreaName(areaid)
      )
      setUnderline(false)
      echo(")\n")
    end
    resetFormat()
  elseif not areaid and #multiples > 0 then
    mmp.echo("Which area would you like to view exactly?")
    fg("DimGrey")
    for _, areaname in ipairs(multiples) do
      echo("  ");
      setUnderline(true)
      echoLink(
        areaname,
        'mmp.areaLabels("' .. areaname .. '", true)',
        "Click to view labels in " .. areaname,
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

function mmp.echoPath(from, to)
  assert(tonumber(from) and tonumber(to), "mmp.getPath: both from and to have to be room IDs")
  if mmp.getPath(from, to) then
    mmp.echo(
      "<white>Directions from <yellow>" ..
      string.upper(searchRoom(from)) ..
      " <white>to <yellow>" ..
      string.upper(searchRoom(to)) ..
      "<white>:"
    )
    mmp.echo(table.concat(speedWalkDir, ", "))
    return mmp.speedWalkDir
  else
    mmp.echo(
      "<white>I can't find a way from <yellow>" ..
      string.upper(searchRoom(from)) ..
      " <white>to <yellow>" ..
      string.upper(searchRoom(to)) ..
      "<white>"
    )
  end
end

function mmp.listSpecialExits(filter)
  local c = 0
  mmp.echo("Listing special exits...")
  for area, areaname in pairs(mmp.areatabler) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)
      if exits and next(exits) then
        for exit, cmd in pairs(exits) do
          if type(cmd) == "table" then
            cmd = next(cmd)
          end
          if cmd:match("^%d") then
            cmd = cmd:sub(2)
          end
          if not filter or cmd:lower():find(filter, 1, true) then
            if getRoomArea(exit) ~= area then
              cecho(
                string.format(
                  "<dark_slate_grey>%s <LightSlateGray>(%d, in %s)<dark_slate_grey> <MediumSlateBlue>-> <coral>%s -<MediumSlateBlue>><dark_slate_grey> %s <LightSlateGray>(%d, in %s)\n",
                  getRoomName(rooms[i]),
                  rooms[i],
                  areaname,
                  cmd,
                  getRoomName(exit),
                  exit,
                  mmp.areatabler[getRoomArea(exit)] or '?'
                )
              )
            else
              cecho(
                string.format(
                  "<dark_slate_grey>%s <LightSlateGray>(%d)<dark_slate_grey> <MediumSlateBlue>-> <coral>%s <MediumSlateBlue>-><dark_slate_grey> %s <LightSlateGray>(%d)<dark_slate_grey> in %s\n",
                  getRoomName(rooms[i]),
                  rooms[i],
                  cmd,
                  getRoomName(exit),
                  exit,
                  areaname
                )
              )
            end
            c = c + 1
          end
        end
      end
    end
  end
  mmp.echo(
    string.format(
      "%d exits listed%s.", c, (not filter and '' or ", with for the filter '" .. filter .. "'")
    )
  )
end

function mmp.delSpecialExits(filter)
  local c = 0
  for area, areaname in pairs(mmp.areatabler) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)
      if exits and next(exits) then
        for exit, cmd in pairs(exits) do
          if type(cmd) == "table" then
            cmd = next(cmd)
          end
          if cmd:match("^%d") then
            cmd = cmd:sub(2)
          end
          if not filter or cmd:lower():find(filter, 1, true) then
            local rid, action
            local originalExits = {}
            local e = getSpecialExits(rooms[i])
            for t, n in pairs(e) do
              rid = tonumber(t)
              for a, l in pairs(n) do
                action = tostring(a)
              end
              if not action:find(filter, 1, true) then
                originalExits[rid] = action
              end
            end
            clearSpecialExits(rooms[i])
            for rid, act in pairs(originalExits) do
              addSpecialExit(rooms[i], tonumber(rid), tostring(act))
            end
            c = c + 1
          end
        end
      end
    end
  end
  mmp.echo(
    string.format(
      "%d exits deleted%s.", c, (not filter and '' or ", with for the filter '" .. filter .. "'")
    )
  )
end