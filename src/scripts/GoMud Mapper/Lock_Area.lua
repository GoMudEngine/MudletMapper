-- Lock Area

mmp.locked = mmp.locked or {}
mmp.lastLockSearch = mmp.lastLockSearch or nil

function mmp.doLockArea(search)
	local areaList
	if search ~= nil then
		local r = rex.new(string.lower(search))
		mmp.lastLockSearch = search
		for name, id in pairs(getAreaTable()) do
			if r:match(string.lower(name)) then
				areaList = areaList or {}
				areaList[name] = id
			end
		end
		if areaList == nil then
			mmp.echo("'" .. search .. "' did not match any known areas!")
			return
		end
	else
		mmp.lastLockSearch = nil
		areaList = getAreaTable()
	end

	for name, id in pairs(areaList) do
		mmp.echon(name .. string.rep(" ", 40 - string.len(name)))
		if not mmp.locked[id] then
			setFgColor(0, 200, 0)
			setUnderline(true)
			echoLink("Lock!", [[mmp.lockArea( ']] .. name:gsub("'", [[\']]) .. [[', true )]], "Click to lock area '" .. name .. "'", true)
		else
			setFgColor(200, 0, 0)
			setUnderline(true)
			echoLink("Unlock!", [[mmp.lockArea( ']] .. name:gsub("'", [[\']]) .. [[', false )]], "Click to unlock area '" .. name .. "'", true)
		end
	end

	if not search then
		echo"\n\n" mmp.echo("Use <green>arealock <area><white> to filter areas.")
	end
end

function mmp.lockArea(name, lock, dontreshow)
	local areas = getAreaTable()
	local rooms = getAreaRooms(areas[name]) or {}
    local lockRoom = lockRoom
    local count = 0
	for _, room in pairs(rooms) do
		lockRoom(room, lock)
        count = count + 1
	end

	mmp.locked[areas[name]] = lock and true or nil
	mmp.echo(string.format("Area '%s' %slocked! All %s room%s within it.", name, (lock and '' or 'un'), count, (count == 1 and '' or 's')))

	if not dontreshow then mmp.doLockArea(mmp.lastLockSearch) end
end


