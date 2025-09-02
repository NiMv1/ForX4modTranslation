local bigLogString = ""
---Add to the debug string buffer and flush it if it reach max length
---@param str string to add
function AddToBigLogString(str)
    if #bigLogString + #str >= 8192 then
        DebugError(bigLogString)
        -- Restart the str.
        bigLogString = str
    else
        -- Append to running str.
        bigLogString = bigLogString .. str
    end
end
---A helper function to print a table's contents. Used internally, please use PrintTable instead
---@param tbl table @The table to print.
---@param depth number @The depth of sub-tables to traverse through and print.
---@param n number @Do NOT manually set this. This controls formatting through recursion.
function PrintTableRecurse(tbl, depth, n)
    n = n or 0;
    depth = depth or 3;
  
    if (depth == 0) then
        AddToBigLogString(string.rep(' ', n).."\"more\" : \"...\"");
        return;
    end
  
    if (n == 0) then
        AddToBigLogString(" ");
    end
    for key, value in pairs(tbl) do
        if (key and type(key) == "number" or type(key) == "string") then
            key = string.format("\"%s\"", key);
            if (type(value) == "table") then
                if (next(value)) then
                    AddToBigLogString(string.rep(' ', n)..key..": {");
                    PrintTableRecurse(value, depth - 1, n + 4);
                    AddToBigLogString(string.rep(' ', n).."},");
                else
                    AddToBigLogString(string.rep(' ', n)..key..": {},");
                end
            else
                if (type(value) == "string") then
                    value = string.format("%s", value);
                else
                    value = tostring(value);
                end
  
                AddToBigLogString(string.rep(' ', n)..key..": \""..value.."\",");
            end
        end
    end
  
    if (n == 0) then
        AddToBigLogString(" ");
    end
end
---A helper function to print a table's contents.
---@param tbl table @The table to print.
---@param depth number @The depth of sub-tables to traverse through and print.
function PrintTable(tbl, depth)
    if type(tbl) == "table" then
        depth = depth or 3;
        bigLogString = ""
        PrintTableRecurse(tbl,depth)
        DebugError(bigLogString)
        bigLogString=""
    else
        DebugError("PrintTable : The argument passed was not a table")
    end
end


-- Set up any used ffi functions.
local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
    typedef uint64_t UniverseID;
    typedef struct {
		size_t queueidx;
		const char* state;
		const char* statename;
		const char* orderdef;
		size_t actualparams;
		bool enabled;
		bool isinfinite;
		bool issyncpointreached;
		bool istemporder;
	} Order;
    bool GetDefaultOrder(Order* result, UniverseID controllableid);
]]
--GetOrderParams(order, paramindex)
--SetOrderParam(shipluaid, order(default or planneddefault), param, index, value)
--ConvertStringToLuaID()
local DebugMessage = "HJ CopyBehavior: "


function CopyParams(_,controllableid)
    local copiedOrder = ffi.new("Order") 
    if C.GetDefaultOrder(copiedOrder, controllableid) then
        local defaultorder = {}
        defaultorder.orderdef = ffi.string(copiedOrder.orderdef)
        local orderparams = GetOrderParams(controllableid, "default")
        local ships = GetNPCBlackboard (ConvertStringTo64Bit (tostring (C.GetPlayerID ())), "$hj_ordersData").ships

        --For each ship that copies the order
        for _, ship in ipairs(ships) do
            local shipid = ConvertStringTo64Bit(tostring(ship))

            C.RemoveAllOrders(shipid)
            C.ResetOrderLoop(shipid)
            --create a default order
            local orderindex = C.CreateOrder(shipid, defaultorder.orderdef, true)
            if orderindex == 0 then
                for i, par in ipairs(orderparams) do
                    if par.editable and (par.type ~= "internal")  then
                        if par.type == "list" then
                            for _,elem in ipairs(par.value) do
                                SetOrderParam(ConvertStringToLuaID(tostring(shipid)), "planneddefault", i, nil, elem)
                            end
                        else
                            SetOrderParam(ConvertStringToLuaID(tostring(shipid)), "planneddefault", i, nil, FormatValue(par))
                        end
                    end
                end
                C.EnablePlannedDefaultOrder(shipid, false)
            else
                DebugError(DebugMessage.."Could not create order. Index is "..tostring(orderindex))
            end
        end
    
    else
        DebugError(DebugMessage.."Couldnt find DefaultOrder for ship with controllableid "..tostring(controllableid))
    end
end

function FormatValue(inputvalue)
    local result = {}
    if inputvalue.type == "position" then
        DebugError(DebugMessage.."Found a position")
        result = {ConvertStringToLuaID(tostring(inputvalue.value[1])), {inputvalue.value[2].x, inputvalue.value[2].y,inputvalue.value[2].z}}
        return result
    elseif inputvalue.type == "list" then
        DebugError(DebugMessage.."Type of param is "..tostring(inputvalue.type))
        PrintTable(inputvalue)
        return inputvalue.value
    elseif inputvalue.type == "object" then
        DebugError(DebugMessage.."Type of param is "..tostring(inputvalue.type))
        PrintTable(inputvalue)
        return inputvalue.value
    elseif inputvalue.type == "bool" then
        return inputvalue.value
    else
        DebugError(DebugMessage.."Type of param is "..tostring(inputvalue.type))
        return inputvalue.value
    end
end

RegisterEvent("CopyBehavior.CopyParams", CopyParams)