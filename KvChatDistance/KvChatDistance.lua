-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local C_Timer = _G["C_Timer"]
local ChatFrame_AddMessageEventFilter = _G["ChatFrame_AddMessageEventFilter"]
local CreateFrame = _G["CreateFrame"]
local GetMessageTypeColor = _G["GetMessageTypeColor"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================
-- TODO
-- + Make the Config UI not suck
-- + Configurable colors for: Friends, Guildmates, Party/Raid
-- + Slashcommands
-- + Self?
-- ====================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------
-- Addon class
-- --------------------------------------------------------
KvChatDistance = CreateFrame("Frame", "KvChatDistance", UIParent)
KvChatDistance.initDone = false

-- --------------------------------------------------------------------------------------------------------------------
-- GetSettings
-- --------------------------------------------------------
function KvChatDistance:GetSettings()
    return _G["KvChatDistance_SV"].settings
end

-- --------------------------------------------------------------------------------------------------------------------
-- InitSavedVariables
-- --------------------------------------------------------
function KvChatDistance:InitAccountSavedVariables()
    self.settingsDefaults = {
        enabled = true,
        highlightFriends = true,
        highlightGuild = true,
        highlightGroup = true,

        useNameplateTrick = false,
        nameplateTickerInterval = 30,
        unitSearchTargetDepth = 3,

        sayEnabled = true,
        sayColorMin = 0.30,
        sayColorMid = 0.45,
        sayColorMax = 0.80,

        emoteEnabled = true,
        emoteColorMin = 0.45,
        emoteColorMid = 0.55,
        emoteColorMax = 0.75,

        yellEnabled = true,
        yellColorMin = 0.35,
        yellColorMid = 0.45,
        yellColorMax = 0.85,
    }
    if not _G["KvChatDistance_SV"] then
        _G["KvChatDistance_SV"] = {settings = {}}
        KvChatDistance.TableMergeNoOverwrite(self.settingsDefaults, _G["KvChatDistance_SV"].settings)
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- OnEnable
-- --------------------------------------------------------
function KvChatDistance:OnEnable()
    KvChatDistance.nameplates:StartTicker()
end

-- --------------------------------------------------------------------------------------------------------------------
-- Init
-- --------------------------------------------------------
function KvChatDistance:Init()
    -- KLib:Con("KvChatDistance.Init")
    if self.initDone then return end

    self:InitAccountSavedVariables()
    self.rangeChecker = LibStub("LibRangeCheck-2.0")
    self.initDone = true

    local guildColorR, guildColorG, guildColorB = GetMessageTypeColor("GUILD")
    KvChatDistance.guildColor = KvChatDistance.RGBDecToHex(guildColorR, guildColorG, guildColorB)
    KvChatDistance.friendColor = "55EEDD"

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", KvChatDistance.FilterFunc)

    if self:GetSettings().enabled then
        self:OnEnable()
    end

    KvChatDistance:CreateOptionsMenu()

end

-- --------------------------------------------------------------------------------------------------------------------
-- Events
-- --------------------------------------------------------
function KvChatDistance:PLAYER_LOGIN(event, addon)
    -- Delay initialization for some time after the event to give the server time to populate friend info
    C_Timer.After(7, function() KvChatDistance:Init() end)
end

function KvChatDistance:OnEvent(event, ...)
    -- KLib:Con("KvChatDistance", "OnEvent", event, ...)
    if event == "PLAYER_LOGIN" then
        KvChatDistance:PLAYER_LOGIN(event, ...)
    else
        if not KvChatDistance.initDone then return end
        if KvChatDistance.InCombat() then return end

        if event == "NAME_PLATE_UNIT_ADDED" then
            KvChatDistance:NAME_PLATE_UNIT_ADDED(event, ...)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            KvChatDistance:NAME_PLATE_UNIT_REMOVED(event, ...)
        end
    end
end

KvChatDistance:RegisterEvent("PLAYER_LOGIN")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_ADDED")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
KvChatDistance:SetScript("OnEvent", KvChatDistance.OnEvent)
