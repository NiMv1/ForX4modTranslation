-- lua script to instant build stations
local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
  typedef uint64_t UniverseID;
  void ForceBuildCompletion(UniverseID containerid);
]]

local function instant_build(_, argstr)
  local ct = ConvertStringTo64Bit(tostring(tonumber(argstr)))
  C.ForceBuildCompletion(ct)
end

local function Init()

  -- MD triggered events.
  RegisterEvent("shiptestfield_lualib.instant_build", instant_build)

end

Init()