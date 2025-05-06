-- mmp = mudlet mapper namespace
mmp =
  mmp or
  {
    paused = false,
    autowalking = false,
    currentroom = 0,
    currentroomname = "(unknown)",
    firstRun = true,
    specials = {},
    ferry_rooms = {},
  }
mmp.speedWalkWatch = createStopWatch()
-- speedWalkPath and speedWalkDir populated by Mudlet from getPath() and gotoRoom()
speedWalkPath = speedWalkPath or {}
speedWalkDir = speedWalkDir or {}

-- actually used by the mapper for walking
mmp.speedWalkCounter = 0
mmp.speedWalk = mmp.speedWalk or {}
mmp.speedWalkPath = mmp.speedWalkPath or {}
mmp.speedWalkDir = mmp.speedWalkDir or {}
mmp.lagtable =
  {
    [1] = {description = "Normal, default level.", time = 0.5},
    [2] = {description = "Decent, but slightly laggy.", time = 1},
    [3] = {description = "Noticeably laggy with occasional spikes.", time = 2},
    [4] = {description = "Bad. Terrible. Terribad.", time = 5},
    [5] = {description = "Carrier Pigeon", time = 10},
  }
local newversion = "1.0.4"
if mmp.version and mmp.version ~= newversion then
  if not mmp.game then
    mmp.echo("Mapper script updated - Thanks! I don't know what game are you connected to, though - so please reconnect, if you could.")
  else
    mmp.echo("Mapper script updated - thanks! You don't need to restart.")
  end
end
mmp.version = newversion

