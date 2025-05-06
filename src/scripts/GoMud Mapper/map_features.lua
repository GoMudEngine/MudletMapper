-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

local function loadMapFeatures()
  local mapFeaturesString = getMapUserData("mapFeatures")
  local mapFeatures
  if mapFeaturesString and mapFeaturesString ~= "" then
    mapFeatures = yajl.to_value(mapFeaturesString)
  else
    mapFeatures = {}
  end
  return mapFeatures
end

local function saveMapFeatures(mapFeaturesToSave)
  local mapFeaturesString = yajl.to_string(mapFeaturesToSave)
  setMapUserData("mapFeatures", mapFeaturesString)
end

function mmp.createMapFeature(featureName, roomCharacter)
  if not featureName or featureName == "" then
    mmp.echo("Can't create an empty map feature.")
    return
  end
  if featureName:find("%d") then
    mmp.echo("Map feature names must not contain numbers.")
    return
  end
  roomCharacter = roomCharacter or ""
  if type(roomCharacter) ~= "string" then
    mmp.echo(
      "The new room character must be either a string or nil. " ..
      type(roomCharacter) ..
      " is not allowed."
    )
    return
  end
  local lowerFeatureName = featureName:lower()
  local mapFeatures = loadMapFeatures()
  if not mapFeatures[lowerFeatureName] then
    mapFeatures[lowerFeatureName] = roomCharacter
    saveMapFeatures(mapFeatures)
    mmp.echo(
      "Created map feature '" ..
      featureName ..
      "' with the room character '" ..
      roomCharacter ..
      "'."
    )
  else
    mmp.echo("A map feature with the name '" .. featureName .. "' already exists.")
    return
  end
  return true
end

function mmp.listMapFeatures()
  local mapFeatures = loadMapFeatures()
  mmp.echo("This map has the following features:")
  echo(string.format("    %-25s | %s\n", "feature name", "room character"))
  echo(string.format("    %s\n", string.rep("-", 45)))
  for featureName, roomCharacter in pairs(mapFeatures) do
    echo(string.format("    %-25s | %s\n", featureName, roomCharacter))
  end
  return true
end

function mmp.roomCreateMapFeature(featureName, roomId)
  -- checks for the feature name
  if not featureName then
    mmp.echo("Which feature would you like to create?")
    return
  end
  local lowerFeatureName = featureName:lower()
  local mapFeatures = loadMapFeatures()
  if not mapFeatures[lowerFeatureName] then
    mmp.echo(
      "A feature with name '" ..
      featureName ..
      "' does not exist. You need to use 'feature create' first."
    )
    return
  end
  -- checks for the room ID
  if not roomId then
    if not mmp.currentroom then
      mmp.echo("Don't know where we are at the moment.")
      return
    end
    roomId = mmp.currentroom
  else
    if type(roomId) ~= "number" then
      mmp.echo("Need a room ID as number for creating a map feature on a room.")
      return
    end
  end
  if not getRoomName(roomId) then
    mmp.echo("Room number '" .. roomId .. "' does not exist.")
    return
  end
  -- check if feature already exists
  if table.contains(mmp.getRoomMapFeatures(roomId), lowerFeatureName) then
    mmp.echo("Room '" .. roomId .. "' has already map feature '" .. featureName .. "'.")
    return
  end
  -- create map feature in room
  setRoomUserData(roomId, "feature-" .. lowerFeatureName, "true")
  mmp.echo(string.format("Map feature '%s' created in room number '%d'.", featureName, roomId))
  local featureRoomChar = mapFeatures[lowerFeatureName]
  if featureRoomChar ~= "" then
    setRoomChar(roomId, featureRoomChar)
    mmp.echo("The room now carries the room char '" .. featureRoomChar .. "'.")
  end
  return true
end

