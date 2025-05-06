function mmp.registerGoMudEnvData(_, game)
  if game ~= "gomud" then
    return
  end
  mmp.envids =
    {
      Air = 20,
      Badland = 22,
      Beach = 23,
      Cave = 25,
      City = 26,
      Coast = 27,
      Default = 28,
      Desert = 29,
      Field = 30,
      Forest = 31,
      Garden = 32,
      Grove = 33,
      Hills = 34,
      Home = 35,
      Inn = 36,
      Inside = 37,
      Marsh = 38,
      Meadow = 39,
      Mountain = 40,
      Orchard = 41,
      Path = 42,
      Road = 43,
      Ship = 44,
      Shop = 45,
      Temple = 46,
      Thicket = 47,
      Tundra = 48,
      Underwater = 49,
      Water = 50,
      Glade = 51,
      Clearing = 52,
    }
  mmp.waterenvs = {}
  mmp.envidsr = {}
  for name, id in pairs(mmp.envids) do
    mmp.envidsr[id] = name
  end


mmp.colorcodes = {}
mmp.colorcodes[20] = {176, 224, 230, 255}  -- Air: Light blue
mmp.colorcodes[22] = {205, 133, 63, 255}   -- Badland: Peru brown
mmp.colorcodes[23] = {218, 165, 32, 255}   -- Beach: Goldenrod
mmp.colorcodes[25] = {47, 79, 79, 255}     -- Cave: Dark slate gray
mmp.colorcodes[26] = {190, 190, 190, 255}  -- City: Gray
mmp.colorcodes[27] = {210, 180, 140, 255}  -- Coast: Tan
mmp.colorcodes[28] = {255, 69, 0, 255}     -- Default: Red-orange
mmp.colorcodes[29] = {255, 215, 0, 255}    -- Desert: Gold
mmp.colorcodes[30] = {127, 255, 0, 255}    -- Field: Chartreuse
mmp.colorcodes[31] = {0, 100, 0, 255}      -- Forest: Dark green
mmp.colorcodes[32] = {152, 251, 152, 255}  -- Garden: Pale green
mmp.colorcodes[33] = {34, 139, 34, 255}    -- Grove: Forest green
mmp.colorcodes[34] = {50, 205, 50, 255}    -- Hills: Lime green
mmp.colorcodes[35] = {102, 205, 170, 255}  -- Home: Medium aquamarine
mmp.colorcodes[36] = {0, 128, 128, 255}    -- Inn: Teal
mmp.colorcodes[37] = {255, 250, 205, 255}  -- Inside: Lemon chiffon
mmp.colorcodes[38] = {107, 142, 35, 255}   -- Marsh: Olive drab
mmp.colorcodes[39] = {154, 205, 50, 255}   -- Meadow: Yellow green
mmp.colorcodes[40] = {139, 69, 19, 255}    -- Mountain: Saddle brown
mmp.colorcodes[41] = {124, 252, 0, 255}    -- Orchard: Lawn green
mmp.colorcodes[42] = {153, 102, 51, 255}   -- Path: Brown
mmp.colorcodes[43] = {112, 128, 144, 255}  -- Road: Slate gray
mmp.colorcodes[44] = {255, 42, 42, 255}    -- Ship: Red
mmp.colorcodes[45] = {0, 190, 255, 255}    -- Shop: Deep sky blue
mmp.colorcodes[46] = {138, 43, 226, 255}   -- Temple: Blue violet
mmp.colorcodes[47] = {85, 107, 47, 255}    -- Thicket: Dark olive green
mmp.colorcodes[48] = {255, 250, 250, 255}  -- Tundra: Snow
mmp.colorcodes[49] = {65, 105, 225, 255}   -- Underwater: Royal blue
mmp.colorcodes[50] = {30, 144, 255, 255}   -- Water: Dodger blue
mmp.colorcodes[51] = {144, 238, 144, 255}  -- Glade: Light green
mmp.colorcodes[52] = {143, 188, 143, 255}  -- Clearing: Dark sea green

function mmp.setGoMudColorcodes()
  for id, rgba in pairs(mmp.colorcodes) do
    setCustomEnvColor(id, rgba[1], rgba[2], rgba[3], rgba[4])
  end
 end
end