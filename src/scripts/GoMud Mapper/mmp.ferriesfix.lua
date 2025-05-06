function mmp.ferriesfix()
  if table.is_empty(mmp.ferry_rooms) then
    local tmp = getRoomUserData(1, "ferry rooms")
    if tmp ~= "" then
      for _, i in ipairs(yajl.to_value(tmp)) do
        mmp.ferry_rooms[i] = true
      end
    end
  end
end