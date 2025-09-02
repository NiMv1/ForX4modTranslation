local ffi = require ("ffi")
local C = ffi.C
ffi.cdef[[
	void ToggleMouseSteeringMode(void);
]]

local ModLua = {}

local topLevelMenu
local kuertee_reset_mouse = {}
local newFuncs = {}

function ModLua.init()
	RegisterEvent ("kuertee_reset_mouse.OnOpenFullScreenMenu", kuertee_reset_mouse.OnOpenFullScreenMenu)
	RegisterEvent ("kuertee_reset_mouse.OnCloseFullScreenMenu", kuertee_reset_mouse.OnCloseFullScreenMenu)
	topLevelMenu = Helper.getMenu ("TopLevelMenu")
	topLevelMenu.registerCallback ("createInfoFrame_onUpdate_before_frame_update", newFuncs.createInfoFrame_onUpdate_before_frame_update)
	RegisterEvent ("kuertee_reset_mouse.OnOptionChange_GamepadStart", kuertee_reset_mouse.OnOptionChange_GamepadStart)
	RegisterEvent ("kuertee_reset_mouse.OnOptionChange_GamepadEnd", kuertee_reset_mouse.OnOptionChange_GamepadEnd)
	RegisterEvent ("kuertee_reset_mouse.OnAutoPilotEnd", kuertee_reset_mouse.OnAutoPilotEnd)
	RegisterEvent ("kuertee_reset_mouse.DisableMouseSteering", kuertee_reset_mouse.DisableMouseSteering)
	RegisterEvent ("kuertee_reset_mouse.AutoCamCutscene_On", kuertee_reset_mouse.AutoCamCutscene_On)
	RegisterEvent ("kuertee_reset_mouse.AutoCamCutscene_Off", kuertee_reset_mouse.AutoCamCutscene_Off)
	local mode, angle = GetControllerInfo ()
	Helper.debugText ("kuertee_reset_mouse.Init mode: " .. tostring (mode) .. " angle: " .. tostring (angle))
	newFuncs.lastUsedMode = mode
end
function kuertee_reset_mouse.OnOpenFullScreenMenu ()
	Helper.debugText ("kuertee_reset_mouse.OnOpenFullScreenMenu")
	if newFuncs.isAnalog (newFuncs.lastUsedMode) then
		if newFuncs.resetGamepadEnd and newFuncs.resetGamepadEnd ~= "disabled" then
			newFuncs.setMouseCursorPosition (newFuncs.resetGamepadEnd, "resetGamepadEnd")
		elseif newFuncs.x and newFuncs.y then
			-- C.SetMouseCursorPosition (newFuncs.x, newFuncs.y)
			newFuncs.setMouseCursorPosition ("previous", "previous")
		end
	elseif newFuncs.x and newFuncs.y then
		-- C.SetMouseCursorPosition (newFuncs.x, newFuncs.y)
		newFuncs.setMouseCursorPosition ("previous", "previous")
	end
end
function kuertee_reset_mouse.OnCloseFullScreenMenu (_, location)
	Helper.debugText ("kuertee_reset_mouse.OnCloseFullScreenMenu location: " .. tostring (location))
	local mousepos = C.GetCenteredMousePos()
	local x = mousepos.x
	local y = mousepos.y
	Helper.debugText ("kuertee_reset_mouse.OnCloseFullScreenMenu x: " .. tostring (x) .. " y: " .. tostring (y))
	newFuncs.x = x
	newFuncs.y = y
	if location and location ~= "disabled" then
		newFuncs.setMouseCursorPosition (location, "menuClose")
	end
end
function kuertee_reset_mouse.OnAutoPilotEnd (_, location)
	Helper.debugText ("kuertee_reset_mouse.OnAutoPilotEnd location: " .. tostring (location))
	if location and location ~= "disabled" then
		newFuncs.setMouseCursorPosition (location, "autopilotEnd")
	end
end
function kuertee_reset_mouse.DisableMouseSteering (_, isDisable)
	Helper.debugText ("kuertee_reset_mouse.DisableMouseSteering isDisable: " .. tostring (isDisable))
	local mode, angle = GetControllerInfo ()
	Helper.debugText ("kuertee_reset_mouse.DisableMouseSteering mode: " .. tostring (mode) .. " angle: " .. tostring (angle))
	Helper.debugText ("kuertee_reset_mouse.DisableMouseSteering wasMouseSteering: " .. tostring (kuertee_reset_mouse.wasMouseSteering))
	if isDisable == 1 or isDisable == true then
		if mode == "mouseSteering" then
			kuertee_reset_mouse.wasMouseSteering = true
			C.ToggleMouseSteeringMode ()
		end
	else
		if kuertee_reset_mouse.wasMouseSteering == true then
			kuertee_reset_mouse.wasMouseSteering = false
			if mode ~= "mouseSteering" then
				C.SetMouseCursorPosition (0, 0)
				C.ToggleMouseSteeringMode ()
			end
		end
	end
