mmp.defs = {current = {}}
mmp.defs.add =
  function()
    local def = gmcp.Char.Defences.Add.name
    if not mmp.defs.current[def] then
      mmp.defs.current[def] = true
      raiseEvent("mmp got def", def)
    end
  end
mmp.defs.remove =
  function()
    for _, def in ipairs(gmcp.Char.Defences.Remove) do
      mmp.defs.current[def] = nil
      raiseEvent("mmp lost def", def)
    end
  end
mmp.defs.list =
  function()
    local newDefs = {}
    local addedDefs, lostDefs = {}, {}
    for _, v in ipairs(gmcp.Char.Defences.List) do
      newDefs[v.name] = true
      if not mmp.defs.current[v.name] then
        addedDefs[#addedDefs + 1] = v.name
      end
    end
    for def in pairs(mmp.defs.current) do
      if not newDefs[def] then
        lostDefs[#lostDefs + 1] = def
      end
    end
    mmp.defs.current = newDefs
    for _, def in pairs(lostDefs) do
      raiseEvent("mmp lost def", def)
    end
    for _, def in ipairs(addedDefs) do
      raiseEvent("mmp got def", def)
    end
  end
-- EVENT HANDLERS
registerAnonymousEventHandler("gmcp.Char.Defences.Add", "mmp.defs.add")
registerAnonymousEventHandler("gmcp.Char.Defences.Remove", "mmp.defs.remove")
registerAnonymousEventHandler("gmcp.Char.Defences.List", "mmp.defs.list")