function mmp.startup()
  if not mmp.firstRun then
    return
  end
  local private_settings = {}

  --General settings

  private_settings["echocolour"] = mmp.createOption("cyan", mmp.changeEchoColour, {"string"}, "Set the color for room number echos?", function(newSetting) return color_table[newSetting] ~= nil end)
  private_settings["crowdmap"] = mmp.createOption(false, mmp.changeMapSource, {"boolean"}, "Use a crowd-sourced map instead of games default?", nil, {achaea = true, starmourn = true, lusternia = true, stickmud = true, imperian = true, aetolia = true})
  private_settings["showcmds"] = mmp.createOption(true, mmp.changeBoolFunc, {"boolean"}, "Show walking commands?")
  private_settings["laglevel"] = mmp.createOption(1, mmp.changeLaglevel, {"number"}, "How laggy is your connection, (fast 1<->5 slow)?", mmp.verifyLaglevel)
  private_settings["slowwalk"] = mmp.createOption(false, mmp.setSlowWalk, {"boolean"}, "Walk slowly instead of as quick as possible?")
  private_settings["updatemap"] = mmp.createOption(true, mmp.changeUpdateMap, {"boolean"}, "Check for new maps from your MUD?")
  private_settings["waterwalk"] = mmp.createOption(true, mmp.setWaterWalk, {"boolean"}, "Have waterwalk (don't avoid water)?", nil, {achaea = true})
  private_settings["autopositionrooms"] = mmp.createOption(true, mmp.setAutoPositionRooms, {"boolean"}, "Auto position rooms when mapping?", nil, {gomud = true})
  

  --Settings that lock things

  private_settings["lockpathways"] = mmp.createOption(true, mmp.lockPathways, {"boolean"}, "Lock pathway exits?", nil, {lusternia = true})
  private_settings["locksewers"] = mmp.createOption(false, mmp.lockSewers, {"boolean"}, "Lock all sewers?", nil, {achaea = true})
  private_settings["lockspecials"] = mmp.createOption(false, mmp.lockSpecials, {"boolean"}, "Lock all special exits?")
  private_settings["lockwormholes"] = mmp.createOption(true, mmp.lockWormholes, {"boolean"}, "Lock all wormholes?", nil, {achaea = true, imperian = true, aetolia = true})

  --Sprint movement

  private_settings["dash"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Dash?", nil, {achaea = true, imperian = true, aetolia = true})
  private_settings["sprint"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Sprint?", nil, {achaea = true, imperian = true, aetolia = true, lusternia = true})
  private_settings["gallop"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Gallop?", nil, {achaea = true, imperian = true, aetolia = true, lusternia = true})
  private_settings["runaway"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Jester Runaway?", nil, {achaea = true})

  --Achaea wings and things

  private_settings["winglanguage"] = mmp.createOption("", mmp.setWingsLanguage, {"string"}, "Speak non-default language for wings:", nil, {achaea = true})
  private_settings["pebble"] = mmp.createOption(false, mmp.lockPebble, {"boolean"}, "Make use of your enchanted pebble?", nil, {achaea = true})
  private_settings["removewings"] = mmp.createOption(true, mmp.setWingsRemoval, {"boolean"}, "Remove Wings after using them?", nil, {achaea = true, imperian = true})
  private_settings["harness"] = mmp.createOption(false, mmp.setHarness, {"boolean"}, "Use Stratospheric Harness?", nil, {achaea = true})
  private_settings["duantahar"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Chenubian Wings?", nil, {achaea = true})
  private_settings["duanatharan"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Atavian Wings?", nil, {achaea = true, aetolia = true})
  private_settings["duanathar"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Eagle Wings?", nil, {achaea = true, aetolia = true})
  private_settings["duanatharic"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Island Wings?", nil, {achaea = true})
  private_settings["soar"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Aero Soar?", nil, {achaea = true})
  private_settings["shackle"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Take off shackle?", nil, {achaea = true})
  private_settings["universe"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Universe Tarot?", nil, {achaea = true})
  private_settings["gare"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Gare?", nil, {achaea = true})

  --aet wings and things
  private_settings["voltda"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use dark amulet?", nil, {aetolia = true})
  private_settings["voltdaran"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use midnight amulet?", nil, {aetolia = true})
  
  --Wings pathfinding improvements

  private_settings["betterwings"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Better Wings pathfinding?", nil, {achaea = true})

  --Achaea Orb of Confinement

  private_settings["orbashtan"] = mmp.createOption(false, function() mmp.setOrb("ashtan") end, {"boolean"}, "Orb of Confinement active in Ashtan?", nil, {achaea = true})
  private_settings["orbcyrene"] = mmp.createOption(false, function() mmp.setOrb("cyrene") end, {"boolean"}, "Orb of Confinement active in Cyrene?", nil, {achaea = true})
  private_settings["orbeleusis"] = mmp.createOption(false, function() mmp.setOrb("eleusis") end, {"boolean"}, "Orb of Confinement active in Eleusis?", nil, {achaea = true})
  private_settings["orbhashan"] = mmp.createOption(false, function() mmp.setOrb("hashan") end, {"boolean"}, "Orb of Confinement active in Hashan?", nil, {achaea = true})
  private_settings["orbmhaldor"] = mmp.createOption(false, function() mmp.setOrb("mhaldor") end, {"boolean"}, "Orb of Confinement active in Mhaldor?", nil, {achaea = true})
  private_settings["orbtargossas"] = mmp.createOption(false, function() mmp.setOrb("targossas") end, {"boolean"}, "Orb of Confinement active in Targossas?", nil, {achaea = true})

  --Imperian wings

  private_settings["shekinah"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Seraphim Wings?", nil, {imperian = true})
  private_settings["suriel"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Orphanim Wings?", nil, {imperian = true})

  --Lusternia bixes

  private_settings["torus"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Torus?", nil, {lusternia = true})
  private_settings["prism"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your transplanar prism?", nil, {lusternia = true})
  private_settings["cubix"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Cubix?", nil, {lusternia = true})
  private_settings["medallion"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Medallion?", nil, {lusternia = true})

  --Lusternia Bubblixes
  private_settings["twist"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Mt. Dio Bix?", nil, {lusternia = true})
  private_settings["figurine"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Icewynd Bix?", nil, {lusternia = true})
  private_settings["periscope"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Aquagoria Bix?", nil, {lusternia = true})
  private_settings["pebble"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Lyraa Bix?", nil, {lusternia = true})
  private_settings["shard"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Xion Bix?", nil, {lusternia = true})
  private_settings["tibia"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Cankermore Bix?", nil, {lusternia = true})
  private_settings["mud"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Mucklemarsh Bix?", nil, {lusternia = true})
  private_settings["cookie"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Crumkindivia Bix?", nil, {lusternia = true})
  private_settings["icicle"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Frosticia Bix?", nil, {lusternia = true})
  private_settings["screwdriver"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Facility Bix?", nil, {lusternia = true})
  private_settings["snowglobe"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Tree of Trees Bix?", nil, {lusternia = true})
  private_settings["head"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Bottledowns Bix?", nil, {lusternia = true})
  private_settings["wheel"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Dramube Bix?", nil, {lusternia = true})

  --lusternia athergoop setButtons

  private_settings["buttons"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of Aethergoop Buttons?", nil, {lusternia = true})

  --Lusternia Curio collections

  private_settings["bonecurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Bone curios?", nil, {lusternia = true})
  private_settings["facecurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Face curios?", nil, {lusternia = true})
  private_settings["feathercurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Feather curios?", nil, {lusternia = true})
  private_settings["figurecurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Figure curios?", nil, {lusternia = true})
  private_settings["flowercurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Flower curios?", nil, {lusternia = true})
  private_settings["fluttercurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Flutter curios?", nil, {lusternia = true})
  private_settings["toolcurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Tool curios?", nil, {lusternia = true})
  private_settings["vernalcurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Vernal curios?", nil, {lusternia = true})
  private_settings["utensilcurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Utensil curios?", nil, {lusternia = true})
  private_settings["toycurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Toy curios?", nil, {lusternia = true})
  private_settings["soullesscurio"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Soulless curios?", nil, {lusternia = true})

  --Lusternia epic quest bixes

  private_settings["fingerblade"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Fingerblade?", nil, {lusternia = true})
  private_settings["blossom"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Flame of dae'Seren?", nil, {lusternia = true})
  private_settings["belt"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Belt?", nil, {lusternia = true})
  private_settings["mandala"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Mandala?", nil, {lusternia = true})
  private_settings["mantle"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Mantle?", nil, {lusternia = true})
  private_settings["key"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Make use of your Key?", nil, {lusternia = true})

  --Lusternia other travel things
  private_settings["compass"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use the Compass of the Basin?", nil, {lusternia = true})
  private_settings["astrojump"] = mmp.createOption(false, mmp.astroboots, {"boolean"}, "Use Astral Jumping boots?", nil, {lusternia = true})


  --I have no idea what this does tbh

  private_settings["caravan"] = mmp.createOption(false, mmp.changeBoolFunc, {"boolean"}, "Walk caravans?", nil, {imperian = true})



  mmp.settings = mmp.createOptionsTable(private_settings)
  mmp.settings.disp = mmp.echo
  mmp.game = false
  mmp.settings.dispOption =
    function(opt, val)
      cecho(
        "<green>" ..
        val.use ..
        "<white> (" ..
        opt ..
        ") " ..
        string.rep(" ", 50 - val.use:len() - opt:len()) ..
        tostring(val.value) ..
        "\n"
      )
    end
  mmp.settings.dispDefaultWriteError =
    function()
      mmp.echo("Please use the mconfig alias to set options!")
    end
  raiseEvent("mmp areas changed")
  mmp.firstRun = false
  mmp.echon("Mudlet Mapper script for GoMud (" .. tostring(mmp.version) .. ") loaded! (")
  echoLink(
    "See more on Github",
    "(openUrl or openURL)'https://github.com/GoMudEngine/MudletMapper'",
    "Clicky clicky to read up on what's this about"
  )
  echo(")\n")
end