function mmp.centerRoominfo()
  -- lusternia has gmcp.Room.Players before gmcp.Room.Info is created
  if gmcp.Room.Info then centerview(gmcp.Room.Info.num) end
end