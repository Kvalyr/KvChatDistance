-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local C_CVar = _G["C_CVar"]
local C_NamePlate = _G["C_NamePlate"]
local C_Timer = _G["C_Timer"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================

KvChatDistance.nameplates = {}

-- --------------------------------------------------------------------------------------------------------------------
-- Events
-- --------------------------------------------------------
function KvChatDistance:NAME_PLATE_UNIT_ADDED(event, ...)
    KvChatDistance:CacheUnitRangeFromNameplate(...)
end

function KvChatDistance:NAME_PLATE_UNIT_REMOVED(event, ...)
    KvChatDistance:CacheUnitRangeFromNameplate(...) -- Last known
    -- KvChatDistance:UncacheUnitRangeFromNameplate(...)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Store current CVar values with the (risky) assumption that these are the player's normal play preferences
-- --------------------------------------------------------
function KvChatDistance.nameplates:StoreCurrentCVars()
    -- Don't store values if we currently consider them modified by us
    if KvChatDistance.nameplates.cvars_mutated then return end

    KvChatDistance.nameplates["nameplateShowOnlyNames"] = C_CVar.GetCVar("nameplateShowOnlyNames")
    KvChatDistance.nameplates["nameplateShowAll"] = C_CVar.GetCVar("nameplateShowAll")
    KvChatDistance.nameplates["nameplateShowFriends"] = C_CVar.GetCVar("nameplateShowFriends")
    KvChatDistance.nameplates["nameplateShowEnemies"] =  C_CVar.GetCVar("nameplateShowEnemies")
    -- KvChatDistance.nameplates["nameplateGlobalScale"] = C_CVar.GetCVar("nameplateGlobalScale")
    -- KvChatDistance.nameplates["nameplateMinAlpha"] = C_CVar.GetCVar("nameplateMinAlpha")
    -- KvChatDistance.nameplates["nameplateMaxAlpha"] = C_CVar.GetCVar("nameplateMaxAlpha")
    -- KvChatDistance.nameplates["nameplateMaxAlphaDistance"] = C_CVar.GetCVar("nameplateMaxAlphaDistance")
end

-- --------------------------------------------------------------------------------------------------------------------
-- Change CVars relating to nameplates to make them show (but try to do so without them being visually distracting)
-- --------------------------------------------------------
function KvChatDistance.nameplates:ChangeCVars()
    C_CVar.SetCVar("nameplateShowOnlyNames", 1)
    C_CVar.SetCVar("nameplateShowAll", 1)
    C_CVar.SetCVar("nameplateShowEnemies", 1)
    C_CVar.SetCVar("nameplateShowFriends", 1)

    -- C_CVar.SetCVar("nameplateGlobalScale", 0.01)
    -- C_CVar.SetCVar("nameplateMinAlpha", 0.01)
    -- C_CVar.SetCVar("nameplateMaxAlpha", 0.02)
    -- C_CVar.SetCVar("nameplateMaxAlphaDistance", 60)

    -- Track that we have changed the cvar state
    KvChatDistance.nameplates.cvars_mutated = true
end

-- --------------------------------------------------------------------------------------------------------------------
-- Undo any CVar changes made by this addon to the best of our ability
-- --------------------------------------------------------
function KvChatDistance.nameplates:UndoCVarChanges()
    -- Don't risk touching the CVars if we haven't already mutated them in some way
    if not KvChatDistance.nameplates.cvars_mutated then return end

    -- Try to only hide nameplates if the user has them hidden ordinarily
    C_CVar.SetCVar("nameplateShowOnlyNames", KvChatDistance.nameplates["nameplateShowOnlyNames"] or C_CVar.GetCVarDefault("nameplateShowOnlyNames"))
    C_CVar.SetCVar("nameplateShowAll", KvChatDistance.nameplates["nameplateShowAll"] or C_CVar.GetCVarDefault("nameplateShowAll"))
    C_CVar.SetCVar("nameplateShowFriends", KvChatDistance.nameplates["nameplateShowFriends"] or C_CVar.GetCVarDefault("nameplateShowFriends"))
    C_CVar.SetCVar("nameplateShowEnemies", KvChatDistance.nameplates["nameplateShowEnemies"] or C_CVar.GetCVarDefault("nameplateShowEnemies"))

    -- C_CVar.SetCVar("nameplateGlobalScale", KvChatDistance.nameplates["nameplateGlobalScale"] or C_CVar.GetCVarDefault("nameplateGlobalScale"))
    -- C_CVar.SetCVar("nameplateMinAlpha", KvChatDistance.nameplates["nameplateMinAlpha"] or C_CVar.GetCVarDefault("nameplateMinAlpha"))
    -- C_CVar.SetCVar("nameplateMaxAlpha", KvChatDistance.nameplates["nameplateMaxAlpha"] or C_CVar.GetCVarDefault("nameplateMaxAlpha"))
    -- C_CVar.SetCVar("nameplateMaxAlphaDistance", KvChatDistance.nameplates["nameplateMaxAlphaDistance"] or C_CVar.GetCVarDefault("nameplateMaxAlphaDistance"))

end

-- --------------------------------------------------------------------------------------------------------------------
-- Force Nameplates to appear so that we trigger NAME_PLATE_UNIT_ADDED and NAME_PLATE_UNIT_REMOVED and grab their range
-- --------------------------------------------------------
function KvChatDistance.nameplates:ForceShow(hideNameplatesDuringTrick)
    if KvChatDistance.InCombat() then return end
    KvChatDistance:Debug("Showing Nameplates")

    KvChatDistance.nameplates:StoreCurrentCVars()
    KvChatDistance.nameplates:ChangeCVars()

    -- Extra hack to reduce visual interference from nameplates - Hide the frames as soon we can
    -- We care about nameplates being created/removed - It doesn't matter if they're invisible
    -- The game will re-show them on recreation anyway (or even just turning the camera)
    if hideNameplatesDuringTrick then
        local nameplates = C_NamePlate.GetNamePlates()
        for _, nameplate in pairs(nameplates) do
            -- TODO: Filter by friend/enemy/etc in regards to cvars
            nameplate:Hide()
        end
    end
end

function KvChatDistance.nameplates:Hide()
    if KvChatDistance.InCombat() then return end
    KvChatDistance:Debug("Hiding Nameplates")

    KvChatDistance.nameplates:UndoCVarChanges()

    -- Clear tracking of our manipulation of the CVars
    KvChatDistance.nameplates.cvars_mutated = false
end

-- --------------------------------------------------------------------------------------------------------------------
-- Ticker
-- --------------------------------------------------------
function KvChatDistance.nameplates.TickerFunc()
    local settings = KvChatDistance:GetSettings()
    if not settings.useNameplateTrick then return end

    KvChatDistance.nameplates:ForceShow(settings.hideNameplatesDuringTrick)
    C_Timer.After(settings.nameplateTickerHideDelay, function() KvChatDistance.nameplates:Hide() end)
end

function KvChatDistance.nameplates:StartTicker()
    -- KvChatDistance:Debug("StartTicker")
    KvChatDistance.nameplates:StoreCurrentCVars()

    local settings = KvChatDistance:GetSettings()

    KvChatDistance.nameplates.TickerFunc()

    local ticker = C_Timer.NewTicker(settings.nameplateTickerInterval or 30, KvChatDistance.nameplates.TickerFunc)
    KvChatDistance.nameplates.ticker = ticker
end

function KvChatDistance.nameplates:StopTicker()
    if not KvChatDistance.nameplates.ticker then return end
    KvChatDistance.nameplates:Hide()
    KvChatDistance.nameplates.ticker:Cancel()
end
 
function KvChatDistance.nameplates:ResetTicker()
    KvChatDistance.nameplates:StopTicker()
    KvChatDistance.nameplates:StartTicker()
end