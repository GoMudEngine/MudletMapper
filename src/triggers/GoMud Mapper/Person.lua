for i = 1, #matches, 2 do
  mmp.pdb[matches[i]] = mmp.currentroomname
  mmp.pdb_lastupdate[matches[i]] = true
  raiseEvent("mmapper updated pdb")
end