local ffi = require ("ffi")
local C = ffi.C

local ModLua = {}

local newFuncs = {}
function ModLua.init()
	-- DebugError ("kuertee_surface_element_targeting Init")
	RegisterEvent ("kSET_set_target", newFuncs.kSET_set_target)
	RegisterEvent ("kSET_get_active_mission", newFuncs.kSET_get_active_mission)
end
function newFuncs.kSET_get_active_mission ()
	-- DebugError ("kuertee_surface_element_targeting kSET_get_active_mission")
	local activeMissionId = ConvertStringToLuaID (tostring (C.GetActiveMissionID ()))
	AddUITriggeredEvent ("kSET", "get_active_mission", activeMissionId)
end
function newFuncs.kSET_set_target (_, object)
	-- DebugError ("kuertee_surface_element_targeting kSET_set_target object " .. tostring (object))
	local object64Bit = ConvertStringTo64Bit (object)
	-- DebugError ("kuertee_surface_element_targeting kSET_set_target object64Bit " .. tostring (object64Bit))
	C.SetSofttarget(object64Bit, "")
end

ModLua.init()
