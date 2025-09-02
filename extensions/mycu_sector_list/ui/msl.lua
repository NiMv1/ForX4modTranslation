local ffi = require("ffi")
local C = ffi.C

local dataProvider = MSLDataProvider

local isDebug = false
local msl = {}

local shouldUpdate = true
local updatedAt = getElapsedTime()

local disabledSectors = {}

local mapMenu
local uiScale = C.GetUIScale(true)

local data = {}
local sort = {
    typeId = 1001
}
local expandedSectors = {}

local config = {

    mode = "sectorlist",

    buySellOffersCount = uiScale > 1.3 and 5 or 8, -- limit buy/sell offers for bigger UI scales

    icons = {
        playerhq = { icon = "mapob_playerhq", text = ReadText(20102, 2011), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "playercolor" },
        factionhq = { icon = "maplegend_hq_01", text = ReadText(1001, 9808), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        shipyard = { icon = "mapob_shipyard", text = ReadText(1001, 92), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        wharf = { icon = "mapob_wharf", text = ReadText(1001, 9805), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        equipmentdock = { icon = "mapob_equipmentdock", text = ReadText(1001, 9804), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        tradestation = { icon = "mapob_tradestation", text = ReadText(1001, 9803), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        defensestation = { icon = "mapob_defensestation", text = ReadText(1001, 9802), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        freeport = { icon = "mapob_piratestation", text = ReadText(20102, 1511), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
        factory = { icon = "mapob_factory", text = ReadText(20102, 1001), width = 0.8 * Helper.sidebarWidth, height = 0.8 * Helper.sidebarWidth, color = "friendcolor" },
    },

    sortPropDropdownOptions = {
        { id = 1001, invert = true,  property = "name", text = ReadText(20811, 200), icon = "", displayremoveoption = false },
        { id = 1002, invert = true,  property = "ownershortname", text = ReadText(20811, 201), icon = "", displayremoveoption = false },
        { id = 1003, invert = false, property = "sunlight", text = ReadText(20811, 202), icon = "", displayremoveoption = false },
        { id = 1004, invert = false, property = "knownStations", text = ReadText(20811, 203), icon = "", displayremoveoption = false },
        { id = 1005, invert = false, property = "population", text = ReadText(20811, 204), icon = "", displayremoveoption = false },
        { id = 1006, invert = false, property = "stationWorkforce", text = ReadText(20811, 205), icon = "", displayremoveoption = false },
    },

    sortResDropdownOptions = {
        { id = 2001, invert = false, resource = "helium", text = ReadText(20811, 250), icon = "", displayremoveoption = false },
        { id = 2002, invert = false, resource = "hydrogen", text = ReadText(20811, 251), icon = "", displayremoveoption = false },
        { id = 2003, invert = false, resource = "ice", text = ReadText(20811, 252), icon = "", displayremoveoption = false },
        { id = 2004, invert = false, resource = "methane", text = ReadText(20811, 253), icon = "", displayremoveoption = false },
        { id = 2005, invert = false, resource = "nividium", text = ReadText(20811, 254), icon = "", displayremoveoption = false },
        { id = 2006, invert = false, resource = "ore", text = ReadText(20811, 255), icon = "", displayremoveoption = false },
        { id = 2008, invert = false, resource = "rawscrap", text = ReadText(20811, 257), icon = "", displayremoveoption = false },
        { id = 2007, invert = false, resource = "silicon", text = ReadText(20811, 256), icon = "", displayremoveoption = false },
    },

    settingsTable = {
        columnsNumber = 5,
    },

    sectorsTable = {
        columnsNumber = 8,
        descriptionLines = 4,
    },

    sortHederProperties = {
        font = Helper.standardFontMono,
        fontsize = 9,
        height = 20,
        y = Helper.scaleY(4),
        scaling = true,
        color = { r = 180, g = 180, b = 180, a = 100 },
    },

    textProperties = {
        font = Helper.standardFontMono,
        fontsize = 9,
        scaling = true,
        color = Helper.color.white,
        y = 6,
    },

    headerRowProperties = {
        bgColor = Helper.color.semitransparent,
    },

    rowTextProperties = {
        font = Helper.standardFontMono,
        fontsize = 9,
        scaling = true,
    },

    headerRowCenteredProperties = {
        font = Helper.standardFontMono,
        fontsize = 9,
        scaling = true,
        y = Helper.scaleY(7),
        halign = "center",
        titleColor = Helper.defaultSimpleBackgroundColor,
    },

    factionShortTextProperties = {
        font = Helper.standardFontMono,
        fontsize = 9,
        scaling = true,
        halign = "right",
        y = 6,
    },

    descriptionTextProperties = {
        font = Helper.standardFontMono,
        fontsize = 8,
        scaling = true,
        color = { r = 180, g = 180, b = 180, a = 100 },
    }
}

local function init ()
    msl.debugText("INIT")

    mapMenu = Helper.getMenu("MapMenu")

    mapMenu.registerCallback("ic_onSelectElement", msl.onSelectElement)
    mapMenu.registerCallback("ic_onRowChanged", msl.onRowChanged)
    mapMenu.registerCallback("createRightBar_on_start", msl.createRightBar)
    mapMenu.registerCallback("createInfoFrame2_on_menu_infoModeRight", msl.createInfoFrame2_on_menu_infoModeRight)
    mapMenu.registerCallback("refreshInfoFrame2_on_start", msl.refreshInfoFrame2_on_start)
end

function msl.createRightBar(globalConfig)
    msl.debugText("Creating right bar")

    local isMapSectorListExists
    for _, rightBarEntry in ipairs(globalConfig.rightBar) do
        if rightBarEntry.mode == config.mode then
            isMapSectorListExists = true
        end
    end
    if not isMapSectorListExists then
        local entry = {
            name = ReadText(20811, 100), -- sector list
            icon = "mapst_sectorlist",
            mode = config.mode,
        }
        table.insert(globalConfig.rightBar, { spacing = true })
        table.insert(globalConfig.rightBar, 3, entry)
        msl.debugText("Creating icon")
    end

    mapMenu.prepareEconomyWares()
end

function msl.refreshInfoFrame2_on_start()
    if not mapMenu.createInfoFrame2Running then
        if mapMenu.infoTableRight2 then
            mapMenu.topRows.infotable2right = mapMenu.topRows.infotable2right or GetTopRow(mapMenu.infoTableRight2)
            mapMenu.selectedRows.infotable2right = mapMenu.selectedRows.infotable2right or Helper.currentTableRow[mapMenu.infoTableRight2]
        end
    end
end

function msl.createInfoFrame2_on_menu_infoModeRight (infoFrame2)

    if mapMenu.searchTableMode == config.mode then

        if (shouldUpdate) then
            msl.debugText("Providing data")
            data = dataProvider.prepareData()
            updatedAt = C.GetCurrentGameTime()
            shouldUpdate = false
        end

        msl.debugText("Drawing MSL", mapMenu.searchTableMode)

        -- settings table
        local settingsTable = infoFrame2:addTable(config.settingsTable.columnsNumber, { tabOrder = 1, highlightMode = "off", skipTabChange = true, multiSelect = false, backgroundID = "solid", backgroundColor = Helper.color.semitransparent, reserveScrollBar = false })
        settingsTable:setColWidthMinPercent(1, 22)
        settingsTable:setColWidthMinPercent(2, 22)
        settingsTable:setColWidthMinPercent(3, 22)
        settingsTable:setColWidthMinPercent(4, 19)
        settingsTable:setColWidth(5, Helper.scaleY(20))
        settingsTable:setDefaultCellProperties("dropdown", { height = 20 })

        local row = settingsTable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
        row[1]:setColSpan(config.settingsTable.columnsNumber):createText(ReadText(20811, 101), Helper.headerRowCenteredProperties) -- Sort settings

        -- last updated time and button
        row = settingsTable:addRow(true, { bgColor = Helper.defaultTitleBackgroundColor })
        local lastUpdatedTextProperties = msl.shallowCopy(config.sortHederProperties)
        lastUpdatedTextProperties.color = { r = 140, g = 140, b = 140, a = 100 }
        lastUpdatedTextProperties.halign = "right"
        row[1]:setColSpan(3):createText(ReadText(20811, 150), lastUpdatedTextProperties) -- last updated

        local lastUpdatedTimeProperties = msl.shallowCopy(config.sortHederProperties)
        lastUpdatedTimeProperties.color = { r = 140, g = 140, b = 140, a = 100 }
        local timeUpdatedText = msl.getTimeUpdatedText()
        row[4]:createText(timeUpdatedText .. " " .. ReadText(20811, 151), lastUpdatedTimeProperties)
        row[5]:createButton({ height = Helper.scaleY(config.sortHederProperties.height), mouseOverText = ReadText(20811, 141) }):setIcon("msl_update", { })
        row[5].handlers.onClick = function()
            msl.refreshData()
        end

        row = settingsTable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
        row[1]:createText(ReadText(20811, 111), config.sortHederProperties) -- by property
        row[2]:createText(ReadText(20811, 112), config.sortHederProperties) -- by resource
        row[3]:createText(ReadText(20811, 113), config.sortHederProperties) -- by buy offers
        row[4]:setColSpan(2):createText(ReadText(20811, 114), config.sortHederProperties) -- by sell offers

        -- dropdown
        row = settingsTable:addRow("dropdown_elements")

        row[1]:createDropDown(config.sortPropDropdownOptions, { startOption = sort.typeId })
        row[1].handlers.onDropDownActivated = function()
            mapMenu.noupdate = true
        end
        row[1].handlers.onDropDownConfirmed = function(_, id)
            return msl.onPropDropDownConfirmed(id, config.sortPropDropdownOptions)
        end

        row[2]:createDropDown(config.sortResDropdownOptions, { startOption = sort.typeId })
        row[2].handlers.onDropDownActivated = function()
            mapMenu.noupdate = true
        end
        row[2].handlers.onDropDownConfirmed = function(_, id)
            return msl.onResDropDownConfirmed(id, config.sortResDropdownOptions)
        end

        -- buy dropdown
        local buyDropdownOptions = {}
        for name, ware in pairs(mapMenu.economyWares) do
            table.insert(buyDropdownOptions,
                    { id = "buy:" .. ware, ware = ware, text = name, invert = false, icon = "", displayremoveoption = false }
            )
        end

        table.sort(buyDropdownOptions, function(a, b)
            return msl.propertySorter(a, b, 'text', true)
        end)

        row[3]:createDropDown(buyDropdownOptions, { startOption = sort.typeId })
        row[3].handlers.onDropDownActivated = function()
            mapMenu.noupdate = true
        end
        row[3].handlers.onDropDownConfirmed = function(_, id)
            return msl.onBuySellDropDownConfirmed(id, buyDropdownOptions, 'offersBuy')
        end

        -- sell dropdown
        local sellDropdownOptions = {}
        for name, ware in pairs(mapMenu.economyWares) do
            table.insert(sellDropdownOptions,
                    { id = "sell:" .. ware, ware = ware, text = name, invert = false, icon = "", displayremoveoption = false }
            )
        end

        table.sort(sellDropdownOptions, function(a, b)
            return msl.propertySorter(a, b, 'text', true)
        end)

        row[4]:setColSpan(2):createDropDown(sellDropdownOptions, { startOption = sort.typeId })
        row[4].handlers.onDropDownActivated = function()
            mapMenu.noupdate = true
        end
        row[4].handlers.onDropDownConfirmed = function(_, id)
            return msl.onBuySellDropDownConfirmed(id, sellDropdownOptions, 'offersSell')
        end

        -- sector list header
        row = settingsTable:addRow(false, { bgColor = Helper.defaultTitleBackgroundColor })
        row[1]:setColSpan(config.settingsTable.columnsNumber):createText(ReadText(20811, 102), Helper.headerRowCenteredProperties) -- Sector list


        -- sectors table
        local sectorsTable = infoFrame2:addTable(config.sectorsTable.columnsNumber, {
            tabOrder = 2,
            borderEnabled = true,
            backgroundID = "solid",
            backgroundColor = Helper.color.semitransparent,
            y = settingsTable.properties.y + settingsTable:getVisibleHeight() + Helper.borderSize,
            reserveScrollBar = true
        })
        sectorsTable:setColWidth(1, Helper.scaleX(20), false) -- expand btn
        sectorsTable:setColWidth(2, Helper.scaleX(50), false) -- faction name
        sectorsTable:setColWidthMinPercent(3, Helper.scaleX(11), false)
        sectorsTable:setColWidthMinPercent(4, Helper.scaleX(7), false) -- buy value
        sectorsTable:setColWidthMinPercent(5, Helper.scaleX(5), false)
        sectorsTable:setColWidthMinPercent(6, Helper.scaleX(6), false) -- station icons
        sectorsTable:setColWidthMinPercent(7, Helper.scaleX(6), false) -- sell value
        sectorsTable:setColWidth(8, Helper.scaleX(30), false) -- center sector button
        sectorsTable:setDefaultBackgroundColSpan(1, 8)

        for _, sector in ipairs(data) do
            local sectorComponent = ConvertStringTo64Bit(tostring(sector.component))

            row = sectorsTable:addRow(sectorComponent, { bgColor = Helper.color.transparent, borderBelow = false, interactive = true })
            local isSectorExpanded = msl.isSectorExpanded(tostring(sectorComponent))

            row[1]:createButton({ height = 25, bgColor = Helper.color.semitransparent }):setText(isSectorExpanded and "-" or "+", {
                halign = "center",
            })
            row[1].handlers.onClick = function()
                return msl.buttonExpandSector(tostring(sectorComponent))
            end

            local factionShortTextProperties = msl.shallowCopy(config.factionShortTextProperties)
            factionShortTextProperties.color = sector.ownercolor

            -- sector owner
            row[2]:createText("[" .. tostring(sector.ownershortname) .. "] ", factionShortTextProperties)

            -- sector name
            local textProperties = msl.shallowCopy(config.textProperties)
            if (disabledSectors[sector]) then
                textProperties.color = { r = 180, g = 180, b = 180, a = 20 }
            end
            row[3]:setColSpan(3):createText(tostring(sector.name), textProperties)

            local stationIcons = ""
            if sector.hasshipyard then
                stationIcons = msl.addIcon(stationIcons, config.icons.shipyard.icon)
            end
            if sector.haswharf then
                stationIcons = msl.addIcon(stationIcons, config.icons.wharf.icon)
            end
            if sector.hasequipmentdock then
                stationIcons = msl.addIcon(stationIcons, config.icons.equipmentdock.icon)
            end
            if sector.hasplayerhq then
                stationIcons = msl.addIcon(stationIcons, config.icons.playerhq.icon)
            end
            if sector.hasfactionhq then
                stationIcons = msl.addIcon(stationIcons, config.icons.factionhq.icon)
            end
            row[6]:setColSpan(3):createText(stationIcons, { halign = "right", fontsize = 15, height = 15, titleColor = Helper.color.semitransparent })

            -- center map on sector button
            --[[row[8]:createButton({ y = Helper.scaleY(3), width = Helper.scaleX(10), mouseOverText = string.format(ReadText(20811, 142), ffi.string(sector.name)) }):setIcon("menu_center_selection", {
                y = 8,
            })
            row[8].handlers.onClick = function()
                return msl.centerOnSector(sectorComponent)
            end]]

            if (isSectorExpanded) then
                sectorsTable:addEmptyRow(5)

                -- sector image
                row = sectorsTable:addRow(false, { bgColor = Helper.color.black })
                if (sector.image ~= '') then
                    row[2]:setColSpan(7):createIcon(sector.image, { height = Helper.scaleY(100), x = 6, scaling = true })
                end

                -- description
                local width = sectorsTable.properties.width - 10
                local description = GetTextLines(sector.description, Helper.standardFont, Helper.scaleFont(Helper.standardFont, Helper.standardFontSize), width)

                sectorsTable:addEmptyRow(10)

                for linenum, descline in ipairs(description) do
                    if (linenum > config.sectorsTable.descriptionLines) then
                        row = sectorsTable:addRow(false, { bgColor = Helper.color.semitransparent, borderBelow = false })
                        row[2]:setColSpan(6):createText(descline:sub(1, -10) .. "(...)", config.descriptionTextProperties)
                        break
                    end

                    row = sectorsTable:addRow(false, { bgColor = Helper.color.semitransparent, borderBelow = false })
                    row[2]:setColSpan(7):createText(descline, config.descriptionTextProperties)
                end

                row = sectorsTable:addRow(true, { bgColor = Helper.color.semitransparent, borderBelow = false })
                -- encyclopedia entry button
                row[6]:setColSpan(3):createButton({ y = 10 }):setText(ReadText(20811, 120), {
                    halign = "center",
                    fontsize = 8,
                    scaling = true,
                })
                row[6].handlers.onClick = function()
                    Helper.closeMenuAndOpenNewMenu(mapMenu, "EncyclopediaMenu", { 0, 0, "Galaxy", "", nil, ConvertStringToLuaID(tostring(sectorComponent)) });
                    mapMenu.cleanup()
                end

                sectorsTable:addEmptyRow(5)

                -- properties
                row = sectorsTable:addRow(false, config.headerRowProperties)
                row[2]:setColSpan(config.sectorsTable.columnsNumber - 1):createText(ReadText(20811, 130), config.headerRowCenteredProperties)

                -- owner
                msl.addSubRow(sectorsTable, ReadText(1001, 9040), sector.ownername)

                -- population
                msl.addSubRow(sectorsTable, ReadText(1001, 9041), ConvertIntegerString(tonumber(sector.population), true, 3, true))

                -- workforce Availability Bonus
                msl.addSubRow(sectorsTable, ReadText(1001, 11296), string.format("%+.0f%%", (sector.workforceAvailabilityBonus * 100)))

                -- station Workforce
                msl.addSubRow(sectorsTable, ReadText(1001, 2456), ConvertIntegerString(sector.stationWorkforce, true, 3, true))

                -- known Stations
                msl.addSubRow(sectorsTable, ReadText(1001, 9042), sector.knownStations)

                -- main Production
                msl.addSubRow(sectorsTable, ReadText(1001, 9050), sector.mainProduction)


                -- natural resources
                row = sectorsTable:addRow(false, config.headerRowProperties)
                row[2]:setColSpan(config.sectorsTable.columnsNumber - 1):createText(ReadText(20811, 131), config.headerRowCenteredProperties) -- Natural Resources

                -- Sunlight
                msl.addSubRow(sectorsTable, ReadText(1001, 2412), sector.sunlight .. "%")

                for _, resourceEntry in ipairs(sector.resources) do
                    msl.addSubRow(sectorsTable, resourceEntry.name, ConvertIntegerString(resourceEntry.current, true, 3, true))
                end

                -- Best Buy / Sell
                row = sectorsTable:addRow(false, config.headerRowProperties)
                row[2]:setColSpan(3):createText(string.format(ReadText(20811, 132), config.buySellOffersCount), config.headerRowCenteredProperties)
                row[5]:setColSpan(4):createText(string.format(ReadText(20811, 133), config.buySellOffersCount), config.headerRowCenteredProperties)

                local textRight = msl.shallowCopy(config.rowTextProperties)
                textRight.halign = "right"

                local maxEntries = math.max(#sector.offersBuy, #sector.offersSell)
                local currentOfferCount = {
                    buy = 0,
                    sell = 0,
                }
                for i = 1, maxEntries, 1 do
                    row = sectorsTable:addRow(false, {
                        bgColor = Helper.color.unselectable,
                    })

                    row[1]:createText(" ", { cellBGColor = Helper.color.semitransparent })

                    if (sector.offersBuy[i] and currentOfferCount.buy < config.buySellOffersCount) then
                        currentOfferCount.buy = currentOfferCount.buy +1
                        row[2]:setColSpan(2):createText(sector.offersBuy[i].name, config.rowTextProperties)
                        row[4]:createText(ConvertIntegerString(sector.offersBuy[i].current, true, 3, true), textRight)
                    end

                    if (sector.offersSell[i] and currentOfferCount.sell < config.buySellOffersCount) then
                        currentOfferCount.sell = currentOfferCount.sell +1
                        row[5]:setColSpan(2):createText(sector.offersSell[i].name, config.rowTextProperties)
                        row[7]:setColSpan(2):createText(ConvertIntegerString(sector.offersSell[i].current, true, 3, true), textRight)
                    end

                    if (currentOfferCount.buy >= config.buySellOffersCount or currentOfferCount.sell >= config.buySellOffersCount) then
                        break
                    end
                end

                sectorsTable:addEmptyRow(10)
            end
        end

        if mapMenu.selectedRows["infotable2right"] then
            sectorsTable:setSelectedRow(mapMenu.selectedRows["infotable2right"])
            mapMenu.selectedRows["infotable2right"] = nil
            if mapMenu.topRows["infotable2right"] then
                sectorsTable:setTopRow(mapMenu.topRows["infotable2right"])
                mapMenu.topRows["infotable2right"] = nil
            end
        end
    end

    return nil
end

function msl.refreshData()
    shouldUpdate = true
    sort = {
        typeId = 1001
    }
    msl.resetStates()
end

function msl.getTimeUpdatedText()
    local minute = 60
    local unit = ReadText(20811, 152)
    local time = C.GetCurrentGameTime() - updatedAt
    if (time > minute) then
        unit = ReadText(20811, 153)
        time = time / minute
    end
    return string.format("%d", time) .. unit
end

function msl.addIcon(iconsString, icon)
    iconsString = iconsString .. " \27[" .. icon .. "]"
    return iconsString
end

function msl.onPropDropDownConfirmed(id, options)
    disabledSectors = {}
    sort.typeId = id

    for _, option in ipairs(options) do
        if (tostring(option.id) == id) then
            table.sort(data, function(a, b)
                return msl.propertySorter(a, b, option.property, option.invert)
            end)
        end
    end
    msl.resetStates()
end

function msl.onResDropDownConfirmed(id, options)
    disabledSectors = {}
    sort.typeId = id

    for _, option in ipairs(options) do
        if (tostring(option.id) == id) then
            table.sort(data, function(a, b)
                return msl.resourceSorter(a, b, option.resource, option.invert)
            end)
        end
    end
    msl.resetStates()
end

function msl.onBuySellDropDownConfirmed(id, options, type)
    disabledSectors = {}
    sort.typeId = id

    for _, option in ipairs(options) do
        if (tostring(option.id) == id) then
            table.sort(data, function(a, b)
                return msl.buySellOfferSorter(a, b, type, option.ware, option.invert)
            end)
        end
    end
    msl.resetStates()
end

function msl.propertySorter(sectorA, sectorB, propertyName, invert)
    local lastSortString = "zzz"
    local ax = sectorA[propertyName]
    local bx = sectorB[propertyName]

    if (ax == "" or ax=="------") then
        ax = lastSortString
    end
    if (bx == "" or bx=="------") then
        bx = lastSortString
    end

    if (ax == 0 or ax == lastSortString) then
        disabledSectors[sectorA] = true
    end
    if (bx == 0 or bx == lastSortString) then
        disabledSectors[sectorB] = true
    end

    if sectorA.name and sectorB.name and ax == bx then
        return Helper.sortName(sectorA, sectorB)
    end

    if (invert) then
        return ax < bx
    else
        return ax > bx
    end
end

function msl.buySellOfferSorter(sectorA, sectorB, type, resourceName, invert)
    local ax = 0
    local bx = 0

    for _, resource in ipairs(sectorA[type]) do
        if (resource.ware == resourceName) then
            ax = resource.current
        end
    end

    for _, resource in ipairs(sectorB[type]) do
        if (resource.ware == resourceName) then
            bx = resource.current
        end
    end

    if (ax == 0) then
        disabledSectors[sectorA] = true
    end
    if (bx == 0) then
        disabledSectors[sectorB] = true
    end

    if ax == bx then
        return Helper.sortName(sectorA, sectorB)
    end

    if (invert) then
        return ax < bx
    else
        return ax > bx
    end
end

function msl.resourceSorter(sectorA, sectorB, resourceWare, invert)

    local ax = 0
    local bx = 0

    for _, resource in ipairs(sectorA.resources) do
        if (resource.ware == resourceWare) then
            ax = resource.current
        end
    end

    for _, resource in ipairs(sectorB.resources) do
        if (resource.ware == resourceWare) then
            bx = resource.current
        end
    end

    if (ax == 0) then
        disabledSectors[sectorA] = true
    end
    if (bx == 0) then
        disabledSectors[sectorB] = true
    end

    if ax == bx then
        return Helper.sortName(sectorA, sectorB)
    end

    if (invert) then
        return ax < bx
    else
        return ax > bx
    end
end

function msl.centerOnSector(sectorComponent)
    C.SetFocusMapComponent(mapMenu.holomap, sectorComponent, true)
end

function msl.isSectorExpanded(sector)
    return expandedSectors[sector] == true
end

function msl.buttonExpandSector(sector)
    if (expandedSectors[sector] == nil) then
        expandedSectors[sector] = false
    end

    expandedSectors[sector] = not expandedSectors[sector]

    mapMenu.refreshInfoFrame2()
end

function msl.resetStates()
    expandedSectors = {}
    mapMenu.topRows.infotable2right = 1
    mapMenu.selectedRows.infotable2right = 1
    mapMenu.noupdate = false
    mapMenu.refreshInfoFrame2()
end

function msl.onSelectElement(uitable, modified, row, isdblclick, input)
    local rowdata = Helper.getCurrentRowData(mapMenu, uitable)
    if (uitable == mapMenu.infoTableRight2 and isdblclick and type(rowdata) == 'number') then
        C.SetFocusMapComponent(mapMenu.holomap, rowdata, true)
    end
end

function msl.onRowChanged(row, rowdata, uitable, modified, input, source)
    if mapMenu.searchTableMode == config.mode then
        mapMenu.noupdate = false
    end
end

function msl.addSubRow(uitable, dataleft, dataright)
    row = uitable:addRow(false, {
        bgColor = Helper.color.unselectable,
    })

    row[1]:createText(" ", { cellBGColor = Helper.color.semitransparent })

    row[2]:setColSpan(3):createText(dataleft, config.rowTextProperties)

    local textRight = msl.shallowCopy(config.rowTextProperties)
    textRight.halign = "right"
    row[5]:setColSpan(4):createText(dataright, textRight)
end

function msl.shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function msl.debugText(title, text)
    if (isDebug) then
        DebugError("msl.lua: " .. title .. ": " .. tostring(text))
    end
end

init()

