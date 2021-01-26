-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local C_CVar = _G["C_CVar"]
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
-- Show/Hide by manipulating CVars
-- --------------------------------------------------------
function KvChatDistance.nameplates:StoreCurrentCVars()
    -- Don't store values if we currently consider them modified by us
    if KvChatDistance.nameplates.cvars_mutated then return end

    KvChatDistance.nameplates["nameplateShowAll"] = C_CVar.GetCVar("nameplateShowAll")
    KvChatDistance.nameplates["nameplateShowFriends"] = C_CVar.GetCVar("nameplateShowFriends")
    KvChatDistance.nameplates["nameplateShowEnemies"] =  C_CVar.GetCVar("nameplateShowEnemies")
end

function KvChatDistance.nameplates:ForceShow()
    if KvChatDistance.InCombat() then return end
    -- KLib:Con("KvChatDistance","Showing Nameplates")
    -- TODO: Track user's configured normal state for nameplates

    -- Risky assumption here: If CVars are already enabled, assume that the player has enabled them since last tick
    KvChatDistance.nameplates:StoreCurrentCVars()

    C_CVar.SetCVar("nameplateShowAll", 1)
    C_CVar.SetCVar("nameplateShowEnemies", 1)
    C_CVar.SetCVar("nameplateShowFriends", 1)

    -- TODO: Maybe if user has nameplates disabled, hide them immediately when we enable them just to grab range info
    -- local nameplates = C_NamePlate.GetNamePlates()
    -- for _, nameplate in pairs(nameplates) do
    --     -- TODO: Filter by friend/enemy/etc in regards to cvars
    --     nameplate:Hide()
    -- end

    -- Track that we have changed the cvar state
    KvChatDistance.nameplates.cvars_mutated = true
end


function KvChatDistance.nameplates:Hide()
    if KvChatDistance.InCombat() then return end
    -- KLib:Con("KvChatDistance","Hiding Nameplates")

    -- Try to only hide nameplates if the user has them hidden ordinarily
    C_CVar.SetCVar("nameplateShowAll", KvChatDistance.nameplates["nameplateShowAll"] or C_CVar.GetCVarDefault("nameplateShowAll"))
    C_CVar.SetCVar("nameplateShowFriends", KvChatDistance.nameplates["nameplateShowFriends"] or C_CVar.GetCVarDefault("nameplateShowFriends"))
    C_CVar.SetCVar("nameplateShowEnemies", KvChatDistance.nameplates["nameplateShowEnemies"] or C_CVar.GetCVarDefault("nameplateShowEnemies"))

    -- Clear tracking of our manipulation of the CVars
    KvChatDistance.nameplates.cvars_mutated = false
end

-- --------------------------------------------------------------------------------------------------------------------
-- Ticker
-- --------------------------------------------------------
function KvChatDistance.nameplates.TickerFunc()
    local settings = KvChatDistance:GetSettings()

    if settings.useNameplateTrick then
        KvChatDistance.nameplates:ForceShow()
        C_Timer.After(0.01, function() KvChatDistance.nameplates:Hide() end)
    end
end

function KvChatDistance.nameplates:StartTicker()
    -- KLib:Con("KvChatDistance","StartTicker")
    -- TODO: Cancel and restart ticker if settings change
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