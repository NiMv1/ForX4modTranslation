local ffi = require("ffi")
local C = ffi.C
--[[local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library]]

local isDebug = false
local equipmentTooltips = {
    outputString = {},
    selectedData,
    hoveredData,
}

local colors = {
    positive = "\27G",
    negative = "\27R",

}

local config = {
    indent = "    ",
    colors = {
        gray = { r = 190, g = 190, b = 190, a = 100 }
    }
}

local shipMenu
local stationMenu
local blueprintMenu

---
--- Register the callbacks and events
---
function equipmentTooltips.register()
    equipmentTooltips.debugText("REGISTER")

    shipMenu = Helper.getMenu("ShipConfigurationMenu")
    stationMenu = Helper.getMenu("StationConfigurationMenu")
    blueprintMenu = Helper.getMenu("BlueprintOrLicenceTraderMenu")

    shipMenu.registerCallback("displaySlots_on_before_create_button_mouseovertext", equipmentTooltips.onBeforeCreateButton)
    stationMenu.registerCallback("displayModules_on_before_create_button_mouseovertext", equipmentTooltips.onBeforeCreateButton)
    blueprintMenu.registerCallback("display_on_after_create_equipment_text", equipmentTooltips.onBeforeCreateButton)
end

---
---
---
function equipmentTooltips.onBeforeCreateButton(hoveredMacro, selectedMacro, mouseover)
    equipmentTooltips.clearOutputString()

    local hoveredName, hoveredLibrary = GetMacroData(hoveredMacro, "name", "infolibrary")
    local selectedName, selectedLibrary = GetMacroData(selectedMacro, "name", "infolibrary")

    if (hoveredLibrary) then
        hoveredData = GetLibraryEntry(hoveredLibrary, hoveredMacro)
    end

    if (selectedLibrary and hoveredMacro ~= selectedMacro) then
        selectedData = GetLibraryEntry(selectedLibrary, selectedMacro)
    end

    if (mouseover:match("%S")) then
        equipmentTooltips.addTextLine(mouseover)
        equipmentTooltips.addTextLine("\27X")
    end

    if (hoveredLibrary == "enginetypes") then
        equipmentTooltips.getTextEnginetypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "shieldgentypes") then
        equipmentTooltips.getTextShieldgentypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "thrustertypes") then
        equipmentTooltips.getTextThrustertypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_lasers") then
        equipmentTooltips.getTextWeaponsLasers(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_turrets") then
        equipmentTooltips.getTextWeaponsTurrets(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_missilelaunchers") then
        equipmentTooltips.getTextWeaponsMissilelaunchers(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_missileturrets") then
        equipmentTooltips.getTextWeaponsMissileturrets(hoveredData, selectedData)
    end

    if (hoveredName) then
        return {
            mouseovertext = tostring(table.concat(equipmentTooltips.outputString, "\n"))
        }
    end

end

---
--- Clear the output string
---
function equipmentTooltips.clearOutputString()
    equipmentTooltips.outputString = {}
end

---
--- Add a line of text to the output string
---
function equipmentTooltips.addTextLine(text)
    table.insert(equipmentTooltips.outputString, text)
end

---
--- Add a number value to the output string
---
function equipmentTooltips.addNumberValue(title, current, selected, unit, asfloat, hidePercentage, reverseColors)

    local percentDifference = ""

    current = tonumber(current)
    selected = tonumber(selected)

    local colorPositive = colors.positive
    local colorNegative = colors.negative
    if reverseColors then
        colorPositive = colors.negative
        colorNegative = colors.positive
    end

    if (current and selected) then

        percentDifference = ((current - selected) / selected) * 100
        if (current == 0 or selected == 0 or hidePercentage) then
            percentDifference = 0
        end
        equipmentTooltips.debugText("hidePercentage", hidePercentage)
        equipmentTooltips.debugText(title, "current: " .. (current or "") .. " | selected: " .. (selected or "") .. " | percentDifference: " .. (percentDifference or ""))

        if (percentDifference < 0) then
            percentDifference = colorNegative .. " (" .. ConvertIntegerString(percentDifference, true, 0, true) .. "%)\27X"
        elseif (percentDifference > 0) then
            percentDifference = colorPositive .. " (+" .. ConvertIntegerString(percentDifference, true, 0, true) .. "%)\27X"
        else
            percentDifference = ""
        end
    end
    if (not asfloat) then
        current = ConvertIntegerString(current, true, 0, true)
    end

    title = Helper.convertColorToText(config.colors.gray) .. "\027 " .. tostring(title) .. "\027X"
    table.insert(equipmentTooltips.outputString, tostring(title) .. ": " .. current .. " " .. (unit or "") .. tostring(percentDifference))
end

---
--- Add a boolean value to the output string
---
function equipmentTooltips.addBooleanValue(title, current, selected)

    local boolDifference = ""

    if (current and selected and selectedData and selectedData ~= hoveredData) then
        if (current < selected) then
            boolDifference = colors.negative .. " (-)\27X"
        elseif (current > selected) then
            boolDifference = colors.positive .. " (+)\27X"
        end
    end

    local currentAsString = ReadText(1001, 2617)
    if (current == 0) then
        currentAsString = ReadText(1001, 2618)
    end

    title = Helper.convertColorToText(config.colors.gray) .. "\027 " .. tostring(title) .. "\027X"
    table.insert(equipmentTooltips.outputString, tostring(title) .. ": " .. currentAsString .. " " .. tostring(boolDifference))
end

---
---
---
function equipmentTooltips.getTextEnginetypes(hoveredData, selectedData)
    if hoveredData.thrust_forward > 0 then
        -- forward

        equipmentTooltips.addNumberValue(ReadText(1001, 9065),
                hoveredData.thrust_forward,
                selectedData and selectedData.thrust_forward,
                ReadText(1001, 115)
        )
    end

    -- reverse
    if hoveredData.thrust_reverse > 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 9066),
                hoveredData.thrust_reverse,
                selectedData and selectedData.thrust_reverse,
                ReadText(1001, 115)
        )
    end
    -- empty line
    equipmentTooltips.addTextLine("")

    -- boost
    if hoveredData.boost_thrustfactor > 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 9067),
                hoveredData.thrust_forward * hoveredData.boost_thrustfactor,
                selectedData and selectedData.thrust_forward and selectedData.thrust_forward * selectedData.boost_thrustfactor,
                ReadText(1001, 115)
        )
    end

    -- boost duration
    if hoveredData.boost_maxduration > 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 9068),
                hoveredData.boost_maxduration,
                selectedData and selectedData.boost_maxduration,
                ReadText(1001, 100)
        )
    end
    if hoveredData.boost_chargetime > 0 or hoveredData.boost_rechargetime > 1 then
        -- boost charge
        if hoveredData.boost_chargetime > 0 then
            equipmentTooltips.addNumberValue(ReadText(1001, 9070),
                    hoveredData.boost_chargetime,
                    selectedData and selectedData.boost_chargetime,
                    ReadText(1001, 100),
                    false,
                    false,
                    true
            )
        elseif hoveredData.boost_rechargetime > 1 then
            equipmentTooltips.addNumberValue(ReadText(1001, 9070),
                    hoveredData.boost_rechargetime,
                    selectedData and selectedData.boost_rechargetime,
                    ReadText(1001, 100),
                    false,
                    false,
                    true
            )
        end

        -- immediate boost
        equipmentTooltips.addBooleanValue(ReadText(1001, 9071),
                (hoveredData.boost_chargetime == 0 and hoveredData.boost_rechargetime > 1) and 1 or 0,
                selectedData and (selectedData.boost_chargetime == 0 and selectedData.boost_rechargetime > 1) and 1 or 0
        )
    end

    if hoveredData.travel_thrustfactor and hoveredData.travel_thrustfactor > 0 then
        -- empty line
        equipmentTooltips.addTextLine("")

        -- travel mode: max thrust
        equipmentTooltips.addNumberValue(ReadText(1001, 9629),
                hoveredData.thrust_forward * hoveredData.travel_thrustfactor,
                selectedData and selectedData.thrust_forward and selectedData.thrust_forward * selectedData.travel_thrustfactor,
                ReadText(1001, 115)
        )
        -- travel mode: charge time
        equipmentTooltips.addNumberValue(ReadText(1001, 9630),
                hoveredData.travel_chargetime,
                selectedData and selectedData.travel_chargetime,
                ReadText(1001, 100),
                false,
                false,
                true
        )
        -- travel mode: attack time
        equipmentTooltips.addNumberValue(ReadText(1001, 9631),
                hoveredData.travel_attacktime,
                selectedData and selectedData.travel_attacktime,
                ReadText(1001, 100),
                false,
                false,
                true
        )
    end

