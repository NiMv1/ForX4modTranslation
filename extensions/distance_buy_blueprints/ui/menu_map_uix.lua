local ffi = require("ffi")
local C = ffi.C

local ModLua = {}

local playerInfoMenu

function ModLua.init()
    playerInfoMenu = Helper.getMenu("PlayerInfoMenu")

    playerInfoMenu.registerCallback("createFactions_on_before_render_licences", CreateFactions_on_before_render_licences) 

    OverrideOnCloseElement()
end

function CreateFactions_on_before_render_licences(frame, tableProperties, factionId, infotable)
    local factionRepresentative = ConvertStringTo64Bit(tostring(C.GetFactionRepresentative(factionId)))

    row = infotable:addRow(true, { bgColor = Helper.color.transparent })

    CreateBlueprintOrLicenceButton(
        row[2], 
        ReadText(1001, 98), 
        "blueprint",
        factionRepresentative, 
        GetUIRelation(factionId)
    )
    CreateBlueprintOrLicenceButton(
        row[3], 
        ReadText(1001, 62), 
        "licence", 
        factionRepresentative, 
        GetUIRelation(factionId)
    )
end

function CreateBlueprintOrLicenceButton(row, text, mode, factionRepresentative, relation)
    local buttonActive = factionRepresentative ~= 0 and relation > -10
     
    row:createButton(
        { active = buttonActive }
    ):setText(text, { halign = "center" })

    row.handlers.onClick = function ()
        OpenBlueprintOrLicenceTraderMenu(factionRepresentative, mode)
    end
    
    row.properties.mouseOverText = GetHint(factionRepresentative, relation)
end

function OpenBlueprintOrLicenceTraderMenu(factionRepresentative, mode)
    Helper.closeMenuAndOpenNewMenu(
        playerInfoMenu, 
        "BlueprintOrLicenceTraderMenu", 
        { 0, 0, factionRepresentative, mode },
        false
    )
    playerInfoMenu.cleanup()
end

function GetHint(factionRepresentative, relation)
    if (factionRepresentative == 0) then
        return ReadText(9537903, 1)
    elseif (relation <= -10) then
        return ReadText(9537903, 2)
    else
        return ""
    end
end

-- Overriding OnCloseElement to be able to return to the previous menu
function OverrideOnCloseElement()
    local menu = Helper.getMenu("BlueprintOrLicenceTraderMenu")

    menu.onCloseElement = function(dueToClose)
        Helper.closeMenu(menu, dueToClose)
        menu.cleanup()
    end
end

ModLua.init()