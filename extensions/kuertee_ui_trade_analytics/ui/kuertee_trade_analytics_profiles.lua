local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
	UniverseID GetPlayerID(void);
]]

local ModLua = {}

StationBuySellProfiles = {}
function ModLua.init()
	-- factory: will buy from and sell to only the player's stations and construction projects.
	local text_empty = ""
	local text_disabled = ReadText(11201, 54)
	local text_auto = ReadText(11201, 55)
	local text_unrestricted = ReadText(11201, 56)
	local text_restricted = ReadText(11201, 57)
	StationBuySellProfiles.factory = {
		id = "factory",
		list_order = 1,
		name = ReadText(11201, 10),
		shortName = ReadText(11201, 20103),
		callToAction = ReadText(11201, 13),
		mouseOverText = string.format(ReadText(11201, 11), "100%", "0%"),
		summary = string.format(ReadText(11201, 12), "100%", text_restricted, "0%", text_restricted),
		buy = {
			isoffered = true,
			waretypes = {"resource", "intermediate", "trade"},
			price_factor = 1,
			trade_isrestricted = true,
		},
		sell = {
			isoffered = true,
			waretypes = {"intermediate", "product", "trade"},
			price_factor = 0,
			trade_isrestricted = true,
		}
	}
	-- distribution centre: will sell to factory with largest margin.
	-- i.e. to factory with best margin: buy factor - this sell factor
	-- to supply warehouse because: SW buy factor (0.4) - this sell factor (0) = 0.4
	-- OR to factory outlet because: FO buy factor (0.4) - this sell factor (0) = 0.4
	StationBuySellProfiles.distributioncentre = {
		id = "distributioncentre",
		list_order = 2,
		name = ReadText(11201, 20),
		shortName = ReadText(11201, 20104),
		callToAction = ReadText(11201, 23),
		mouseOverText = string.format(ReadText(11201, 21), "50%", "0%"),
		summary = string.format(ReadText(11201, 12), "50%", text_restricted, "0%", text_restricted),
		buy = {
			isoffered = true,
			waretypes = {"resource", "intermediate", "trade"},
			price_factor = 0.5,
			trade_isrestricted = true,
		},
		sell = {
			isoffered = true,
			waretypes = {"intermediate", "product", "trade"},
			price_factor = 0,
			trade_isrestricted = true,
		}
	}
	-- supply warehouse: will sell to factory with largest margin.
	-- i.e. to factory with best margin: buy factor - this sell factor
	-- to trading station because: TS buy factor is auto - this sell factor (0.5) = MAY BE A GOOD MARGIN
	-- OR to station projects and build projects because: their buy factor is 1 - this sell factor (0.5) = ALWAYS A GOOD MARGIN
	-- NOT to distribution centre because: DC buy factor (0.5) - this sell factor (0.6) = -0.1
	-- NOT to factory outlet because: FO buy factor (0.4) - this sell factor (0.6) = -0.2
	StationBuySellProfiles.supplywarehouse = {
		id = "supplywarehouse",
		list_order = 3,
		name = ReadText(11201, 30),
		shortName = ReadText(11201, 20105),
		callToAction = ReadText(11201, 33),
		mouseOverText = string.format(ReadText(11201, 31), "40%", "60%"),
		summary = string.format(ReadText(11201, 12), "40%", text_restricted, "60%", text_restricted),
		buy = {
			isoffered = true,
			waretypes = {"resource", "intermediate", "trade"},
			price_factor = 0.4,
			trade_isrestricted = true,
		},
		sell = {
			isoffered = true,
			waretypes = {"intermediate", "product", "trade"},
			price_factor = 0.6,
			trade_isrestricted = true,
		}
	}
	-- factory outlet: will sell to factory with largest margin.
	-- i.e. to factory with best margin: buy factor - this sell factor
	-- to trading station because: TS buy factor is auto - this sell factor (0.5) = MAY BE A GOOD MARGIN
	-- OR to station projects and build projects because: their buy factor is 1 - this sell factor is auto = MAY BE A GOOD MARGIN
	-- OR back to distribution centre because: DC buy factor (0.5) - this sell factor is auto = MAY BE A GOOD MARGIN
	-- OR back to supply warehouse because: SW buy factor (0.4) - this sell factor is auto = MAY BE A GOOD MARGIN
	StationBuySellProfiles.factoryoutlet = {
		id = "factoryoutlet",
		list_order = 4,
		name = ReadText(11201, 40),
		shortName = ReadText(11201, 20106),
		callToAction = ReadText(11201, 43),
		mouseOverText = string.format(ReadText(11201, 41), "40%", text_auto),
		summary = string.format(ReadText(11201, 12), "40%", text_restricted, text_auto, text_unrestricted),
		buy = {
			isoffered = true,
			waretypes = {"resource", "intermediate", "trade"},
			price_factor = 0.4,
			trade_isrestricted = true,
		},
		sell = {
			isoffered = true,
			waretypes = {"intermediate", "product", "trade"},
			price_factor = "auto",
			trade_isrestricted = false,
		}
	}
	-- trading station: all auto. kind-of base-game default.
	StationBuySellProfiles.tradingstation = {
		id = "tradingstation",
		list_order = 5,
		name = ReadText(11201, 50),
		shortName = ReadText(11201, 20107),
		callToAction = ReadText(11201, 53),
		mouseOverText = string.format(ReadText(11201, 51), text_auto, text_auto),
		summary = string.format(ReadText(11201, 12), text_auto, text_unrestricted, text_auto, text_unrestricted),
		buy = {
			isoffered = true,
			waretypes = {"resource", "intermediate", "trade"},
			price_factor = "auto",
			trade_isrestricted = false,
		},
		sell = {
			isoffered = true,
			waretypes = {"intermediate", "product", "trade"},
			price_factor = "auto",
			trade_isrestricted = false,
		}
	}
	-- custom profile
	-- notes:
	-- id must be the same as the table name. e.g.: for "StationBuySellProfiles.mycustomprofile1", its id must be "mycustomprofile1"
	--
	-- valid values
	-- isoffered = true|false
	-- waretypes = {"resource", "intermediate", "product", "trade"}
	-- notes:
	--     if "isoffered" == false, then offers will be removed only on applicable wares
	--     resource wares are always bought. i.e. there's no "remove buy offer" on resource wares.
	--     intermediate wares are always bought and sold. i.e. there's no "remove buy/sell offer" on intermediate wares.
	--     product wares are always sold. i.e. there's no "remove sell offer" on product wares.
	-- price_factor = "auto"|0.0 - 1.0
	-- trade_isrestriced = true|false
	--
	-- uncomment/enable the lines below to enable mycustomprofile1. copy them then edit the copy to suit to create new profiles
	-- StationBuySellProfiles.mycustomprofile1 = {
	-- 	id = "mycustomprofile1",
	-- 	list_order = 6,
	-- 	name = "my custom profile",
	-- 	callToAction = "Set with my custom profile",
	-- 	mouseOverText = string.format("Buy prices: 100%%. Sale prices: 100%%. My custom profile buys from X profile and sells to Y profile.", "100%%", "100%%"),
	-- 	summary = string.format("Buy: 100%%, unrestricted. Sell: 100%%, unrestricted.", "100%%", "100%%"),
	-- 	buy = {
	-- 		isoffered = true,
	-- 		waretypes = {"resource", "intermediate", "trade"},
	-- 		price_factor = 1.0,
	-- 		trade_isrestricted = false,
	-- 	},
	-- 	sell = {
	-- 		isoffered = true,
	-- 		waretypes = {"resource", "intermediate", "product", "trade"},
	-- 		price_factor = 1.0,
	-- 		trade_isrestricted = false,
	-- 	}
	-- }
	-- uncomment/enable the lines above to enable mycustomprofile1.

	local playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
	Helper.debugText("kuertee_trade_analytics_profiles init playerId", playerId)
	Helper.debugText("kuertee_trade_analytics_profiles init IsValidComponent(playerId)", IsValidComponent(playerId))
	if playerId and IsValidComponent(playerId) then
		SetNPCBlackboard(playerId, "$StationBuySellProfiles", StationBuySellProfiles)
	else
		Helper.addDelayedOneTimeCallbackOnUpdate(ModLua.init, false, getElapsedTime() + 1)
	end
end

ModLua.init()
