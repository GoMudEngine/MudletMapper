-- functions internal to the mapper

function mmp.highlight_unfinished_rooms()
	if not mmp.areatable then return end
	for a,b in pairs (mmp.areatable) do
		local roomList = getAreaRooms(b) or {}
		for c,d in pairs (roomList) do
			if (getRoomName(d) == "") then
				local fgr,fgg,fgb = unpack(color_table.red)
				local bgr,bgg,bgb = unpack(color_table.blue)
				highlightRoom(d, fgr,fgg,fgb,bgr,bgg,bgb, 1, 100, 100)
			end
		end
	end
end

function mmp.usebix()
	if mmp.game ~= "lusternia" then return end

	if (table.contains(gmcp.Room.Info.details, "the Prime Material Plane") or
		table.contains(gmcp.Room.Info.details, "the Ethereal Plane") or
		table.contains(gmcp.Room.Info.details, "the Water Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Air Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Fire Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Earth Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "Celestia, Plane of Light") or
		table.contains(gmcp.Room.Info.details, "the Tainted Plane of Nil") or
		table.contains(gmcp.Room.Info.details, "the Cosmic Plane of Continuum") or
		table.contains(gmcp.Room.Info.details, "the Cosmic Plane of Vortex") or
		table.contains(gmcp.Room.Info.details, "the Astral Plane")) and
        gmcp.Room.Info.area ~= "the City of Climanti" and
		table.contains(gmcp.Room.Info.details, "outdoors") then
		return true
	end
	return false
end

function mmp.useprism()
	if mmp.game ~= "lusternia" then return end
	if (table.contains(gmcp.Room.Info.details, "the Prime Material Plane") or
	table.contains(gmcp.Room.Info.details, "the Ethereal Plane") or
	table.contains(gmcp.Room.Info.details, "the Water Elemental Plane") or
	table.contains(gmcp.Room.Info.details, "the Air Elemental Plane") or
	table.contains(gmcp.Room.Info.details, "the Fire Elemental Plane") or
	table.contains(gmcp.Room.Info.details, "the Earth Elemental Plane")) and
    gmcp.Room.Info.area ~= "the City of Climanti" and
	table.contains(gmcp.Room.Info.details, "outdoors") then
		return true
	end
	return false
end
function mmp.usebubblix()
	if mmp.game ~= "lusternia" then return end

	if ((table.contains(gmcp.Room.Info.details, "the Prime Material Plane") or
		table.contains(gmcp.Room.Info.details, "the Ethereal Plane") or
		table.contains(gmcp.Room.Info.details, "the Water Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Air Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Fire Elemental Plane") or
		table.contains(gmcp.Room.Info.details, "the Earth Elemental Plane")) and
        gmcp.Room.Info.area ~= "the City of Climanti" and
		table.contains(gmcp.Room.Info.details, "outdoors")) or
		table.contains(gmcp.Room.Info.details, "an Aetherbubble") then
		return true
	end
	return false
end