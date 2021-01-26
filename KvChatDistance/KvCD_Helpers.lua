-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local C_FriendList = _G["C_FriendList"]
local C_GuildInfo = _G["C_GuildInfo"]
local GetGuildInfo = _G["GetGuildInfo"]
local InCombatLockdown = _G["InCombatLockdown"]
local UnitAffectingCombat = _G["UnitAffectingCombat"]
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

function KvChatDistance:Debug(...)
    if not KLib or not KLib.Con then return end
    if self:GetSettings().debugMode then
        KLib:Con("KvChatDistance", ...)
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Friends/Guild/Group
-- --------------------------------------------------------
function KvChatDistance.IsFriend(unitName)
    C_FriendList.ShowFriends()
    local friendInfo = C_FriendList.GetFriendInfo(unitName)
    if friendInfo then return true end
    return false
end

function KvChatDistance.IsUnitInPlayerGuild(unitID)
    C_GuildInfo.GuildRoster()
    local playerGuild = GetGuildInfo("player")
    local unitGuild = GetGuildInfo(unitID)
    return playerGuild ~= nil and playerGuild == unitGuild
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
            if not to[key] then
                to[key] = {}
                KvChatDistance.TableMergeNoOverwrite(from[key], to[key])
            end
        else
            if not to[key] then to[key] = value end
        end
    end
end

function KvChatDistance.RoundNumber(num, places)
    if not num then return end
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
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
