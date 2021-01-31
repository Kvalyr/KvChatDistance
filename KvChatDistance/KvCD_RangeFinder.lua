-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local strsplit = _G["strsplit"]
local time = _G["time"]
local C_Map = _G["C_Map"]
local GetNumGroupMembers = _G["GetNumGroupMembers"]
local IsInRaid = _G["IsInRaid"]
local UnitIsEnemy = _G["UnitIsEnemy"]
local UnitIsUnit = _G["UnitIsUnit"]
local UnitName = _G["UnitName"]
local UnitPosition = _G["UnitPosition"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================
-- Interaction Range Indices:
-- 1,  -- 28 yds (achi)
-- 2,  -- 8 (trade)
-- 3,  -- 7 (duel)
-- 4,  -- 28 (follow)
-- 5,  -- 7 (???)
-- ====================================================================================================================
local numPartyMembers = 5
local numRaidMembers = 40
local nameplateMax = 60
local unitIDsToTest = {
    -- "player",
    "target",
    "focus",
    "mouseover",
    "partyN",
    "raidN",
    "nameplateN",
    -- "partypetN",
    -- "arenaN",
    -- "raidpetN",
    -- "bossN",
    -- "pet",
    -- "vehicle",
}

-- ====================================================================================================================


-- --------------------------------------------------------------------------------------------------------------------
-- Range Info by UnitName
-- --------------------------------------------------------
KvChatDistance.unitRangeCache = {}

function KvChatDistance:RangeStoreUnitInfo(unitName, minRange, maxRange)
    local curTime = time()
    unitName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)

    if not self.unitRangeCache[unitName] then
        self.unitRangeCache[unitName] = {min=minRange, max=maxRange, time=curTime}
    else
        self.unitRangeCache[unitName].min = minRange
        self.unitRangeCache[unitName].max = maxRange
        self.unitRangeCache[unitName].time = curTime
    end
end

function KvChatDistance:RangeDeleteUnitInfo(unitName)
    unitName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)
    self.unitRangeCache[unitName] = nil
end

function KvChatDistance:RangeGetUnitInfo(unitName)
    local rangeData = self.unitRangeCache[unitName]
    if not rangeData then
        unitName = strsplit("-", unitName)
    end
    rangeData = self.unitRangeCache[unitName]
    if rangeData then
        return rangeData.min, rangeData.max, rangeData.time
    end
end

function KvChatDistance.RangeUpdateCache()
    local settings = KvChatDistance:GetSettings()
    local curTime = time()

    for unitName, rangeData in pairs(KvChatDistance.unitRangeCache) do
        local rangeTime = rangeData.time

        -- If position data for player has expired by TTL
        if not rangeTime or (rangeTime + settings.rangeCacheTTL) < curTime then

            -- If unitName isn't a registered player and we're unable to get a unit/nameplate for them, evict from cache
            if not KvChatDistance:CommsIsPlayerRegistered(unitName) then
                local unitID = KvChatDistance.GetViableUnitIDForName(unitName)
                if not unitID then
                    KvChatDistance:Debug4("Evicting from Range cache:", unitName)
                    KvChatDistance:RangeDeleteUnitInfo(unitName)
                end
            else
                -- Query known player for position?
                KvChatDistance:CommsRequestRange(unitName)
            end
        end

    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Given a unitID, grab its range with librangecheck and cache that value
-- --------------------------------------------------------
function KvChatDistance:RangeCacheFromUnit(unitID)
    if not self.initDone then return end
    if not (unitID and not UnitIsUnit("player", unitID)) then return end

    local minRange, maxRange = self.rangeChecker:GetRange(unitID)
    local unitName = KvChatDistance.UnitNameWithRealm(unitID)
    if not unitName then return end

    -- KvChatDistance:Debug2("RangeCacheFromUnit", unitName, minRange, maxRange)

    self:RangeStoreUnitInfo(unitName, minRange, maxRange)
end

function KvChatDistance:RangeUncacheFromUnit(unitID)
    if not self.initDone then return end
    if not (unitID and not UnitIsUnit("player", unitID)) then return end

    local unitName = KvChatDistance.UnitNameWithRealm(unitID)
    if not unitName then return end

    self:RangeDeleteUnitInfo(unitName)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Walk target tree
-- --------------------------------------------------------
local function GetUnitIDFromTargets(unitID, unitName)
    local targetDepth = KvChatDistance:GetSettings().unitSearchTargetDepth
    for i=1, targetDepth do
        unitID = unitID.."target"
        if UnitName(unitID) == unitName then
            return unitID
        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Search N nameplates for a unitName