end
function kuertee_reset_mouse.AutoCamCutscene_On (_)
	newFuncs.setMouseCursorPosition ("br", "autocam_cutscene_on")
end
function kuertee_reset_mouse.AutoCamCutscene_Off (_)
	newFuncs.setMouseCursorPosition ("c", "autocam_cutscene_off")
end
newFuncs.mouseCursorPositionId = "none"
function newFuncs.setMouseCursorPosition (location, id)
	if (id ~= newFuncs.mouseCursorPositionId or id == 'menuClose' or id == "autopilotEnd") then
		local mousepos = C.GetCenteredMousePos()
		local x = mousepos.x
		local y = mousepos.y
		if location == "c" then
			newFuncs.x = x
			newFuncs.y = y
			C.SetMouseCursorPosition (0, 0)
		elseif location == "tl" then
			newFuncs.x = x
			newFuncs.y = y
			C.SetMouseCursorPosition (-1000000, -1000000)
		elseif location == "tr" then
			newFuncs.x = x
			newFuncs.y = y
			C.SetMouseCursorPosition (1000000, -1000000)
		elseif location == "br" then
			newFuncs.x = x
			newFuncs.y = y
			C.SetMouseCursorPosition (1000000, 1000000)
		elseif location == "bl" then
			newFuncs.x = x
			newFuncs.y = y
			C.SetMouseCursorPosition (-1000000, 1000000)
		elseif location == "previous" then
			if newFuncs.x and newFuncs.y then
				C.SetMouseCursorPosition (newFuncs.x, newFuncs.y)
				newFuncs.x = nil
				newFuncs.y = nil
			end
		end
	end
	newFuncs.mouseCursorPositionId = id
end
function newFuncs.isAnalog(mode)
	return mode == "gamepad" or mode == "joystick" or mode == "touch"
end
function kuertee_reset_mouse.OnOptionChange_GamepadStart (_, location)
	Helper.debugText ("kuertee_reset_mouse.lua: OnOptionChange_GamepadStart: " .. location)
	newFuncs.resetGamepadStart = location
end
function kuertee_reset_mouse.OnOptionChange_GamepadEnd (_, location)
	Helper.debugText ("kuertee_reset_mouse.lua: OnOptionChange_GamepadEnd: " .. location)
	newFuncs.resetGamepadEnd = location
end
function newFuncs.createInfoFrame_onUpdate_before_frame_update (frame)
	-- mode, angle = GetControllerInfo()
	-- Returns the current input mode ("mouseSteering"|"mouseCursor"|"gamepad"|"touch"|"joystick") and the joystick input angle (only reasonable in "touch", "joystick", or "gamepad" mode).
	-- The angle value will be -1, if the joystick is in its safe area. Otherwise it returns the angle in radian [0..2π] (with 0 corresponding to the joystick pointing upwards - rotation is clockwise).
	local mode, angle
	mode, angle = GetControllerInfo ()
	Helper.debugText ("kuertee_reset_mouse " .. mode .. " angle " .. angle)
	Helper.debugText ("isAnalog", isAnalog)
	Helper.debugText ("newFuncs.lastUsedMode", newFuncs.lastUsedMode)
	-- start: Mycu code
	if newFuncs.lastUsedMode ~= mode then
		if newFuncs.isAnalog(mode) and newFuncs.lastUsedMode ~= "mouseSteering" then
			-- C.SetMouseCursorPosition (1000000, -1000000)
			if newFuncs.resetGamepadStart and newFuncs.resetGamepadStart ~= "disabled" then
				newFuncs.setMouseCursorPosition (newFuncs.resetGamepadStart, "resetGamepadStart")
			end
		elseif newFuncs.isAnalog(newFuncs.lastUsedMode) then
			-- C.SetMouseCursorPosition (0, 0)
			if newFuncs.resetGamepadEnd and newFuncs.resetGamepadEnd ~= "disabled" then
				newFuncs.setMouseCursorPosition (newFuncs.resetGamepadEnd, "resetGamepadEnd")
			end
		end
	end
	newFuncs.lastUsedMode = mode
	-- end: Mycu code
end

ModLua.init()
