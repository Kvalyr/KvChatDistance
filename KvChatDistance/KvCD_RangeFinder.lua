-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local GetNumGroupMembers = _G["GetNumGroupMembers"]
local IsInRaid = _G["IsInRaid"]
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
local targetDepth = 3  -- TODO: Config
local numPartyMembers = 5
local numRaidMembers = 40
local nameplateMax = 60
local unitIDsToTest = {
    "player",
    "target",
    "focus",
    "mouseover",
    -- "partyN", -- TODO
    -- "raidN", -- TODO
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

function KvChatDistance:StoreUnitRangeInfo(unitName, minRange, maxRange)
    self.unitRangeCache[unitName] = minRange--{min=minRange, max=maxRange}
end

function KvChatDistance:DeleteUnitRangeInfo(unitName)
    self.unitRangeCache[unitName] = nil
end

function KvChatDistance:GetUnitRangeInfo(unitName)
    return self.unitRangeCache[unitName]
end

function KvChatDistance:CacheUnitRangeFromNameplate(nameplateID)
    if not self.initDone then return end
    if not (nameplateID and not UnitIsUnit("player", nameplateID)) then return end

    local minRange, maxRange = self.rangeChecker:GetRange(nameplateID)
    local unitName = UnitName(nameplateID)
    if not unitName then return end

    -- KLib:Con("KvChatDistance", "CacheUnitRangeFromNameplate", unitName, minRange, maxRange)
    self:StoreUnitRangeInfo(unitName, minRange, maxRange)
end

function KvChatDistance:UncacheUnitRangeFromNameplate(nameplateID)
    if not self.initDone then return end
    if not (nameplateID and not UnitIsUnit("player", nameplateID)) then return end

    local unitName = UnitName(nameplateID)
    if not unitName then return end

    self:DeleteUnitRangeInfo(unitName)
end


local function GetUnitIDFromTargets(unitID, unitName)
    local targetDepth = KvChatDistance:GetSettings().unitSearchTargetDepth
    for i=1, targetDepth do
        unitID = unitID.."target"
        if UnitName(unitID) == unitName then
            return unitID
        end
    end
end

local function GetUnitIDFromN(unitName, unitBase, numToCheck)
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
-- TODO: Cleanup
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
            if unitID == "partyN" and numGroupMembers > 0 then
                local unitIDFromNameplate = GetUnitIDFromN(unitName, "party", numPartyMembers)
                if unitIDFromNameplate then
                    return unitIDFromNameplate
                end
            elseif unitID == "raidN" and IsInRaid() and numGroupMembers > 0 then
                local unitIDFromNameplate = GetUnitIDFromN(unitName, "raid", numRaidMembers)
                if unitIDFromNameplate then
                    return unitIDFromNameplate
                end
            end

        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------
function KvChatDistance:GetUnitDistanceFromPlayerByName(unitName, unitID)
    local distance = -1
    local method = "cached"
    if not unitID then
        local rangeInfo = KvChatDistance:GetUnitRangeInfo(unitName)
        if rangeInfo then
            return rangeInfo, method
        end
        return distance
    end

    local posY, posX, posZ, instanceID = UnitPosition(unitID) -- TODO: Skip this call for unitIDs that it won't work for
    if (posY and posX) then
        method = "UnitPosition"
        local y1, x1, _, playerInstance = UnitPosition("player")
        distance = playerInstance == instanceID and ((posX - x1) ^ 2 + (posY - y1) ^ 2) ^ 0.5
    else
        method = "librangecheck"
        local minRange = self.rangeChecker:GetRange(unitID)
        distance = minRange
    end
    return distance or -1, method

end