-- --------------------------------------------------------
function GetUnitIDFromN(unitName, unitBase, numToCheck)
    for i=1, numToCheck do
        local unitID = unitBase..i
        -- KLib:Con("KvChatDistance", "GetUnitIDFromN", "unitID:",  unitID)

        if UnitName(unitID) == unitName then
            return unitID
        end

        local unitIDFromTarget = GetUnitIDFromTargets(unitID, unitName)
        if unitIDFromTarget then
            return unitIDFromTarget
        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Cycle through relevant unitIDs to find one whose UnitName(unitID) matches the speaking unitName
-- --------------------------------------------------------
function KvChatDistance.GetViableUnitIDForName(unitName)
    for _, unitID in pairs(unitIDsToTest) do
        -- KLib:Con("KvChatDistance", "GetViableUnitIDForName", "unitName:", unitName, "unitID:",  unitID)

        if UnitName(unitID) == unitName then
            return unitID
        end

        if unitID == "nameplateN" then
            local unitIDFromNameplate = GetUnitIDFromN(unitName, "nameplate", nameplateMax)
            if unitIDFromNameplate then
                return unitIDFromNameplate
            end

        elseif unitID == "partyN" or unitID == "raidN" then
            local numGroupMembers = GetNumGroupMembers()
            if numGroupMembers > 0 then
                if unitID == "partyN" then
                    local unitIDFromNameplate = GetUnitIDFromN(unitName, "party", numPartyMembers)
                    if unitIDFromNameplate then
                        return unitIDFromNameplate
                    end
                elseif unitID == "raidN" and IsInRaid() then
                    local unitIDFromNameplate = GetUnitIDFromN(unitName, "raid", numRaidMembers)
                    if unitIDFromNameplate then
                        return unitIDFromNameplate
                    end
                end
            end

        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Compare player position and mapID to another unit's to calculate distance
-- --------------------------------------------------------
function KvChatDistance:RangeGetDistanceFromPlayerByPosition(posY, posX, mapID)
    local y1, x1 = UnitPosition("player")
    local playerMapID = C_Map.GetBestMapForUnit("player")
    KvChatDistance:Debug2("RangeGetDistanceFromPlayerByPosition", posY, posX, y1, x1, mapID, playerMapID)
    if tostring(mapID) == tostring(playerMapID) then
        local distance = ((posX - x1) ^ 2 + (posY - y1) ^ 2) ^ 0.5
        return KvChatDistance.RoundNumber(distance, 0)
    end
    KvChatDistance:Debug2("RangeGetDistanceFromPlayerByPosition", "mapID mismatch", mapID, playerMapID)
    return -1
end

-- --------------------------------------------------------------------------------------------------------------------
-- GetUnitDistanceFromPlayerByUnitID
-- --------------------------------------------------------
function KvChatDistance:GetUnitDistanceFromPlayerByUnitID(unitID)
    local distance = -1
    local method = "LiveUnitPosition"

    -- Then try a live UnitPosition() in the off-chance that the unit is one this is valid for
    if not UnitIsEnemy("player", unitID) then
        -- TODO: Skip these calls for other unitIDs that they won't work for
        local posY, posX = UnitPosition(unitID)
        if (posY and posX) then
            local mapID = C_Map.GetBestMapForUnit(unitID)
            distance = KvChatDistance:RangeGetDistanceFromPlayerByPosition(posY, posX, mapID)
            if distance >= 0 then
                KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", unitID, method, distance)
                return distance, method
            end
        end
    end

    -- Finally, fall back to trying to librangecheck the unit directly
    method = "LibRangeCheck"
    local minRange = self.rangeChecker:GetRange(unitID)
    distance = minRange

    KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", unitID, method, distance)

    return distance or -1, method
end

-- --------------------------------------------------------------------------------------------------------------------
-- GetUnitDistanceFromPlayerByName
-- --------------------------------------------------------
function KvChatDistance:GetUnitDistanceFromPlayerByName(unitName)
    local distance = -1
    local method

    -- KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", unitName)

    -- First try to get an accurate distance by comparing unit positions from cache
    local cachedPosY, cachedPosX, cachedPosZ, cachedMapID = KvChatDistance:PositionGetUnitInfo(unitName)
    if (cachedPosY and cachedPosX) then
        method = "CachedPosition"
        distance = KvChatDistance:RangeGetDistanceFromPlayerByPosition(cachedPosY, cachedPosX, cachedMapID)
        if distance >= 0 then
            -- KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", unitName, method, distance)
            return distance, method
        end
    end
    -- KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", "NoCachedPos")

    -- Then try to get librangecheck distance from cache

    local rangeInfo = KvChatDistance:RangeGetUnitInfo(unitName)
    if rangeInfo then
        method = "CachedRange"
        -- KvChatDistance:Debug2("GetUnitDistanceFromPlayerByName", unitName, method, rangeInfo)
        distance = rangeInfo
    end

    return distance, method
end
