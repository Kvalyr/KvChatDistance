-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local C_Timer = _G["C_Timer"]
local ChatFrame_AddMessageEventFilter = _G["ChatFrame_AddMessageEventFilter"]
local CreateFrame = _G["CreateFrame"]
local GetInstanceInfo = _G["GetInstanceInfo"]
local GetMessageTypeColor = _G["GetMessageTypeColor"]
local UnitFullName = _G["UnitFullName"]
local UnitIsPlayer = _G["UnitIsPlayer"]

local addon, ns = ...

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
KvChatDistance.system = {addon=addon, ns={...}}
KvChatDistance.version = GetAddOnMetadata("KvChatDistance", "version")
KvChatDistance.comms_apiVersion = "0.1.0"
KvChatDistance.constants = {}
KvChatDistance.tickers = {}
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
        -- "useNameplateTrick",    -- Need to make this default-on to stem the tide of "everything is grey" reports
    }
    self.settingsDefaults = {
        settingsVersion = currentSettingsVersion,
        enabled = true,

        allowInDungeons = false,
        allowInRaids = false,
        allowInScenarios = false,

        highlightFriends = true,
        highlightFriendsBypassDistance = false,
        highlightGuild = true,
        highlightGuildBypassDistance = false,
        highlightGroup = true,
        highlightGroupBypassDistance = false,

        useNameplateTrick = true,
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
        prefixNPCs = false,
        prefixNPCs_Str = "[NPC]",
        prefixStrangers = false,
        prefixStrangers_Str = "[S]",

        -- Comms settings
        allowComms = true,
        positionBroadcastEnabled = true,
        positionBroadcastInterval = 30,

        -- Note: This interval also controls how often we make requests for position from known players
        positionCacheTickerInterval = 15,
        positionCacheTTL = 240,
        -- Note: This interval also controls how often we make requests for range from known players
        rangeCacheTickerInterval = 15,
        rangeCacheTTL = 60,

        -- Debug settings
        debugMode = false,
        debugLevel = 1,
        hideNameplatesDuringTrick = false,
        nameplateTickerHideDelay = 0.01,

        commsBroadcastTickerInterval = 60,
        commsThrottleDuration = 20,
        commsThrottleTickerInterval = 9,  -- < Half of throttle duration
    }
    if not _G["KvChatDistance_SV"] then
        KvChatDistance:Con("InitAccountSavedVariables", "No existing SV")
        _G["KvChatDistance_SV"] = {settings = {}}
    else
        KvChatDistance:Con("InitAccountSavedVariables", "Existing SV")

        -- Selectively reset certain settings to defaults on new versions
        local prevSettingsVersion = _G["KvChatDistance_SV"].settingsVersion
        if (not prevSettingsVersion) or prevSettingsVersion < currentSettingsVersion then
            KvChatDistance:Con("Newer version of settings than stored in SV.")
            for _, key in pairs(settingsToForciblyUpgrade) do
                local newValue = self.settingsDefaults[key]
                KvChatDistance:Con("Forcibly updating setting", key, "from", _G["KvChatDistance_SV"].settings[key], "to", newValue)
                _G["KvChatDistance_SV"].settings[key] = newValue
            end
        end
    end

    -- Populate SV settings with any from defaults that are missing
    KvChatDistance.TableMergeNoOverwrite(self.settingsDefaults, _G["KvChatDistance_SV"].settings)
end

-- --------------------------------------------------------------------------------------------------------------------
--
-- --------------------------------------------------------
function KvChatDistance:Allowed(settings)
    if self.InCombat() then return false end

    if not settings then settings = self:GetSettings() end
    if not settings.enabled then return false end

    local _, instanceType = GetInstanceInfo()
    if instanceType == "pvp" or instanceType == "arena" then
        -- Always disabled during instacned pvp
        return false
    end
    if instanceType == "scenario" and not settings.allowInScenarios then
        return false
    end
    if instanceType == "party" and not settings.allowInDungeons then
        return false
    end
    if instanceType == "raid" and not settings.allowInRaids then
        return false
    end

    return true
end

-- --------------------------------------------------------------------------------------------------------------------
-- Ticker Management
-- --------------------------------------------------------
function KvChatDistance:StartTicker(tickerName, interval, callback)
    callback()
    local ticker = C_Timer.NewTicker(interval, callback)
    ticker.interval = interval
    ticker.callback = callback
    KvChatDistance.tickers[tickerName] = ticker
end
function KvChatDistance:StopTicker(tickerName)
    local ticker = KvChatDistance.tickers[tickerName]
    if not ticker then return end
    ticker:Cancel()
end
function KvChatDistance:ResetTicker(tickerName, interval, callback)
    local ticker = KvChatDistance.tickers[tickerName]
    if not ticker then return end
    self:StopTicker(tickerName)
    self:StartTicker(tickerName, interval or ticker.interval, callback or ticker.callback)
end

