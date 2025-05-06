function mmp.regenerateAreas()
  -- cached data
  mmp.areatable = getAreaTable() -- this translates an area name to an ID
  mmp.areatabler = {} -- this translates an ID to an area name

  local t = getAreaTable()
  for k,v in pairs(t) do
    mmp.areatabler[tonumber(v)] = k
  end

  mmp.clearpathcache()
end