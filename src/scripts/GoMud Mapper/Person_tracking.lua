--[[
mmp will have 2 person tracking databases:
- mmp.pdb  =  used to store the last known location of a person
- mmp.pdb_lastupdate  =  used to store the output of the last locating command

Both databases work with the person's name as key and the location name as value.

]]
mmp.pdb = mmp.pdb or {}
mmp.pdb_lastupdate = mmp.pdb_lastupdate or {}

function mmp.is_here(who)
  return (mmp.pdb[who] and mmp.pdb[who] == mmp.currentroomname) and true or false
end