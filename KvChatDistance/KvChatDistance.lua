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
-- + Self-highlight?
-- + Configurable prefixes for Near/Friend/Guild/Group
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
    local currentSettingsVersion = 2
    local settingsToForciblyUpgrade = {
        "useNameplateTrick",    -- Need to make this default-on to stem the tide of "everything is grey" reports
    }
    self.settingsDefaults = {
        settingsVersion = currentSettingsVersion,
        enabled = true,
        highlightFriends = true,
        highlightGuild = true,
        highlightGroup = true,

        useNameplateTrick = true,
        nameplateTickerInterval = 15,
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

        prefixFriends = false,
        prefixFriends_Str = "[F]",
        prefixGuild = false,
        prefixGuild_Str = "[G]",
        prefixGroup = false,
        prefixGroup_Str = "[P]",
        prefixTarget = false,
        prefixTarget_Str = "[T]",
        prefixFocus = false,
        prefixFocus_Str = "[X]",

        -- Debug settings
        debugMode = false,
        hideNameplatesDuringTrick = false,
        nameplateTickerHideDelay = 0.01,
        prefixNPCs = false,
        prefixNPCs_Str = "[NPC]",
        prefixStrangers = false,
        prefixStrangers_Str = "[S]",
    }
    if not _G["KvChatDistance_SV"] then
        KvChatDistance:Debug("InitAccountSavedVariables", "No existing SV")
        _G["KvChatDistance_SV"] = {settings = {}}
    else
        KvChatDistance:Debug("InitAccountSavedVariables", "Existing SV")

        -- Selectively reset certain settings to defaults on new versions
        local prevSettingsVersion = _G["KvChatDistance_SV"].settingsVersion
        if (not prevSettingsVersion) or prevSettingsVersion < currentSettingsVersion then
            KvChatDistance:Debug("Newer version of settings than stored in SV.")
            for _, key in pairs(settingsToForciblyUpgrade) do
                local newValue = self.settingsDefaults[key]
                KvChatDistance:Debug("Forcibly updating setting", key, "from", _G["KvChatDistance_SV"].settings[key], "to", newValue)
                _G["KvChatDistance_SV"].settings[key] = newValue
            end
        end
    end

    -- Populate SV settings with any from defaults that are missing
    KvChatDistance.TableMergeNoOverwrite(self.settingsDefaults, _G["KvChatDistance_SV"].settings)
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
    KvChatDistance.groupColor = KvChatDistance.guildColor -- TODO
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
    C_Timer.After(3, function() KvChatDistance:Init() end)
end

function KvChatDistance:OnEvent(event, ...)
    -- KLib:Con("KvChatDistance", "OnEvent", event, ...)
    if event == "PLAYER_LOGIN" then
        KvChatDistance:PLAYER_LOGIN(event, ...)
    else
        if not KvChatDistance.initDone then return end

        if event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
            -- Make sure we don't persist our CVar changes to the player's settings
            KvChatDistance.nameplates:UndoCVarChanges()
        end

        if KvChatDistance.InCombat() then return end

        if event == "NAME_PLATE_UNIT_ADDED" then
            KvChatDistance:NAME_PLATE_UNIT_ADDED(event, ...)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            KvChatDistance:NAME_PLATE_UNIT_REMOVED(event, ...)
        end
    end
end

KvChatDistance:RegisterEvent("PLAYER_LEAVING_WORLD")
KvChatDistance:RegisterEvent("PLAYER_LOGOUT")
KvChatDistance:RegisterEvent("PLAYER_LOGIN")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_ADDED")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
KvChatDistance:SetScript("OnEvent", KvChatDistance.OnEvent)
