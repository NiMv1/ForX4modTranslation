local ffi = require("ffi")
local C = ffi.C

local ModLua = {}
local newFuncs = {}

local mapMenu

local MODULE_TYPES_CONFIG = {
  broken = {
    rank = 80,
    icon = "order_repair",
    color = Color["text_failure"]
  },
  hacked = {
    rank = 90,
    icon = "order_repair",
    color = Color["helpoverlay_border"]
  },
  toBuild = {
    rank = 100,
    icon = "order_repair",
    color = nil
  }
}

function ModLua.init()
  mapMenu = Helper.getMenu("MapMenu")
  mapMenu.registerCallback("getPropertyOwnedFleetDataInternal_addToFleetIcons", newFuncs.getPropertyOwnedFleetDataInternal_addToFleetIcons)
end

function newFuncs.getPropertyOwnedFleetDataInternal_addToFleetIcons(component, shiptyperanks, shiptypedata)
  if not IsComponentClass(component, "station") then
    return
  end

  local modulesData = mapMenu.getModuleData(ConvertStringTo64Bit(tostring(component)))

  local moduleCounts = {
    toBuild = 0,
    broken = 0,
    hacked = 0
  }

  for _, moduleType in pairs(modulesData) do
    for _, moduleEntry in pairs(moduleType) do
      local module = moduleEntry.module

      if type(module) == "string" then
        moduleCounts.toBuild = moduleCounts.toBuild + 1
      elseif IsComponentConstruction(module) then
        moduleCounts.toBuild = moduleCounts.toBuild + 1
      else
        local isfunctional, ishacked = GetComponentData(module, "isfunctional", "ishacked")

        if not isfunctional then
          if ishacked then
            moduleCounts.hacked = moduleCounts.hacked + 1
          else
            moduleCounts.broken = moduleCounts.broken + 1
          end
        end
      end
    end
  end

  -- Print moduleCounts 
  for field, config in pairs(MODULE_TYPES_CONFIG) do
    local count = moduleCounts[field]

    if count and count > 0 then
      if not shiptypedata[config.rank] then
        table.insert(shiptyperanks, config.rank)
        shiptypedata[config.rank] = {
          icon = config.icon,
          color = config.color,
          count = count
        }
      end
    end
  end
end

ModLua.init()
