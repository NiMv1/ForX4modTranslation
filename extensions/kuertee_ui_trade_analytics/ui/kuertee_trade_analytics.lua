local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
	const char* GetComponentClass(UniverseID componentid);
	const char* GetObjectIDCode(UniverseID objectid);
	float GetDistanceBetween(UniverseID component1id, UniverseID component2id);
	bool IsComponentClass(UniverseID componentid, const char* classname);
	float GetUIScaleFactor();
	bool GetDefaultOrder(Order* result, UniverseID controllableid);
	uint32_t GetNumAllTradeRules(void);
	uint32_t GetAllTradeRules(TradeRuleID* result, uint32_t resultlen);
	TradeRuleCounts GetTradeRuleInfoCounts(TradeRuleID id);
	TradeRuleCounts GetTradeRuleInfoCounts(TradeRuleID id);
	TradeRuleID CreateTradeRule(TradeRuleInfo info);
	int32_t GetContainerBuyLimit(UniverseID containerid, const char* wareid);
	void SetContainerTradeRule(UniverseID containerid, TradeRuleID id, const char* ruletype, const char* wareid, bool value);
	bool GetContainerWareIsBuyable(UniverseID containerid, const char* wareid);
	bool GetContainerWareIsSellable(UniverseID containerid, const char* wareid);
	int32_t GetContainerSellLimit(UniverseID containerid, const char* wareid);
	UniverseID GetPlayerID(void);
]]

local ModLua = {}
local mapMenu = nil
local transactionLogMenu = nil
local stationOverviewMenu = nil
local stationConfigurationMenu = nil
local oldFuncs = {}
local newFuncs = {
	isDebug_analytics = false,
	isDebug_profiles = false,
	noupdate_backup = Helper.transactionLogData and Helper.transactionLogData.noupdate or nil,
}

function ModLua.init()
	mapMenu = Helper.getMenu ("MapMenu")
	mapMenu.registerCallback ("createPropertyRow_on_set_locationtext", newFuncs.createPropertyRow_on_set_locationtext)
	mapMenu.registerCallback ("getPropertyOwnedFleetDataInternal_addToFleetIcons", newFuncs.getPropertyOwnedFleetDataInternal_addToFleetIcons)
	mapMenu.registerCallback ("utRenaming_infoChangeObjectName", newFuncs.utRenaming_infoChangeObjectName)
	mapMenu.registerCallback ("buttonRenameConfirm_onMultiRename_on_before_rename", newFuncs.buttonRenameConfirm_onMultiRename_on_before_rename)

	transactionLogMenu = Helper.getMenu ("TransactionLogMenu")
	transactionLogMenu.registerCallback ("createFrame_on_create_transaction_log", newFuncs.createFrame_on_create_transaction_log)
	transactionLogMenu.registerCallback ("cleanup", newFuncs.cleanup_transactionLogMenu)

	Helper.registerCallback ("createTransactionLog_set_graph_height", newFuncs.createTransactionLog_set_graph_height)
	Helper.registerCallback ("createLSOStorageNode_get_ware_name", newFuncs.createLSOStorageNode_get_ware_name)
	Helper.registerCallback("onExpandLSOStorageNode_list_incoming_trade", newFuncs.onExpandLSOStorageNode_list_incoming_trade)
	Helper.registerCallback("onCollapseLSOStorageNode", newFuncs.onCollapseLSOStorageNode)
	Helper.registerCallback("onExpandLSOStorageNode_pre_buy_offer_title", newFuncs.onExpandLSOStorageNode_pre_buy_offer_title)
	Helper.registerCallback("onExpandLSOStorageNode_pre_sell_offer_title", newFuncs.onExpandLSOStorageNode_pre_sell_offer_title)
	Helper.registerCallback("updateLSOStorageNode_pre_update_expanded_node", newFuncs.updateLSOStorageNode_pre_update_expanded_node)
	Helper.registerCallback("checkboxSetTradeRuleOverride_pre_update_expanded_node", newFuncs.checkboxSetTradeRuleOverride_pre_update_expanded_node)
	Helper.registerCallback("dropdownTradeRule_pre_update_expanded_node", newFuncs.dropdownTradeRule_pre_update_expanded_node)

	stationOverviewMenu = Helper.getMenu ("StationOverviewMenu")
	stationOverviewMenu.registerCallback("cleanup", newFuncs.cleanup_stationOverviewMenu)
	stationOverviewMenu.registerCallback("onShowMenu_start", newFuncs.onShowMenu_start)
	stationOverviewMenu.registerCallback("display_get_station_name_extras", newFuncs.display_get_station_name_extras)
	stationOverviewMenu.registerCallback("setupFlowchartData_pre_trade_wares_button", newFuncs.setupFlowchartData_pre_trade_wares_button)
	stationOverviewMenu.registerCallback("onExpandTradeWares_insert_ware_to_allwares", newFuncs.onExpandTradeWares_insert_ware_to_allwares)
	stationOverviewMenu.registerCallback("updateExpandedNode_at_start", newFuncs.updateExpandedNode_at_start)
	stationOverviewMenu.registerCallback("updateExpandedNode_at_end", newFuncs.updateExpandedNode_at_end)

	stationConfigurationMenu = Helper.getMenu ("StationConfigurationMenu")
	stationConfigurationMenu.registerCallback("cleanup", newFuncs.cleanup_stationConfigurationMenu)
	stationConfigurationMenu.registerCallback("displayPlan_getWareName", newFuncs.displayPlan_getWareName)
	stationConfigurationMenu.registerCallback("displayPlan_render_incoming_ware", newFuncs.displayPlan_render_incoming_ware)

	-- md events
	RegisterEvent ("kTAnalytics_uiData_loaded", newFuncs.kTAnalytics_uiData_loaded)
	RegisterEvent ("kTAnalytics_set_profile", newFuncs.kTAnalytics_set_profile)
end
function newFuncs.createPropertyRow_on_set_locationtext (locationtext, component)
	local menu = mapMenu
	local convertedComponent = ConvertStringTo64Bit (tostring (component))
	local destination_final = nil
	if IsComponentClass (component, "ship") then
		local buf = ffi.new ("Order")
		if C.GetDefaultOrder (buf, convertedComponent) then
			local destinations = {}
			Helper.ffiVLA (destinations, "UniverseID", C.GetNumOrderLocationData, C.GetOrderLocationData, convertedComponent, 0, true)
			if #destinations > 0 then
				for _, destination in pairs (destinations) do
					newFuncs.debugText_analytics("createPropertyRow_on_set_locationtext IsComponentClass sector: " .. tostring (C.IsComponentClass (destination, "sector")))
					if C.IsComponentClass (destination, "sector") then
						destination_final = ffi.string (C.GetComponentName (destination))
						newFuncs.debugText_analytics("destination_final: " .. tostring (destination_final))
					elseif C.IsComponentClass (destination, "ship") or C.IsComponentClass (destination, "station") then
						destination_final = GetComponentData (ConvertStringTo64Bit (tostring (destination)), "sector")
					end
				end
			end
		end
		if destination_final and locationtext ~= destination_final then
			locationtext = locationtext .. " (" .. tostring (destination_final) .. ")"
		end
	end
	return {locationtext = locationtext}
end
function newFuncs.getPropertyOwnedFleetDataInternal_addToFleetIcons (component, shiptyperanks, shiptypedata)
	local purpose = GetComponentData (component, "primarypurpose")
	if IsComponentClass (component, "ship") and purpose ~= "fight" and purpose ~= "auxiliary" then
		local shiptyperank_idlers = 60
		if not shiptypedata [shiptyperank_idlers] then
			table.insert (shiptyperanks, shiptyperank_idlers)
			shiptypedata [shiptyperank_idlers] = {icon = "order_wait", count = 0}
		end
		local numOrders = C.GetNumOrders (ConvertStringTo64Bit (tostring (component)))
		newFuncs.debugText_analytics("getPropertyOwnedFleetDataInternal_addToFleetIcons numOrders: " .. tostring (numOrders))
		if numOrders == 0 then
			shiptypedata [shiptyperank_idlers].count = shiptypedata [shiptyperank_idlers].count + 1
			newFuncs.debugText_analytics("count: " .. tostring (shiptypedata [shiptyperank_idlers].count))
		end
	end
	local shiptyperank_away = 70
	local kuertee_sector = GetComponentData (ConvertStringTo64Bit (tostring (component)), "sector")
	if not shiptypedata [shiptyperank_away] then
		table.insert (shiptyperanks, shiptyperank_away)
		-- shiptypedata [shiptyperank_away] = {icon = "order_movegeneric", count = 0, sector = kuertee_sector}
		shiptypedata [shiptyperank_away] = {icon = "missiontype_follow", count = 0, sector = kuertee_sector}
	elseif kuertee_sector ~= shiptypedata [shiptyperank_away].sector then
		shiptypedata [shiptyperank_away].count = shiptypedata [shiptyperank_away].count + 1
	end
end
function newFuncs.kTAnalytics_uiData_loaded ()
	if transactionLogMenu and transactionLogMenu.infoFrame then
		newFuncs.player64Bit = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
		newFuncs.kTAnalytics_uiData = GetNPCBlackboard (newFuncs.player64Bit, "$kTAnalytics_uiData")
		transactionLogMenu.createFrame()
	end
end
newFuncs.traderId = nil
newFuncs.sortBy = nil
newFuncs.isSortAsc = nil
newFuncs.kTAnalytics_uiData = nil
__userdata_kuertee_TAnalytics = __userdata_kuertee_TAnalytics or {}
-- __userdata_kuertee_TAnalytics.activeTab = {}
-- __userdata_kuertee_TAnalytics.activeMode = {}
-- __userdata_kuertee_TAnalytics.activeTimeOption = {}
-- __userdata_kuertee_TAnalytics.activeFactionFilter = {}
function newFuncs.cleanup_transactionLogMenu()
	newFuncs.traderId = nil
	newFuncs.kTAnalytics_uiData = nil
	debug_isTableGraphPropertiesLogged = nil
	Helper.transactionLogData.noupdate = newFuncs.noupdate_backup
