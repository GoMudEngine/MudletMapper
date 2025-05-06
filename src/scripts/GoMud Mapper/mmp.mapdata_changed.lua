-- aggregates map load and such events into one
function mmp.mapdata_changed()
  raiseEvent("mmapper map reloaded")
end
					