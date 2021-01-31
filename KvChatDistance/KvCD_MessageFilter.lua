-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local strsplit = _G["strsplit"]
local C_Timer = _G["C_Timer"]
local GetMessageTypeColor = _G["GetMessageTypeColor"]
local UnitInParty = _G["UnitInParty"]
local UnitInRaid = _G["UnitInRaid"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================

local colorStringOpen = "|cff"
local colorStringClose = "|r"

-- --------------------------------------------------------------------------------------------------------------------
-- ThrottleFilter
-- --------------------------------------------------------
KvChatDistance.throttleTable = {}
function KvChatDistance:ThrottleFilter(event, msg, author, language)
    local hash = (event or "event") .. (msg or "") .. (author or "") .. (language or "")
    if self.throttleTable[hash] then
        return true
    end
    self.throttleTable[hash] = true
    C_Timer.After(1, function() self.throttleTable[hash] = nil end)
    return false
end

-- --------------------------------------------------------------------------------------------------------------------
-- Get a scaling multiplier within a min/max range to scale distances between a min and max distance
-- --------------------------------------------------------
function KvChatDistance.ScaleDistance(distance, distanceMultMin, distanceMultMax, distanceMin, distanceMax)
    return ((distanceMultMax - distanceMultMin) * (distance - distanceMin) / (distanceMax - distanceMin)) + distanceMultMin;
end

-- --------------------------------------------------------------------------------------------------------------------
-- Given a chat event and a distance, get the appropriate text color and then scale its luminosity appropriately
-- --------------------------------------------------------
function KvChatDistance.GetColorForDistance(event, distance, inputColor)
    local veryNearDistanceEnd = 7 -- 5: Melee range, 7: Duel, 8: Trade
    local nearDistanceEnd = 10
    local midDistanceEnd = 50
    local midDistanceFar = 100
    -- local farDistanceStart = 28

    local settings = KvChatDistance:GetSettings()

    -- Color scaling should not be linear from 5yds to >50yds
    -- Give more resolution to ranges within near distance. Subtle distance differences between near units matter more.
    -- i.e.; Whether someone is 8yds away or 15yds away is more noticable than 38yds vs 45yds.
    local distanceMultMin = 0.30 -- Messages beyond 'mid' distance cannot be any darker than this
    local distanceMultMid = 0.40 -- Messages outside of 'near' distance cannot be any brighter than this
    local distanceMultMax = 0.80 -- Messages outside of 'very near' distance cannot be any brighter than this
    local multByDistance = 1

    local colorR, colorG, colorB = 1, 1, 1
    if event == "CHAT_MSG_SAY" or event == "CHAT_MSG_MONSTER_SAY" then
        if not inputColor then
            colorR, colorG, colorB = GetMessageTypeColor("SAY")
        end
        distanceMultMin = settings.sayColorMin--0.30
        distanceMultMid = settings.sayColorMid--0.45
        distanceMultMax = settings.sayColorMax--0.80

    elseif event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        if not inputColor then
            colorR, colorG, colorB = GetMessageTypeColor("EMOTE")
        end
        distanceMultMin = settings.emoteColorMin--0.45
        distanceMultMid = settings.emoteColorMid--0.50
        distanceMultMax = settings.emoteColorMax--0.75

    elseif event == "CHAT_MSG_YELL" then
        if not inputColor then
            colorR, colorG, colorB = GetMessageTypeColor("YELL")
        end
        distanceMultMin = settings.yellColorMin--0.35
        distanceMultMid = settings.yellColorMid--0.45
        distanceMultMax = settings.yellColorMax--0.85

    end

    if inputColor then
        colorR, colorG, colorB = KvChatDistance.HexToRGB(inputColor)
    end

    if distance < 0 then
        -- Distance unknown, assume the speaker is far away or obscured by world geometry
        multByDistance = distanceMultMin
        -- KvChatDistance:Debug4("GetColorForDistance", "UNKNOWN", event, distance, multByDistance)
    else
        -- Very Near -- Scale colors from distanceMultMax to 1.0
        if distance <= veryNearDistanceEnd then
            multByDistance = KvChatDistance.ScaleDistance(distance, 1.0, distanceMultMax, 0, veryNearDistanceEnd)
            -- KvChatDistance:Debug4("GetColorForDistance", "VERY NEAR", event, distance, multByDistance)

        -- Near -- Scale colors from distanceMultMid to distanceMultMax
        elseif distance <= nearDistanceEnd then
            multByDistance = KvChatDistance.ScaleDistance(distance, distanceMultMax, distanceMultMid, veryNearDistanceEnd, midDistanceEnd)
            -- KvChatDistance:Debug4("GetColorForDistance", "NEAR", event, distance, multByDistance)

        -- Mid -- Scale colors from distanceMultMin to distanceMultMid
        elseif distance <= midDistanceFar then
            multByDistance = KvChatDistance.ScaleDistance(distance, distanceMultMid, distanceMultMin, midDistanceEnd, midDistanceFar)
            -- KvChatDistance:Debug4("GetColorForDistance", "MID/FAR", event, distance, multByDistance)
        else
            multByDistance = distanceMultMin
        end
    end

    return KvChatDistance.RGBDecToHex(colorR * multByDistance, colorG * multByDistance, colorB * multByDistance)
end

-- --------------------------------------------------------------------------------------------------------------------
-- TODO: Separate toggles for distance/prefix/highlighting per event
-- --------------------------------------------------------
function KvChatDistance:ShouldFilterForEvent(event, author)
    local settings = self:GetSettings()
    local shouldApply = KvChatDistance:Allowed(settings)
    if shouldApply then
        if author == self.constants.playerName or author == self.constants.playerNameWithRealm then
            return false
        end
        if (event == "CHAT_MSG_SAY" or event == "CHAT_MSG_MONSTER_SAY") and not settings.sayEnabled then
            return false
        end
        if (event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE") and not settings.emoteEnabled then
            return false
        end
        if (event == "CHAT_MSG_YELL") and not settings.yellEnabled then
            return false
        end
    end
    return shouldApply
end

-- --------------------------------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------
function KvChatDistance:ApplyPrefixToMessage(msg, event, prefixToApply)
    -- Emotes don't get prefixes
    if event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        return msg
    end
    return prefixToApply .. " " .. msg
end

-- --------------------------------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------
function KvChatDistance:ApplyColorToMessage(msg, colorToApply)
    return colorStringOpen .. colorToApply .. msg .. colorStringClose
end

-- --------------------------------------------------------------------------------------------------------------------
-- Main Message Filter
-- --------------------------------------------------------
function KvChatDistance.FilterFunc(chatFrame, event, msg, author, language,  ...)
    local origAuthor = author
    author = strsplit("-", author)

    if not KvChatDistance:ShouldFilterForEvent(event, author) then
        return false, msg, origAuthor, language, ...
    end

    local settings = KvChatDistance:GetSettings()

    local unitID = KvChatDistance.GetViableUnitIDForName(author)
    local isFriend = false
    local isGuild = false
    local isGroup = false
    local colorToApply = nil
    local prefixToApply = nil

    if settings.highlightFriends or settings.prefixFriends then
        isFriend = KvChatDistance.IsFriend(author)
    end
    if unitID then
        if settings.highlightGuild or settings.prefixGuild then
            isGuild = KvChatDistance.IsUnitInPlayerGuild(unitID)
        end
        if settings.highlightGroup or settings.prefixGroup then
            isGroup = UnitInParty(unitID) or UnitInRaid(unitID)
        end
    end

    -- Prefixes and colors have a priority: Guild, Friend, Group
    if isGuild then
        if settings.highlightGuild then
            -- TODO: Make this color configurable
            colorToApply = KvChatDistance.guildColor
        end
        if settings.prefixGuild then
            prefixToApply = settings.prefixGuild_Str
        end
    end
    if isFriend then
        if settings.highlightFriends then
            -- TODO: Make this color configurable
            colorToApply = KvChatDistance.friendColor
        end
        if settings.prefixFriends then
            prefixToApply = settings.prefixFriends_Str
        end
    end
    if isGroup then
        if settings.highlightGroup then
            -- TODO: Make this color configurable
            colorToApply = KvChatDistance.groupColor
        end
        if settings.prefixGroup then
            prefixToApply = settings.prefixGroup_Str
        end
    end

    local isStranger = not (isGroup or isFriend or isGuild)
    if settings.prefixStrangers and isStranger then
        prefixToApply = settings.prefixStrangers_Str
    end
    if settings.prefixNPCs and event == "CHAT_MSG_MONSTER_SAY" then
        prefixToApply = settings.prefixNPCs_Str
    end

    if settings.prefixTarget and unitID == "target" then
        prefixToApply = settings.prefixTarget_Str
    end
    if settings.prefixFocus and unitID == "focus" then
        prefixToApply = settings.prefixFocus_Str
    end

    if prefixToApply then
        msg = KvChatDistance:ApplyPrefixToMessage(msg, event, prefixToApply)
    end

    KvChatDistance:CacheUnit(unitID, origAuthor, "FilterFunc")

    -- TODO: Separate toggles for distance/prefix/highlighting per event
    local distance, methodUsed = KvChatDistance:GetUnitDistanceFromPlayerByName(author)
    if unitID and ((not distance) or distance < 0) then
        distance, methodUsed = KvChatDistance:GetUnitDistanceFromPlayerByUnitID(unitID)
    end
    colorToApply = KvChatDistance.GetColorForDistance(event, distance, colorToApply)

    if colorToApply then
        msg = KvChatDistance:ApplyColorToMessage(msg, colorToApply)
    end

    -- if settings.showLanguage and KvChatDistance.StrContains(strlower(language), "common") then -- TODO: Config
    --     language = colorStringOpen .. distanceColor .. language .. colorStringClose
    -- end

    if settings.debugMode then
        local throttle = KvChatDistance:ThrottleFilter(event, msg, author, language)
        if not throttle then
            -- TODO: Use throttle logic elsewhere since this func will get fired for each chat frame that exists

            KvChatDistance:Debug2("FilterFunc", distance, author, language, unitID, methodUsed, msg )
            KvChatDistance:Debug3("FilterFunc", "isFriend", isFriend, "isGuild", isGuild, "isGroup", isGroup )
            -- KvChatDistance:Debug2("FilterFunc", event, author, language, {...})
        end
    end

    return false, msg, origAuthor, language, ...
end
