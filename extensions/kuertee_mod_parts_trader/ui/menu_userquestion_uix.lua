local ffi = require("ffi")
local C = ffi.C

local ModLua = {}

local userQuestionMenu = nil
local playerInfoMenu = nil
local shipConfigurationMenu = nil
local oldFuncs = {}
local newFuncs = {}

function ModLua.init()
	userQuestionMenu = Helper.getMenu ("UserQuestionMenu")
	-- callbacks
	userQuestionMenu.registerCallback ("cleanup_end", newFuncs.cleanup_end)
	userQuestionMenu.registerCallback ("createInfoFrame_custom_frame_properties", newFuncs.createInfoFrame_custom_frame_properties)
	userQuestionMenu.registerCallback ("createTable_new_custom_table", newFuncs.createTable_new_custom_table)
end
function newFuncs.debugText (data1, data2, indent, isForced)
	local isDebug = false
	if isDebug == true or isForced == true then
		if indent == nil then
			indent = ""
		end
		if type (data1) == "table" then
			for i, value in pairs (data1) do
				DebugError (indent .. tostring (i) .. " (" .. type (i) .. ")" .. ReadText (1001, 120) .. " " .. tostring (value) .. " (" .. type (value) .. ")")
				if type (value) == "table" then
					newFuncs.debugText (value, nil, indent .. "    ", isForced)
				end
			end
		else
			DebugError (indent .. tostring (data1) .. " (" .. type (data1) .. ")")
		end
		if data2 then
			newFuncs.debugText (data2, nil, indent .. "    ", isForced)
		end
	end
end
function newFuncs.debugText_forced (data1, data2, indent)
	return newFuncs.debugText (data1, data2, indent, true)
end
local barterFrameProperties = {
	width = Helper.viewWidth * 0.5,
	height = Helper.viewHeight * 0.5,
	borderSize = 3 * Helper.borderSize
}
local barterTableProperties = {
	width = barterFrameProperties.width * 0.5,
	height = barterFrameProperties.height
}
local barterData
local barterMenu = {}
function newFuncs.cleanup_end ()
	barterData = nil
	barterMenu = {}
end
function newFuncs.createInfoFrame_custom_frame_properties (config)
	local menu = userQuestionMenu
	local frameProperties
	if menu.mode == "custom_barter" then
		if not barterData then
			newFuncs.playerId = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
			barterData = GetNPCBlackboard (newFuncs.playerId, "$kMPT_barterData")
			if not barterData.playerData.barterValue then
				barterData.playerData.barterValue = 0
			end
			if not barterData.storeData.barterValue then
				barterData.storeData.barterValue = 0
			end
			if barterData.playerData.isTradeForMoney == 0 then
				barterData.playerData.tradeForMoneyMult = 1
			end
			if barterData.storeData.isMoneyForTrade == 0 then
				barterData.storeData.moneyForTradeMult = 1
			end
			newFuncs.setSortedBarterInventories ()
		end
		newFuncs.config = config
		local width = barterFrameProperties.width + 3 * barterFrameProperties.borderSize
		local height = barterFrameProperties.height + 3 * barterFrameProperties.borderSize
		local x = (Helper.viewWidth - width) / 2
		local y = (Helper.viewHeight - height) / 2
		frameProperties = {
			standardButtons = {close = true},
			width = width,
			height = height,
			x = x,
			y = y,
			layer = config.layer,
			-- backgroundID = "solid",
			-- backgroundColor = Helper.color.semitransparent,
			startAnimation = false,
			playerControls = menu.mode == "markashostile"
		}
	end
	return frameProperties
end
function newFuncs.createTable_new_custom_table (frame)
	local menu = userQuestionMenu
	if menu.mode == "custom_barter" then
		local ftable = newFuncs.createBarterTables (frame)
		if barterMenu.playerFTable and barterMenu.playerRow then
			barterMenu.playerFTable:setSelectedRow (barterMenu.playerRow)
			barterMenu.playerRow = nil
		end
		if barterMenu.storeFTable and barterMenu.storeRow then
			barterMenu.storeFTable:setSelectedRow (barterMenu.storeRow)
			barterMenu.storeRow = nil
		end
		if barterMenu.confirmFTable and barterMenu.confirmRow then
			barterMenu.confirmFTable:setSelectedRow (barterMenu.confirmRow)
			barterMenu.confirmRow = nil
		end
		return ftable
	end
	return nil
