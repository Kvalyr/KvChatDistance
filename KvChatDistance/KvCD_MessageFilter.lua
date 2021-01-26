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
function KvChatDistance.GetColorForDistance(event, distance)
    -- TODO: Make the multipliers a gradient within min/max instead of tiers of distance
    local veryNearDistanceEnd = 7 -- 5: Melee range, 7: Duel, 8: Trade
    local nearDistanceEnd = 15
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
        colorR, colorG, colorB = GetMessageTypeColor("SAY")
        distanceMultMin = settings.sayColorMin--0.30
        distanceMultMid = settings.sayColorMid--0.45
        distanceMultMax = settings.sayColorMax--0.80

    elseif event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
        colorR, colorG, colorB = GetMessageTypeColor("EMOTE")
        distanceMultMin = settings.emoteColorMin--0.45
        distanceMultMid = settings.emoteColorMid--0.50
        distanceMultMax = settings.emoteColorMax--0.75

    elseif event == "CHAT_MSG_YELL" then
        colorR, colorG, colorB = GetMessageTypeColor("YELL")
        distanceMultMin = settings.yellColorMin--0.35
        distanceMultMid = settings.yellColorMid--0.45
        distanceMultMax = settings.yellColorMax--0.85

    end

    if distance < 0 then
        -- Distance unknown, assume the speaker is far away or obscured by world geometry
        multByDistance = distanceMultMin
        -- KLib:Con("KvChatDistance","GetColorForDistance", "UNKNOWN", event, distance, multByDistance)
    else
        -- Very Near -- Scale colors from distanceMultMax to 1.0
        if distance <= veryNearDistanceEnd then
            multByDistance = KvChatDistance.ScaleDistance(distance, 1.0, distanceMultMax, 0, veryNearDistanceEnd)
            -- KLib:Con("KvChatDistance","GetColorForDistance", "VERY NEAR", event, distance, multByDistance)

        -- Near -- Scale colors from distanceMultMid to distanceMultMax
        elseif distance <= nearDistanceEnd then
            multByDistance = KvChatDistance.ScaleDistance(distance, distanceMultMax, distanceMultMid, veryNearDistanceEnd, midDistanceEnd)
            -- KLib:Con("KvChatDistance","GetColorForDistance", "NEAR", event, distance, multByDistance)

        -- Mid -- Scale colors from distanceMultMin to distanceMultMid
        elseif distance <= midDistanceFar then
            multByDistance = KvChatDistance.ScaleDistance(distance, distanceMultMid, distanceMultMin, midDistanceEnd, midDistanceFar)
            -- KLib:Con("KvChatDistance","GetColorForDistance", "MID/FAR", event, distance, multByDistance)
        else
            multByDistance = distanceMultMin
        end
    end

    return KvChatDistance.RGBDecToHex(colorR * multByDistance, colorG * multByDistance, colorB * multByDistance)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Main Message Filter
-- --------------------------------------------------------
function KvChatDistance.FilterFunc(chatFrame, event, msg, author, language,  ...)
    local shouldApply = KvChatDistance:GetSettings().enabled and not KvChatDistance.InCombat()

    if (event == "CHAT_MSG_SAY" or event == "CHAT_MSG_MONSTER_SAY") and not KvChatDistance:GetSettings().sayEnabled then
        shouldApply = false
    end
    if (event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE") and not KvChatDistance:GetSettings().emoteEnabled then
        shouldApply = false
    end
    if (event == "CHAT_MSG_YELL") and not KvChatDistance:GetSettings().yellEnabled then
        shouldApply = false
    end

    if not shouldApply then
        return false, msg, author, language, ...
    end

    local origAuthor = author
    author = strsplit("-", author)

    local unitID = KvChatDistance.GetViableUnitIDForName(author)

    if unitID then
        if KvChatDistance:GetSettings().highlightGuild and KvChatDistance.IsUnitInPlayerGuild(unitID) then
            -- TODO: Make this color configurable
            msg = colorStringOpen .. KvChatDistance.guildColor .. msg .. colorStringClose
            return false, msg, origAuthor, language, ...
        end
        if KvChatDistance:GetSettings().highlightGroup and (UnitInParty(unitID) or UnitInRaid(unitID)) then
            -- TODO: Make this color configurable
            msg = colorStringOpen .. KvChatDistance.guildColor .. msg .. colorStringClose
            return false, msg, origAuthor, language, ...
        end
    end
    if KvChatDistance.IsFriend(author) then
        msg = colorStringOpen .. KvChatDistance.friendColor .. msg .. colorStringClose
        return false, msg, origAuthor, language, ...
    end

    local distance, methodUsed = KvChatDistance:GetUnitDistanceFromPlayerByName(author, unitID)

    local distanceColor = KvChatDistance.GetColorForDistance(event, distance)
    msg = colorStringOpen .. distanceColor .. msg .. colorStringClose

    -- if KvChatDistance.StrContains(strlower(language), "common") then -- TODO: Config
    --     language = colorStringOpen .. distanceColor .. language .. colorStringClose
    -- end

    --[[
    local throttle = KvChatDistance:ThrottleFilter(event, msg, author, language)
    if not throttle then
        -- TODO: Move more logic in here and reuse data across chat frames to reduce calls

        KLib:Con("KvChatDistance", "FilterFunc", distance, author, language, unitID, methodUsed, msg )
        -- KLib:Con("KvChatDistance", "FilterFunc", event, author, language, {...})
    end
    --]]--

    return false, msg, origAuthor, language, ...
end
