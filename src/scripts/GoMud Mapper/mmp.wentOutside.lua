--genericized version of the went_outside event handlers.
--when you go outside, it sees if a shorter path can be found using external links. If so, routes you on the new path instead.
function mmp.wentOutside()
  if
    not mmp.autowalking or
    (mmp.currentroom == mmp.speedWalkPath[#mmp.speedWalkPath]) or
    table.contains(gmcp.Room.Info.details, "indoors") or
    table.contains(gmcp.Room.Info.details, "considered indoors") or
    mmp.orbed(mmp.currentroom)
  then
    return
  end
  -- repath, maybe that'll allow us to use wings now.
  local previousDirection = mmp.speedWalkDir[mmp.speedWalkCounter + 1]
  if mmp.speedWalk.type == "room" then
    raiseEvent("mmp link externals")
    mmp.getPath(mmp.currentroom, mmp.speedWalkPath[#mmp.speedWalkPath])
    raiseEvent("mmp clear externals")
    -- don't need to check return value since that fact shouldnt've changed
  else
    mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
  end
  -- if our path didn't change, re-instate it as it was (since the new path starts from this room that we checked at)
  if speedWalkDir[1] ~= previousDirection then
    mmp.speedWalkCounter = 0
    mmp.echo("We got outside - going to shortcut with travel device.")
    if mmp.speedWalk.type == "room" then
      mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
    else
      mmp.gotoAreaID(getRoomArea(mmp.speedWalkPath[#mmp.speedWalkPath]))
    end
    mmp.ignore_speedwalking = true
  end
end