end
function newFuncs.createBarterTables (frame)
	local menu = userQuestionMenu
	local tableProperties = {
		tabOrder = 1,
		borderEnabled = true,
		width = barterTableProperties.width,
		x = barterFrameProperties.borderSize,
		y = barterFrameProperties.borderSize
	}
	local playerBarterTable = newFuncs.renderBarterTable (frame, barterData.playerData, tableProperties, true)
	tableProperties = {
		tabOrder = 2,
		borderEnabled = true,
		width = barterTableProperties.width,
		x = barterFrameProperties.borderSize + barterTableProperties.width + barterFrameProperties.borderSize,
		y = barterFrameProperties.borderSize
	}
	local storeBarterTable = newFuncs.renderBarterTable (frame, barterData.storeData, tableProperties, false)
	newFuncs.updateValues (playerBarterTable, true)
	local y = barterFrameProperties.borderSize
	if playerBarterTable:getVisibleHeight () > storeBarterTable:getVisibleHeight () then
		y = playerBarterTable:getVisibleHeight ()
	else
		y = storeBarterTable:getVisibleHeight ()
	end
	tableProperties = {
		tabOrder = 3,
		borderEnabled = true,
		width = barterTableProperties.width * 2 + barterFrameProperties.borderSize,
		x = barterFrameProperties.borderSize,
		y = barterFrameProperties.borderSize + y + barterFrameProperties.borderSize
	}
	local confirmFTable = frame:addTable (5, tableProperties)
	barterMenu.confirmFTable = confirmFTable
	local row = confirmFTable:addRow (true, {bgColor = Helper.color.transparent})
	local barterNet_toPlayer = newFuncs.getBarterNet ()
	local isConfirmActive = false
	newFuncs.debugText ("kuertee_mod_parts_trader createBarterTables barterData.isTradeForMoney: " .. tostring (barterData.isTradeForMoney))
	newFuncs.debugText ("kuertee_mod_parts_trader createBarterTables barterData.tradeForMoneyMult: " .. tostring (barterData.tradeForMoneyMult))
	newFuncs.debugText ("kuertee_mod_parts_trader createBarterTables barterData.storeData.barterValue: " .. tostring (barterData.storeData.barterValue))
	local playerMoney = GetPlayerMoney ()
	if barterData.isTradeForMoney == 1 and barterData.isMoneyForTrade == 1 then
		if barterNet_toPlayer ~= 0 then
			if barterNet_toPlayer > 0 and barterData.storeData.money > barterNet_toPlayer then
				isConfirmActive = true
			elseif barterNet_toPlayer < 0 and playerMoney > barterNet_toPlayer * -1 then
				isConfirmActive = true
			end
		end
	elseif barterData.isTradeForMoney == 1 then
		isConfirmActive = barterNet_toPlayer > 0 and barterData.storeData.money > barterNet_toPlayer
	elseif barterData.isMoneyForTrade == 1 then
		isConfirmActive = barterNet_toPlayer < 0 and playerMoney > barterNet_toPlayer * -1
	else
		isConfirmActive = barterData.playerData.barterValue > barterData.storeData.barterValue
	end
	row [3]:createButton ({active = isConfirmActive}):setText ("Complete trade", {halign = "center"})
	row [3].handlers.onClick = function ()
		barterMenu.confirmRow = 1
		return newFuncs.completeBarter ()
	end
	return confirmFTable
