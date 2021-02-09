-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local strlen = _G["strlen"]
local strsplit = _G["strsplit"]
local C_FriendList = _G["C_FriendList"]
local C_GuildInfo = _G["C_GuildInfo"]
local GetGuildInfo = _G["GetGuildInfo"]
local GetNumGuildMembers = _G["GetNumGuildMembers"]
local InCombatLockdown = _G["InCombatLockdown"]
local IsInGuild = _G["IsInGuild"]
local SetGuildRosterShowOffline = _G["SetGuildRosterShowOffline"]
local UnitAffectingCombat = _G["UnitAffectingCombat"]
local UnitFullName = _G["UnitFullName"]
local UnitIsPlayer = _G["UnitIsPlayer"]
local UnitName = _G["UnitName"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------
-- Helpers
-- TODO: Kill this file by using KLibLite
-- --------------------------------------------------------

-- --------------------------------------------------------------------------------------------------------------------
-- Debugging
-- --------------------------------------------------------
function KvChatDistance:ToggleDebugMode(bool)
    if bool ~= nil then
        if bool == false then
            _G["KvChatDistance_SV"].settings.debugMode = false
        elseif bool then
            _G["KvChatDistance_SV"].settings.debugMode = true
        end
    else
        _G["KvChatDistance_SV"].settings.debugMode = not (_G["KvChatDistance_SV"].settings.debugMode)
    end
end

function KvChatDistance:DebugOptionsMenu()
    KvChatDistance:CreateOptionsMenu()
    KvChatDistance:OpenOptionsMenu()
end

function KvChatDistance:Con(...)
    if not KLib or not KLib.Con then return end
    KLib:Con("KvChatDistance", ...)
end

function KvChatDistance:Debug(...)
    if not KLib or not KLib.Con then return end
    if self:GetSettings().debugMode then
        KLib:Con("KvChatDistance", "DEBUG", ...)
    end
end

function KvChatDistance:Debug2(...)
    local settings = self:GetSettings()
    if settings.debugMode and settings.debugLevel > 1 then
        KvChatDistance:Debug(...)
    end
end

function KvChatDistance:Debug3(...)
    local settings = self:GetSettings()
    if settings.debugMode and settings.debugLevel > 2 then
        KvChatDistance:Debug(...)
    end
end

function KvChatDistance:Debug4(...)
    local settings = self:GetSettings()
    if settings.debugMode and settings.debugLevel > 3 then
        KvChatDistance:Debug(...)
    end
end

function KvChatDistance:CommsTest(target, channel)
    if not target then target = UnitName("player") end
    if not channel then channel = "WHISPER" end

    self:CommsTransmit("MI", {"--Test Miscellaneous Message--"}, channel, target)

    KvChatDistance:CommsRequestVersion(target, channel)
    KvChatDistance:CommsRequestPosition(target, channel)
    KvChatDistance:CommsRequestRange(target, channel, nil)
end

-- --------------------------------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------
function KvChatDistance.TableIsEmpty(tab)
    if next(tab) == nil then
        return true
    end
    return false
end

-- --------------------------------------------------------------------------------------------------------------------
-- Unit Names
-- --------------------------------------------------------
function KvChatDistance.UnitNameIsPlayer(unitName)
    if unitName == KvChatDistance.constants.playerName then return true end
    if unitName == KvChatDistance.constants.playerNameWithRealm then return true end
    return false
end

function KvChatDistance.StripRealmFromUnitName(unitFullName)
    return strsplit("-", unitFullName)
end

function KvChatDistance.IsUnitNameSameRealm(unitFullName)
    local unitName, unitRealm = strsplit("-", unitFullName)
    if unitName then
        if not unitRealm then
            return true
        end
        if unitRealm and unitRealm == KvChatDistance.constants.playerRealm then
            return true
        end
    end
    return false
end

function KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)
    if KvChatDistance.IsUnitNameSameRealm(unitName) then
        unitName = KvChatDistance.StripRealmFromUnitName(unitName)
    end
    return unitName
end

function KvChatDistance.AddRealmToUnitName(unitName)
    local unitNameOnly, unitRealm = strsplit("-", unitName)
    if not unitRealm then
        return unitName .. "-" .. KvChatDistance.constants.playerRealm
    end
    return unitName
end

function KvChatDistance.UnitNameWithRealm(unitID)
    if unitID == "player" then return KvChatDistance.constants.playerNameWithRealm end
    if not UnitIsPlayer(unitID) then
        return UnitName(unitID)
    end
    local unitName, unitRealm = UnitFullName(unitID)
    if not unitName then return end
    if not unitRealm then unitRealm = KvChatDistance.constants.playerRealm end
    return unitName.."-"..unitRealm
end

-- --------------------------------------------------------------------------------------------------------------------
-- Friends/Guild/Group
-- --------------------------------------------------------
function KvChatDistance.IsFriend(unitName)
    local unitName = KvChatDistance.StripRealmFromUnitName(unitName)
    C_FriendList.ShowFriends()
    local friendInfo = C_FriendList.GetFriendInfo(unitName)
    if friendInfo then return true end
    return false
end

function KvChatDistance.IsUnitInPlayerGuild(unitID)
    C_GuildInfo.GuildRoster()
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then return false end

    local unitGuild = GetGuildInfo(unitID)
    return playerGuild == unitGuild
end

function KvChatDistance.IsUnitNameInPlayerGuild(unitName)
    unitName = KvChatDistance.AddRealmToUnitName(unitName)
    local guildMembers = KvChatDistance.GetAllGuildMembers()
    if guildMembers[unitName] then
        return true
    end
    return false
end