end
-- <t id="1001">Mining</t>
-- <t id="1002">Purchases</t>
-- <t id="1003">Sales</t>
-- <t id="1019">Repairs</t>
newFuncs.actionTextIdsById = {
	mining = 1001,
	purchases = 1002,
	sales = 1003,
	repairs = 1019
}
local colSpans = {2, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1}
local debug_last10Mins = {}
local debug_isTableGraphPropertiesLogged
function newFuncs.createFrame_on_create_transaction_log ()
	local menu = transactionLogMenu
	for i = 1, #menu.infoFrame.content do
		if menu.infoFrame.content [i].type == "table" then
			ftable = menu.infoFrame.content [i]
		end
	end
	local table_graph = ftable -- assume last table is always graph table
	if not debug_isTableGraphPropertiesLogged then
		debug_isTableGraphPropertiesLogged = true
		Helper.debugText_forced("createFrame_on_create_transaction_log table_graph", table_graph.properties)
		Helper.debugText_forced("table_graph:getVisibleHeight ()", table_graph:getVisibleHeight ())
		local y = table_graph.properties.y + table_graph:getVisibleHeight () + Helper.frameBorder
		Helper.debugText_forced("y", y)
	end
	local ftable = menu.infoFrame:addTable (#colSpans, {
		tabOrder = 4,
		width = table_graph.properties.width,
		x = table_graph.properties.x,
		y = table_graph.properties.y + table_graph:getVisibleHeight () + Helper.frameBorder
	})
	-- local rowHeight = Helper.scaleY (Helper.standardTextHeight)
	ftable:setDefaultCellProperties ("text", {minRowHeight = Helper.standardTextHeight})
	ftable:setDefaultCellProperties ("button", {height = Helper.standardTextHeight})
	ftable:setDefaultCellProperties ("dropdown", {height = Helper.standardTextHeight})
	ftable:setDefaultCellProperties ("icon", {height = Helper.standardTextHeight})
	newFuncs.traderId = ConvertStringToLuaID(tostring(menu.container))
	if newFuncs.kTAnalytics_uiData then
		newFuncs.noupdate_backup = Helper.transactionLogData.noupdate
		Helper.transactionLogData.noupdate = true
		local kTAnalytics_uiData = newFuncs.kTAnalytics_uiData
		newFuncs.debugText_analytics("tAnalytics kTAnalytics_uiData", tostring(kTAnalytics_uiData))
		local row = ftable:addRow (false, {fixed = true, bgColor = Helper.defaultTitleBackgroundColor})
		row [1]:setColSpan (#colSpans):createText (ReadText (11201, 101), Helper.titleTextProperties) -- trade analytics
		newFuncs.debugText_analytics("newFuncs.traderId", newFuncs.traderId)
		local tAnalytics
		local tradesByTraders = {}
		if IsValidComponent(newFuncs.traderId) then
			-- <t id="1001">Mining</t>
			-- <t id="1002">Purchases</t>
			-- <t id="1003">Sales</t>
			-- <t id="1004">From Other Factions</t>
			-- <t id="1005">From Own Faction</t>
			-- <t id="1006">From Any Faction</t>
			-- <t id="1007">To Other Factions</t>
			-- <t id="1008">To Own Faction</t>
			-- <t id="1009">To any Faction</t>
			-- <t id="1010">Filters:</t>
			-- <t id="1011">Purchases &#38; Sales</t>
			-- <t id="1012">Purchases, Sales &#38; Mining</t>
			-- <t id="1013">To/From Other Factions</t>
			-- <t id="1014">To/From Own Faction</t>
			-- <t id="1015">To/From Any Faction</t>
			-- <t id="1016">From %s(faction)</t>
			-- <t id="1017">To %s(faction)</t>
			-- <t id="1018">To/From %s(faction)</t>
			-- <t id="1019">Repairs</t>
			local factionFilters = {}
			table.insert (factionFilters, {id = 1004, text = ReadText (11201, 1004), icon = "", displayremoveoption = false}) -- with other factions
			table.insert (factionFilters, {id = 1005, text = ReadText (11201, 1005), icon = "", displayremoveoption = false}) -- with own factions
			table.insert (factionFilters, {id = 1006, text = ReadText (11201, 1006), icon = "", displayremoveoption = false}) -- with any factions
			if not __userdata_kuertee_TAnalytics.activeFactionFilter then
				__userdata_kuertee_TAnalytics.activeFactionFilter = factionFilters [3]
			end
			if not __userdata_kuertee_TAnalytics.actionsShown then
				__userdata_kuertee_TAnalytics.actionsShown = {
					mining = true,
					purchases = true,
					sales = true,
					repairs = true,
				}
			end
			local tabs = {}
			local icon_cross = "\27[widget_cross_01]\27X"
			local icon_tick = "\27[widget_tick_01]\27X"
			local actionIds = {"mining", "purchases", "sales", "repairs"}
			local actionsShown_count = 0
			local actionsShown_text = ""
			for _, actionId in ipairs(actionIds) do
				if __userdata_kuertee_TAnalytics.actionsShown[actionId] then
					actionsShown_count = actionsShown_count + 1
					actionsShown_text = actionsShown_text .. string.sub(ReadText (11201, newFuncs.actionTextIdsById[actionId]), 1, 1)
				end
			end
			if not actionsShown_count then
				actionsShown_text = ReadText (11201, 1020)
			else
				actionsShown_text = string.format (ReadText (11201, 1021), actionsShown_text)
			end
			table.insert (tabs, {id = "actionsShown", name = actionsShown_text})
			for _, actionId in ipairs(actionIds) do
				local actionName = (__userdata_kuertee_TAnalytics.actionsShown[actionId] and icon_tick or icon_cross) .. ReadText (11201, newFuncs.actionTextIdsById[actionId])
				table.insert (tabs, {id = actionId, name = actionName})
			end
			tAnalytics = newFuncs.copyTable(kTAnalytics_uiData)
			newFuncs.debugText_analytics("tAnalytics", tAnalytics)
			newFuncs.addEgosoftDataToAnalytics (tAnalytics, ConvertStringTo64Bit (tostring (newFuncs.traderId)))
			newFuncs.debugText_analytics("tAnalytics (post addEgosoftDataToAnalytics)", tAnalytics)
			-- if not tAnalytics then
			-- 	tAnalytics = {
			-- 		traderIdCode = ffi.string(C.GetObjectIDCode(ConvertStringTo64Bit(tostring(newFuncs.traderId)))),
			-- 		traderName = GetComponentData(newFuncs.traderId, "name"),
			-- 		miningByMiner = {},
			-- 		buysFromByTrader = {},
			-- 		salesToByTrader = {},
			-- 		repairsByShip = {},
			-- 	}
			-- end
			newFuncs.debugText_analytics("tAnalytics", tAnalytics)
			debug_last10Mins = {}
			local row_totals = ftable:addRow (true, {fixed = true, bgColor = Helper.color.transparent})
			local row_filters = ftable:addRow (true, {fixed = true, bgColor = Helper.color.transparent})
			row_filters [1]:setColSpan (colSpans [1]):createText (ReadText (11201, 1010)) -- filters
			local modes = {}
			table.insert (modes, {id = 2002, name = ReadText (11201, 2002)}) -- by wares
			table.insert (modes, {id = 2003, name = ReadText (11201, 2003)}) -- by trading ship
			if class == "ship" and __userdata_kuertee_TAnalytics.activeMode and __userdata_kuertee_TAnalytics.activeMode.id == 2003 then
				-- subject is ship and activeMode is by ship, so remove activeMode
				__userdata_kuertee_TAnalytics.activeMode = nil
			end
			if __userdata_kuertee_TAnalytics.activeMode == nil or (not next(__userdata_kuertee_TAnalytics.activeMode)) then
				__userdata_kuertee_TAnalytics.activeMode = modes [1]
			end
			-- <t id="4001">Ungrouped by time</t>
			-- <t id="4002">Group by hour</t>
			local timeOptions = {
				{id = 4001, name = ReadText(11201, 4001)},
				{id = 4002, name = ReadText(11201, 4002)},
			}
			if __userdata_kuertee_TAnalytics.activeTimeOption == nil or (not next(__userdata_kuertee_TAnalytics.activeTimeOption)) then
				__userdata_kuertee_TAnalytics.activeTimeOption = timeOptions [1]
			end
			local isOk = false
			local isPositive, isRepair
			local tradeDatas, wares, factions = {}, {}, {}
			if tAnalytics then
				if __userdata_kuertee_TAnalytics.actionsShown.purchases and tAnalytics.buysFromByTrader then
					isPositive = false -- purchases is negative
					tradeDatas = newFuncs.listify (tAnalytics.buysFromByTrader, isPositive, tradeDatas)
					isOk = true
				end
				if __userdata_kuertee_TAnalytics.actionsShown.sales and tAnalytics.salesToByTrader then
					isPositive = true -- sales is positive
					isRepair = false
					tradeDatas = newFuncs.listify (tAnalytics.salesToByTrader, isPositive, tradeDatas)
					isOk = true
				end
				if __userdata_kuertee_TAnalytics.actionsShown.mining and tAnalytics.miningByMiner then
					isPositive = true -- mining is positive
					isRepair = false
					tradeDatas = newFuncs.listify (tAnalytics.miningByMiner, isPositive, tradeDatas)
					isOk = true
				end
				if __userdata_kuertee_TAnalytics.actionsShown.repairs and tAnalytics.repairsByShip then
					isPositive = true -- repairs is positive
					isRepair = true
					tradeDatas = newFuncs.listify (tAnalytics.repairsByShip, isPositive, tradeDatas, isRepair)
					isOk = true
				end
				newFuncs.debugText_analytics("time: " .. tostring(time))
				wares, factions, hasValidEntries = newFuncs.renderAnalytics (tradeDatas, ftable, true, row_totals)
			end
			local row_modes, col_modes = newFuncs.renderFilters (tabs, ftable, factionFilters, row_filters, factions)
			local row_timeOptions, col_timeOptions = newFuncs.renderModes (ftable, row_modes, col_modes, modes, wares)
			newFuncs.renderTimeOptions(ftable, row_timeOptions, col_timeOptions, timeOptions)
			if not hasValidEntries then
				local row = ftable:addRow (false, {bgColor = Helper.color.transparent})
				row [1]:setColSpan (#colSpans):createText (ReadText (11201, 10004)) -- <t id="10004">There are no trades for this category.</t>
				-- row [1]:setColSpan (#colSpans):createText (ReadText (11201, 10005)) -- there are no analytics for this trader (yet)
			end
		end
	else
		AddUITriggeredEvent("kTAnalytic_ui_trigger", "uiData_request", newFuncs.traderId)
		local row = ftable:addRow (false, {bgColor = Helper.color.transparent})
		row [1]:setColSpan (#colSpans):createText (ReadText (11201, 10003)) -- loading trade analytics ...
	end
	newFuncs.debugText_analytics("debug_last10Mins", debug_last10Mins)
end
function newFuncs.listify (tradeDatas, isPositive, list_current, isRepair)
	local list = list_current
	if list == nil then
		list = {}
	end
	local sign, sign_reversed = -1, 1
	if isPositive then
		sign, sign_reversed = 1, -1
	end
	for trader, tradeData in pairs (tradeDatas) do
		tradeData.trader = trader
		tradeData.sign = sign
		tradeData.sign_reversed = sign_reversed
		tradeData.isRepair = isRepair
		table.insert (list, tradeData)
	end
	return list
end
function newFuncs.copyTable (table)
	local newTable = {}
	if type(table) == "table" then
		for key, data in pairs (table) do
			if type (data) == "table" then
				newTable [tostring (key)] = newFuncs.copyTable (data)
			else
				newTable [tostring (key)] = data
			end
		end
	end
	return newTable
end
function newFuncs.renderFilters (tabs, ftable, factionFilters, row, factions)
	local menu = transactionLogMenu
	local isTabActive, bgColor, purpose
	local col, colSpan = 1, 1
	-- if C.GetUIScaleFactor () > 1 then
	-- 	colSpan = 2
	-- end
	if row == nil then
		row = ftable:addRow (true, {fixed = true, bgColor = Helper.color.transparent})
		row [col]:setColSpan (colSpans [col]):createText (ReadText (11201, 1010)) -- filters
	end
	col = col + colSpans [col]
	for i, tab in ipairs (tabs) do
		tab.text = tab.name
		tab.icon = ""
		tab.displayremoveoption = false
	end
	row [col]:setColSpan (colSpans [col]):createDropDown (tabs, {startOption = "actionsShown"})
	row [col].handlers.onDropDownConfirmed = function (_, tabId)
		if tabId ~= "actionsShown" then
			__userdata_kuertee_TAnalytics.actionsShown[tabId] = not __userdata_kuertee_TAnalytics.actionsShown[tabId]
			menu.createFrame ()
		end
	end
	col = col + colSpans [col]
	-- render faction filters
	local textEntry
	factionFilters [1].text = ReadText (11201, 1013)
	factionFilters [2].text = ReadText (11201, 1014)
	factionFilters [3].text = ReadText (11201, 1015)
	textEntry = 1018
	if factions ~= nil and #factions then
		table.sort (factions, function (a, b)
			return a < b
		end)
		local factionName
		for i, faction in ipairs (factions) do
			if faction ~= "player" then
				factionName = GetFactionData (faction, "name")
				factionName = string.format (ReadText (11201, textEntry), factionName)
				table.insert (factionFilters, {id = 1007 + (i - 1), text = factionName, faction = faction, icon = "", displayremoveoption = false})
			end
		end
	end
	row [col]:setColSpan (colSpans [col]):createDropDown (factionFilters, {startOption = __userdata_kuertee_TAnalytics.activeFactionFilter.id})
	row [col].handlers.onDropDownConfirmed = function (_, factionFilterId)
		for _, factionFilter in ipairs (factionFilters) do
			if tostring (factionFilter.id) == tostring (factionFilterId) then
				__userdata_kuertee_TAnalytics.activeFactionFilter = factionFilter
				break
			end
		end
		menu.createFrame ()
	end
	col = col + colSpans [col]
	return row, col, colSpan
end
function newFuncs.renderModes (ftable, row, col, modes, wares)
	local colSpan = 1
	if wares ~= nil and #wares then
		table.sort (wares, function (a, b)
			local wareName_a = GetWareData (a, "name") or GetMacroData(a, "name")
			local wareName_b = GetWareData (b, "name") or GetMacroData(b, "name")
			return wareName_a < wareName_b
		end)
		local wareName
		for i, ware in ipairs (wares) do
			wareName = GetWareData (ware, "name")
			if not wareName then
				-- assume macro
				wareName = GetMacroData(ware, "name")
			end
			wareName = string.format (ReadText (11201, 2005), wareName)
			table.insert (modes, {id = 2005 + (i - 1), name = wareName, ware = ware}) -- by ware
		end
	end
	local menu = transactionLogMenu
	local isModeActive, bgColor
	for i, mode in ipairs (modes) do
		mode.text = mode.name
		mode.icon = ""
		mode.displayremoveoption = false
	end
	if __userdata_kuertee_TAnalytics.activeMode == nil then
		__userdata_kuertee_TAnalytics.activeMode = modes [1]
	end
	-- row [col]:setColSpan (colSpans [col]):createDropDown (modes, {startOption = __userdata_kuertee_TAnalytics.activeMode.id})
	row [col]:setColSpan (2):createDropDown (modes, {startOption = __userdata_kuertee_TAnalytics.activeMode.id})
	row [col].handlers.onDropDownConfirmed = function (_, modeId)
		for _, mode in ipairs (modes) do
			if tostring (mode.id) == tostring (modeId) then
				__userdata_kuertee_TAnalytics.activeMode = mode
				break
			end
		end
		menu.createFrame ()
	end
	col = col + 2
	return row, col, colSpan
end
function newFuncs.renderTimeOptions(ftable, row, col, timeOptions)
	local menu = transactionLogMenu
	for i, timeOption in ipairs (timeOptions) do
		timeOption.text = timeOption.name
		timeOption.icon = ""
		timeOption.displayremoveoption = false
	end
	if not __userdata_kuertee_TAnalytics.activeTimeOption then
		__userdata_kuertee_TAnalytics.activeTimeOption = timeOptions[1]
	end
	row[11]:setColSpan (2):createDropDown(timeOptions, {startOption = __userdata_kuertee_TAnalytics.activeTimeOption.id})
	row[11].handlers.onDropDownConfirmed = function(_, timeOptionId)
		for _, timeOption in ipairs(timeOptions) do
			if tostring(timeOption.id) == tostring(timeOptionId) then
				__userdata_kuertee_TAnalytics.activeTimeOption = timeOption
				break
			end
		end
		menu.createFrame ()
	end
end
function newFuncs.renderAnalytics (analytics, ftable, isRenderColumnHeadings, row_totals)
	local keys_count = 0
	for _, data in pairs (analytics) do
		keys_count = keys_count + 1
	end
	local menu = transactionLogMenu
	local row
	-- row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	-- row [1]:setColSpan (#colSpans):createText (__userdata_kuertee_TAnalytics.activeTab.name, Helper.headerRowCenteredProperties)
	local isOkToAdd, trader64Bit, traderName, sector64Bit, sectorName, amount, price, class, purpose, distance, distanceText, wareName, ship64Bit, shipName, traderName_formatted, faction
	-- local tradeDatas = {}
	local wareCountsByWare, tradingShipDeliveriesByShip = {}, {}
	local byTimeSegment = 60 * 60 -- by hour segments
	local tradeDatasByTimeSegment = {}
	local wareCountsByTimeSegmentByWare, tradingShipDeliveriesByTimeSegmentByShip = {}, {}
	local analyticsSubject_trader64Bit = ConvertStringTo64Bit (tostring (ConvertStringToLuaID (tostring (menu.container))))
	local analyticsSubject_sector64Bit = ConvertStringTo64Bit (tostring (GetComponentData (analyticsSubject_trader64Bit, "sectorid")))
	local sectorName = GetComponentData (analyticsSubject_sector64Bit, "name")
	local analyticsSubject_class = ffi.string (C.GetComponentClass (analyticsSubject_trader64Bit))
	if analyticsSubject_class == "ship_xs" or analyticsSubject_class == "ship_s" or analyticsSubject_class == "ship_m" or analyticsSubject_class == "ship_l" or analyticsSubject_class == "ship_xl" then
		analyticsSubject_class = "ship"
	end
	local analyticsSubject_purpose = GetComponentData(analyticsSubject_trader64Bit, "primarypurpose")
	if isRenderColumnHeadings then
		newFuncs.renderColumnNames (ftable, sectorName)
	end
	local trader, wares_inAnalytics, isAdded_ware, factions_inAnalytics, isAdded_faction = nil, {}, {}, {}, {}
	local time = C.GetCurrentGameTime()
	local isFactionTrader = false
	local hasValidEntries = false
	for _, tradeData in ipairs (analytics) do
		trader = tradeData.trader
		trader64Bit = ConvertStringTo64Bit (tostring (tradeData.trader))
		tradeData.isValidTrader = IsValidComponent (trader64Bit)
		if tradeData.isValidTrader then
			tradeData.traderName = GetComponentData(trader64Bit, "name")
			tradeData.traderIdCode = ffi.string(C.GetObjectIDCode(trader64Bit))
			tradeData.isPlayerOwned, tradeData.faction = GetComponentData (trader64Bit, "isplayerowned", "owner")
			tradeData.isSubordinateTrade = false
			tradeData.isSubordinateMine = false
			tradeData.isShipBuild = false
		else
			tradeData.isTraderAFaction = false
			local factionName = GetFactionData(tradeData.trader, "name")
			if factionName then
				tradeData.isTraderAFaction = true
			end
			if tradeData.isTraderAFaction then
				tradeData.traderName = factionName
				tradeData.traderIdCode = nil
				tradeData.isPlayerOwned = (tradeData.trader == "player")
				tradeData.faction = tradeData.trader
				tradeData.isSubordinateTrade = false
				tradeData.isSubordinateMine = false
				tradeData.isShipBuild = false
			else
				tradeData.traderName = nil
				tradeData.traderIdCode = nil
				tradeData.isPlayerOwned = false
				tradeData.faction = nil
				tradeData.isSubordinateTrade = false
				tradeData.isSubordinateMine = false
				tradeData.isShipBuild = false
			end
		end
		-- tradeData.count = tradeData.count * tradeData.sign
		if tradeData.faction ~= nil then
			if isAdded_faction [tradeData.faction] ~= true then
				isAdded_faction [tradeData.faction] = true
				table.insert (factions_inAnalytics, tradeData.faction)
			end
		end
		isOkToAdd = true
		if __userdata_kuertee_TAnalytics.activeFactionFilter.id == 1004 and tradeData.isPlayerOwned == true then
			isOkToAdd = false
		elseif __userdata_kuertee_TAnalytics.activeFactionFilter.id == 1005 and tradeData.isPlayerOwned ~= true then
			isOkToAdd = false
		elseif __userdata_kuertee_TAnalytics.activeFactionFilter.id > 1006 and tradeData.faction ~= __userdata_kuertee_TAnalytics.activeFactionFilter.faction then
			isOkToAdd = false
		end
		if isOkToAdd then
			if tradeData.traderName and tradeData.traderIdCode then
				traderName_formatted = tradeData.traderName .. " " .. tradeData.traderIdCode
			elseif tradeData.traderName then
				traderName_formatted = tradeData.traderName
			elseif not tradeData.isValidTrader then
				-- <t id="10002">no longer exists</t>
				traderName_formatted = traderName_formatted .. "(" .. ReadText (11201, 10002) .. ")"
			end
			class = nil
			sector64Bit = nil
			distance = 0
			distanceText = nil
			sectorName = nil
			if tradeData.isValidTrader then
				class = ffi.string (C.GetComponentClass (trader64Bit))
				if class == "ship_xs" or class == "ship_s" or class == "ship_m" or class == "ship_l" or class == "ship_xl" then
					class = "ship"
				end
				sector64Bit = ConvertStringTo64Bit (tostring (GetComponentData (trader64Bit, "sectorid")))
				if IsValidComponent (sector64Bit) then
					distance = C.GetDistanceBetween (trader64Bit, ConvertStringTo64Bit (tostring (newFuncs.traderId)))
					if distance > 0 then
						distanceText = math.floor (distance / 1000 * 100) / 100
						distanceText = tostring (distanceText) .. ReadText (1001, 108) --km
					end
					sectorName = GetComponentData (sector64Bit, "name")
					if distanceText then
						sectorName = string.format (ReadText (11201, 10001), distanceText, sectorName) -- distance (sectorName)
					end
				end
			end
			amount, price = 0, 0
			if __userdata_kuertee_TAnalytics.activeMode.id == 2001 or __userdata_kuertee_TAnalytics.activeMode.id == 2002 or __userdata_kuertee_TAnalytics.activeMode.id >= 2005 then
				-- by wares or macro
				local tradeDataList
				tradeDataList = tradeData.tradesByWare
				for ware, wareTradeData in pairs (tradeDataList) do
					if __userdata_kuertee_TAnalytics.activeMode.id < 2005 or __userdata_kuertee_TAnalytics.activeMode.ware == ware then
						if not wareTradeData.time then
							wareTradeData.time = 0
						end
						local tradeDataByWare = {
							isTraderAFaction = tradeData.isTraderAFaction,
							isValidTrader = tradeData.isValidTrader,
							isPlayerOwned = tradeData.isPlayerOwned,
							trader = tradeData.trader,
							traderIdCode = tradeData.traderIdCode,
							traderName = tradeData.traderName,
							traderName_formatted = traderName_formatted,
							class = class,
							faction = tradeData.faction,
							sectorName = sectorName,
							gateDistance = distance,
							ware = ware,
							count = wareTradeData.count,
							amount = wareTradeData.amount,
							price = wareTradeData.price * tradeData.sign,
							apc = math.floor (wareTradeData.amount / wareTradeData.count * 100) / 100,
							ppc = math.floor (wareTradeData.price * tradeData.sign / wareTradeData.count * 100) / 100,
							time = wareTradeData.time,
							isRepair = tradeData.isRepair,
							isSubordinateTrade = tradeData.isSubordinateTrade,
							isSubordinateMine = tradeData.isSubordinateMine,
							isShipBuild = tradeData.isShipBuild,
							isFreeTransaction = false,
						}
						if wareTradeData.ship then
							local ship = ConvertStringTo64Bit (tostring (wareTradeData.ship))
							local commander = newFuncs.getTopLevelCommander(ship)
							tradeDataByWare.isSubordinateTrade = IsSameComponent(commander, menu.container)
							local purpose = GetComponentData(ship, "primarypurpose")
							tradeDataByWare.isSubordinateMine = tradeDataByWare.isSubordinateTrade and purpose == "mine"
						end
						tradeDataByWare.isFreeTransaction = tradeDataByWare.isSubordinateMine
						if time - tradeDataByWare.time < 10 * 60 then
							table.insert(debug_last10Mins, tradeDataByWare)
						end
						if wareCountsByWare [ware] == nil then
							wareCountsByWare [ware] = 0
						end
						wareCountsByWare [ware] = wareCountsByWare [ware] + wareTradeData.amount * tradeData.sign_reversed
						-- by time segment
						local tradeTimeSegment = 0
						if __userdata_kuertee_TAnalytics.activeTimeOption.id == 4002 then
							-- <t id="4002">Group by hour</t>
							tradeTimeSegment = math.floor((time - tradeDataByWare.time) / byTimeSegment)
						end
						if not tradeDatasByTimeSegment[tradeTimeSegment] then
							tradeDatasByTimeSegment[tradeTimeSegment] = {}
						end
						table.insert(tradeDatasByTimeSegment[tradeTimeSegment], tradeDataByWare)
						if not wareCountsByTimeSegmentByWare[tradeTimeSegment] then
							wareCountsByTimeSegmentByWare[tradeTimeSegment] = {}
						end
						if not wareCountsByTimeSegmentByWare[tradeTimeSegment][ware] then
							wareCountsByTimeSegmentByWare[tradeTimeSegment][ware] = 0
						end
						wareCountsByTimeSegmentByWare [tradeTimeSegment][ware] = wareCountsByTimeSegmentByWare [tradeTimeSegment][ware] + wareTradeData.amount * tradeData.sign_reversed
					end
					if isAdded_ware [ware] ~= true then
						table.insert (wares_inAnalytics, ware)
						isAdded_ware [ware] = true
					end
				end
			elseif __userdata_kuertee_TAnalytics.activeMode.id == 2003 then
				-- by trading ship
				local tradeDataList
				tradeDataList = tradeData.tradesByShip
				for ship, shipTradeData in pairs (tradeDataList) do
					ship64Bit = ConvertStringTo64Bit (tostring (ship))
					local isValidShip = IsValidComponent(ship64Bit)
					if isValidShip then
						shipName = GetComponentData(ship64Bit, "name")
						local shipIdCode = ffi.string(C.GetObjectIDCode(ship64Bit))
						-- shipName = shipTradeData.shipName .. " (" .. shipTradeData.shipIdCode .. ")"
						if shipIdCode then
							shipName = shipName .. " " .. shipIdCode
						else
							shipName = shipName
						end
						if (not distance) or distance <= 0 then
							sector64Bit = ConvertStringTo64Bit (tostring (GetComponentData (ship64Bit, "sectorid")))
							if IsValidComponent (sector64Bit) then
								distance = C.GetDistanceBetween (ship64Bit, ConvertStringTo64Bit (tostring (newFuncs.traderId)))
								if distance > 0 then
									distanceText = math.floor (distance / 1000 * 100) / 100
									distanceText = tostring (distanceText) .. ReadText (1001, 108) --km
								end
								sectorName = GetComponentData (sector64Bit, "name")
								if distanceText then
									sectorName = string.format (ReadText (11201, 10001), distanceText, sectorName) -- distance (sectorName)
								end
							end
						end
					else
						shipName = "(" .. ReadText (11201, 10002) .. ")" -- no longer exists
					end
					if not shipTradeData.time then
						shipTradeData.time = 0
					end
					local tradeDataByShip = {
						isTraderAFaction = tradeData.isTraderAFaction,
						isValidTrader = tradeData.isValidTrader,
						isPlayerOwned = tradeData.isPlayerOwned,
						trader = tradeData.trader,
						traderIdCode = tradeData.traderIdCode,
						traderName = tradeData.traderName,
						traderName_formatted = traderName_formatted,
						class = class,
						faction = tradeData.faction,
						sectorName = sectorName,
						gateDistance = distance,
						tradingShip64Bit = ship64Bit,
						tradingShipName = shipName,
						count = shipTradeData.count,
						amount = shipTradeData.amount,
						price = shipTradeData.price * tradeData.sign,
						apc = math.floor (shipTradeData.amount / shipTradeData.count * 100) / 100,
						ppc = math.floor (shipTradeData.price / shipTradeData.count * 100) / 100,
						time = shipTradeData.time,
						isRepair = tradeData.isRepair,
						isSubordinateTrade = tradeData.isSubordinateTrade,
						isSubordinateMine = tradeData.isSubordinateMine,
						isShipBuild = tradeData.isShipBuild,
						isFreeTransaction = false,
					}
					if shipTradeData.ship then
						local ship = ConvertStringTo64Bit (tostring (shipTradeData.ship))
						local commander = newFuncs.getTopLevelCommander(ship)
						tradeDataByShip.isSubordinateTrade = IsSameComponent(commander, menu.container)
						local purpose = GetComponentData(ship, "primarypurpose")
						tradeDataByShip.isSubordinateMine = tradeDataByShip.isSubordinateTrade and purpose == "mine"
					end
					tradeDataByShip.isFreeTransaction = tradeDataByShip.isSubordinateMine
					-- table.insert (tradeDatas, tradeDataByShip)
					if tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)] == nil then
						tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)] = 0
					end
					tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)] = tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)] + shipTradeData.amount * tradeData.sign_reversed
					-- by time segment
					local tradeTimeSegment = 0
					if __userdata_kuertee_TAnalytics.activeTimeOption.id == 4002 then
						-- <t id="4002">Group by hour</t>
						tradeTimeSegment = math.floor((time - tradeDataByShip.time) / byTimeSegment)
					end
					if not tradeDatasByTimeSegment[tradeTimeSegment] then
						tradeDatasByTimeSegment[tradeTimeSegment] = {}
					end
					table.insert(tradeDatasByTimeSegment[tradeTimeSegment], tradeDataByShip)
					if not tradingShipDeliveriesByTimeSegmentByShip[tradeTimeSegment] then
						tradingShipDeliveriesByTimeSegmentByShip[tradeTimeSegment] = {}
					end
					if not tradingShipDeliveriesByTimeSegmentByShip[tradeTimeSegment]["s" .. tostring (ship64Bit)] then
						tradingShipDeliveriesByTimeSegmentByShip[tradeTimeSegment]["s" .. tostring (ship64Bit)] = 0
					end
					tradingShipDeliveriesByTimeSegmentByShip [tradeTimeSegment]["s" .. tostring (ship64Bit)] = tradingShipDeliveriesByTimeSegmentByShip [tradeTimeSegment]["s" .. tostring (ship64Bit)] + shipTradeData.amount * tradeData.sign_reversed
				end
				-- get wares anyway
				local tradeDataList = tradeData.tradesByWare and tradeData.tradesByWare
				for ware, wareTradeData in pairs (tradeDataList) do
					if isAdded_ware [ware] ~= true then
						table.insert (wares_inAnalytics, ware)
						isAdded_ware [ware] = true
					end
				end
			end
		end
	end
	-- newFuncs.sortTradeDatas (tradeDatas, wareCountsByWare, tradingShipDeliveriesByShip)
	for timeSegment, tradeDataByTimeSegment in pairs(tradeDatasByTimeSegment) do
		newFuncs.sortTradeDatas (tradeDataByTimeSegment, wareCountsByTimeSegmentByWare[timeSegment], tradingShipDeliveriesByTimeSegmentByShip[timeSegment])
	end
	local color
	local count_total, amount_total, price_total, apc_total, ppc_total = 0, 0, 0, 0, 0
	-- local tradeDatas_toRender = tradeDatas
	local tradeDatas_toRender
	local isHasTradesToRender
	for timeSegment, tradeDatas_toRender in pairs(tradeDatasByTimeSegment) do
		if #tradeDatas_toRender > 0 then
			isHasTradesToRender = true
			break
		end
	end
	if isHasTradesToRender then
		row_totals [6]:setColSpan (colSpans [6]):createText (ReadText (11201, 3011), {halign = "right"}) -- totals
		local isFirstTimeSegmentRendered
		local timeSegments = {}
		for timeSegment, tradeDatas_toRender in pairs(tradeDatasByTimeSegment) do
			table.insert(timeSegments, timeSegment)
		end
		table.sort(timeSegments, function(a, b)
			return a < b
		end)
		for _, timeSegment in ipairs(timeSegments) do
			local tradeDatas_toRender = tradeDatasByTimeSegment[timeSegment]
			local count_total_byTimeSegment, amount_total_byTimeSegment, price_total_byTimeSegment, apc_total_byTimeSegment, ppc_total_byTimeSegment = 0, 0, 0, 0, 0
			if #tradeDatas_toRender > 0 then
				if isFirstTimeSegmentRendered then
					row = ftable:addRow (false, {bgColor = Helper.color.transparent})
					row[1]:createText("")
				end
				-- <t id="4001">Ungrouped by time</t>
				-- <t id="4002">Group by hour</t>
				-- <t id="4003">Up to an hour ago</t>
				-- <t id="4004">Between hours $FROM$ and $TO$ ago</t>
				local row_timeSegment
				if __userdata_kuertee_TAnalytics.activeTimeOption and __userdata_kuertee_TAnalytics.activeTimeOption.id == 4002 then
					local timeSegmentName
					if timeSegment == 0 then
						timeSegmentName = ReadText(11201, 4003)
					else
						timeSegmentName = ReadText(11201, 4004)
						timeSegmentName = string.gsub(timeSegmentName, "%$FROM%$", tostring(timeSegment))
						timeSegmentName = string.gsub(timeSegmentName, "%$TO%$", tostring(timeSegment))
					end
					row_timeSegment = ftable:addRow (false, {bgColor = Helper.color.transparent})
					row_timeSegment[1]:setColSpan(colSpans [1]):createText(timeSegmentName)
				end
				local icon_mine = "\27[order_miningplayer]\27X"
				local icon_trade = "\27[order_traderoutine]\27X"
				local icon_repair = "\27[order_repair]\27X"
				local icon_build = "\27[missiontype_build]\27X"
				hasValidEntries = true
				for _, tradeData in ipairs (tradeDatas_toRender) do
					sectorName = tradeData.sectorName
					class = tradeData.class
					row = ftable:addRow (true, {bgColor = Helper.color.transparent})
					if tradeData.isFreeTransaction == true or tradeData.price == 0 then
						color = Helper.color.white
					elseif tradeData.price > 0 then
						color = Helper.color.green
					else
						color = Helper.color.red
					end
					if not tradeData.isPlayerOwned then
						-- not player owned or in mining tab
						-- do not make trader column clickable because this shows the trader's transaction log, which it won't have
						-- row [1]:setColSpan (2):createText (traderName, {mouseOverText = traderName})
						row [1]:setColSpan (colSpans [1]):createButton ({active = false, mouseOverText = tradeData.traderName_formatted}):setText (tradeData.traderName_formatted)
					else
						row [1]:setColSpan (colSpans [1]):createButton ({active = tradeData.isValidTrader, mouseOverText = tradeData.traderName_formatted}):setText (tradeData.traderName_formatted)
						row [1].handlers.onClick = function ()
							if tradeData.isValidTrader then
								newFuncs.cleanup_transactionLogMenu()
								menu.container = ConvertStringTo64Bit(tostring (tradeData.trader))
								menu.createFrame ()
							end
						end
					end
					-- by wares or by trading ship
					if tradeData.gateDistance and tradeData.gateDistance > 0 then
						if tradeData.isPlayerOwned then
							row [3]:setColSpan (colSpans [3]):createButton ({active = true, mouseOverText = tradeData.traderName_formatted .. ", " .. sectorName}):setText (sectorName)
							local trader64Bit_this = ConvertStringTo64Bit (tostring (tradeData.trader))
							row [3].handlers.onClick = function ()
								if IsValidComponent (trader64Bit_this) then
									newFuncs.showOnMap (trader64Bit_this)
								end
							end
						else
							-- row [3]:createText (sectorName, {mouseOverText = sectorName})
							row [3]:setColSpan (colSpans [3]):createButton ({active = false, mouseOverText = tradeData.traderName_formatted .. ", " .. sectorName}):setText (sectorName)
						end
					end
					if __userdata_kuertee_TAnalytics.activeMode.id == 2001 or __userdata_kuertee_TAnalytics.activeMode.id == 2002 or __userdata_kuertee_TAnalytics.activeMode.id >= 2005 then
						-- by wares
						if tradeData.ware == 0 then
							wareName = ReadText (11201, 10007) -- unknown
						else
							wareName = GetWareData (tradeData.ware, "name")
							if not wareName then
								-- assume macro
								local ware_of_macro
								wareName, ware_of_macro = GetMacroData(tradeData.ware, "name", "ware")
								local isship = GetWareData(ware_of_macro, "isship")
								tradeData.isShipBuild = true
								tradeData.isFreeTransaction = tradeData.faction == GetComponentData(menu.container, "owner")
								if tradeData.isFreeTransaction then
									color = Helper.color.white
								end
							end
							if tradeData.isSubordinateMine then
								wareName = icon_mine .. wareName
							elseif tradeData.isSubordinateTrade then
								wareName = icon_trade .. wareName
							elseif tradeData.isRepair then
								wareName = icon_repair .. wareName
							elseif tradeData.isShipBuild then
								wareName = icon_build .. wareName
							end
						end
						if wareCountsByWare [tradeData.ware] then
							-- wareName = wareName .. " x " .. wareCountsByWare [tradeData.ware]
							wareName = string.format (ReadText (11201, 10008), wareName, wareCountsByWare [tradeData.ware]) -- X (total: Y)
						end
						-- row [5]:setColSpan (colSpans [5]):createText (wareName, {mouseOverText = wareName})
						row [5]:setColSpan (colSpans [5]):createText (wareName, {color = color})
					elseif __userdata_kuertee_TAnalytics.activeMode.id == 2003 then
						-- by trading ship
						ship64Bit = ConvertStringTo64Bit (tostring (tradeData.tradingShip64Bit))
						if IsValidComponent (ship64Bit) then
							shipName = tradeData.tradingShipName
							if tradeData.isSubordinateMine then
								shipName = icon_mine .. shipName
							elseif tradeData.isSubordinateTrade then
								shipName = icon_trade .. shipName
							elseif tradeData.isRepair then
								shipName = icon_repair .. shipName
							elseif tradeData.isShipBuild then
								wareName = icon_build .. shipName
							end
							if tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)] then
								shipName = string.format (ReadText (11201, 10008), shipName, tostring (tradingShipDeliveriesByShip ["s" .. tostring (ship64Bit)])) -- X (total: Y)
							end
							if GetComponentData (ship64Bit, "isplayerowned") then
								-- row [5]:setColSpan (colSpans [5]):createButton ({active = true, mouseOverText = shipName}):setText (shipName)
								row [5]:setColSpan (colSpans [5]):createButton ({active = true}):setText (shipName)
								local tradingShip64Bit_this = ConvertStringTo64Bit (tostring (ship64Bit))
								row [5].handlers.onClick = function ()
									if IsValidComponent (tradingShip64Bit_this) then
										-- menu.container = ConvertStringToLuaID (tostring (tradingShip64Bit_this))
										newFuncs.cleanup_transactionLogMenu()
										menu.container = tradingShip64Bit_this
										menu.createFrame ()
									end
								end
							else
								-- row [4]:createText (tradeData.tradingShipName, {mouseOverText = tradeData.tradingShipName})
								-- row [5]:setColSpan (colSpans [5]):createButton ({active = false, mouseOverText = shipName}):setText (shipName)
								row [5]:setColSpan (colSpans [5]):createButton ({active = false}):setText (shipName)
							end
						else
							-- row [4]:createText (tradeData.tradingShipName, {mouseOverText = tradeData.tradingShipName})
							-- row [5]:setColSpan (colSpans [5]):createButton ({active = false, mouseOverText = tradeData.tradingShipName}):setText (tradeData.tradingShipName)
							row [5]:setColSpan (colSpans [5]):createButton ({active = false}):setText (tradeData.tradingShipName)
						end
					end
					row [7]:setColSpan (colSpans [7]):createText (tostring (tradeData.count), {halign = "right"})
					row [8]:setColSpan (colSpans [8]):createText (tostring (tradeData.amount), {halign = "right"})
					row [10]:setColSpan (colSpans [10]):createText (tostring (tradeData.apc), {halign = "right"})
					if tradeData.isFreeTransaction then
						row [9]:setColSpan (colSpans [9]):createText ("(" .. tostring (ConvertMoneyString (math.floor (tradeData.price / 100), false, true, 0, true)) .. ")", {color = color, halign = "right"})
						row [11]:setColSpan (colSpans [11]):createText ("(" .. tostring (ConvertMoneyString (math.floor (tradeData.ppc / 100), false, true, 0, true)) .. ")", {color = color, halign = "right"})
					else
						row [9]:setColSpan (colSpans [9]):createText (tostring (ConvertMoneyString (math.floor (tradeData.price / 100), false, true, 0, true)), {color = color, halign = "right"})
						row [11]:setColSpan (colSpans [11]):createText (tostring (ConvertMoneyString (math.floor (tradeData.ppc / 100), false, true, 0, true)), {color = color, halign = "right"})
					end
					if tradeData.time then
						row [12]:setColSpan (colSpans [12]):createText (Helper.getPassedTime (tradeData.time), {color = color, halign = "right"})
					end
					count_total = count_total + tradeData.count
					amount_total = amount_total + tradeData.amount
					apc_total = apc_total + tradeData.apc
					count_total_byTimeSegment = count_total_byTimeSegment + tradeData.count
					amount_total_byTimeSegment = amount_total_byTimeSegment + tradeData.amount
					apc_total_byTimeSegment = apc_total_byTimeSegment + tradeData.apc
					if tradeData.isFreeTransaction ~= true then
						price_total = price_total + tradeData.price
						ppc_total = ppc_total + tradeData.ppc
						price_total_byTimeSegment = price_total_byTimeSegment + tradeData.price
						ppc_total_byTimeSegment = ppc_total_byTimeSegment + tradeData.ppc
					end
				end
				if __userdata_kuertee_TAnalytics.activeTimeOption and __userdata_kuertee_TAnalytics.activeTimeOption.id == 4002 then
					-- <t id="4005">Hour totals</t>
					row_timeSegment [5]:setColSpan (colSpans [5]):createText (ReadText(11201, 4005), {halign = "right"})
					row_timeSegment [7]:setColSpan (colSpans [7]):createText (tostring (count_total_byTimeSegment), {halign = "right"})
					row_timeSegment [8]:setColSpan (colSpans [8]):createText (tostring (amount_total_byTimeSegment), {halign = "right"})
					if price_total_byTimeSegment == 0 then
						color = Helper.color.white
					elseif price_total_byTimeSegment > 0 then
						color = Helper.color.green
					else
						color = Helper.color.red
					end
					row_timeSegment [9]:setColSpan (colSpans [9]):createText (tostring (ConvertMoneyString (math.floor (price_total_byTimeSegment / 100), false, true, 0, true)), {color = color, halign = "right"})
					row_timeSegment [10]:setColSpan (colSpans [10]):createText (tostring (apc_total_byTimeSegment), {halign = "right"})
					row_timeSegment [11]:setColSpan (colSpans [11]):createText (tostring (ConvertMoneyString (math.floor (ppc_total_byTimeSegment / 100), false, true, 0, true)), {color = color, halign = "right"})
				end
				isFirstTimeSegmentRendered = true
			end
		end
		row_totals [7]:setColSpan (colSpans [7]):createText (tostring (count_total), {halign = "right"})
		row_totals [8]:setColSpan (colSpans [8]):createText (tostring (amount_total), {halign = "right"})
		if price_total == 0 then
			color = Helper.color.white
		elseif price_total > 0 then
			color = Helper.color.green
		else
			color = Helper.color.red
		end
		row_totals [9]:setColSpan (colSpans [9]):createText (tostring (ConvertMoneyString (math.floor (price_total / 100), false, true, 0, true)), {color = color, halign = "right"})
		row_totals [10]:setColSpan (colSpans [10]):createText (tostring (apc_total), {halign = "right"})
		row_totals [11]:setColSpan (colSpans [11]):createText (tostring (ConvertMoneyString (math.floor (ppc_total / 100), false, true, 0, true)), {color = color, halign = "right"})
	-- else
	-- 	row = ftable:addRow (true, {bgColor = Helper.color.transparent})
	-- 	row [1]:setColSpan (#colSpans):createText (ReadText (11201, 10004)) -- no data for category
	end
	return wares_inAnalytics, factions_inAnalytics, hasValidEntries
end
function newFuncs.renderColumnNames (ftable, sectorName)
	local menu = transactionLogMenu
	local row = ftable:addRow (true, {fixed = true, bgColor = Helper.color.transparent})
	local columns = {}
	local isSortActive, bgColor
	table.insert (columns, {id = "name", name = ReadText (11201, 3001), colSpan = 2}) -- trading partner
	table.insert (columns, {id = "distance", name = string.format (ReadText (11201, 3002), sectorName)}) -- gate distance
	if __userdata_kuertee_TAnalytics.activeMode.id == 2001 or __userdata_kuertee_TAnalytics.activeMode.id == 2002 or __userdata_kuertee_TAnalytics.activeMode.id >= 2005 then
		-- by wares
		table.insert (columns, {id = "ware", name = ReadText (11201, 3008)}) -- ware
	elseif __userdata_kuertee_TAnalytics.activeMode.id == 2003 then
		-- by trading ship
		table.insert (columns, {id = "tradingShipName", name = ReadText (11201, 3010)}) -- trading ship
	end
	table.insert (columns, {id = "count", name = ReadText (11201, 3003)}) -- count
	table.insert (columns, {id = "amount", name = ReadText (11201, 3004)}) -- amount
	table.insert (columns, {id = "price", name = ReadText (11201, 3005)}) -- price
	table.insert (columns, {id = "apc", name = ReadText (11201, 3006)}) -- amount / count
	table.insert (columns, {id = "ppc", name = ReadText (11201, 3007)}) -- price / count
	table.insert (columns, {id = "time", name = ReadText (1001, 24)}) -- time
	local colSpan, nextCol = 1, 1
	local button
	local buttonheight = Helper.scaleY (Helper.standardTextHeight)

	for i, column in ipairs (columns) do
		if newFuncs.sortBy == nil and column.id == "time" then
			newFuncs.sortBy = column
			newFuncs.isSortAsc = false
		end
		if column.colSpan and column.colSpan > 0 then
			colSpan = column.colSpan
		else
			colSpan = 1
		end
		colSpan = colSpans [nextCol]
		-- if column.id == "distance" and __userdata_kuertee_TAnalytics.activeTab.id == 1001 then
		-- 	-- mining
		-- 	-- gate distance invalid, so just show sector
		-- 	row [nextCol]:setColSpan (colSpan):createText (ReadText (11201, 3009)) -- sector
		-- else
			isSortActive = column.id == (newFuncs.sortBy and newFuncs.sortBy.id)
			bgColor = Helper.defaultButtonBackgroundColor
			if isSortActive then
				bgColor = Helper.defaultButtonHighlightColor
			end
			-- if (column.id == "distance" and __userdata_kuertee_TAnalytics.activeMode.id ~= 2001) or C.GetUIScaleFactor () > 1 then
			-- 	button = row [nextCol]:setColSpan (colSpans [nextCol]):createButton ({scaling = true, active = true, bgColor = bgColor, mouseOverText = column.name}):setText (column.name, {scaling = true, halign = "center"})
			-- else
				button = row [nextCol]:setColSpan (colSpans [nextCol]):createButton ({scaling = true, active = true, bgColor = bgColor}):setText (column.name, {scaling = true, halign = "center"})
			-- end
			if isSortActive then
				local scale = C.GetUIScaleFactor ()
				if newFuncs.isSortAsc then
					button:setIcon ("table_arrow_inv_up", {scaling = false, width = buttonheight, height = buttonheight, x = button:getColSpanWidth () - buttonheight, y = 0})
				else
					button:setIcon ("table_arrow_inv_down", {scaling = false, width = buttonheight, height = buttonheight, x = button:getColSpanWidth () - buttonheight, y = 0})
				end
			end
			row [nextCol].handlers.onClick = function ()
				if column.id == newFuncs.sortBy.id then
					newFuncs.isSortAsc = not newFuncs.isSortAsc
				else
					newFuncs.sortBy = column
				end
				menu.createFrame ()
			end
		-- end
		nextCol = nextCol + colSpan
	end
end
newFuncs.sortSteps = {}
function newFuncs.sortTradeDatas (tradeDatas, wareCountsByWare, tradingShipDeliveriesByShip)
	-- remove sortby that's already in the list of steps
	local removeStepI
	for i, sortStep in ipairs (newFuncs.sortSteps) do
		if sortStep.id == newFuncs.sortBy.id then
			removeStepI = i
			break
		end
	end
	if removeStepI ~= nil then
		table.remove (newFuncs.sortSteps, removeStepI)
	end
	-- add sortby to first in list
	newFuncs.sortBy.isSortAsc = newFuncs.isSortAsc
	table.insert (newFuncs.sortSteps, 1, newFuncs.sortBy)
	if #newFuncs.sortSteps > 3 then
		-- ensure there's only 3 sort steps
		table.remove (newFuncs.sortSteps, 4)
	end
	local idAlts = {
		name = "traderName_formatted",
		distance = "gateDistance",
	}
	local additionalData = {
		ware = wareCountsByWare,
		tradingShipName = tradingShipDeliveriesByShip
	}
	function getOrderBySortId (sortId, a, b, isSortAsc)
		if (idAlts [sortId] ~= nil) then
			sortId = idAlts [sortId]
		end
		if additionalData [sortId] ~= nil and additionalData [sortId][a [sortId]] ~= additionalData [sortId][b [sortId]] then
			if isSortAsc then
				return additionalData [sortId][a [sortId]] < additionalData [sortId][b [sortId]]
			else
				return additionalData [sortId][a [sortId]] > additionalData [sortId][b [sortId]]
			end
		elseif a [sortId] ~= b [sortId] then
			if isSortAsc then
				return a [sortId] < b [sortId]
			else
				return a [sortId] > b [sortId]
			end
		end
		return nil
	end
	local stepResult
	table.sort (tradeDatas, function (a, b)
		for i, sortStep in ipairs (newFuncs.sortSteps) do
			stepResult = getOrderBySortId (sortStep.id, a, b, sortStep.isSortAsc)
			if stepResult ~= nil then
				return stepResult
			end
		end
	end)
end
function newFuncs.showOnMap (object64Bit)
	local menu = transactionLogMenu
	Helper.closeMenuAndOpenNewMenu (menu, "MapMenu", {0, 0, true, object64Bit})
	menu.cleanup ()
end
function newFuncs.addEgosoftDataToAnalytics (tAnalytics, container64Bit)
	newFuncs.debugText_analytics("addEgosoftDataToAnalytics")
	local containers = {}
	table.insert (containers, container64Bit)
	local subordinates = GetSubordinates (container64Bit)
	local subordinate64Bit
	for i = #subordinates, 1, -1 do
		subordinate64Bit = ConvertStringTo64Bit (tostring (subordinates [i]))
		if IsValidComponent (subordinate64Bit) then
			table.insert (containers, subordinate64Bit)
		end
	end
	local endtime = C.GetCurrentGameTime ()
	-- local starttime = math.max (0, endtime - 60 * Helper.transactionLogConfig.zoomSteps[Helper.transactionLogData.xZoom].zoom)
	local starttime = 0
	local trader64Bit, buyer64Bit, seller64Bit, ware, amount, price, eventType
	local traderIsPlayerOwned, buyerIsPlayerOwned, sellerIsPlayerOwned, purpose
	local traderCommander64Bit, buyerCommander64Bit, sellerCommander64Bit
	local debugCount, debugMax = 0, 20
	for _, container64Bit in ipairs (containers) do
		debugCount = 0
		purpose = GetComponentData (container64Bit, "primarypurpose")
		local n = C.GetNumTransactionLog (container64Bit, starttime, endtime)
		local buf = ffi.new ("TransactionLogEntry[?]", n)
		n = C.GetTransactionLog (buf, n, container64Bit, starttime, endtime)
		for i = 0, n - 1 do
			trader64Bit = ConvertStringTo64Bit (tostring (buf [i].partnerid))
			traderCommander64Bit = nil
			traderIsPlayerOwned = false
			buyer64Bit = ConvertStringTo64Bit (tostring (buf [i].buyerid))
			buyerCommander64Bit = nil
			buyerIsPlayerOwned = false
			seller64Bit = ConvertStringTo64Bit (tostring (buf [i].sellerid))
			sellerCommander64Bit = nil
			sellerIsPlayerOwned = false
			if IsValidComponent (trader64Bit) then
				traderIsPlayerOwned = GetComponentData (container64Bit, "isplayerowned")
				traderCommander64Bit = newFuncs.getTopLevelCommander (trader64Bit)
			end
			if IsValidComponent (buyer64Bit) then
				buyerIsPlayerOwned = GetComponentData (buyer64Bit, "isplayerowned")
				buyerCommander64Bit = newFuncs.getTopLevelCommander (buyer64Bit)
			end
			if IsValidComponent (seller64Bit) then
				sellerIsPlayerOwned = GetComponentData (seller64Bit, "isplayerowned")
				sellerCommander64Bit = newFuncs.getTopLevelCommander (seller64Bit)
			end
			if newFuncs.debugText_analytics and debugCount < debugMax then
				if (IsValidComponent (buyer64Bit) and IsValidComponent (seller64Bit)) or purpose == "mine" then
					debugCount = debugCount + 1
					newFuncs.debugText_analytics("    addEgosoftDataToAnalytics container64Bit: " .. tostring (container64Bit) .. " (" .. GetComponentData (container64Bit, "name") .. ")")
					if IsValidComponent (trader64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics trader64Bit: " .. tostring (trader64Bit) .. " (" .. GetComponentData (trader64Bit, "name") .. ")")
					end
					if IsValidComponent (traderCommander64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics traderCommander64Bit: " .. tostring (traderCommander64Bit) .. " (" .. GetComponentData (traderCommander64Bit, "name") .. ")")
					end
					if IsValidComponent (buyer64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics buyer64Bit: " .. tostring (buyer64Bit) .. " (" .. GetComponentData (buyer64Bit, "name") .. ")")
					end
					if IsValidComponent (buyerCommander64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics buyerCommander64Bit: " .. tostring (buyerCommander64Bit) .. " (" .. GetComponentData (buyerCommander64Bit, "name") .. ")")
					end
					if IsValidComponent (seller64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics seller64Bit: " .. tostring (seller64Bit) .. " (" .. GetComponentData (seller64Bit, "name") .. ")")
					end
					if IsValidComponent (sellerCommander64Bit) then
						newFuncs.debugText_analytics("        addEgosoftDataToAnalytics sellerCommander64Bit: " .. tostring (sellerCommander64Bit) .. " (" .. GetComponentData (sellerCommander64Bit, "name") .. ")")
					end
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics id: " .. Helper.getPassedTime (buf [i].time))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics buf[i].time: " .. tostring (tonumber (buf [i].time)) .. " " .. Helper.getPassedTime (buf [i].time))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics eventtype: " .. ffi.string (buf [i].eventtype))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics eventtypename: " .. ffi.string (buf [i].eventtypename))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics tradeeventtype: " .. ffi.string (buf [i].tradeeventtype))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics tradeeventtypename: " .. ffi.string (buf [i].tradeeventtypename))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics ware: " .. tostring(GetWareData (ffi.string (buf [i].ware), "name") or "unknown ware"))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics amount: " .. tostring (buf [i].amount))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics unit price (ct): " .. tostring (buf [i].price))
					newFuncs.debugText_analytics("        addEgosoftDataToAnalytics complete: " .. tostring (buf [i].complete))
				end
			end
			time = tonumber (buf [i].time)
			ware = ffi.string (buf [i].ware)
			amount = buf [i].amount
			price = math.floor (tonumber (buf [i].price) * 100) / 100
			eventType = ffi.string (buf [i].eventtype)
			if IsValidComponent (buyer64Bit) and IsValidComponent (seller64Bit) and eventType == "trade" then
				if buyerIsPlayerOwned then
					if IsValidComponent (sellerCommander64Bit) then
						newFuncs.addBuyData (tAnalytics, buyer64Bit, sellerCommander64Bit, ware, amount, price, trader64Bit, time)
					else
						newFuncs.addBuyData (tAnalytics, buyer64Bit, seller64Bit, ware, amount, price, trader64Bit, time)
					end
					if IsValidComponent (buyerCommander64Bit) then
						if IsValidComponent (sellerCommander64Bit) then
							newFuncs.addBuyData (tAnalytics, buyerCommander64Bit, sellerCommander64Bit, ware, amount, price, buyer64Bit, time)
						else
							newFuncs.addBuyData (tAnalytics, buyerCommander64Bit, seller64Bit, ware, amount, price, buyer64Bit, time)
						end
					end
				end
				if sellerIsPlayerOwned then
					if IsValidComponent (buyerCommander64Bit) then
						newFuncs.addSaleData (tAnalytics, seller64Bit, buyerCommander64Bit, ware, amount, price, trader64Bit, time)
					else
						newFuncs.addSaleData (tAnalytics, seller64Bit, buyer64Bit, ware, amount, price, trader64Bit, time)
					end
					if IsValidComponent (sellerCommander64Bit) then
						if IsValidComponent (buyerCommander64Bit) then
							newFuncs.addSaleData (tAnalytics, sellerCommander64Bit, buyerCommander64Bit, ware, amount, price, seller64Bit, time)
						else
							newFuncs.addSaleData (tAnalytics, sellerCommander64Bit, buyer64Bit, ware, amount, price, seller64Bit, time)
						end
					end
				end
			end
		end
	end
	return tAnalytics
end
function newFuncs.getTopLevelCommander (container64Bit)
	local commander_topLevel
	if IsValidComponent (container64Bit) and C.IsComponentClass (container64Bit, "controllable") then
		local commander = GetCommander (container64Bit)
		while IsValidComponent (commander) do
			commander_topLevel = ConvertStringTo64Bit (tostring (commander))
			commander = GetCommander (commander_topLevel)
		end
	end
	return commander_topLevel
end
function newFuncs.initAnalyticsEntry (data, trader64Bit)
	local traderI = tostring (ConvertStringToLuaID (trader64Bit))
	if data == nil then
		local traderIdCode, traderName
		if IsValidComponent (trader64Bit) then
			traderIdCode = ffi.string (C.GetObjectIDCode (trader64Bit))
			traderName = GetComponentData (trader64Bit, "name")
		end
		data = {
			traderIdCode = traderIdCode,
			traderName = traderName,
			miningByMiner = {},
			buysFromByTrader = {},
			salesToByTrader = {}
		}
	end
end
function newFuncs.addMiningData (data, trader64Bit, miner64Bit, ware, amount, price, time)
	local traderI = tostring (ConvertStringToLuaID (trader64Bit))
	local minerI = tostring (ConvertStringToLuaID (miner64Bit))
	newFuncs.initAnalyticsEntry (data, trader64Bit)
	local minerIdCode, minerName
	if IsValidComponent (miner64Bit) then
		minerIdCode = ffi.string (C.GetObjectIDCode (miner64Bit))
		minerName = GetComponentData (miner64Bit, "name")
	end
	if data.miningByMiner == nil then
		data.miningByMiner = {}
	end
	if data.miningByMiner [minerI] == nil then
		data.miningByMiner [minerI] = {
			traderIdCode = minerIdCode,
			traderName = minerName,
			count = 0,
			tradesByWare = {},
			tradesByShip = {}
		}
	end
	data.miningByMiner [minerI].count = data.miningByMiner [minerI].count + 1
	if data.miningByMiner [minerI].tradesByWare [ware] == nil then
		data.miningByMiner [minerI].tradesByWare [ware] = {count = 0, amount = 0, price = 0, time = 0}
	end
	data.miningByMiner [minerI].tradesByWare [ware].count = data.miningByMiner [minerI].tradesByWare [ware].count + 1
	data.miningByMiner [minerI].tradesByWare [ware].amount = data.miningByMiner [minerI].tradesByWare [ware].amount + amount
	data.miningByMiner [minerI].tradesByWare [ware].price = data.miningByMiner [minerI].tradesByWare [ware].price + (amount * price)
	if time > data.miningByMiner [minerI].tradesByWare [ware].time then
		data.miningByMiner [minerI].tradesByWare [ware].time = time
	end
end
function newFuncs.addBuyData (data, trader64Bit, trader_other64Bit, ware, amount, price, ship64Bit, time)
	local traderI = tostring (ConvertStringToLuaID (trader64Bit))
	local trader_otherI = tostring (ConvertStringToLuaID (trader_other64Bit))
	local shipI = tostring (ConvertStringToLuaID (ship64Bit))
	newFuncs.initAnalyticsEntry (data, trader64Bit)
	local traderIdCode, traderName, gateDistance
	if IsValidComponent (trader_other64Bit) then
		traderIdCode = ffi.string (C.GetObjectIDCode (trader_other64Bit))
		traderName = GetComponentData (trader_other64Bit, "name")
		gateDistance = C.GetDistanceBetween (trader64Bit, trader_other64Bit)
	end
	if data.buysFromByTrader == nil then
		data.buysFromByTrader = {}
	end
	if data.buysFromByTrader [trader_otherI] == nil then
		data.buysFromByTrader [trader_otherI] = {
			traderIdCode = traderIdCode,
			traderName = traderName,
			gateDistance = gateDistance,
			count = 0,
			tradesByWare = {},
			tradesByShip = {}
		}
	end
	data.buysFromByTrader [trader_otherI].count = data.buysFromByTrader [trader_otherI].count + 1
	if data.buysFromByTrader [trader_otherI].tradesByWare [ware] == nil then
		data.buysFromByTrader [trader_otherI].tradesByWare [ware] = {count = 0, amount = 0, price = 0, time = 0}
	end
	data.buysFromByTrader [trader_otherI].tradesByWare [ware].count = data.buysFromByTrader [trader_otherI].tradesByWare [ware].count + 1
	data.buysFromByTrader [trader_otherI].tradesByWare [ware].amount = data.buysFromByTrader [trader_otherI].tradesByWare [ware].amount + amount
	data.buysFromByTrader [trader_otherI].tradesByWare [ware].price = data.buysFromByTrader [trader_otherI].tradesByWare [ware].price + (amount * price)
	if time > data.buysFromByTrader [trader_otherI].tradesByWare [ware].time then
		data.buysFromByTrader [trader_otherI].tradesByWare [ware].time = time
	end
	if IsValidComponent (ship64Bit) then
		if data.buysFromByTrader [trader_otherI].tradesByShip [shipI] == nil then
			data.buysFromByTrader [trader_otherI].tradesByShip [shipI] = {count = 0, amount = 0, price = 0, time = 0}
		end
		data.buysFromByTrader [trader_otherI].tradesByShip [shipI].shipIdCode = ffi.string (C.GetObjectIDCode (ship64Bit))
		data.buysFromByTrader [trader_otherI].tradesByShip [shipI].shipName =  GetComponentData (ship64Bit, "name")
		data.buysFromByTrader [trader_otherI].tradesByShip [shipI].count = data.buysFromByTrader [trader_otherI].tradesByShip [shipI].count + 1
		data.buysFromByTrader [trader_otherI].tradesByShip [shipI].amount = data.buysFromByTrader [trader_otherI].tradesByShip [shipI].amount + amount
		data.buysFromByTrader [trader_otherI].tradesByShip [shipI].price = data.buysFromByTrader [trader_otherI].tradesByShip [shipI].price + (amount * price)
		if time > data.buysFromByTrader [trader_otherI].tradesByShip [shipI].time then
			data.buysFromByTrader [trader_otherI].tradesByShip [shipI].time = time
		end
	end
end
function newFuncs.addSaleData (data, trader64Bit, trader_other64Bit, ware, amount, price, ship64Bit, time)
	local traderI = tostring (ConvertStringToLuaID (trader64Bit))
	local trader_otherI = tostring (ConvertStringToLuaID (trader_other64Bit))
	local shipI = tostring (ConvertStringToLuaID (ship64Bit))
	newFuncs.initAnalyticsEntry (data, trader64Bit)
	local traderIdCode, traderName, gateDistance
	if IsValidComponent (trader_other64Bit) then
		traderIdCode = ffi.string (C.GetObjectIDCode (trader_other64Bit))
		traderName = GetComponentData (trader_other64Bit, "name")
		gateDistance = C.GetDistanceBetween (trader64Bit, trader_other64Bit)
	end
	if data.salesToByTrader == nil then
		data.salesToByTrader = {}
	end
	if data.salesToByTrader [trader_otherI] == nil then
		data.salesToByTrader [trader_otherI] = {
			traderIdCode = traderIdCode,
			traderName = traderName,
			gateDistance = gateDistance,
			count = 0,
			tradesByWare = {},
			tradesByShip = {},
		}
	end
	data.salesToByTrader [trader_otherI].count = data.salesToByTrader [trader_otherI].count + 1
	if data.salesToByTrader [trader_otherI].tradesByWare [ware] == nil then
		data.salesToByTrader [trader_otherI].tradesByWare [ware] = {count = 0, amount = 0, price = 0, time = 0}
	end
	data.salesToByTrader [trader_otherI].tradesByWare [ware].count = data.salesToByTrader [trader_otherI].tradesByWare [ware].count + 1
	data.salesToByTrader [trader_otherI].tradesByWare [ware].amount = data.salesToByTrader [trader_otherI].tradesByWare [ware].amount + amount
	data.salesToByTrader [trader_otherI].tradesByWare [ware].price = data.salesToByTrader [trader_otherI].tradesByWare [ware].price + (amount * price)
	if time > data.salesToByTrader [trader_otherI].tradesByWare [ware].time then
		data.salesToByTrader [trader_otherI].tradesByWare [ware].time = time
	end
	if IsValidComponent (ship64Bit) then
		if data.salesToByTrader [trader_otherI].tradesByShip [shipI] == nil then
			data.salesToByTrader [trader_otherI].tradesByShip [shipI] = {count = 0, amount = 0, price = 0, time = 0}
		end
		data.salesToByTrader [trader_otherI].tradesByShip [shipI].shipIdCode = ffi.string (C.GetObjectIDCode (ship64Bit))
		data.salesToByTrader [trader_otherI].tradesByShip [shipI].shipName =  GetComponentData (ship64Bit, "name")
		data.salesToByTrader [trader_otherI].tradesByShip [shipI].count = data.salesToByTrader [trader_otherI].tradesByShip [shipI].count + 1
		data.salesToByTrader [trader_otherI].tradesByShip [shipI].amount = data.salesToByTrader [trader_otherI].tradesByShip [shipI].amount + amount
		data.salesToByTrader [trader_otherI].tradesByShip [shipI].price = data.salesToByTrader [trader_otherI].tradesByShip [shipI].price + (amount * price)
		if time > data.salesToByTrader [trader_otherI].tradesByShip [shipI].time then
			data.salesToByTrader [trader_otherI].tradesByShip [shipI].time = time
		end
	end
end
newFuncs.productioncounts = nil
newFuncs.hasChanges = nil
newFuncs.matchedProfileId = nil
newFuncs.bestProfileId = nil
newFuncs.isIgnoreCollapseOnUpdateNode = nil
newFuncs.stationOverviewMenu_station = nil
newFuncs.bestProfileDataByWare = nil
function newFuncs.cleanup_stationOverviewMenu()
	newFuncs.productioncounts = nil
	newFuncs.hasChanges = nil
	newFuncs.matchedProfileId = nil
	newFuncs.bestProfileId = nil
	newFuncs.isIgnoreCollapseOnUpdateNode = nil
	newFuncs.stationOverviewMenu_station = nil
	newFuncs.bestProfileDataByWare = nil
end
function newFuncs.createTransactionLog_set_graph_height(tableProperties, width)
	return Helper.viewHeight * 0.5 - tableProperties.y - Helper.frameBorder - Helper.scaleY(Helper.standardTextHeight) - Helper.borderSize
end
function newFuncs.createLSOStorageNode_get_ware_name(ware)
	return newFuncs.getWareNameAndProductionCounts(ware)
end
function newFuncs.getWareNameAndProductionCounts(ware)
	local name = GetWareData(ware, "name")
	if not newFuncs.productioncounts then
		newFuncs.productioncounts = newFuncs.getPlayerProductionCounts()
	end
	local wareProfileName
	if newFuncs.productioncounts[ware] then
		local icon_factory = "\27[mapob_factory]\27X"
		if wareProfileName then
			name = name .. " (x" .. tostring(newFuncs.productioncounts[ware]) .. " " .. icon_factory .. ", " .. wareProfileName .. ")"
		else
			name = name .. " (x" .. tostring(newFuncs.productioncounts[ware]) .. " " .. icon_factory .. ")"
		end
	elseif wareProfileName then
		name = name .. " (" .. wareProfileName .. ")"
	end
	return name
end





--------------
-- profiles --
--------------
function newFuncs.onExpandLSOStorageNode_list_incoming_trade(row, name, reservation, isplayerowned)
	local menu = stationOverviewMenu
	-- kuertee start: clickable reservation traders
	-- if isplayerowned then
		row[1]:createButton({ mouseOverText = name }):setText(function () return Helper.getETAString(name, reservation.eta) end, { font = Helper.standardFontMono })
		row[1].handlers.onClick = function () return newFuncs.showOnMap(reservation.reserver) end
	-- else
	--  row[1]:createText(function () return Helper.getETAString(name, reservation.eta) end, { font = Helper.standardFontMono })
	-- end
	-- kuertee end: clickable reservation traders
end
function newFuncs.onCollapseLSOStorageNode(menu, nodedata)
	if newFuncs.isIgnoreCollapseOnUpdateNode ~= true then
		if newFuncs.hasChanges then
			newFuncs.hasChanges = false
			local menu = stationOverviewMenu
			newFuncs.setMatchedAndBestProfileBasedOnSettings(menu.container)
			menu.refresh = true
		end
	end
end
function newFuncs.updateExpandedNode_at_start(row, col)
	newFuncs.isIgnoreCollapseOnUpdateNode = true
end
function newFuncs.updateExpandedNode_at_end(row, col)
	newFuncs.isIgnoreCollapseOnUpdateNode = nil
	newFuncs.hasChanges = true
end
function newFuncs.getPlayerProductionCounts()
	local playerobjects = GetContainedObjectsByOwner("player")
	local productioncounts = {}
	local stationproducts
	for i = #playerobjects, 1, -1 do
		stationproducts = GetComponentData(playerobjects[i], "products")
		for _, product in ipairs(stationproducts) do
			if productioncounts[product] then
				productioncounts[product] = productioncounts[product] + 1
			else
				productioncounts[product] = 1
			end
		end
	end
	return productioncounts
end
function newFuncs.onShowMenu_start(station)
	Helper.debugText_forced("kuertee_trade_anaytics onShowMenu_start station", tostring(station))
	newFuncs.stationOverviewMenu_station = station
	newFuncs.setMatchedAndBestProfileBasedOnSettings(station)
end
function newFuncs.display_get_station_name_extras(station)
	newFuncs.getProfiles()
	if (not StationBuySellProfiles) or (not next(StationBuySellProfiles)) then
		return
	end
	local nameExtra
	newFuncs.setMatchedAndBestProfileBasedOnSettings(station)
	if newFuncs.matchedProfileId and newFuncs.matchedProfileId ~= "tradingstation" then
		nameExtra = StationBuySellProfiles[newFuncs.matchedProfileId].name
	elseif newFuncs.bestProfileId and newFuncs.bestProfileId ~= "tradingstation" then
		nameExtra = StationBuySellProfiles[newFuncs.bestProfileId].name .. "*"
	end
	local stationName = GetComponentData(station, "name")

	local utADR_editname = newFuncs.UTAdvancedRenaming_getEditName(station)
	local hasUTAdvancedRenamingShortcuts
	if utADR_editname then
		hasUTAdvancedRenamingShortcuts = string.find(utADR_editname, ReadText(11201, 20101)) or string.find(utADR_editname, ReadText(11201, 20102))
	end
	if not hasUTAdvancedRenamingShortcuts then
		return nameExtra
	else
		-- no need for nameExtra as ut advanced renaming will replace the shortcuts
		return nil
	end
end
newFuncs.node_setStationPresets = nil
function newFuncs.setupFlowchartData_pre_trade_wares_button(remainingcargonodes)
	local menu = stationOverviewMenu
	-- <t id="8">Station profiles</t>
	local buttonText = ReadText(11201, 8)
	-- start: having dynamic text here (i.e. the profile name) doesn't work
	-- search for: updateStationProfileText for possible reason
	-- if StationBuySellProfiles and newFuncs.matchedProfileId and StationBuySellProfiles[newFuncs.matchedProfileId] then
	-- 	buttonText = buttonText .. " (" .. StationBuySellProfiles[newFuncs.matchedProfileId].name .. ")"
	-- end
	-- end: having dynamic text here (i.e. the profile name) doesn't work
	newFuncs.node_setStationPresets = {
		cargo = true,
		text = buttonText,
		row = 1,
		col = 1,
		numrows = 1,
		numcols = 1,
		{
			properties = {
			},
			expandedFrameNumTables = 1,
			expandedTableNumColumns = 1,
			expandHandler = newFuncs.onExpandStationProfiles,
		}
	}
	table.insert(remainingcargonodes, newFuncs.node_setStationPresets)
end
function newFuncs.getProfiles()
	-- if (not StationBuySellProfiles) or (not next(StationBuySellProfiles)) then
	-- 	return
	-- end
	-- local menu = stationOverviewMenu
	-- for profileId, settings in pairs(StationBuySellProfiles) do
	-- 	local station = menu.container
	-- 	local profileId = settings.id
	-- 	settings.script = function ()
	-- 		return newFuncs.setStationProfile(station, profileId)
	-- 	end
	-- end
end
function newFuncs.onExpandStationProfiles(frame, ftable)
	newFuncs.getProfiles()
	if (not StationBuySellProfiles) or (not next(StationBuySellProfiles)) then
		return
	end
	local menu = stationOverviewMenu
	local row
	local mouseOverText
	row = ftable:addRow(true, { bgColor = Helper.color.transparent })
	-- <t id="9">Set this station's behaviour by clicking on one of the profiles. A profile will set this station's prices, and trade restrictions of production, and trade wares.</t>
	row[1]:createText(ReadText(11201, 9), {wordwrap = true})
	local profiles_sorted = {}
	for profileId, settings in pairs(StationBuySellProfiles) do
		table.insert(profiles_sorted, settings)
	end
	table.sort(profiles_sorted, function(a, b)
		return a.list_order < b.list_order
	end)
	local icon_tick = "\27[widget_tick_01]\27X"
	local station = menu.container
	for _, settings in ipairs(profiles_sorted) do
		local profileId = settings.id
		local profileName = " " .. settings.name
		if newFuncs.matchedProfileId and settings.id == newFuncs.matchedProfileId then
			profileName = " " .. icon_tick .. profileName
		elseif newFuncs.bestProfileId and settings.id == newFuncs.bestProfileId then
			profileName = " " .. icon_tick .. profileName .. "*"
		end
		row = ftable:addRow(true, { bgColor = Helper.color.transparent })
		row[1]:createButton({mouseOverText = settings.mouseOverText}):setText(profileName)
		row[1].handlers.onClick = function () return newFuncs.setStationProfile(station, profileId) end
		row = ftable:addRow(false, { bgColor = Helper.color.transparent })
		row[1]:createText(settings.summary, {mouseOverText = mouseOverText})
	end
end
function newFuncs.getPlayerOnlyTradeRule()
	local traderules = {}
	local traderule_playeronly
	traderules = {}
	Helper.ffiVLA(traderules, "TradeRuleID", C.GetNumAllTradeRules, C.GetAllTradeRules)
	for i = #traderules, 1, -1 do
		local id = traderules[i]

		local counts = C.GetTradeRuleInfoCounts(id)
		local buf = ffi.new("TradeRuleInfo")
		buf.numfactions = counts.numfactions
		buf.factions = Helper.ffiNewHelper("const char*[?]", counts.numfactions)
		if C.GetTradeRuleInfo(buf, id) then
			if buf.iswhitelist and buf.numfactions == 1 then
				local factions = {}
				for j = 0, buf.numfactions - 1 do
					if (ffi.string(buf.factions[j]) == "player") then
						traderule_playeronly = { id = id, name = ffi.string(buf.name), factions = factions, iswhitelist = buf.iswhitelist, defaults = defaults }
						break
					end
				end
			end
		else
			table.remove(traderules, i)
		end
	end
	if not traderule_playeronly then
		traderule_playeronly = newFuncs.createPlayerOnlyTradeRule()
	end
	return traderule_playeronly
end
function newFuncs.createPlayerOnlyTradeRule()
	local traderule = ffi.new("TradeRuleInfo")
	traderule.name = Helper.ffiNewString("Don't trade with others")

	traderule.iswhitelist = true
	traderule.numfactions = 1
	traderule.factions = Helper.ffiNewHelper("const char*[?]", traderule.numfactions)
	traderule.factions[0] = Helper.ffiNewString("player")

	C.CreateTradeRule(traderule)
	return traderule
end
function newFuncs.getIdealWarePrice(station, ware, factor)
	local minprice, maxprice = GetWareData(ware, "minprice", "maxprice")
	local idealprice = minprice + (maxprice - minprice) * (factor - 1)
	return idealprice
end
function newFuncs.getAllWares(station)
	local waresTable = {}
	local availableproducts, pureresources, intermediatewares, tradewares = GetComponentData(station, "availableproducts", "pureresources", "intermediatewares", "tradewares")
	if availableproducts then
		for _, ware in ipairs(availableproducts) do
			waresTable[ware] = ware
		end
	end
	if pureresources then
		for _, ware in ipairs(pureresources) do
			waresTable[ware] = ware
		end
	end
	if intermediatewares then
		for _, ware in ipairs(intermediatewares) do
			waresTable[ware] = ware
		end
	end
	if tradewares then
		for _, ware in ipairs(tradewares) do
			waresTable[ware] = ware
		end
	end
	local wares = {}
	for _, ware in pairs(waresTable) do
		table.insert(wares, ware)
	end
	return wares
end
function newFuncs.setStationProfile(station, profileId)
	newFuncs.debugText_profiles("setStationProfile station", station)
	newFuncs.debugText_profiles("setStationProfile profileId", profileId)
	local profile = StationBuySellProfiles[profileId]
	local menu = stationOverviewMenu
	local wares = newFuncs.getAllWares(station)
	local waretype
	local min, maxprice, currentlimit_buy, currentlimit_sell, isbuy, isremoveoffer
	local traderule_playeronly = newFuncs.getPlayerOnlyTradeRule()
	for _, ware in ipairs(wares) do
		waretype = Helper.getContainerWareType(station, ware)
		newFuncs.debugText_profiles("ware", ware)
		newFuncs.debugText_profiles("    waretype", waretype)
		minprice, maxprice, isprocessed = GetWareData(ware, "minprice", "maxprice", "isprocessed")
		currentlimit_buy = C.GetContainerBuyLimit(station, ware)
		currentlimit_sell = C.GetContainerSellLimit(station, ware)
		if (waretype == "resource") or (waretype == "intermediate") or (waretype == "product") or (waretype == "trade") then
			isbuy = true
			local isApplyToWare = false
			if isApplyToWare ~= true then
				for _, wareType_applicable in ipairs(profile.buy.waretypes) do
					if waretype == wareType_applicable then
						isApplyToWare = true
						break
					end
				end
			end
			if isApplyToWare then
				newFuncs.debugText_profiles("    buy")
				isremoveoffer = profile.buy.isoffered ~= true
				if isremoveoffer then
					-- remove buy offer
					-- can be removed only from product and trade wares
					if waretype == "product" then
						newFuncs.debugText_profiles("        buttonStorageBuyProductWare - removing")
						Helper.buttonStorageBuyProductWare(menu, station, ware, isremoveoffer, currentlimit_buy)
					elseif waretype == "trade" then
						newFuncs.debugText_profiles("        buttonStorageBuyTradeWare - removing")
						Helper.buttonStorageBuyTradeWare(menu, station, ware, isremoveoffer)
					else
						-- resource and intermediate are always bought
					end
				else
					-- set buy offer
					if waretype == "product" then
						newFuncs.debugText_profiles("        buttonStorageBuyProductWare")
						Helper.buttonStorageBuyProductWare(menu, station, ware, isremoveoffer, currentlimit_buy)
					elseif waretype == "trade" then
						newFuncs.debugText_profiles("        buttonStorageBuyTradeWare")
						Helper.buttonStorageBuyTradeWare(menu, station, ware, isremoveoffer)
					else
						-- resource and intermediate are always bought
					end
				end
				-- set price
				if profile.buy.price_factor ~= "auto" then
					value = minprice + (maxprice - minprice) * profile.buy.price_factor
					newFuncs.debugText_profiles("        SetContainerWarePriceOverride value", value)
					SetContainerWarePriceOverride(station, ware, isbuy, value)
				else
					newFuncs.debugText_profiles("        ClearContainerWarePriceOverride")
					ClearContainerWarePriceOverride(station, ware, isbuy)
				end
				-- set trade rule
				newFuncs.debugText_profiles("        SetContainerTradeRule trade_isrestricted", profile.buy.trade_isrestricted)
				if profile.buy.trade_isrestricted == true then
					C.SetContainerTradeRule(station, tonumber(traderule_playeronly.id), "buy", ware, true)
				else
					C.SetContainerTradeRule(station, -1, "buy", ware, true)
				end
			end
		end
		if (not isprocessed) and ((waretype == "resource") or (waretype == "intermediate") or (waretype == "product") or (waretype == "trade")) then
			isbuy = false
			isApplyToWare = false
			if isApplyToWare ~= true then
				for _, wareType_applicable in ipairs(profile.sell.waretypes) do
					if waretype == wareType_applicable then
						isApplyToWare = true
						break
					end
				end
			end
			if isApplyToWare then
				newFuncs.debugText_profiles("    sell")
				isremoveoffer = profile.sell.isoffered ~= true
				if isremoveoffer then
					-- remove sell offer
					-- can only be removed from resource and trade wares
					if waretype == "resource" then
						newFuncs.debugText_profiles("        buttonStorageSellResourceWare - removing")
						Helper.buttonStorageSellResourceWare(menu, station, ware, isremoveoffer, currentlimit_sell)
					elseif waretype == "trade" then
						newFuncs.debugText_profiles("        buttonStorageSellTradeWare - removing")
						Helper.buttonStorageSellTradeWare(menu, station, ware, isremoveoffer)
					else
						-- intermediate and products are always sold
					end
				else
					-- set sell offer
					if waretype == "resource" then
						newFuncs.debugText_profiles("        buttonStorageSellResourceWare")
						Helper.buttonStorageSellResourceWare(menu, station, ware, isremoveoffer, currentlimit_sell)
					elseif waretype == "trade" then
						newFuncs.debugText_profiles("        buttonStorageSellTradeWare")
						Helper.buttonStorageSellTradeWare(menu, station, ware, isremoveoffer)
					else
						-- intermediate and products are always sold
					end
				end
				-- set price
				if profile.sell.price_factor ~= "auto" then
					value = minprice + (maxprice - minprice) * profile.sell.price_factor
					newFuncs.debugText_profiles("        SetContainerWarePriceOverride value", value)
					SetContainerWarePriceOverride(station, ware, isbuy, value)
				else
					newFuncs.debugText_profiles("        ClearContainerWarePriceOverride")
					ClearContainerWarePriceOverride(station, ware, isbuy)
				end
				-- set trade rule
				newFuncs.debugText_profiles("        SetContainerTradeRule trade_isrestricted", profile.sell.trade_isrestricted)
				if profile.sell.trade_isrestricted == true then
					C.SetContainerTradeRule(station, tonumber(traderule_playeronly.id), "sell", ware, true)
				else
					C.SetContainerTradeRule(station, -1, "sell", ware, true)
				end
			end
		end
	end
	newFuncs.saveProfileIdForMD(station, profile.id)

	if menu.frame then
		menu.setupFlowchartData()
		menu.refresh = true
		menu.expandedNode:collapse()
	end
end
function newFuncs.saveProfileIdForMD(station, profileId, isDebug)
	if profileId then
		newFuncs.player64Bit = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
		local profileListOrdersByStation = GetNPCBlackboard (newFuncs.player64Bit, "$profileListOrdersByStation")
		if profileListOrdersByStation then
			local stationName = GetComponentData(station, "name") .. " " .. ffi.string(C.GetObjectIDCode(station))
			if isDebug then
				newFuncs.debugText_profiles("saveProfileIdForMD", tostring(station) .. " " .. stationName)
				newFuncs.debugText_profiles("profileId", profileId)
				newFuncs.debugText_profiles("StationBuySellProfiles[profileId]", StationBuySellProfiles[profileId])
				newFuncs.debugText_profiles("saveProfileIdForMD pre set", profileListOrdersByStation)
			end
			profileListOrdersByStation[ConvertStringToLuaID(tostring(station))] = StationBuySellProfiles[profileId].list_order
			SetNPCBlackboard(ConvertStringTo64Bit(newFuncs.player64Bit), "$profileListOrdersByStation", profileListOrdersByStation)
			if newFuncs.isDebug_profiles then
				profileListOrdersByStation = GetNPCBlackboard (newFuncs.player64Bit, "$profileListOrdersByStation")
				newFuncs.debugText_profiles("saveProfileIdForMD post set", profileListOrdersByStation)
			end
		end
	end
end
-- function newFuncs.updateStationProfileText()
-- 	-- doesn't work
-- 	-- the bug: it displays the PREVIOUS selected profile and not the just-selected profile
-- 	-- reason: it's likely that this gets called BEFORE changes have been applied and can be tested
-- 	local menu = stationOverviewMenu
-- 	if newFuncs.node_setStationPresets then
-- 		local matchedProfile_old = newFuncs.matchedProfileId
-- 		local bestProfile_old = newFuncs.bestProfileId
-- 		newFuncs.setMatchedAndBestProfileBasedOnSettings(menu.container)
-- 		if newFuncs.matchedProfileId ~= matchedProfile_old or newFuncs.bestProfileId ~= bestProfile_old then
-- 			local buttonText = ReadText(11201, 8)
-- 			if StationBuySellProfiles and newFuncs.matchedProfileId and StationBuySellProfiles[newFuncs.matchedProfileId] then
-- 				buttonText = buttonText .. " (" .. StationBuySellProfiles[newFuncs.matchedProfileId].name .. ")"
-- 			end
-- 			newFuncs.node_setStationPresets:updateText(buttonText)
-- 		end
-- 	end
-- end
function newFuncs.cleanup_stationConfigurationMenu()
	newFuncs.productioncounts = nil
end
function newFuncs.onExpandTradeWares_insert_ware_to_allwares(allwares, ware)
	table.insert(allwares, { ware = ware, name = newFuncs.getWareNameAndProductionCounts(ware) })
end
function newFuncs.kTAnalytics_set_profile ()
	newFuncs.player64Bit = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
	local kTAnalytics_uiData = GetNPCBlackboard (newFuncs.player64Bit, "$kTAnalytics_uiData")
	local stations = kTAnalytics_uiData.stations
	local profileId = kTAnalytics_uiData.profileId
	newFuncs.debugText_profiles("stations", stations)
	newFuncs.debugText_profiles("profileId", profileId)
	local station64Bit
	local profileListOrdersByStation = GetNPCBlackboard (newFuncs.player64Bit, "$profileListOrdersByStation")
	if profileListOrdersByStation then
		for _, station in pairs(stations) do
			station64Bit = ConvertStringTo64Bit(tostring(station))
			newFuncs.setStationProfile(station64Bit, profileId)
		end
	end
end
function newFuncs.displayPlan_getWareName(ware, name)
	local name = newFuncs.getWareNameAndProductionCounts(ware)
	return name
end
function newFuncs.displayPlan_render_incoming_ware(row, colorprefix, name, reservation)
	-- row[2]:setColSpan(3):createText(function ()                                     return Helper.getETAString(colorprefix .. name, reservation.eta) end, { font = Helper.standardFontMono })
	row[2]:setColSpan(3):createButton({ mouseOverText = name }):setText(function () return Helper.getETAString(colorprefix .. name, reservation.eta) end)
	row[2].handlers.onClick = function () return newFuncs.showOnMap(reservation.reserver) end
	return true
end
function newFuncs.setMatchedAndBestProfileBasedOnSettings(station)
	newFuncs.getProfiles()
	if newFuncs.isDebug_profiles then
		Helper.debugText_forced("kuertee_trade_anaytics setMatchedAndBestProfileBasedOnSettings StationBuySellProfiles", StationBuySellProfiles)
	end
	if (not StationBuySellProfiles) or (not next(StationBuySellProfiles)) then
		return
	end
	if newFuncs.isDebug_profiles then
		local stationName = GetComponentData(station, "name") .. " " .. ffi.string(C.GetObjectIDCode(station))
		newFuncs.debugText_profiles("")
		newFuncs.debugText_profiles("")
		newFuncs.debugText_profiles("")
		newFuncs.debugText_profiles("==========")
		newFuncs.debugText_profiles("stationName", stationName)
		newFuncs.debugText_profiles("==========")
	end
	newFuncs.matchedProfileId = nil
	newFuncs.bestProfileId = nil
	local traderule_playeronly = newFuncs.getPlayerOnlyTradeRule()
	local wares = newFuncs.getAllWares(station)
	local profiles_sorted = {}
	local matchScoresByProfileId = {}
	local hasOfferByProfile = {}
	for profileId, settings in pairs(StationBuySellProfiles) do
		table.insert(profiles_sorted, settings)
		matchScoresByProfileId[profileId] = {current = 0, max = 0}
		hasOfferByProfile[profileId] = {hasBuy = false, hasSell = false}
	end
	table.sort(profiles_sorted, function(a, b)
		return a.list_order < b.list_order
	end)
	newFuncs.bestProfileDataByWare = {}
	for _, ware in ipairs(wares) do
		newFuncs.bestProfileDataByWare[ware] = {profileId = nil, score = 0, max = 0}
		local waretype = Helper.getContainerWareType(station, ware)
		local minprice, maxprice, isprocessed = GetWareData(ware, "minprice", "maxprice", "isprocessed")
		-- resource and intermediate are always bought
		-- intermediate and product are always sold
		local isoffered_buy = C.GetContainerWareIsBuyable(station, ware) or waretype == "resource" or waretype == "intermediate"
		local isoffered_sell = ((not isprocessed) and (C.GetContainerWareIsSellable(station, ware) or waretype == "intermediate" or waretype == "product")) ~= false
		-- scores
		if newFuncs.isDebug_profiles then
			newFuncs.debugText_profiles("==========")
			newFuncs.debugText_profiles("ware", ware)
			newFuncs.debugText_profiles("==========")
			newFuncs.debugText_profiles("    isoffered_buy", isoffered_buy)
			newFuncs.debugText_profiles("    isoffered_sell", isoffered_sell)
			newFuncs.debugText_profiles("    minprice", minprice)
			newFuncs.debugText_profiles("    maxprice", maxprice)
		end
		for _, settings in ipairs(profiles_sorted) do
			if newFuncs.isDebug_profiles then
				newFuncs.debugText_profiles("    " .. settings.id)
			end
			local hasForcedBuyOffer, hasBuy, hasForcedSellOffer, hasSell
			local matchedScore_buy, matchedScore_sell, wareScore_max = 0, 0, 0
			-- buy offer, price, trade rule
			local isApplyToWare_buy = newFuncs.getBestMatchedProfileBuy_step0(station, ware, settings)
			if isApplyToWare_buy then
				local currentprice_buy, currentpricefactor_buy, haspriceoverride_buy, istraderuleplayeronly_buy, traderuleid_buy
				currentprice_buy, currentpricefactor_buy, haspriceoverride_buy, istraderuleplayeronly_buy, traderuleid_buy = newFuncs.getBestMatchedProfileBuy_step1(station, ware, minprice, maxprice, settings, isDebug)
				matchScoresByProfileId[settings.id].max = matchScoresByProfileId[settings.id].max + 3
				wareScore_max = wareScore_max + 3
				hasForcedBuyOffer, hasBuy, matchedScore_buy = newFuncs.getBestMatchedProfileBuy_step2(ware, waretype, settings, minprice, maxprice, isoffered_buy, currentprice_buy, currentpricefactor_buy, haspriceoverride_buy, istraderuleplayeronly_buy, traderuleid_buy, isDebug)
				hasOfferByProfile[settings.id].hasForcedBuyOffer = hasForcedBuyOffer
				hasOfferByProfile[settings.id].hasBuy = hasBuy
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + matchedScore_buy
			end
			-- sell offer, price, trade rule
			local isApplyToWare_sell = newFuncs.getBestMatchedProfileSell_step0(station, ware, settings)
			if isApplyToWare_sell then
				local currentprice_sell, currentpricefactor_sell, haspriceoverride_sell, istraderuleplayeronly_sell, traderuleid_sell
				currentprice_sell, currentpricefactor_sell, haspriceoverride_sell, istraderuleplayeronly_sell, traderuleid_sell = newFuncs.getBestMatchedProfileSell_step1(station, ware, minprice, maxprice, settings, isDebug)
				matchScoresByProfileId[settings.id].max = matchScoresByProfileId[settings.id].max + 3
				wareScore_max = wareScore_max + 3
				hasForcedSellOffer, hasSell, matchedScore_sell = newFuncs.getBestMatchedProfileSell_step2(ware, waretype, settings, minprice, maxprice, isoffered_sell, currentprice_sell, currentpricefactor_sell, haspriceoverride_sell, istraderuleplayeronly_sell, traderuleid_sell, isDebug)
				hasOfferByProfile[settings.id].hasForcedSellOffer = hasForcedSellOffer
				hasOfferByProfile[settings.id].hasSell = hasSell
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + matchedScore_sell
			end
			if newFuncs.isDebug_profiles and (isApplyToWare_buy or settings.buy.isoffered == true or isApplyToWare_sell or settings.sell.isoffered == true) then
				newFuncs.debugText_profiles("        " .. settings.id .. " current", matchScoresByProfileId[settings.id].current)
				newFuncs.debugText_profiles("        " .. settings.id .. " max", matchScoresByProfileId[settings.id].max)
			end
			local wareScore = matchedScore_buy + matchedScore_sell
			if wareScore > newFuncs.bestProfileDataByWare[ware].score then
				newFuncs.bestProfileDataByWare[ware] = {profileId = settings.id, score = wareScore, max = wareScore_max}
				newFuncs.debugText_profiles(ware, newFuncs.bestProfileDataByWare[ware])
			end
		end
	end
	for _, settings in ipairs(profiles_sorted) do
		if newFuncs.isDebug_profiles then
			newFuncs.debugText_profiles(settings.id)
		end
		matchScoresByProfileId[settings.id].max = matchScoresByProfileId[settings.id].max + 1
		if settings.buy.isoffered == true or hasOfferByProfile[settings.id].hasForcedBuyOffer == true then
			if hasOfferByProfile[settings.id].hasBuy == true then
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + 1
			end
		else
			if hasOfferByProfile[settings.id].hasBuy ~= true then
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + 1
			end
		end
		matchScoresByProfileId[settings.id].max = matchScoresByProfileId[settings.id].max + 1
		if newFuncs.isDebug_profiles then
			newFuncs.debugText_profiles("        required buy offer (needs: " .. tostring(settings.buy.isoffered) .. ", is: " .. tostring(hasOfferByProfile[settings.id].hasBuy) .. "):", matchScoresByProfileId[settings.id].current)
		end
		if settings.sell.isoffered == true or hasOfferByProfile[settings.id].hasForcedSellOffer == true then
			if hasOfferByProfile[settings.id].hasSell == true then
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + 1
			end
		else
			if hasOfferByProfile[settings.id].hasSell ~= true then
				matchScoresByProfileId[settings.id].current = matchScoresByProfileId[settings.id].current + 1
			end
		end
		if newFuncs.isDebug_profiles then
			newFuncs.debugText_profiles("        required sell offer (needs: " .. tostring(settings.sell.isoffered) .. ", is: " .. tostring(hasOfferByProfile[settings.id].hasSell) .. "):", matchScoresByProfileId[settings.id].current)
			newFuncs.debugText_profiles("    " .. settings.id .. " current", matchScoresByProfileId[settings.id].current)
			newFuncs.debugText_profiles("    " .. settings.id .. " max", matchScoresByProfileId[settings.id].max)
		end
	end
	-- get matched profile
	-- matched profile score = number of wares * 6 (because there are 3 criterias for buy and 3 for sell)
	local bestScore = 0
	for profileId, scores in pairs(matchScoresByProfileId) do
		local score = scores.current
		local max = scores.max
		if score >= max * 0.75 then
			if newFuncs.isDebug_profiles then
				newFuncs.debugText_profiles("    possible match: " .. tostring(profileId))
			end
			if score == max then
				if newFuncs.isDebug_profiles then
					newFuncs.debugText_profiles("    exact match: " .. tostring(profileId))
				end
				newFuncs.matchedProfileId = profileId
			elseif score > bestScore then
				if newFuncs.isDebug_profiles then
					newFuncs.debugText_profiles("    near match: " .. tostring(profileId))
				end
				bestScore = score
				newFuncs.bestProfileId = profileId
			end
		end
	end
	if newFuncs.matchedProfileId then
		-- if matched, then set best to matched
		newFuncs.bestProfileId = newFuncs.matchedProfileId
		newFuncs.saveProfileIdForMD(station, newFuncs.matchedProfileId, isDebug)
	elseif newFuncs.bestProfileId then
		newFuncs.saveProfileIdForMD(station, newFuncs.bestProfileId, isDebug)
	else
		newFuncs.saveProfileIdForMD(station, nil, isDebug)
	end
	if newFuncs.isDebug_profiles then
		newFuncs.debugText_profiles("newFuncs.matchedProfileId", newFuncs.matchedProfileId)
		newFuncs.debugText_profiles("newFuncs.bestProfileId", newFuncs.bestProfileId)
	end
end
function newFuncs.getBestMatchedProfileBuy_step0(station, ware, settings)
	local waretype = Helper.getContainerWareType(station, ware)
	local isApplyToWare_buy = false
	for _, wareType_applicable in ipairs(settings.buy.waretypes) do
		if waretype == wareType_applicable then
			isApplyToWare_buy = true
			break
		end
	end
	return isApplyToWare_buy
end
function newFuncs.getBestMatchedProfileBuy_step1(station, ware, minprice, maxprice, settings, isDebug)
	local currentprice_buy = math.max(minprice, math.min(maxprice, RoundTotalTradePrice(GetContainerWarePrice(station, ware, true))))
	local currentpricefactor_buy = (currentprice_buy - minprice) / (maxprice - minprice)
	local haspriceoverride_buy = HasContainerWarePriceOverride(station, ware, true)
	local istraderuleplayeronly_buy = false
	local traderuleid_buy = C.GetContainerTradeRuleID(station, "buy", ware)
	if traderuleid_buy > 0 then
		local counts = C.GetTradeRuleInfoCounts(traderuleid_buy)
		local buf = ffi.new("TradeRuleInfo")
		buf.numfactions = counts.numfactions
		buf.factions = Helper.ffiNewHelper("const char*[?]", counts.numfactions)
		if C.GetTradeRuleInfo(buf, traderuleid_buy) then
			if buf.iswhitelist and buf.numfactions == 1 then
				local factions = {}
				for j = 0, buf.numfactions - 1 do
					if (ffi.string(buf.factions[j]) == "player") then
						istraderuleplayeronly_buy = true
						break
					end
				end
			end
		end
	end
	if newFuncs.isDebug_profiles then
		newFuncs.debugText_profiles("        " .. settings.id .. " buy:")
		newFuncs.debugText_profiles("        ==========================")
		newFuncs.debugText_profiles("        currentprice_buy", currentprice_buy)
		newFuncs.debugText_profiles("        currentpricefactor_buy", currentpricefactor_buy)
		newFuncs.debugText_profiles("        haspriceoverride_buy", haspriceoverride_buy)
		newFuncs.debugText_profiles("        traderuleid_buy", traderuleid_buy)
		newFuncs.debugText_profiles("        istraderuleplayeronly_buy", istraderuleplayeronly_buy)
	end
	return currentprice_buy, currentpricefactor_buy, haspriceoverride_buy, istraderuleplayeronly_buy, traderuleid_buy
end
function newFuncs.getBestMatchedProfileBuy_step2(ware, waretype, settings, minprice, maxprice, isoffered_buy, currentprice_buy, currentpricefactor_buy, haspriceoverride_buy, istraderuleplayeronly_buy, traderuleid_buy, isDebug)
	local hasForcedBuyOffer = false
	local hasBuy = false
	local matchedScore = 0
	if waretype == "resource" or waretype == "intermediate" then
		hasForcedBuyOffer = true
	end
	if isoffered_buy == true then
		hasBuy = true
	end
	if (settings.buy.isoffered == true or hasForcedBuyOffer == true) and isoffered_buy == true then
		matchedScore = matchedScore + 1
	elseif (settings.buy.isoffered ~= true and hasForcedBuyOffer ~= true) and isoffered_buy ~= true then
		matchedScore = matchedScore + 1
	end
	newFuncs.debugText_profiles("            matchedScore offer:", matchedScore)
	if settings.buy.isoffered == true then
		if settings.buy.price_factor ~= "auto" then
			price_req = RoundTotalTradePrice(minprice + (maxprice - minprice) * settings.buy.price_factor)
		end
		if settings.buy.price_factor ~= "auto" then
			if haspriceoverride_buy == true and currentprice_buy > price_req - 0.25 and currentprice_buy < price_req + 0.25 then
				matchedScore = matchedScore + 1
			end
		else
			if haspriceoverride_buy ~= true then
				matchedScore = matchedScore + 1
			end
		end
		newFuncs.debugText_profiles("            matchedScore price (needs: " .. tostring(price_req) .. ", is: " .. tostring(currentprice_buy) .. "):", matchedScore)
		if settings.buy.trade_isrestricted == true and istraderuleplayeronly_buy == true then
			matchedScore = matchedScore + 1
		elseif settings.buy.trade_isrestricted ~= true and istraderuleplayeronly_buy ~= true then
			matchedScore = matchedScore + 1
		end
		newFuncs.debugText_profiles("            matchedScore trade rule:", matchedScore)
	else
		matchedScore = matchedScore + 1
		newFuncs.debugText_profiles("            matchedScore price (needs: " .. tostring(price_req) .. ", is: not offered):", matchedScore)
		matchedScore = matchedScore + 1
		newFuncs.debugText_profiles("            matchedScore trade rule: not offered", matchedScore)
	end
	return hasForcedBuyOffer, hasBuy, matchedScore
end
function newFuncs.getBestMatchedProfileSell_step0(station, ware, settings)
	local waretype = Helper.getContainerWareType(station, ware)
	local isApplyToWare_sell = false
	for _, wareType_applicable in ipairs(settings.sell.waretypes) do
		if waretype == wareType_applicable then
			isApplyToWare_sell = true
			break
		end
	end
	return isApplyToWare_sell
end
function newFuncs.getBestMatchedProfileSell_step1(station, ware, minprice, maxprice, settings, isDebug)
	local currentprice_sell = math.max(minprice, math.min(maxprice, RoundTotalTradePrice(GetContainerWarePrice(station, ware, false))))
	local currentpricefactor_sell = (currentprice_sell - minprice) / (maxprice - minprice)
	local haspriceoverride_sell = HasContainerWarePriceOverride(station, ware, false)
	local istraderuleplayeronly_sell = false
	local traderuleid_sell = C.GetContainerTradeRuleID(station, "sell", ware)
	if traderuleid_sell > 0 then
		local counts = C.GetTradeRuleInfoCounts(traderuleid_sell)
		local buf = ffi.new("TradeRuleInfo")
		buf.numfactions = counts.numfactions
		buf.factions = Helper.ffiNewHelper("const char*[?]", counts.numfactions)
		if C.GetTradeRuleInfo(buf, traderuleid_sell) then
			if buf.iswhitelist and buf.numfactions == 1 then
				local factions = {}
				for j = 0, buf.numfactions - 1 do
					if (ffi.string(buf.factions[j]) == "player") then
						istraderuleplayeronly_sell = true
						break
					end
				end
			end
		end
	end
	if newFuncs.isDebug_profiles then
		newFuncs.debugText_profiles("        " .. settings.id .. " sell:")
		newFuncs.debugText_profiles("        ===========================")
		newFuncs.debugText_profiles("        currentprice_sell", currentprice_sell)
		newFuncs.debugText_profiles("        currentpricefactor_sell", currentpricefactor_sell)
		newFuncs.debugText_profiles("        haspriceoverride_sell", haspriceoverride_sell)
		newFuncs.debugText_profiles("        traderuleid_sell", traderuleid_sell)
		newFuncs.debugText_profiles("        istraderuleplayeronly_sell", istraderuleplayeronly_sell)
	end
	return currentprice_sell, currentpricefactor_sell, haspriceoverride_sell, istraderuleplayeronly_sell, traderuleid_sell
end
function newFuncs.getBestMatchedProfileSell_step2(ware, waretype, settings, minprice, maxprice, isoffered_sell, currentprice_sell, currentpricefactor_sell, haspriceoverride_sell, istraderuleplayeronly_sell, traderuleid_sell, isDebug)
	local hasForcedSellOffer = false
	local hasSell = false
	local matchedScore = 0
	local price_req
	if waretype == "intermediate" or waretype == "product" then
		hasForcedSellOffer = true
	end
	if isoffered_sell == true then
		hasSell = true
	end
	if (settings.sell.isoffered == true or hasForcedSellOffer == true) and isoffered_sell == true then
		matchedScore = matchedScore + 1
	elseif (settings.sell.isoffered ~= true and hasForcedSellOffer ~= true) and isoffered_sell ~= true then
		matchedScore = matchedScore + 1
	end
	newFuncs.debugText_profiles("            matchedScore offer:", matchedScore)
	if settings.sell.isoffered == true then
		if settings.sell.price_factor ~= "auto" then
			price_req = RoundTotalTradePrice(minprice + (maxprice - minprice) * settings.sell.price_factor)
		end
		if settings.sell.price_factor ~= "auto" then
			if haspriceoverride_sell == true and currentprice_sell > price_req - 0.25 and currentprice_sell < price_req + 0.25 then
				matchedScore = matchedScore + 1
			end
		else
			if haspriceoverride_sell ~= true then
				matchedScore = matchedScore + 1
			end
		end
		newFuncs.debugText_profiles("            matchedScore price (needs: " .. tostring(price_req) .. ", is: " .. tostring(currentprice_sell) .. "):", matchedScore)
		if settings.sell.trade_isrestricted == true and istraderuleplayeronly_sell == true then
			matchedScore = matchedScore + 1
		elseif settings.sell.trade_isrestricted ~= true and istraderuleplayeronly_sell ~= true then
			matchedScore = matchedScore + 1
		end
		newFuncs.debugText_profiles("            matchedScore trade rule:", matchedScore)
	else
		matchedScore = matchedScore + 1
		newFuncs.debugText_profiles("            matchedScore price (needs: " .. tostring(price_req) .. ", is: not offered):", matchedScore)
		matchedScore = matchedScore + 1
		newFuncs.debugText_profiles("            matchedScore trade rule: not offered", matchedScore)
	end
	return hasForcedSellOffer, hasSell, matchedScore
end
function newFuncs.onExpandLSOStorageNode_pre_buy_offer_title(menu, container, ftable, nodedata)
	local ware = nodedata.ware
end
function newFuncs.onExpandLSOStorageNode_pre_sell_offer_title(menu, container, ftable, nodedata)
	local ware = nodedata.ware
end
function newFuncs.getWareProfileName(ware)
	local wareProfileId, wareProfileName, isExactWareProfileMatch
	if newFuncs.bestProfileDataByWare[ware] then
		local wareProfileId = newFuncs.bestProfileDataByWare[ware].profileId
		local wareProfileName = ""
		if wareProfileId and StationBuySellProfiles[wareProfileId] then
			wareProfileName = StationBuySellProfiles[wareProfileId].name
		end
		local isExactWareProfileMatch = true
		if newFuncs.bestProfileDataByWare[ware].score ~= newFuncs.bestProfileDataByWare[ware].max then
			isExactWareProfileMatch = false
			wareProfileName = wareProfileName .. "*"
		end
		wareProfileName = string.format(ReadText(11201, 7), wareProfileName)
	end
	return wareProfileId, wareProfileName, isExactWareProfileMatch
end
function newFuncs.updateLSOStorageNode_pre_update_expanded_node(menu, node, container, ware, status_text, status_icon, status_bgicon, status_color, status_mouseovertext)
	local stationProfileId = newFuncs.matchedProfileId
	if not stationProfileId then
		stationProfileId = newFuncs.bestProfileId
	end
	local wareProfileId, wareProfileName, isExactWareProfileMatch = newFuncs.getWareProfileName(ware)
	if wareProfileId and (wareProfileId ~= stationProfileId or (not isExactWareProfileMatch)) then
		status_icon = status_icon or ""
		if status_icon == "" then
			status_icon = "lso_warning"
		end
		if not status_color then
			status_color = Color["icon_warning"]
		end
		if not status_mouseovertext then
			status_mouseovertext = wareProfileName
		else
			status_mouseovertext = status_mouseovertext .. "\n" .. wareProfileName
		end
	end
	return status_text, status_icon, status_bgicon, status_color, status_mouseovertext
end
function newFuncs.checkboxSetTradeRuleOverride_pre_update_expanded_node(menu, container, type, ware, checked, status_text, status_icon, status_bgicon, status_color, status_mouseovertext)
	local stationProfileId = newFuncs.matchedProfileId
	if not stationProfileId then
		stationProfileId = newFuncs.bestProfileId
	end
	local wareProfileId, wareProfileName, isExactWareProfileMatch = newFuncs.getWareProfileName(ware)
	if wareProfileId and (wareProfileId ~= stationProfileId or (not isExactWareProfileMatch)) then
		status_icon = status_icon or ""
		if status_icon == "" then
			status_icon = "lso_warning"
		end
		if not status_color then
			status_color = Color["icon_warning"]
		end
		if not status_mouseovertext then
			status_mouseovertext = wareProfileName
		else
			status_mouseovertext = status_mouseovertext .. "\n" .. wareProfileName
		end
	end
	return status_text, status_icon, status_bgicon, status_color, status_mouseovertext
end
function newFuncs.dropdownTradeRule_pre_update_expanded_node(menu, container, type, ware, id, status_text, status_icon, status_bgicon, status_color, status_mouseovertext)
	local stationProfileId = newFuncs.matchedProfileId
	if not stationProfileId then
		stationProfileId = newFuncs.bestProfileId
	end
	local wareProfileId, wareProfileName, isExactWareProfileMatch = newFuncs.getWareProfileName(ware)
	if wareProfileId and (wareProfileId ~= stationProfileId or (not isExactWareProfileMatch)) then
		status_icon = status_icon or ""
		if status_icon == "" then
			status_icon = "lso_warning"
		end
		if not status_color then
			status_color = Color["icon_warning"]
		end
		if not status_mouseovertext then
			status_mouseovertext = wareProfileName
		else
			status_mouseovertext = status_mouseovertext .. "\n" .. wareProfileName
		end
	end
	return status_text, status_icon, status_bgicon, status_color, status_mouseovertext
end
function newFuncs.UTAdvancedRenaming_getEditName(station)
	local editName
	-- start: from utrenaming.lua utRenaming.setupInfoSubmenuRows() --
	local editNames = GetNPCBlackboard(ConvertStringTo64Bit(tostring(C.GetPlayerID())) , "$unformatted_names")
	if editNames then
		for k,v in pairs(editNames) do
			--DebugError(tostring(k))
			--DebugError("ID: "..tostring(inputobject))
			if tostring(k) == "ID: "..tostring(station) then
				editName = v
				--DebugError(editName)
				break
			end
		end
	end
	return editName
end
function newFuncs.buttonRenameConfirm_onMultiRename_on_before_rename()
	local menu = mapMenu
	for _, uix_renameThisObject in ipairs(menu.contextMenuData.uix_multiRename_objects) do
		if C.IsRealComponentClass(uix_renameThisObject, "station") then
			newFuncs.setMatchedAndBestProfileBasedOnSettings(uix_renameThisObject)
		end
	end
end
function newFuncs.utRenaming_infoChangeObjectName(objectid, text, textchanged)
	if C.IsRealComponentClass(objectid, "station") then
		newFuncs.setMatchedAndBestProfileBasedOnSettings(objectid)
	end
end
function newFuncs.debugText_profiles(data1, data2)
	if newFuncs.isDebug_profiles then
		if type(data1) == "table" then
			Helper.debugText_forced("tAnalytics")
			Helper.debugText_forced(data1, data2)
		else
			Helper.debugText_forced("tAnalytics " .. tostring(data1), data2)
		end
	end
end
function newFuncs.debugText_analytics(data1, data2)
	if newFuncs.isDebug_analytics then
		if type(data1) == "table" then
			Helper.debugText_forced("tAnalytics")
			Helper.debugText_forced(data1, data2)
		else
			Helper.debugText_forced("tAnalytics " .. tostring(data1), data2)
		end
	end
end
ModLua.init()

	-- local n = C.GetNumTransactionLog(container, starttime, endtime)
	-- local buf = ffi.new("TransactionLogEntry[?]", n)
	-- n = C.GetTransactionLog(buf, n, container, starttime, endtime)
	-- for i = 0, n - 1 do
	-- 	local partnername = ffi.string(buf[i].partnername)

	-- 	table.insert(Helper.transactionLogData.accountLogUnfiltered, { 
	-- 		time = buf[i].time,
	-- 		money = tonumber(buf[i].money) / 100,
	-- 		entryid = ConvertStringTo64Bit(tostring(buf[i].entryid)),
	-- 		eventtype = ffi.string(buf[i].eventtype),
	-- 		eventtypename = ffi.string(buf[i].eventtypename),
	-- 		partner = buf[i].partnerid,
	-- 		partnername = (partnername ~= "") and (partnername .. " (" .. ffi.string(buf[i].partneridcode) .. ")") or "",
	-- 		tradeentryid = ConvertStringTo64Bit(tostring(buf[i].tradeentryid)),
	-- 		tradeeventtype = ffi.string(buf[i].tradeeventtype),
	-- 		tradeeventtypename = ffi.string(buf[i].tradeeventtypename),
	-- 		buyer = buf[i].buyerid,
	-- 		seller = buf[i].sellerid,
	-- 		ware = ffi.string(buf[i].ware),
	-- 		amount = buf[i].amount,
	-- 		price = tonumber(buf[i].price) / 100,
	-- 		complete = buf[i].complete,
	-- 		description = "",
	-- 	})
-- <set_value name="$tradesByTraders.{$Trader}.$miningByMiner.{$Miner.idcode}" exact="table[
-- 	$traderMacro = $Miner.macro,
-- 	$traderName = $Miner.knownname,
-- 	$count = 0,
-- 	$tradeByWare = table[]
-- ]" />
-- <set_value name="$tradesByTraders.{$Trader}.$buysFromByTrader.{$Trader_Other}" exact="table[
-- 	$traderMacro = $Trader_Other.macro,
-- 	$traderName = $Trader_Other.knownname,
-- 	$gateDistance = $Trader.gatedistance.{$Trader_Other},
-- 	$count = 0,
-- 	$tradeByWare = table[]
-- ]" />
-- <set_value name="$tradesByTraders.{$Trader}.$salesToByTrader.{$Trader_Other}" exact="table[
-- 	$traderMacro = $Trader_Other.macro,
-- 	$traderName = $Trader_Other.knownname,
-- 	$gateDistance = $Trader.gatedistance.{$Trader_Other},
-- 	$count = 0,
-- 	$tradeByWare = table[]
-- ]" />
-- <do_if value="not @$tradesByTraders.{$Trader}.$miningByMiner.{$Miner}.$tradeByWare.{$Ware}">
-- 	<set_value name="$tradesByTraders.{$Trader}.$miningByMiner.{$Miner}.$tradeByWare.{$Ware}" exact="table[$amount = 0, $price = 0]" />
-- </do_if>
-- <set_value name="$tradesByTraders.{$Trader}.$miningByMiner.{$Miner}.$count" operation="add" />
-- <set_value name="$tradesByTraders.{$Trader}.$miningByMiner.{$Miner}.$tradeByWare.{$Ware}.$amount" operation="add" exact="$Amount" />
-- <set_value name="$tradesByTraders.{$Trader}.$miningByMiner.{$Miner}.$tradeByWare.{$Ware}.$price" operation="add" exact="$Price" />