end
function newFuncs.renderBarterTable (frame, traderData, tableProperties, isPlayer)
	local menu = userQuestionMenu
	local numCols = 4
	local width = barterTableProperties.width
	local height = barterTableProperties.height
	local x = barterFrameProperties.borderSize
	local y = barterFrameProperties.borderSize
	-- end: table properties
	ftable = frame:addTable (numCols, tableProperties)
	ftable:setColWidth (2, Helper.scaleY (Helper.standardTextHeight) * 5, false)
	ftable:setColWidth (3, Helper.scaleY (Helper.standardTextHeight) * 7, false)
	ftable:setColWidth (4, Helper.scaleY (Helper.standardTextHeight) * 5, false)
	-- ftable:setDefaultCellProperties ("text", {bgColor = Helper.color.transparent})
	-- title
	local row = ftable:addRow (true, {bgColor = Helper.defaultTitleBackgroundColor})
	if isPlayer then
		barterMenu.playerFTable = ftable
	else
		barterMenu.storeFTable = ftable
	end
	row [1]:setColSpan (4):createText (traderData.name, Helper.titleTextProperties)
	-- money
	row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	row [3]:createText (ReadText (1001, 6522), Helper.subHeaderTextProperties) -- money
	if isPlayer then
		row [4]:createText (ConvertMoneyString (GetPlayerMoney (), false, true, nil, true), {halign = "right"})
	else
		row [4]:createText (ConvertMoneyString (traderData.money, false, true, nil, true), {halign = "right"})
	end
	-- header
	row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	row [1]:createText (ReadText (11131620, 200), Helper.subHeaderTextProperties) -- part
	row [2]:createText (ReadText (11131620, 201), Helper.subHeaderTextProperties) -- part value
	row [3]:createText (ReadText (11131620, 202), Helper.subHeaderTextProperties) -- amount
	row [4]:createText (ReadText (11131620, 203), Helper.subHeaderTextProperties) -- barter value
	-- inventory rows
	local sliderProperties
	local item_barterAmount
	local item_barterValue
	local barterValue = 0
	local color
	for _, wareData in ipairs (traderData.inventory_sorted) do
		row = ftable:addRow (true, {bgColor = Helper.color.transparent})
		item_barterAmount = 0
		if isPlayer then
			barterData.playerData.inventory [wareData.id].row = row.index
			item_barterAmount = barterData.playerData.inventory [wareData.id].barterAmount
		else
			barterData.storeData.inventory [wareData.id].row = row.index
			item_barterAmount = barterData.storeData.inventory [wareData.id].barterAmount
		end
		if item_barterAmount > 0 then
			row [1]:createText (wareData.name, {color = Helper.color.green})
		else
			row [1]:createText (wareData.name)
		end
		sliderProperties = {
			min = 0, max = wareData.count, start = item_barterAmount
		}
		row [2]:createText (ConvertMoneyString (wareData.value, false, true, nil, true), {halign = "right"})
		row [3]:createSliderCell (sliderProperties)
		if isPlayer then
			row [3].handlers.onSliderCellChanged = function (_, value)
				barterMenu.playerRow = barterData.playerData.inventory [wareData.id].row
				barterData.playerData.inventory [wareData.id].barterAmount = value
				return
			end
		else
			row [3].handlers.onSliderCellChanged = function (_, value)
				barterMenu.storeRow = barterData.storeData.inventory [wareData.id].row
				barterData.storeData.inventory [wareData.id].barterAmount = value
				return
			end
		end
		row [3].handlers.onSliderCellConfirm = function ()
			menu.refresh = getElapsedTime ()
			return
		end
		item_barterValue = wareData.value * item_barterAmount
		barterValue = barterValue + item_barterValue
		row [4]:createText (ConvertMoneyString (item_barterValue, false, true, nil, true), {halign = "right"})
	end
	-- row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	-- row [3]:createText (ReadText (11131620, 204), Helper.subHeaderTextProperties) -- total value
	if isPlayer then
		barterData.playerData.barterValue = barterValue
	else
		barterData.storeData.barterValue = barterValue
	end
	-- if barterData.playerData.barterValue > 0 and barterData.storeData.barterValue > 0 then
	-- 	if barterData.playerData.barterValue > 0 and barterData.playerData.barterValue >= barterData.storeData.barterValue then
	-- 		row [4]:createText (ConvertMoneyString (barterValue, false, true, nil, true), {color = Helper.color.green, halign = "right"})
	-- 	else
	-- 		row [4]:createText (ConvertMoneyString (barterValue, false, true, nil, true), {color = Helper.color.red, halign = "right"})
	-- 	end
	-- else
	-- 	-- if barterData.isTradeForMoney == 1 and barterData.tradeForMoneyMult > 0 and barterData.storeData.barterValue == 0 then
	-- 	-- 	local barterValue_new = barterValue * barterData.tradeForMoneyMult
	-- 	-- 	row [4]:createText (ConvertMoneyString (barterValue_new, false, true, nil, true), {halign = "right"})
	-- 	-- else
	-- 	-- 	row [4]:createText (ConvertMoneyString (barterValue, false, true, nil, true), {halign = "right"})
	-- 	-- end
	-- 	row [4]:createText (ConvertMoneyString (barterValue, false, true, nil, true), {halign = "right"})
	-- end
	if isPlayer then
		-- don't do here because updateValues () for the player will be done AFTER both columns are updated
		-- this is because it needs to be updated AFTER interactions with the store data
		-- newFuncs.updateValues (ftable, isPlayer, barterValue) at createBarterTables
	else
		newFuncs.updateValues (ftable, isPlayer)
	end
	return ftable
end
-- <t id="200">Modification Part</t>
-- <t id="201">Value</t>
-- <t id="202">Amount</t>
-- <t id="203">Barter Value</t>
-- <t id="204">Total Value</t>
-- <t id="205">Money Value</t>
function newFuncs.getMoneyValue (isPlayer)
	local barterValue = 0
	if isPlayer then
		barterValue = barterData.playerData.barterValue
		if barterData.isTradeForMoney == 1 and barterData.isMoneyForTrade == 1 then
			barterValue = barterValue * barterData.tradeForMoneyMult
		elseif barterData.isTradeForMoney == 1 then
			barterValue = barterValue * barterData.tradeForMoneyMult
		elseif barterData.isMoneyForTrade == 1 then
			barterValue = barterValue * 1
		end
	else
		barterValue = barterData.storeData.barterValue
		if barterData.isMoneyForTrade == 1 and barterData.isMoneyForTrade == 1 then
			barterValue = barterValue * barterData.moneyForTradeMult
		elseif barterData.isTradeForMoney == 1 then
			barterValue = barterValue * 1
		elseif barterData.isMoneyForTrade == 1 then
			barterValue = barterValue * barterData.moneyForTradeMult
		end
	end
	return barterValue
