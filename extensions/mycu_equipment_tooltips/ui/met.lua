local ffi = require("ffi")
local C = ffi.C
--[[local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library]]

local isDebug = false
local met = {
    outputString = {}
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

local function init ()
    met.debugText("INIT")

    shipMenu = Helper.getMenu("ShipConfigurationMenu")
    stationMenu = Helper.getMenu("StationConfigurationMenu")
    blueprintMenu = Helper.getMenu("BlueprintOrLicenceTraderMenu")

    shipMenu.registerCallback("displaySlots_on_before_create_button_mouseovertext", met.onBeforeCreateButton)
    stationMenu.registerCallback("displayModules_on_before_create_button_mouseovertext", met.onBeforeCreateButton)
    blueprintMenu.registerCallback("display_on_after_create_equipment_text", met.onBeforeCreateButton)
end

function met.onBeforeCreateButton(hoveredMacro, selectedMacro, mouseover)
    met.clearOutputString()

    local hoveredName, hoveredLibrary = GetMacroData(hoveredMacro, "name", "infolibrary")
    local selectedName, selectedLibrary = GetMacroData(selectedMacro, "name", "infolibrary")

    local selectedData
    local hoveredData

    if (hoveredLibrary) then
        hoveredData = GetLibraryEntry(hoveredLibrary, hoveredMacro)
    end

    if (selectedLibrary and hoveredMacro ~= selectedMacro) then
        selectedData = GetLibraryEntry(selectedLibrary, selectedMacro)
    end

    if (mouseover:match("%S")) then
        met.addTextLine(mouseover)
        met.addTextLine("")
    end

    if (hoveredLibrary == "enginetypes") then
        met.getTextEnginetypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "shieldgentypes") then
        met.getTextShieldgentypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "thrustertypes") then
        met.getTextThrustertypes(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_lasers") then
        met.getTextWeaponsLasers(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_turrets") then
        met.getTextWeaponsTurrets(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_missilelaunchers") then
        met.getTextWeaponsMissilelaunchers(hoveredData, selectedData)
    end

    if (hoveredLibrary == "weapons_missileturrets") then
        met.getTextWeaponsMissileturrets(hoveredData, selectedData)
    end

    if (hoveredName) then
        return {
            mouseovertext = tostring(table.concat(met.outputString, "\n"))
        }
    end

end

function met.clearOutputString()
    met.outputString = {}
end

function met.addTextLine(text)
    table.insert(met.outputString, text)
end

function met.addToOutput(title, current, selected, unit, asfloat, hidePercentage, reverseColors)

    local percentDifference = ""

    current = tonumber(current)
    selected = tonumber(selected)

    local colorPositive = "\27G"
    local colorNegative = "\27R"
    if reverseColors then
        colorPositive = "\27R"
        colorNegative = "\27G"
    end

    if (current and selected) then

        percentDifference = ((current - selected) / selected) * 100
        if (current == 0 or selected == 0 or hidePercentage) then
            percentDifference = 0
        end
        met.debugText("hidePercentage", hidePercentage)
        met.debugText(title, "current: " .. (current or "") .. " | selected: " .. (selected or "") .. " | percentDifference: " .. (percentDifference or ""))

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
    table.insert(met.outputString, tostring(title) .. ": " .. current .. " " .. (unit or "") .. tostring(percentDifference))
end

function met.getTextEnginetypes(hoveredData, selectedData)
    if hoveredData.thrust_forward > 0 then
        -- forward

        met.addToOutput(ReadText(1001, 9065),
                hoveredData.thrust_forward,
                selectedData and selectedData.thrust_forward,
                ReadText(1001, 115)
        )
    end

    -- reverse
    if hoveredData.thrust_reverse > 0 then
        met.addToOutput(ReadText(1001, 9066),
                hoveredData.thrust_reverse,
                selectedData and selectedData.thrust_reverse,
                ReadText(1001, 115)
        )
    end
    -- empty line
    met.addTextLine("")

    -- boost
    if hoveredData.boost_thrustfactor > 0 then
        met.addToOutput(ReadText(1001, 9067),
                hoveredData.thrust_forward * hoveredData.boost_thrustfactor,
                selectedData and selectedData.thrust_forward * selectedData.boost_thrustfactor,
                ReadText(1001, 115)
        )
    end

    -- boost duration
    if hoveredData.boost_maxduration > 0 then
        met.addToOutput(ReadText(1001, 9068),
                hoveredData.boost_maxduration,
                selectedData and selectedData.boost_maxduration,
                ReadText(1001, 100)
        )
    end
    if hoveredData.boost_chargetime > 0 or hoveredData.boost_rechargetime > 1 then
        -- boost charge
        if hoveredData.boost_chargetime > 0 then
            met.addToOutput(ReadText(1001, 9070),
                    hoveredData.boost_chargetime,
                    selectedData and selectedData.boost_chargetime,
                    ReadText(1001, 100)
            )
        elseif hoveredData.boost_rechargetime > 1 then
            met.addToOutput(ReadText(1001, 9070),
                    hoveredData.boost_rechargetime,
                    selectedData and selectedData.boost_rechargetime,
                    ReadText(1001, 100)
            )
        end
    end

    if hoveredData.travel_thrustfactor and hoveredData.travel_thrustfactor > 0 then
        -- empty line
        met.addTextLine("")

        -- travel mode: max thrust
        met.addToOutput(ReadText(1001, 9629),
                hoveredData.thrust_forward * hoveredData.travel_thrustfactor,
                selectedData and selectedData.thrust_forward * selectedData.travel_thrustfactor,
                ReadText(1001, 115)
        )
        -- travel mode: charge time
        met.addToOutput(ReadText(1001, 9630),
                hoveredData.travel_chargetime,
                selectedData and selectedData.travel_chargetime,
                ReadText(1001, 100),
                false,
                false,
                true
        )
        -- travel mode: attack time
        met.addToOutput(ReadText(1001, 9631),
                hoveredData.travel_attacktime,
                selectedData and selectedData.travel_attacktime,
                ReadText(1001, 100),
                false,
                false,
                true
        )
    end

end

function met.getTextShieldgentypes(hoveredData, selectedData)
    -- shield capacity
    met.addToOutput(ReadText(1001, 9060),
            hoveredData.shield,
            selectedData and selectedData.shield,
            ReadText(1001, 118)
    )
    -- shield recharge
    met.addToOutput(ReadText(1001, 9079),
            hoveredData.recharge,
            selectedData and selectedData.recharge,
            ReadText(1001, 119)
    )
    -- shield recharge delay
    met.addToOutput(ReadText(1001, 9618),
            hoveredData.rechargedelay,
            selectedData and selectedData.rechargedelay,
            ReadText(1001, 100),
            false,
            false,
            true
    )
end

function met.getTextThrustertypes(hoveredData, selectedData)
    if hoveredData.thrust_yaw > 0 then
        -- turning thrust
        if hoveredData.thrust_yaw > 0 then
            met.addToOutput(ReadText(1001, 9072),
                    Helper.round(hoveredData.thrust_yaw * 180 / math.pi),
                    selectedData and Helper.round(selectedData.thrust_yaw * 180 / math.pi),
                    ReadText(1001, 115)
            )
        end

        -- pitch thrust
        if hoveredData.thrust_pitch > 0 then
            met.addToOutput(ReadText(1001, 9073),
                    Helper.round(hoveredData.thrust_pitch * 180 / math.pi),
                    selectedData and Helper.round(selectedData.thrust_pitch * 180 / math.pi),
                    ReadText(1001, 115)
            )
        end

        -- empty line
        met.addTextLine("")

        met.addTextLine(ReadText(20918, 105))

        -- horizontal strafe
        if hoveredData.thrust_horizontal > 0 then
            met.addToOutput(config.indent .. ReadText(20918, 106),
                    hoveredData.thrust_horizontal,
                    selectedData and selectedData.thrust_horizontal,
                    ReadText(1001, 115)
            )
        end

        -- vertical strafe
        if hoveredData.thrust_vertical > 0 then
            met.addToOutput(config.indent .. ReadText(20918, 107),
                    hoveredData.thrust_horizontal,
                    selectedData and selectedData.thrust_horizontal,
                    ReadText(1001, 115)
            )
        end
    end
end

function met.getTextWeaponsLasers(hoveredData, selectedData)
    met.addTextLine(ReadText(20918, 100))
    -- burst damage
    met.addToOutput(config.indent .. ReadText(20918, 101),
            hoveredData.dps,
            selectedData and selectedData.dps,
            ReadText(1001, 119)
    )
    -- sustained damage
    met.addToOutput(config.indent .. ReadText(20918, 102),
            hoveredData.sustaineddps,
            selectedData and selectedData.sustaineddps,
            ReadText(1001, 119)
    )

    -- empty line
    met.addTextLine("")

    -- shielded target
    met.addTextLine(ReadText(1001, 2460))

    if hoveredData.isrepairweapon == 0 then
        met.addToOutput(config.indent .. ReadText(1001, 2462),
                hoveredData.hullshielddpshot + hoveredData.shieldonlydpshot,
                selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.shieldonlydpshot),
                ReadText(1001, 119)
        )
    end
    met.addToOutput(config.indent .. ((hoveredData.isrepairweapon == 0) and ReadText(1001, 2463) or ReadText(1001, 2464)),
            hoveredData.hullonlydpshot,
            selectedData and selectedData.hullonlydpshot,
            ReadText(1001, 119)
    )

    -- unshieldedtarget
    met.addTextLine(ReadText(1001, 2461))

    met.addToOutput(config.indent .. ((hoveredData.isrepairweapon == 0) and ReadText(1001, 2463) or ReadText(1001, 2464)),
            hoveredData.hullshielddpshot + hoveredData.hullonlydpshot + hoveredData.hullnoshielddps,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.hullonlydpshot + selectedData.hullnoshielddps),
            ReadText(1001, 119)
    )

    -- empty line
    met.addTextLine("")

    -- rate
    if hoveredData.isbeamweapon == 0 then
        met.addToOutput(ReadText(1001, 9084),
                Helper.round(hoveredData.reloadrate, 2),
                selectedData and Helper.round(selectedData.reloadrate, 2),
                ReadText(20918, 104),
                true,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- initial heat
    if hoveredData.initialheat > 0 then
        met.addToOutput(ReadText(1001, 2465),
                hoveredData.initialheat,
                selectedData and selectedData.initialheat,
                ReadText(1001, 118)
        )
    end
    -- heat buildup
    met.addToOutput(ReadText(20918, 103),
            hoveredData.maxheatrate,
            selectedData and selectedData.maxheatrate,
            ReadText(1001, 119),
            false,
            false,
            true
    )

    -- cooling rate
    met.addToOutput(ReadText(1001, 9626),
            hoveredData.coolingrate,
            selectedData and selectedData.coolingrate,
            ReadText(1001, 119),
            false,
            false,
            true
    )

    -- empty line
    met.addTextLine("")

    -- projectile speed
    if hoveredData.isbeamweapon == 0 then
        met.addToOutput(ReadText(1001, 9086),
                hoveredData.bulletspeed,
                selectedData and selectedData.bulletspeed,
                ReadText(1001, 113),
                false,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- range
    met.addToOutput(ReadText(1001, 9087),
            met.formatRange(hoveredData.range),
            selectedData and selectedData.range and (met.formatRange(selectedData.range)),
            ReadText(1001, 108),
            true
    )
end

function met.getTextWeaponsTurrets(hoveredData, selectedData)
    -- dps
    met.addToOutput(ReadText(1001, 9077),
            hoveredData.dps,
            selectedData and selectedData.dps,
            ReadText(1001, 119)
    )
    -- empty line
    met.addTextLine("")

    -- shielded target
    met.addTextLine(ReadText(1001, 2460))

    met.addToOutput(config.indent .. ReadText(1001, 2462),
            hoveredData.hullshielddpshot + hoveredData.shieldonlydpshot,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.shieldonlydpshot),
            ReadText(1001, 119)
    )
    met.addToOutput(config.indent .. ReadText(1001, 2463),
            hoveredData.hullonlydpshot,
            selectedData and selectedData.hullonlydpshot,
            ReadText(1001, 119)
    )
    -- unshieldedtarget
    met.addTextLine(ReadText(1001, 2461))

    met.addToOutput(config.indent .. ReadText(1001, 2463),
            hoveredData.hullshielddpshot + hoveredData.hullonlydpshot + hoveredData.hullnoshielddps,
            selectedData and selectedData.hullshielddpshot and (selectedData.hullshielddpshot + selectedData.hullonlydpshot + selectedData.hullnoshielddps),
            ReadText(1001, 119)
    )
    -- empty line
    met.addTextLine("")
    if hoveredData.isbeamweapon == 0 then
        -- rate
        met.addToOutput(ReadText(1001, 9084),
                Helper.round(hoveredData.reloadrate, 2),
                selectedData and selectedData.reloadrate and Helper.round(selectedData.reloadrate, 2),
                ReadText(20918, 104),
                true,
                not selectedData or selectedData.isbeamweapon == 1
        )

        -- empty line
        met.addTextLine("")

        -- projectile speed
        met.addToOutput(ReadText(1001, 9086),
                hoveredData.bulletspeed,
                selectedData and selectedData.bulletspeed,
                ReadText(1001, 113),
                false,
                not selectedData or selectedData.isbeamweapon == 1
        )
    end
    -- range
    met.addToOutput(ReadText(1001, 9087),
            met.formatRange(hoveredData.range),
            selectedData and selectedData.range and (met.formatRange(selectedData.range)),
            ReadText(1001, 108),
            true
    )
    -- rotation speed
    local printedrot = (hoveredData.rotation > 1 and hoveredData.rotation) or (hoveredData.rotation > 0.1 and Helper.round(hoveredData.rotation, 1)) or Helper.round(hoveredData.rotation, 2)
    local instlledprintedrot = selectedData and selectedData.hullshielddpshot and (((selectedData.rotation > 1 and selectedData.rotation) or (selectedData.rotation > 0.1 and Helper.round(selectedData.rotation, 1)) or Helper.round(selectedData.rotation, 2)))
    met.addToOutput(ReadText(1001, 2419),
            printedrot,
            selectedData and instlledprintedrot,
            ReadText(1001, 117)
    )
end

function met.getTextWeaponsMissilelaunchers(hoveredData, selectedData)
    -- storage capacity
    met.addToOutput(ReadText(1001, 9063),
            "+" .. hoveredData.storagecapacity,
            selectedData and selectedData.storagecapacity and ("+" .. selectedData.storagecapacity),
            ""
    )
end

function met.getTextWeaponsMissileturrets(hoveredData, selectedData)
    -- storage capacity
    met.addToOutput(ReadText(1001, 9063),
            "+" .. hoveredData.storagecapacity,
            selectedData and selectedData.storagecapacity and ("+" .. selectedData.storagecapacity),
            ""
    )

    -- rotation speed
    local printedrot = (hoveredData.rotation > 1 and hoveredData.rotation) or (hoveredData.rotation > 0.1 and Helper.round(hoveredData.rotation, 1)) or Helper.round(hoveredData.rotation, 2)
    local selectedprintedrot = selectedData and ((selectedData.rotation > 1 and selectedData.rotation) or (selectedData.rotation > 0.1 and Helper.round(selectedData.rotation, 1)) or Helper.round(selectedData.rotation, 2))
    met.addToOutput(ReadText(1001, 2419),
            printedrot,
            selectedprintedrot,
            ReadText(1001, 117)
    )

end

function met.formatRange(range)
    return (range > 10000) and (range / 1000) or Helper.round(range / 1000, (range > 1000) and 1 or 3)
end

function met.debugText(title, text)
    if (isDebug) then
        DebugError("met.lua: " .. title .. ": " .. tostring(text))
    end
end

init()

