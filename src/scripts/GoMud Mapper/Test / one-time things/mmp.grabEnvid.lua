function mmp.grabEnvid()
  if not mmp.envids[gmcp.Room.Info.environment] then
    mmp.envids[gmcp.Room.Info.environment] = getRoomEnv(mmp.currentroom)
    mmp.echo(string.format("Remembered environment %s as %d", gmcp.Room.Info.environment, mmp.envids[gmcp.Room.Info.environment]))
  end
end

function mmp.getMaxID()
  local roomIDs = {}
  for area, _ in pairs(mmp.areatabler) do
    local ok, t = pcall(getAreaRooms, area)
    if ok then
      for _, id in pairs(t or {}) do
        roomIDs[id] = true
      end
    end
  end

  return table.maxn(roomIDs)
end

function mmp.getUnknownEnvs()
  local maxid, missing = mmp.getMaxID(), {}

  for i = 1, maxid do
    if mmp.roomexists(i) then
      if not table.contains(mmp.envids, getRoomEnv(i)) and not table.contains(missing, getRoomEnv(i)) then
        mmp.echo(string.format("Missing env %d from room %d ('%s' in '%s')",
          tostring(getRoomEnv(i)), i, tostring(getRoomName(i)), tostring(mmp.areatabler[getRoomArea(i)])))
        missing[i] = getRoomEnv(i)
      end
    end
  end
end