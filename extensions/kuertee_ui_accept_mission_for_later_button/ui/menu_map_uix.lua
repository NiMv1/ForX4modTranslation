local ffi = require ("ffi")
local C = ffi.C

local ModLua = {}

local mapMenu = nil
local missionBriefingMenu = nil
local oldFuncs = {}
local newFuncs = {}

function ModLua.init()
	mapMenu = Helper.getMenu ("MapMenu")
	oldFuncs.buttonMissionOfferAccept = mapMenu.buttonMissionOfferAccept
	mapMenu.buttonMissionOfferAccept = newFuncs.buttonMissionOfferAccept
	RegisterEvent ("kAMFLB_continue_mission_offer_accept", newFuncs.kAMFLB_continue_mission_offer_accept)
	RegisterEvent ("kAMFLB_get_active_mission", newFuncs.kAMFLB_get_active_mission)
	RegisterEvent ("kAMFLB_on_reactivate_previous_mission", newFuncs.kAMFLB_on_reactivate_previous_mission)
	missionBriefingMenu = Helper.getMenu ("MissionBriefingMenu")
	oldFuncs.buttonAccept = missionBriefingMenu.buttonAccept
	missionBriefingMenu.buttonAccept = newFuncs.buttonAccept
	newFuncs.isAccessFsExists = false
end
function newFuncs.buttonMissionOfferAccept ()
	Helper.debugText_forced("kuertee_amflb.buttonMissionOfferAccept isAccessFsExists: " .. tostring(newFuncs.isAccessFsExists))
	local menu = mapMenu
	if newFuncs.isAccessFsExists ~= true and newFuncs.isAccessFsExists ~= 1 then
		newFuncs.menuAcceptFrom = menu
		Helper.debugText_forced("kuertee_amflb buttonMissionOfferAccept menu: " .. tostring (menu))
		local activeMissionId = ConvertStringToLuaID (tostring (C.GetActiveMissionID ()))
		Helper.debugText_forced("kuertee_amflb buttonMissionOfferAccept activeMissionId " .. tostring (activeMissionId))
		newFuncs.acceptedOfferId = menu.contextMenuData.missionid
		newFuncs.missionMode = menu.missionMode
		Helper.debugText_forced("kuertee_amflb buttonMissionOfferAccept newFuncs.acceptedOfferId " .. tostring (newFuncs.acceptedOfferId))
		Helper.debugText_forced("kuertee_amflb buttonMissionOfferAccept newFuncs.missionMode " .. tostring (newFuncs.missionMode))
		-- oldFuncs.buttonMissionOfferAccept ()
		AddUITriggeredEvent ("kAMFLB_ui_trigger", "on_mission_offer_accepted", activeMissionId)
	else
		oldFuncs.buttonMissionOfferAccept ()
	end
end
function newFuncs.buttonAccept ()
	Helper.debugText_forced("kuertee_amflb.buttonMissionOfferAccept isAccessFsExists: " .. tostring(newFuncs.isAccessFsExists))
	local menu = missionBriefingMenu
	if newFuncs.isAccessFsExists ~= true and newFuncs.isAccessFsExists ~= 1 then
		newFuncs.menuAcceptFrom = menu
		Helper.debugText_forced("kuertee_amflb buttonAccept menu: " .. tostring (menu))
		local activeMissionId = ConvertStringToLuaID (tostring (C.GetActiveMissionID ()))
		Helper.debugText_forced("kuertee_amflb buttonAccept activeMissionId " .. tostring (activeMissionId))
		newFuncs.acceptedOfferId = menu.missionID
		Helper.debugText_forced("kuertee_amflb buttonAccept newFuncs.acceptedOfferId " .. tostring (newFuncs.acceptedOfferId))
		-- oldFuncs.buttonAccept ()
		AddUITriggeredEvent ("kAMFLB_ui_trigger", "on_mission_offer_accepted", activeMissionId)
	else
		oldFuncs.buttonAccept ()
	end
end
function newFuncs.kAMFLB_continue_mission_offer_accept ()
	Helper.debugText_forced("kuertee_amflb kAMFLB_continue_mission_offer_accept menuAcceptFrom: " .. tostring (newFuncs.menuAcceptFrom))
	if newFuncs.menuAcceptFrom == mapMenu then
		oldFuncs.buttonMissionOfferAccept ()
	else
		oldFuncs.buttonAccept ()
	end
end
function newFuncs.kAMFLB_get_active_mission ()
	local activeMissionId = ConvertStringToLuaID (tostring (C.GetActiveMissionID ()))
	Helper.debugText_forced("kuertee_amflb kAMFLB_get_active_mission activeMissionId " .. tostring (activeMissionId))
	AddUITriggeredEvent ("kAMFLB_ui_trigger", "get_active_mission", activeMissionId)
end
function newFuncs.kAMFLB_on_reactivate_previous_mission ()
	local menu = mapMenu
	local activeMissionId = ConvertStringToLuaID (tostring (C.GetActiveMissionID ()))
	Helper.debugText_forced("kuertee_amflb kAMFLB_on_reactivate_previous_mission mapMenu.mainFrame " .. tostring (mapMenu.mainFrame))
	Helper.debugText_forced("kuertee_amflb kAMFLB_on_reactivate_previous_mission activeMissionId " .. tostring (activeMissionId))
	Helper.debugText_forced("kuertee_amflb kAMFLB_on_reactivate_previous_mission newFuncs.acceptedOfferId " .. tostring (newFuncs.acceptedOfferId))
	if mapMenu.mainFrame then
		if activeMissionId then
			menu.closeContextMenu ()
			menu.infoTableMode = "mission"
			menu.missionMode = newFuncs.missionMode
			-- menu.contextMenuData.missionid = newFuncs.acceptedOfferId -- highlight accepted mission
			menu.updateMapAndInfoFrame ()
			-- menu.showMissionContext (tostring (activeMissionId)) -- show re-activated mission
			menu.contextMenuData.missionid = newFuncs.acceptedOfferId
			menu.showMissionContext (tostring (newFuncs.acceptedOfferId)) -- show newly accepted mission
		end
	end
end
function newFuncs.kAMFLB_init_isAccessFsExists (_, isAccessFsExists)
	Helper.debugText_forced("kuertee_amflb kAMFLB_init_isAccessFsExists isAccessFsExists: " .. tostring (isAccessFsExists))
	newFuncs.isAccessFsExists = isAccessFsExists
end

ModLua.init()
