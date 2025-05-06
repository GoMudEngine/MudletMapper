function mmp.wormholesfix()
  local c = 0
  local weight = 10
  for _, area in pairs(getAreaTable()) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)

       if exits and next(exits) then
         for exit, cmd in pairs(exits) do
           if type(cmd) == "table" then cmd = next(cmd) end

           if (cmd:lower():find("worm warp", 1, true)) then
				setExitWeight(rooms[i], cmd, weight)
             c = c + 1
           end
         end
       end
    end
  end

  if c > 0 then mmp.echo(string.format("%s wormholes weighted to %s (so we don't take them over too short distances).", c, weight)) end
end