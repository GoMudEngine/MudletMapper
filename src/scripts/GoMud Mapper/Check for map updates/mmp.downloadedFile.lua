function mmp.downloadedFile(_, filename)
  if not io.exists(filename) then return end

  -- workaround for https://bugs.launchpad.net/mudlet/+bug/1092769
--  if mmp["downloaded_file_block_"..filename] then return end
--  mmp["downloaded_file_block_"..filename] = tempTimer(5, [[mmp["downloaded_file_block_]]..filename..[["] = nil]])

  if filename == tostring(mmp.mapperfile) then   -- mapper script version
	mmp.checkingupdates = false

    local f, s = io.open(filename)
    if f then s = f:read("*l"):trim(); io.close(f) end

    if s ~= tostring(mmp.version) then
      mmp.newmapperversion = s
      mmp.retrievechangelog()
    end

  elseif filename == tostring(mmp.changelogfile) then   -- changelog for the mapper script
	mmp.checkingupdates = false

    local f, s, changelog = io.open(filename)
    if f then changelog = f:read("*a"); io.close(f) end

    echo("\n")
    mmp.echon("------------------[ Mapper Script Update ]------------------")
    mmp.echon(" The mapper script was updated from <orange>"..tostring(mmp.version).."<reset> -> <green>"..tostring(mmp.newmapperversion).."<reset>!")
    mmp.echon("")
    cechoLink(" Would you like to install the update? <u><ForestGreen>Click here if so</u><reset>.", "mmp.downloadmapperscript()", "Changelog for the latest ("..tostring(mmp.version).." -> "..tostring(mmp.newmapperversion)..") update:\n"..changelog, true)
    echo("\n\n")

  elseif filename == mmp.crowdchangelogfile then   -- changelog for the crowdmap
    local f, s = io.open(filename)
    if f then s = f:read("*a"); io.close(f) end

    -- make environment
    local env = {} -- add functions you know are safe here

    -- run code under environment [Lua 5.1]
    local function run(untrusted_code)
      if untrusted_code:byte(1) == 27 then return nil, "binary bytecode prohibited" end
      local untrusted_function, message = loadstring(untrusted_code)
      if not untrusted_function then return nil, message end
      setfenv(untrusted_function, env)
      return pcall(untrusted_function)
    end

    run(s)

	mmp.crowdchangelog = env.changelog

    echo("\n")
    mmp.echon("------------------[ Map Update ]------------------")
    mmp.echon(" The crowdmap map was updated from <orange>"..(mmp.oldversion or "(none)").." <reset>-> <green>"..tostring(mmp.newversion).."<reset>!")
    mmp.echon(" Want to see the full changelog?")
    cechoLink(" <ForestGreen>Click here<reset>.", "mmp.showcrowdchangelog()", 'View the full changelog for mappers', true)
    mmp.echon(" Latest changes were: <LightSkyBlue>"..tostring(mmp.crowdchangelog and mmp.crowdchangelog[#mmp.crowdchangelog] or '?')..".\n")
    echo("\n\n")
    
    mmp.downloadcrowdmap(mmp.newversion)

  elseif filename == mmp.crowdmapfile then    -- crowdmap map
    mmp.echo("Map downloaded, loading it in...")

    local tmp = getRoomUserData(1, "gotoMapping")
    local oldmaptable = {}

    if tmp ~= "" then
      oldmaptable = yajl.to_value(tmp)
    end

    local ok = loadMap(filename)

    if ok then
      if mmp.game ~= "starmourn" then
        local wc = mmp.lockWormholes()
  	local ws = mmp.lockSewers()
        mmp.lockPebble()
        if mmp.game == "achaea" and wc == 0 and ws == 0 then -- in achaea, using crowdmap, if we didn't get any special exits - it means Mudlet needs to be updated
          mmp.echo("Sorry, it seems your Mudlet isn't compatible with the new crowdmap format - and the map cannot be loaded fully. Please update your Mudlet:\n  http://www.mudlet.org/download/")
          return
        end
      end

      if mmp.settings.waterwalk then mmp.enableWaterWalk() else mmp.disableWaterWalk() end

      mmp.echo("Map loaded fine - enjoy!")

      tmp = getRoomUserData(1, "gotoMapping")
      local newmaptable = {}

      if tmp ~= "" then
        newmaptable = yajl.to_value(tmp)
      end

      for k,v in pairs(oldmaptable) do newmaptable[k] = v end
      setRoomUserData(1, "gotoMapping", yajl.to_string(newmaptable))
      mmp.echo("Marks from the old map migrated successfully.")

      raiseEvent("mmapper updated map")
    else
      mmp.echon("Map failed to load - you need to have the mapper open. Please open it, and then ")
      echoLink("click here", [[
        local tmp = getRoomUserData(1, "gotoMapping")
        local oldmaptable = {}
        if tmp ~= "" then
          oldmaptable = yajl.to_value(tmp)
        end

        local ok = loadMap(']]..filename..[[')
        if ok then
        local wc = mmp.lockWormholes()
	    local ws = mmp.lockSewers()
        mmp.lockPebble()
        if mmp.game == "achaea" and wc == 0 and ws == 0 then -- in achaea, using crowdmap, if we didn't get any special exits - it means Mudlet needs to be updated
          mmp.echo("Sorry, it seems your Mudlet isn't compatible with the new crowdmap format - and the map cannot be loaded fully. Please update your Mudlet:\n  http://www.mudlet.org/download/")
          return
        end

        if mmp.settings.waterwalk then mmp.enableWaterWalk() else mmp.disableWaterWalk() end

        mmp.echo("Map loaded successfully!")

          tmp = getRoomUserData(1, "gotoMapping")
          local newmaptable = {}
          if tmp ~= "" then
            newmaptable = yajl.to_value(tmp)
          end
          for k,v in pairs(oldmaptable) do newmaptable[k] = v end
          setRoomUserData(1, "gotoMapping", yajl.to_string(newmaptable))
          mmp.echo("Marks from the old map migrated successfully.")
          raiseEvent("mmapper updated map")
        else mmp.echo("Nope, didn't work. Open the map and try again?") end
      ]],
      "Click here to try loading the map again")
      echo(" to try loading it in again.\n")
    end

  elseif filename == tostring(mmp.downloadedscript) then   -- new mapper script xml downloaded
	  mmp.checkingupdates = false
    mmp.installMapperScript()
  elseif filename == tostring(mmp.mapfile) then   -- map version #, either IRE's or crowd
	mmp.checkingupdates = false

    local function needupdate(currentmd5, oldmd5)
      if not mmp.settings.crowdmap then
        mmp.echon("The games map was ")
        echoLink("updated", '', "New MD5: "..tostring(currentmd5)..", previous MD5: "..(oldmd5 or "(none)"), true)
        echo(" - you should update yours! Go to Settings -> Mapper tab and click on the 'Download' button there. Once you've updated, ")
        echoLink("click here", "mmp.updatedmap('"..currentmd5.."')", "Click here to quiet the update reminder")
        echo(" to remove the reminder.")
      else
        mmp.newversion, mmp.oldversion = currentmd5, oldmd5
        mmp.retrievecrowdchangelog()
      end
    end

    local f, s = io.open(filename)
    if f then s = f:read("*a"); io.close(f) end
    local currentmd5 = string.match(s, "([a-z0-9]+)  map%.xml")

    -- using crowdsourced map
    if not currentmd5 then
      currentmd5 = s:trim()
    end

	os.remove(filename)

    -- never checked yet?
    if not io.exists(getMudletHomeDir().."/map downloads/current") then needupdate(currentmd5) return end

    -- otherwise read old file and check
    local f, s = io.open(getMudletHomeDir().."/map downloads/current")
    if f then s = f:read("*a"); io.close(f) end

    if s ~= currentmd5 then needupdate(currentmd5, s) end
  end
end