local ffi = require("ffi")
local C = ffi.C

MSLDataProvider = {}

function MSLDataProvider.prepareData()
    local curtime = C.GetCurrentGameTime()

    -- Galaxy
    local output = {}

    local clusters = GetClusters(true)
    local sectorsList = {}
    for _, cluster in ipairs(clusters) do
        local name, description, systemid = GetComponentData(cluster, "name", "description", "systemid")
        local sectors = GetSectors(cluster)
        for i, sector in ipairs(sectors) do
            table.insert(sectorsList, sector)
        end
    end

    for _, sector in ipairs(sectorsList) do

        local entry = {}
        local sectorComponent = ConvertStringTo64Bit(tostring(sector))

        entry.image, entry.description, entry.ownericon = GetComponentData(sectorComponent, "image", "description", "ownericon")

        entry.component = sector
        entry.name = GetComponentData(sector, "name")

        local owner, ownername = GetComponentData(sectorComponent, "owner", "ownername")
        if C.IsContestedSector(sectorComponent) then
            ownername = ownername .. " " .. ReadText(1001, 3247)
        end

        entry.ownershortname = GetFactionData(owner, "shortname")
        if (owner == 'ownerless') then
            entry.ownershortname = "------"
        end

        local ownerinfo = C.IsInfoUnlockedForPlayer(sectorComponent, "owner")
        entry.ownername = Helper.unlockInfo(ownerinfo, ownername);
        entry.ownercolor = GetFactionData(owner, "color")
        entry.isshipyard, entry.iswharf, entry.isequipmentdock = false

        -- representative
        local factionrep = ConvertStringTo64Bit(tostring(C.GetFactionRepresentative(owner)))

        -- HQ
        local hqlist = {}
        Helper.ffiVLA(hqlist, "UniverseID", C.GetNumHQs, C.GetHQs, owner)
        if #hqlist > 0 then
            factionhqsector = GetComponentData(ConvertStringTo64Bit(tostring(hqlist[1])), "sectorid")
        end

        entry.hasfactionhq = false
        if (tostring(factionhqsector) == tostring(sector)) then
            entry.hasfactionhq = true
        end

        local stationtable = GetContainedStations(sectorComponent, true)
        local numstations = #stationtable
        local productiontable = {}
        local products = {}
        local sectorpopulation = 0
        for _, station in ipairs(stationtable) do
            local workforceinfo = C.GetWorkForceInfo(ConvertStringTo64Bit(tostring(station)), "")
            sectorpopulation = sectorpopulation + workforceinfo.current
            table.insert(productiontable, GetComponentData(station, "products"))

            local convertedStation = ConvertStringTo64Bit(tostring(station))
            local isshipyard, iswharf, isequipmentdock = GetComponentData(convertedStation, "isshipyard", "iswharf", "isequipmentdock")
            local hasplayerhq = C.IsHQ(convertedStation)
            if isshipyard then
                entry.hasshipyard = true
            end
            if iswharf then
                entry.haswharf = true
            end
            if isequipmentdock then
                entry.hasequipmentdock = true
            end
            if hasplayerhq then
                entry.hasplayerhq = true
            end

        end
        for _, element in ipairs(productiontable) do
            for _, product in ipairs(element) do
                local notincremented = true
                for compproduct, count in pairs(products) do
                    if compproduct == product then
                        products[product] = count + 1
                        notincremented = false
                        break
                    end
                end
                if notincremented then
                    products[product] = 1
                end
            end
        end
        local maxproductgrp = ReadText(1001, 9002)    -- Unknown
        local maxcount = 0
        for product, count in pairs(products) do
            if not maxproductgrp or (count > maxcount) then
                maxproductgrp = GetWareData(product, "groupName")
                maxcount = count
            end
        end

        entry.population = C.GetSectorPopulation(sectorComponent)
        entry.workforceAvailabilityBonus = GetComponentData(sectorComponent, "populationworkforcefactor")
        entry.stationWorkforce = sectorpopulation
        entry.knownStations = (numstations > 0 and numstations or 0)
        entry.mainProduction = maxproductgrp

        -- natural resources
        local sunlight = GetComponentData(sectorComponent, "sunlight") * 100
        entry.sunlight = sunlight

        -- resources
        local resources = {}
        local n = C.GetNumDiscoveredSectorResources(sectorComponent)
        local buf = ffi.new("WareYield[?]", n)
        n = C.GetDiscoveredSectorResources(buf, n, sectorComponent)
        for i = 0, n - 1 do
            local ware = ffi.string(buf[i].ware)
            local name = GetWareData(ware, "name")
            table.insert(resources, { ware = ware, name = name, component = component, current = buf[i].current, max = buf[i].max })
        end
        table.sort(resources, Helper.sortName)

        entry.resources = {}

        for _, resource in ipairs(resources) do
            table.insert(entry.resources, {
                ware = resource.ware,
                name = resource.name,
                current = resource.current,
            })
        end

        entry.offers = {}

        -- highest buy/sell
        local offersData = {}
        local buyDataWeights = {}
        local sellDataWeights = {}
        local ffiHelper = {}

        local numdatapoints = 2;

        local xStart = math.max(0, curtime - 10)
        local xEnd = curtime

        local numstats = C.GetNumTradeOfferStatistics(ConvertIDTo64Bit(sectorComponent), xStart, xEnd, numdatapoints)
        if numstats > 0 then
            local result = ffi.new("UITradeOfferStat[?]", numstats)
            for i = 0, numstats - 1 do
                table.insert(ffiHelper, 1, ffi.new("UITradeOfferStatData[?]", numdatapoints))
                result[i].data = ffiHelper[1]
            end
            numstats = C.GetTradeOfferStatistics(result, numstats, numdatapoints)

            for i = 0, numstats - 1 do
                local ware = ffi.string(result[i].wareid)
                local text = GetWareData(ware, "name")

                local dataIdx = getDataIdxByWare(ware, offersData)
                if not dataIdx then
                    table.insert(offersData, { text = text, ware = ware, selldata = {}, buydata = {} })
                    dataIdx = #offersData

                end
                buyDataWeights[dataIdx] = buyDataWeights[dataIdx] or { ware = ware, dataIdx = dataIdx, count = 0, amount = 0 }
                sellDataWeights[dataIdx] = sellDataWeights[dataIdx] or { ware = ware, dataIdx = dataIdx, count = 0, amount = 0 }

                for j = 0, result[i].numdata - 1 do
                    local y = tonumber(result[i].data[j].amount)
                    if result[i].isSellOffer then
                        sellDataWeights[dataIdx].amount = y
                    else
                        buyDataWeights[dataIdx].amount = y
                    end
                end
            end
        end

        table.sort(buyDataWeights, function(a, b)
            return a.amount > b.amount
        end)
        table.sort(sellDataWeights, function(a, b)
            return a.amount > b.amount
        end)

        entry.offersBuy = {}
        for _, buyDataWeight in ipairs(buyDataWeights) do
            if buyDataWeight and (buyDataWeight.amount > 0) then
                --if (buyDataWeight.amount < config.minOffersAmount and _ > config.minOffersCount) then break end

                local offerWareName = GetWareData(buyDataWeight.ware, "name")
                local offerWareAmount = buyDataWeight.amount
                table.insert(entry.offersBuy, {
                    name = offerWareName,
                    ware = buyDataWeight.ware,
                    current = offerWareAmount
                })
            end
        end

        entry.offersSell = {}
        for _, sellDataWeight in ipairs(sellDataWeights) do
            if sellDataWeight and (sellDataWeight.amount > 0) then
                --if (sellDataWeight.amount < config.minOffersAmount and _ > config.minOffersCount) then break end

                local offerWareName = GetWareData(sellDataWeight.ware, "name")
                local offerWareAmount = sellDataWeight.amount
                table.insert(entry.offersSell, {
                    name = offerWareName,
                    ware = sellDataWeight.ware,
                    current = offerWareAmount
                })
            end
        end
        table.insert(output, entry)
    end

    return output
end

function getDataIdxByWare(ware, offersData)
    for i, data in ipairs(offersData) do
        if data.ware == ware then
            return i
        end
    end

    return nil
end