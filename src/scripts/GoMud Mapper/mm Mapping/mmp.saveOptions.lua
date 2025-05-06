function mmp.saveOptions()
	local saveTable = {
		locked_areas = mmp.locked,
		options = mmp.settings:getAllOptions()
	}
  local _sep
	if string.char(getMudletHomeDir():byte()) == "/" then _sep = "/" else  _sep = "\\" end
	local saveFile = getMudletHomeDir() ..  _sep .. "mapper.options.lua"

	table.save(saveFile, saveTable)
end