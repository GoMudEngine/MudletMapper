function mmp.goMudStopSpeedwalkForWrongDir()
  if mmp.game and mmp.game ~= "gomud" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("Can't go \"" .. gmcp.Room.WrongDir .. "\". Stopping speedwalk.")
    mmp.stop()
  end
end