-- --------------------------------------------------------------------------------------------------------------------
-- OnEnable
-- --------------------------------------------------------
function KvChatDistance:OnEnable()
    local settings = self:GetSettings()

    -- Update comms throttle table
    KvChatDistance:StartTicker("commsThrottle", settings.commsThrottleTickerInterval or 15, self.CommsUpdateThrottle)

    -- Ping/version-check chnnels, friends and known players to handshake addon comms
    KvChatDistance:StartTicker("commsBroadcast", settings.commsBroadcastTickerInterval or 60, self.CommsBroadcast)

    -- Nameplates Show/Hide if enabled
    KvChatDistance:StartTicker("nameplates", settings.nameplateTickerInterval or 30, self.NameplatesTickerFunc)

    -- Evict/update range cache
    KvChatDistance:StartTicker("rangeCache", settings.rangeCacheTickerInterval or 15, self.RangeUpdateCache)

    -- Evict/update position cache
    KvChatDistance:StartTicker("positionCache", settings.positionCacheTickerInterval or 15, self.PositionUpdateCache)

    -- Broadcast position to known players
    KvChatDistance:StartTicker("position", settings.positionBroadcastInterval or 15, self.PositionTickerFunc)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Init
-- --------------------------------------------------------
function KvChatDistance:Init()
    -- KLib:Con("KvChatDistance.Init")
    if self.initDone then return end

    local playerName, playerRealm = UnitFullName("player")
    self.constants.playerName = playerName
    self.constants.playerRealm = playerRealm
    self.constants.playerNameWithRealm = playerName.."-"..playerRealm

    self:InitAccountSavedVariables()
    self.rangeChecker = LibStub("LibRangeCheck-2.0")
    self.initDone = true

    local guildColorR, guildColorG, guildColorB = GetMessageTypeColor("GUILD")
    KvChatDistance.guildColor = KvChatDistance.RGBDecToHex(guildColorR, guildColorG, guildColorB)
    KvChatDistance.groupColor = KvChatDistance.guildColor -- TODO: configurable group color
    KvChatDistance.friendColor = "55AAEE"

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", KvChatDistance.FilterFunc)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", KvChatDistance.FilterFunc)

    if self:GetSettings().enabled then
        self:OnEnable()
    end

    KvChatDistance:CommsInit()

    KvChatDistance:CreateOptionsMenu()

end


-- --------------------------------------------------------------------------------------------------------------------
-- Main Caching Entrypoint
-- --------------------------------------------------------
function KvChatDistance:CacheUnit(unitID, unitName, event)
    if not KvChatDistance:Allowed() then return end

    if unitID then
        -- Grab a librangecheck value if we can
        KvChatDistance:RangeCacheFromUnit(unitID)
    end

    if not unitName then
        unitName = KvChatDistance.UnitNameWithRealm(unitID)
    end

    KvChatDistance:Debug3("CacheUnit", unitID, unitName, event)

    if unitName then
        if unitID and not UnitIsPlayer(unitID) then return end
        KvChatDistance:CachePlayerByName(unitName)
    end
end

function KvChatDistance:ProbePlayerIfUnknown(playerName)
    local pinged, compatible = KvChatDistance:CommsIsPlayerRegistered(playerName)
    if not pinged then
        KvChatDistance:CommsRequestVersion(playerName, "WHISPER")
    end
    if compatible then
        KvChatDistance:CommsRequestPosition(playerName)
    end
end

-- Ping the player to see if they use this addon. They get registered if they respond, so we can query them later.
-- Ping is throttled by comms transmit for safety
function KvChatDistance:CachePlayerByName(unitName)
    KvChatDistance:Debug3("CachePlayerByName", unitName)
    KvChatDistance:ProbePlayerIfUnknown(unitName)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Events
-- --------------------------------------------------------
function KvChatDistance:PLAYER_LOGIN(event, addon)
    -- Delay initialization for some time after the event to give the server time to populate friend info
    C_Timer.After(3, function() KvChatDistance:Init() end)
end

function KvChatDistance:Event_UnitChanged(unitID)
    KvChatDistance:Debug2("Event_UnitChanged", unitID)
    -- Make this call async so we don't get perf spikes on mouseovers
    -- C_Timer.After(0.001, function() KvChatDistance:CacheUnit(unitID) end)
    KvChatDistance:CacheUnit(unitID, nil, "Event_UnitChanged"..(unitID or ""))
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

        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            KvChatDistance:Event_UnitChanged("mouseover")

        elseif event == "PLAYER_FOCUS_CHANGED" then
            KvChatDistance:Event_UnitChanged("focus")

        elseif event == "PLAYER_TARGET_CHANGED" then
            KvChatDistance:Event_UnitChanged("target")

        elseif event == "CHAT_MSG_ADDON" then
            KvChatDistance:CHAT_MSG_ADDON(event, ...)
        end
    end
end

KvChatDistance:RegisterEvent("PLAYER_TARGET_CHANGED")
KvChatDistance:RegisterEvent("PLAYER_FOCUS_CHANGED")
KvChatDistance:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_ADDED")
KvChatDistance:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

KvChatDistance:RegisterEvent("CHAT_MSG_ADDON")

KvChatDistance:RegisterEvent("PLAYER_LEAVING_WORLD")
KvChatDistance:RegisterEvent("PLAYER_LOGOUT")
KvChatDistance:RegisterEvent("PLAYER_LOGIN")
KvChatDistance:SetScript("OnEvent", KvChatDistance.OnEvent)