end

function equipmentTooltips.getTextShieldgentypes(hoveredData, selectedData)
    -- shield capacity
    equipmentTooltips.addNumberValue(ReadText(1001, 9060),
            hoveredData.shield,
            selectedData and selectedData.shield,
            ReadText(1001, 118)
    )
    -- shield recharge
    equipmentTooltips.addNumberValue(ReadText(1001, 9079),
            hoveredData.recharge,
            selectedData and selectedData.recharge,
            ReadText(1001, 119)
    )
    -- shield recharge delay
    equipmentTooltips.addNumberValue(ReadText(1001, 9618),
            hoveredData.rechargedelay,
            selectedData and selectedData.rechargedelay,
            ReadText(1001, 100),
            false,
            false,
            true
    )
end

function equipmentTooltips.getTextThrustertypes(hoveredData, selectedData)
    if hoveredData.thrust_yaw > 0 then
        -- turning thrust
        if hoveredData.thrust_yaw > 0 then
            equipmentTooltips.addNumberValue(ReadText(1001, 9072),
                    Helper.round(hoveredData.thrust_yaw * 180 / math.pi),
                    selectedData and selectedData.thrust_yaw and Helper.round(selectedData.thrust_yaw * 180 / math.pi),
                    ReadText(1001, 115)
            )
        end

        -- pitch thrust
        if hoveredData.thrust_pitch > 0 then
            equipmentTooltips.addNumberValue(ReadText(1001, 9073),
                    Helper.round(hoveredData.thrust_pitch * 180 / math.pi),
                    selectedData and selectedData.thrust_pitch and Helper.round(selectedData.thrust_pitch * 180 / math.pi),
                    ReadText(1001, 115)
            )
        end

        -- empty line
        equipmentTooltips.addTextLine("")

        equipmentTooltips.addTextLine(ReadText(20918, 105))

        -- horizontal strafe
        if hoveredData.thrust_horizontal > 0 then
            equipmentTooltips.addNumberValue(config.indent .. ReadText(20918, 106),
                    hoveredData.thrust_horizontal,
                    selectedData and selectedData.thrust_horizontal,
                    ReadText(1001, 115)
            )
        end

        -- vertical strafe
        if hoveredData.thrust_vertical > 0 then
            equipmentTooltips.addNumberValue(config.indent .. ReadText(20918, 107),
                    hoveredData.thrust_horizontal,
                    selectedData and selectedData.thrust_horizontal,
                    ReadText(1001, 115)
            )
        end
    end