function KvChatDistance.GetAllGuildMembers()
    local allGuildMembers = {}
    if not IsInGuild() then return allGuildMembers end

    SetGuildRosterShowOffline(true)
    C_GuildInfo.GuildRoster()
    local numTotalGuildMembers, numOnlineGuildMembers, numOnlineAndMobileMembers = GetNumGuildMembers()
    for i=1, numTotalGuildMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
        -- KvChatDistance:Debug("GetAllGuildMembers", name, rankName, level, isOnline)
        allGuildMembers[name] = true
    end
    return allGuildMembers
end

function KvChatDistance.GetFriendsNotInGuild()
    C_FriendList.ShowFriends()
    local numFriends = C_FriendList.GetNumFriends()
    local nonGuildFriends = {}
    if numFriends < 1 then return nonGuildFriends end
    local guildMembers = KvChatDistance.GetAllGuildMembers()

    for i=1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        -- KvChatDistance:Debug("GetFriendsNotInGuild", friendInfo)

        if friendInfo and friendInfo.connected and friendInfo.name then
            local friendName = friendInfo.name .. "-" .. KvChatDistance.constants.playerRealm
            if not guildMembers[friendName] then
                nonGuildFriends[friendInfo.name] = true
            end
        end
    end

    return nonGuildFriends
end
-- --------------------------------------------------------------------------------------------------------------------
-- Stuff to get from KLib
-- --------------------------------------------------------
function KvChatDistance.InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")
end

function KvChatDistance.StrContains(str, subStr)
    return string.find(str, subStr, nil, true)
end

function KvChatDistance.TableMergeNoOverwrite(from, to)
    for key, value in pairs(from) do
        if type(value) == "table" then
            if to[key] == nil then
                to[key] = {}
                KvChatDistance.TableMergeNoOverwrite(from[key], to[key])
            end
        else
            if to[key] == nil then to[key] = value end
        end
    end
end

function KvChatDistance.RoundNumber(num, places)
    if not num then return end
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- --------------------------------------------------------------------------------------------------------------------
-- Count number of decimal places in a number
-- ----------------------------------------------------------------
function KvChatDistance.CountDecimalPlaces(num)
    local integer, decimal = strsplit(".", tostring(num), 2)
    if decimal then
        return strlen(decimal)
    else
        return 0
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- HexToRGBPerc - http://wowpedia.org/HexToRGB
-- --------------------------------
function KvChatDistance.HexToRGB(hex)
    if type(hex) == "string" then
        local m = #hex == 3 and 17 or (#hex == 6 and 1 or 0)
        local rhex, ghex, bhex = hex:match('^(%x%x?)(%x%x?)(%x%x?)$')
        if rhex and m > 0 then
            return tonumber(rhex, 16) * m, tonumber(ghex, 16) * m, tonumber(bhex, 16) * m
        end
    end
    return 0, 0, 0
end

-- --------------------------------------------------------------------------------------------------------------------
-- Based on: HexToRGBPerc - http://wowpedia.org/HexToRGB
-- --------------------------------
function KvChatDistance.RGBToHex(r, g, b, a)
    r = r <= 255 and r >= 0 and r or 0
    g = g <= 255 and g >= 0 and g or 0
    b = b <= 255 and b >= 0 and b or 0
    if type(a) == "number" and a >= 0 then
        a = a <= 255 and a >= 0 and a or 0
        return string.format("%02x%02x%02x%02x", a, r, g, b)
    else
        return string.format("%02x%02x%02x", r, g, b)
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Round num to match the number of decimal places of numMatch
-- ----------------------------------------------------------------
local function NumberClamp(num, lowerLimit, upperLimit)
    if lowerLimit > upperLimit then lowerLimit, upperLimit = upperLimit, lowerLimit end -- Swap if limits supplied reversed
    if num < lowerLimit then num = lowerLimit end
    if num > upperLimit then num = upperLimit end
    return num
end
-- --------------------------------------------------------------------------------------------------------------------
-- RGBDecTo255
-- Converts decimal RGBA values to fractions of 255
-- --------------------------------
function KvChatDistance.RGBDecTo255(r,g,b,a)
    if r then r = NumberClamp(255 * r, 0, 255) end
    if g then g = NumberClamp(255 * g, 0, 255) end
    if b then b = NumberClamp(255 * b, 0, 255) end
    if a then a = NumberClamp(255 * a, 0, 255) end
    return r,g,b,a
end

function KvChatDistance.RGB255ToDec(r,g,b,a)
    if r then r = NumberClamp(r / 255, 0, 1) end
    if g then g = NumberClamp(g / 255, 0, 1) end
    if b then b = NumberClamp(b / 255, 0, 1) end
    if a then a = NumberClamp(a / 255, 0, 1) end
    return r,g,b,a
end

-- --------------------------------------------------------------------------------------------------------------------
-- RGBDecToHex
-- Expects RGB values in ranges 0.0 to 0.1, converts to 0-255 range then to Hex via KLib.RGBToHex(r, g, b, a)
-- --------------------------------
function KvChatDistance.RGBDecToHex(r, g, b, a)
    local assumeDecimals = true
    if (r and r > 1) or (g and g > 1) or (b and b > 1) or (a and a > 1) then assumeDecimals = false end

    if assumeDecimals then
        r,g,b,a = KvChatDistance.RGBDecTo255(r,g,b,a)
    end

    if a then
        return KvChatDistance.RGBToHex(r, g, b, a)
    else
        return KvChatDistance.RGBToHex(r, g, b)
    end
end

function KvChatDistance.HexToDec(hex)
    local r,g,b,a = KvChatDistance.HexToRGB(hex)
    return KvChatDistance.RGB255ToDec(r,g,b,a)
end