function mmp.roomDeleteMapFeature(featureName, roomId)
  -- checks for the feature name
  if not featureName then
    mmp.echo("Which feature would you like to delete?")
    return
  end
  local lowerFeatureName = featureName:lower()
  -- checks for the room ID
  if not roomId then
    if not mmp.currentroom then
      mmp.echo("Don't know where we are at the moment.")
      return
    end
    roomId = mmp.currentroom
  else
    if type(roomId) ~= "number" then
      mmp.echo("Need a room ID as number for deleting a map feature from a room.")
      return
    end
  end
  if not getRoomName(roomId) then
    mmp.echo("Room number '" .. roomId .. "' does not exist.")
    return
  end
  -- check if feature exists
  local roomMapFeatures = mmp.getRoomMapFeatures(roomId)
  if not table.contains(roomMapFeatures, lowerFeatureName) then
    mmp.echo("Room '" .. roomId .. "' doesn't have map feature '" .. featureName .. "'.")
    return
  end
  -- delete map feature from room
  setRoomUserData(roomId, "feature-" .. lowerFeatureName, "")
  mmp.echo(string.format("Map feature '%s' deleted from room number '%d'.", featureName, roomId))
  -- now update room char if needed.
  -- first update current map features of this room
  roomMapFeatures = mmp.getRoomMapFeatures(roomId)
  local mapFeatures = loadMapFeatures()
  -- find out if we need to set a new room character
  if getRoomChar(roomId) == mapFeatures[lowerFeatureName] and getRoomChar(roomId) ~= "" then
    local index, otherRoomMapFeature
    -- find another usable room character
    repeat
      index, otherRoomMapFeature = next(roomMapFeatures, index)
    until not otherRoomMapFeature or mapFeatures[otherRoomMapFeature] ~= ""
    if otherRoomMapFeature then
      -- we found a usable room character, now set it
      local newRoomChar = mapFeatures[otherRoomMapFeature]
      setRoomChar(roomId, newRoomChar)
      mmp.echo("Using '" .. newRoomChar .. "' as new room character.")
    else
      -- we didn't find a usable room character, delete it.
      setRoomChar(roomId, "")
      mmp.echo("Deleted the current room character.")
    end
  end
  return true
end

function mmp.getRoomMapFeatures(roomId)
  -- checks for the room ID
  if not roomId then
    if not mmp.currentroom then
      mmp.echo("Don't know where we are at the moment.")
      return
    end
    roomId = mmp.currentroom
  else
    if type(roomId) ~= "number" then
      mmp.echo("Need a room ID as number for getting all map features of a room.")
      return
    end
  end
  if not getRoomName(roomId) then
    mmp.echo("Room number '" .. roomId .. "' does not exist.")
    return
  end
  local result = {}
  local mapFeatures = loadMapFeatures()
  for mapFeature in pairs(mapFeatures) do
    if getRoomUserData(roomId, "feature-" .. mapFeature) == "true" then
      result[#result + 1] = mapFeature
    end
  end
  return result
end

function mmp.deleteMapFeature(featureName)
  if not featureName or featureName == "" then
    mmp.echo("Which map feature would you like to delete?")
    return
  end
  local lowerFeatureName = featureName:lower()
  local mapFeatures = loadMapFeatures()
  if not mapFeatures[lowerFeatureName] then
    mmp.echo("Map feature '" .. featureName .. "' does not exist.")
    return
  end
  local roomsWithFeature = searchRoomUserData("feature-" .. lowerFeatureName, "true")
  for _, roomId in pairs(roomsWithFeature) do
    local deletionResult = mmp.roomDeleteMapFeature(lowerFeatureName, roomId)
    if not deletionResult then
      mmp.echo(
        "Something went wrong deleting the map feature '" ..
        featureName ..
        "' from all rooms. Deletion incomplete."
      )
      return
    end
  end
  mapFeatures[lowerFeatureName] = nil
  saveMapFeatures(mapFeatures)
  mmp.echo("Deleted map feature '" .. featureName .. "' from map.")
  return true
end

function mmp.getMapFeatures()
  return loadMapFeatures()
end