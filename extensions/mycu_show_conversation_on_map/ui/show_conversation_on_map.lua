local ffi = require("ffi")
local C = ffi.C

local showConversationOnMap = {}
local mapMenu

---
--- Register mod callbacks and events
---
function showConversationOnMap.register()
    mapMenu = Helper.getMenu("MapMenu")

    RegisterEvent("showConversationOnMap", showConversationOnMap.execute)
end

---
--- Center the selected object on the map
---
function showConversationOnMap.execute(_, object)
    local component = ConvertIDTo64Bit(object)
    if IsValidComponent(component) then
        C.SetFocusMapComponent(mapMenu.holomap, component, true)
    end
end

showConversationOnMap.register()