end
function newFuncs.getBarterNet ()
	local barterNet_toPlayer = 0
	if barterData.playerData.barterValue ~= 0 or barterData.storeData.barterValue ~= 0 then
		local playerMoney = 0
		if barterData.isMoneyForTrade == 1 then
			playerMoney = GetPlayerMoney ()
		end
		barterNet_toPlayer = barterData.playerData.barterValue - barterData.storeData.barterValue
		if barterNet_toPlayer > 0 then
			if barterData.isTradeForMoney then
				barterNet_toPlayer = barterNet_toPlayer * barterData.tradeForMoneyMult
			end
		elseif barterNet_toPlayer < 0 then
			if barterData.isMoneyForTrade then
				barterNet_toPlayer = barterNet_toPlayer * barterData.moneyForTradeMult
			end
		end
	end
	return barterNet_toPlayer
end
function newFuncs.updateValues (ftable, isPlayer)
	local totalValue = 0
	local color = Helper.color.white
	if barterData.playerData.barterValue > barterData.storeData.barterValue then
		color = Helper.color.green
	elseif barterData.playerData.barterValue < barterData.storeData.barterValue then
		color = Helper.color.red
	end
	if isPlayer then
		totalValue = barterData.playerData.barterValue
	else
		totalValue = barterData.storeData.barterValue
	end
	row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	row [3]:createText (ReadText (11131620, 204), Helper.subHeaderTextProperties) -- total value
	row [4]:createText (ConvertMoneyString (totalValue, false, true, nil, true), {color = color, halign = "right"})
	-- local moneyValue = newFuncs.getMoneyValue (isPlayer)
	-- row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	-- row [3]:createText (ReadText (11131620, 205), Helper.subHeaderTextProperties) -- money value
	-- row [4]:createText (ConvertMoneyString (moneyValue, false, true, nil, true), {color = color, halign = "right"})
	if barterData.isTradeForMoney == 1 or barterData.isMoneyForTrade == 1 then
		local barterNet_toPlayer = newFuncs.getBarterNet ()
		newFuncs.debugText ("barterNet_toPlayer", barterNet_toPlayer)
		local negOrPosMult = 1
		color = Helper.color.white
		if isPlayer == true then
			if barterNet_toPlayer < 0 then
				color = Helper.color.red
			elseif barterNet_toPlayer > 0 then
				color = Helper.color.green
			end
		else
			negOrPosMult = -1
			if barterNet_toPlayer > 0 then
				color = Helper.color.red
			elseif barterNet_toPlayer < 0 then
				color = Helper.color.green
			end
		end
		row = ftable:addRow (true, {bgColor = Helper.color.transparent})
		-- row [3]:createText ("Net", Helper.subHeaderTextProperties) -- Money Value
		row [3]:createText (ReadText (11131620, 205), Helper.subHeaderTextProperties) -- Money Value
		row [4]:createText (ConvertMoneyString (barterNet_toPlayer * negOrPosMult, false, true, nil, true), {color = color, halign = "right"})
	end
	return ftable
end
function newFuncs.setSortedBarterInventories ()
	newFuncs.playerId = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
	-- local barterData = GetNPCBlackboard (newFuncs.playerId, "$kMPT_barterData")
	local playerInventory = barterData.playerData.inventory
	local playerInventory_sorted = {}
	for wareId, wareData in pairs (playerInventory) do
		wareData.id = wareId
		wareData.start = 0
		wareData.barterAmount = 0
		table.insert (playerInventory_sorted, wareData)
	end
	table.sort (playerInventory_sorted, function (a, b)
		return a.name < b.name
	end)
	barterData.playerData.inventory_sorted = playerInventory_sorted
	local storeInventory = barterData.storeData.inventory
	local storeInventory_sorted = {}
	for wareId, wareData in pairs (storeInventory) do
		wareData.id = wareId
		wareData.start = 0
		wareData.barterAmount = 0
		table.insert (storeInventory_sorted, wareData)
	end
	table.sort (storeInventory_sorted, function (a, b)
		return a.name < b.name
	end)
	barterData.storeData.inventory_sorted = storeInventory_sorted
	-- return barterData
end
function newFuncs.completeBarter ()
	local menu = userQuestionMenu
	newFuncs.playerId = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
	SetNPCBlackboard (newFuncs.playerId, "$kMPT_barterData", barterData)
	AddUITriggeredEvent (menu.name, "kMPT_complete_barter")
	menu.onCloseElement ("close")
end

ModLua.init()