end

function equipmentTooltips.getTextWeaponsLasers(hoveredData, selectedData)
    equipmentTooltips.addTextLine(ReadText(20918, 100))
    -- burst damage
    equipmentTooltips.addNumberValue(config.indent .. ReadText(20918, 101),
            hoveredData.dps,
            selectedData and selectedData.dps,
            ReadText(1001, 119)
    )
    -- sustained damage
    equipmentTooltips.addNumberValue(config.indent .. ReadText(20918, 102),
            hoveredData.sustaineddps,
            selectedData and selectedData.sustaineddps,
            ReadText(1001, 119)
    )

    -- empty line
    equipmentTooltips.addTextLine("")

    -- shielded target
    equipmentTooltips.addTextLine(ReadText(1001, 2460))

    if hoveredData.isrepairweapon == 0 then
        equipmentTooltips.addNumberValue(config.indent .. ReadText(1001, 2462),
                hoveredData.hullshielddpshot + hoveredData.shieldonlydpshot,
                selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.shieldonlydpshot),
                ReadText(1001, 118)
        )
    end
    equipmentTooltips.addNumberValue(config.indent .. ((hoveredData.isrepairweapon == 0) and ReadText(1001, 2463) or ReadText(1001, 2464)),
            hoveredData.hullonlydpshot,
            selectedData and selectedData.hullonlydpshot,
            ReadText(1001, 118)
    )

    -- unshieldedtarget
    equipmentTooltips.addTextLine(ReadText(1001, 2461))

    equipmentTooltips.addNumberValue(config.indent .. ((hoveredData.isrepairweapon == 0) and ReadText(1001, 2463) or ReadText(1001, 2464)),
            hoveredData.hullshielddpshot + hoveredData.hullonlydpshot + hoveredData.hullnoshielddps,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.hullonlydpshot + selectedData.hullnoshielddps),
            ReadText(1001, 118)
    )

    -- empty line
    equipmentTooltips.addTextLine("")

    -- rate
    if hoveredData.isbeamweapon == 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 9084),
                Helper.round(hoveredData.reloadrate, 2),
                selectedData and selectedData.reloadrate and Helper.round(selectedData.reloadrate, 2),
                ReadText(20918, 104),
                true,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- initial heat
    if hoveredData.initialheat > 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 2465),
                hoveredData.initialheat,
                selectedData and selectedData.initialheat,
                ReadText(1001, 118)
        )
    end
    -- heat buildup
    equipmentTooltips.addNumberValue(ReadText(20918, 103),
            hoveredData.maxheatrate,
            selectedData and selectedData.maxheatrate,
            ReadText(1001, 119),
            false,
            false,
            true
    )

    -- cooling rate
    equipmentTooltips.addNumberValue(ReadText(1001, 9626),
            hoveredData.coolingrate,
            selectedData and selectedData.coolingrate,
            ReadText(1001, 119),
            false,
            false,
            true
    )

    -- empty line
    equipmentTooltips.addTextLine("")

    -- projectile speed
    if hoveredData.isbeamweapon == 0 then
        equipmentTooltips.addNumberValue(ReadText(1001, 9086),
                hoveredData.bulletspeed,
                selectedData and selectedData.bulletspeed,
                ReadText(1001, 113),
                false,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- range
    equipmentTooltips.addNumberValue(ReadText(1001, 9087),
            equipmentTooltips.formatRange(hoveredData.range),
            selectedData and selectedData.range and (equipmentTooltips.formatRange(selectedData.range)),
            ReadText(1001, 108),
            true
    )
end

function equipmentTooltips.getTextWeaponsTurrets(hoveredData, selectedData)
    -- dps
    equipmentTooltips.addNumberValue(ReadText(1001, 9077),
            hoveredData.dps,
            selectedData and selectedData.dps,
            ReadText(1001, 119)
    )
    -- empty line
    equipmentTooltips.addTextLine("")

    -- shielded target
    equipmentTooltips.addTextLine(ReadText(1001, 2460))

    equipmentTooltips.addNumberValue(config.indent .. ReadText(1001, 2462),
            hoveredData.hullshielddpshot + hoveredData.shieldonlydpshot,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.shieldonlydpshot),
            ReadText(1001, 118)
    )
    equipmentTooltips.addNumberValue(config.indent .. ReadText(1001, 2463),
            hoveredData.hullonlydpshot,
            selectedData and selectedData.hullonlydpshot,
            ReadText(1001, 118)
    )
    -- unshieldedtarget
    equipmentTooltips.addTextLine(ReadText(1001, 2461))

    equipmentTooltips.addNumberValue(config.indent .. ReadText(1001, 2463),
            hoveredData.hullshielddpshot + hoveredData.hullonlydpshot + hoveredData.hullnoshielddps,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.hullonlydpshot + selectedData.hullnoshielddps),
            ReadText(1001, 118)
    )
    -- empty line
    equipmentTooltips.addTextLine("")
    if hoveredData.isbeamweapon == 0 then
        -- rate
        equipmentTooltips.addNumberValue(ReadText(1001, 9084),
                Helper.round(hoveredData.reloadrate, 2),
                selectedData and selectedData.reloadrate and Helper.round(selectedData.reloadrate, 2),
                ReadText(20918, 104),
                true,
                not selectedData or selectedData.isbeamweapon == 1
        )

        -- empty line
        equipmentTooltips.addTextLine("")

        -- projectile speed
        equipmentTooltips.addNumberValue(ReadText(1001, 9086),
                hoveredData.bulletspeed,
                selectedData and selectedData.bulletspeed,
                ReadText(1001, 113),
                false,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- range
    equipmentTooltips.addNumberValue(ReadText(1001, 9087),
            equipmentTooltips.formatRange(hoveredData.range),
            selectedData and selectedData.range and (equipmentTooltips.formatRange(selectedData.range)),
            ReadText(1001, 108),
            true
    )
    -- rotation speed
    local printedrot = (hoveredData.rotation > 1 and hoveredData.rotation) or (hoveredData.rotation > 0.1 and Helper.round(hoveredData.rotation, 1)) or Helper.round(hoveredData.rotation, 2)
    local instlledprintedrot = selectedData and selectedData.hullshielddpshot and selectedData.rotation and (((selectedData.rotation > 1 and selectedData.rotation) or (selectedData.rotation > 0.1 and Helper.round(selectedData.rotation, 1)) or Helper.round(selectedData.rotation, 2)))
    equipmentTooltips.addNumberValue(ReadText(1001, 2419),
            printedrot,
            selectedData and instlledprintedrot,
            ReadText(1001, 117)
    )
end

function equipmentTooltips.getTextWeaponsMissilelaunchers(hoveredData, selectedData)
    -- storage capacity
    equipmentTooltips.addNumberValue(ReadText(1001, 9063),
            "+" .. hoveredData.storagecapacity,
            selectedData and selectedData.storagecapacity and ("+" .. selectedData.storagecapacity),
            ""
    )
end

function equipmentTooltips.getTextWeaponsMissileturrets(hoveredData, selectedData)
    -- storage capacity
    equipmentTooltips.addNumberValue(ReadText(1001, 9063),
            "+" .. hoveredData.storagecapacity,
            selectedData and selectedData.storagecapacity and ("+" .. selectedData.storagecapacity),
            ""
    )

    -- rotation speed
    local printedrot = (hoveredData.rotation > 1 and hoveredData.rotation) or (hoveredData.rotation > 0.1 and Helper.round(hoveredData.rotation, 1)) or Helper.round(hoveredData.rotation, 2)
    local selectedprintedrot = selectedData and selectedData.rotation and ((selectedData.rotation > 1 and selectedData.rotation) or (selectedData.rotation > 0.1 and Helper.round(selectedData.rotation, 1)) or Helper.round(selectedData.rotation, 2))
    equipmentTooltips.addNumberValue(ReadText(1001, 2419),
            printedrot,
            selectedprintedrot,
            ReadText(1001, 117)
    )

end

function equipmentTooltips.formatRange(range)
    return Helper.round(range / 1000, 2)
end

function equipmentTooltips.debugText(title, text)
    if (isDebug) then
        DebugError("equipmentTooltips.lua: " .. title .. ": " .. tostring(text))
    end
end

equipmentTooltips.register()

