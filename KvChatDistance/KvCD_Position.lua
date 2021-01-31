-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local strsplit = _G["strsplit"]
local time = _G["time"]
local C_Map = _G["C_Map"]
local UnitPosition = _G["UnitPosition"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================

KvChatDistance.position = {}

-- --------------------------------------------------------------------------------------------------------------------
-- Position Info Cache by UnitName
-- --------------------------------------------------------
KvChatDistance.unitPositionCache = {}

function KvChatDistance:PositionStoreUnitInfo(unitName, posY, posX, posZ, mapID)
    local curTime = time()
    unitName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)

    KvChatDistance:Debug3("PositionStoreUnitInfo", unitName, posY, posX, posZ, mapID)

    if not self.unitPositionCache[unitName] then
        self.unitPositionCache[unitName] = {y=posY, x=posX, z=posZ, mapID=mapID, time=curTime}
    else
        self.unitPositionCache[unitName].y = posY
        self.unitPositionCache[unitName].x = posX
        self.unitPositionCache[unitName].z = posZ
        self.unitPositionCache[unitName].mapID = mapID
        self.unitPositionCache[unitName].time = curTime
    end
end

function KvChatDistance:PositionDeleteUnitInfo(unitName)
    self.unitPositionCache[unitName] = nil
end

function KvChatDistance:PositionGetUnitInfo(unitName)
    local posData = self.unitPositionCache[unitName]
    if not posData then
        unitName = strsplit("-", unitName)
    end
    posData = self.unitPositionCache[unitName]
    if posData then
        return posData.y, posData.x, posData.z, posData.mapID
    end
end

function KvChatDistance.PositionUpdateCache()
    local settings = KvChatDistance:GetSettings()
    local curTime = time()
    KvChatDistance:Debug4("PositionUpdateCache")

    for unitName, positionData in pairs(KvChatDistance.unitPositionCache) do
        local positionTime = positionData.time

        KvChatDistance:Debug4("PositionUpdateCache", unitName, positionData)

        -- If position data for player has expired by TTL
        if not positionTime or (positionTime + settings.positionCacheTTL) < curTime then

            -- If unitName isn't a registered player and we're unable to get a unit/nameplate for them, evict from cache
            if not KvChatDistance:CommsIsPlayerRegistered(unitName) then
                local unitID = KvChatDistance.GetViableUnitIDForName(unitName)
                if not unitID then
                    KvChatDistance:Debug4("Evicting from Position cache:", unitName)
                    KvChatDistance:PositionDeleteUnitInfo(unitName)
                end
            else
                -- Query known player for position?
                KvChatDistance:Debug3("PositionUpdateCache", "Requesting position from:", unitName)
                KvChatDistance:CommsRequestPosition(unitName)
            end
        end

    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Triangulation
-- --------------------------------------------------------
-- TODO

-- --------------------------------------------------------------------------------------------------------------------
-- Ticker
-- --------------------------------------------------------
function KvChatDistance.PositionTickerFunc()
    local settings = KvChatDistance:GetSettings()
    if not settings.positionBroadcastEnabled then return end

    KvChatDistance:Debug4("PositionTickerFunc")

    local knownPlayers = KvChatDistance:CommsGetRegisteredPlayers()
    for playerName, playerData in pairs(knownPlayers) do
        -- KvChatDistance:Debug3("PositionTickerFunc", "knownPlayers", playerName, playerData)

        if playerData.addonUser and playerData.compatible then
            KvChatDistance:CommsRequestPosition(playerName, "WHISPER")
        end
    end

    -- TODO: Broadcast to a custom channel?
end

-- --------------------------------------------------------------------------------------------------------------------
-- Broadcast
-- --------------------------------------------------------

function KvChatDistance:PositionGetCurrent(unitID)
    if not unitID then unitID = "player" end
    local posY, posX, posZ, instanceID = UnitPosition(unitID)
    local mapID = C_Map.GetBestMapForUnit(unitID)
    -- local zoneName = GetZoneText()
    posY = KvChatDistance.RoundNumber(posY, 1)
    posX = KvChatDistance.RoundNumber(posX, 1)
    posZ = KvChatDistance.RoundNumber(posZ, 1)
    return posY, posX, posZ, mapID
end
