function mmp.roomLook(input)
  -- we can do a report with a number

  local function handle_number(num)
    -- compile all available data
    if not mmp.roomexists(num) then
      mmp.echo(num .. " doesn't seem to exist.")
      return
    end
    local s, areanum = pcall(getRoomArea, num)
    if not s then
      mmp.echo(areanum);
      return ;
    end
    local exits = getRoomExits(num)
    local name = getRoomName(num)
    local islocked = roomLocked(num)
    local weight = (getRoomWeight(num) and getRoomWeight(num) or "?")
    -- getRoomWeight is buggy in one of the versions, is actually linked to setRoomWeight and thus returns nil
    local exitweights = (getExitWeights and getExitWeights(num) or {})
    local coords = {getRoomCoordinates(num)}
    local specexits = getSpecialExits(num)
    local env = getRoomEnv(num)
    local envname = (mmp.envidsr and mmp.envidsr[env]) or "?"
    -- generate a report
    mmp.echo(
      string.format(
        "Room: %s #: %d area: %s (%d)", name, num, tostring(mmp.areatabler[areanum]), areanum
      )
    )
    mmp.echo(
      string.format(
        "Coordinates: x:%d, y:%d, z:%d, locked: %s, weight: %s",
        coords[1],
        coords[2],
        coords[3],
        (islocked and "yep" or "nope"),
        tostring(weight)
      )
    )
    mmp.echo(
      string.format(
        "Environment: %s (%d)%s",
        tostring(envname),
        env,
        (getRoomUserData(num, "indoors") ~= '' and ", indoors" or '')
      )
    )
    mmp.echo(string.format("Exits (%d):", table.size(exits)))
    for exit, leadsto in pairs(exits) do
      echo(
        string.format(
          "  %s -> %s (%d)%s%s\n",
          exit,
          getRoomName(leadsto),
          leadsto,
          (
            (getRoomArea(leadsto) or "?") == areanum and
            "" or
            " (in " ..
            (mmp.areatabler[getRoomArea(leadsto)] or "?") ..
            ")"
          ),
          (
            (not exitweights[mmp.anytoshort(exit)] or exitweights[mmp.anytoshort(exit)] == 0) and
            "" or
            " (weight: " ..
            exitweights[mmp.anytoshort(exit)] ..
            ")"
          )
        )
      )
    end
    -- display special exits if we got any
    if next(specexits) then
      mmp.echo(string.format("Special exits (%d):", table.size(specexits)))
      for leadsto, command in pairs(specexits) do
        if type(command) == "string" then
          echo(string.format("  %s -> %s (%d)\n", command, getRoomName(leadsto), leadsto))
        else
          -- new format - exit name, command
          for cmd, locked in pairs(command) do
            if locked == '1' then
              cecho(
                string.format(
                  "<DarkSlateGrey>  %s -> %s (%d) (locked)\n", cmd, getRoomName(leadsto), leadsto
                )
              )
            else
              echo(string.format("  %s -> %s (%d)\n", cmd, getRoomName(leadsto), leadsto))
            end
          end
        end
      end
    end
    local message = "This room has the feature '%s'."
    for _, mapFeature in pairs(mmp.getRoomMapFeatures(num)) do
      mmp.echo(string.format(message, mapFeature))
    end
    -- actions we can do. This will be a short menu of sorts for actions
    mmp.echo("Stuff you can do:")
    echo("  ")
    echo("Clear all labels ")
    setUnderline(true)
    echoLink("(in area)", 'mmp.clearLabels(' .. areanum .. ')', '', true)
    setUnderline(false)
    echo(" ")
    setUnderline(true)
    echoLink(
      "(whole map)",
      [[
    if not mmp.clearinglabels then
      mmp.echo("Are you sure you want to clear all of your labels on this map? If yes, click the link again.")
      mmp.clearinglabels = true
    else
      mmp.clearLabels("map")
      mmp.clearinglabels = nil
    end
    ]],
      '',
      true
    )
    setUnderline(false)
    echo("\n")
    echo("  ")
    setUnderline(true)
    echoLink(
      "Check for mapper & map updates", 'mmp.echo("Checking...") mmp.checkforupdate()', '', true
    )
    setUnderline(false)
    echo(" ")
    setUnderline(true)
    echoLink(
      "(force map)",
      [[
      if io.exists(getMudletHomeDir().."/map downloads/current") then
        local s,m = os.remove(getMudletHomeDir().."/map downloads/current")
        if not s then mmp.echo("Couldn't delete '"..getMudletHomeDir().."/map downloads/current' file: "..tostring(m)..".") end
      end
      mmp.echo("Re-downloading the latest crowdmap...")
      mmp.checkforupdate()
    ]],
      "Re-download the map regardless if you have latest",
      true
    )
    setUnderline(false)
    echo("\n")
  end

  -- see if we can do anything with the name

  local function handle_name(name)
    local result = mmp.searchRoom(name)
    if type(result) == "string" then
      cecho("<grey>You have no recollection of any room with that name.")
      return
    end
    -- if we got one result, then act on it
    if table.size(result) == 1 then
      if type(next(result)) == "number" then
        handle_number(next(result))
      else
        handle_number(select(2, next(result)))
      end
      return
    end
    -- if not, then ask the user to clarify which one would they want
    mmp.echo("Which room specifically would you like to look up?")
    if not select(2, next(result)) or not tonumber(select(2, next(result))) then
      for roomid, roomname in pairs(result) do
        roomid = tonumber(roomid)
        cecho(string.format("  <LightSlateGray>%s<DarkSlateGrey> (", tostring(roomname)))
        cechoLink(
          "<" .. mmp.settings.echocolour .. ">" .. roomid,
          'mmp.roomLook(' .. roomid .. ')',
          string.format("View room details for %s (%s)", roomid, tostring(roomname)),
          true
        )
        cecho(
          string.format(
            "<DarkSlateGrey>) in the <LightSlateGray>%s<DarkSlateGrey>.\n",
            tostring(mmp.areatabler[getRoomArea(roomid)])
          )
        )
      end
    else
      for roomname, roomid in pairs(result) do
        roomid = tonumber(roomid)
        cecho(string.format("  <LightSlateGray>%s<DarkSlateGrey> (", tostring(roomname)))
        cechoLink(
          "<" .. mmp.settings.echocolour .. ">" .. roomid,
          'mmp.roomLook(' .. roomid .. ')',
          string.format("View room details for %s (%s)", roomid, tostring(roomname)),
          true
        )
        cecho(
          string.format(
            "<DarkSlateGrey>) in the <LightSlateGray>%s<DarkSlateGrey>.\n",
            tostring(mmp.areatabler[getRoomArea(roomid)])
          )
        )
      end
    end
  end

  if not input then
    if not mmp.roomexists(mmp.currentroom) then
      mmp.echo(mmp.currentroom .. " doesn't seem to be mapped yet.")
      mmp.echo("Stuff you can do:")
      echo("  ")
      echoLink("Check for all updates", 'mmp.echo("Checking...") mmp.checkforupdate()', '')
      echo(" ")
      echoLink(
        "(force map)",
        [[
      local s,m = os.remove(getMudletHomeDir().."/map downloads/current")
        if io.exists(getMudletHomeDir().."/map downloads/current") then
          local s,m = os.remove(getMudletHomeDir().."/map downloads/current")
          if not s then mmp.echo("Couldn't delete '"..getMudletHomeDir().."/map downloads/current' file: "..tostring(m)..".") end
        end
        mmp.echo("Re-downloading the latest map...")
        mmp.checkforupdate()
      ]],
        "Re-download the map regardless if you have latest"
      )
      echo("\n")
      mmp.echo(string.format("version %s.", tostring(mmp.version)))
      return
    else
      input = mmp.currentroom
    end
  end
  if tonumber(input) then
    handle_number(tonumber(input))
  else
    handle_name(input)
  end
  mmp.echo(string.format("version %s.", tostring(mmp.version)))
end