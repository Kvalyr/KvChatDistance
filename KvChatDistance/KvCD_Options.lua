-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local tinsert = _G["tinsert"]
local CreateFrame = _G["CreateFrame"]
local PlaySound = _G["PlaySound"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================
-- This file is a mess -- WIP hacky options frame to be replaced with something not hideous later
-- Please ignore this entire file. I hate options GUIs :)
-- TODO: Delete this
-- ====================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------
-- CreateOptionsMenu
-- --------------------------------------------------------
function KvChatDistance:CreateOptionsMenu()
    local NewOptionFrame = KvChatDistance.OptionsNewOptionFrame
    local NewHeader = KvChatDistance.OptionsNewHeader
    local NewCheckbox = KvChatDistance.OptionsNewCheckbox
    local NewSlider = KvChatDistance.OptionsNewSlider
    local NewEditBox = KvChatDistance.OptionsNewEditBox
    local NewColorPicker = KvChatDistance.OptionsNewColorPicker

    local debugMode = KvChatDistance:GetSettings().debugMode
    local widgetVerticalSpacing = 8
    local widgetHorizontalSpacing = 16
    local subFrameWidth = 275
    local subFrameBGAlpha = 0.65
    local optionsFrameName = "KvChatDistance_OptionsFrame"
    local optionsFrame = NewOptionFrame(UIParent, optionsFrameName, subFrameWidth, widgetVerticalSpacing, widgetHorizontalSpacing/2)
    KvChatDistance.optionsFrame = optionsFrame
    KvChatDistance.optionsFrame.name = "Darken Chat Messages"
    InterfaceOptions_AddCategory(KvChatDistance.optionsFrame)
    optionsFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.65)

    -- This is hacky as hell
    -- Expand all the options categories when the main panel shows
    optionsFrame.refresh = self.OptionsFrameRefresh

    local generalOptionsFrame = NewOptionFrame(KvChatDistance.optionsFrame, optionsFrame:GetName().."_General", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    generalOptionsFrame.name = "General"
    generalOptionsFrame.parent = KvChatDistance.optionsFrame.name
    generalOptionsFrame:SetScale(0.85)
    KvChatDistance.generalOptionsFrame = generalOptionsFrame

    -- L
    local optionsFrameL = NewOptionFrame(generalOptionsFrame, generalOptionsFrame:GetName().."_Left", 200, widgetVerticalSpacing * 2, widgetHorizontalSpacing/2)
    optionsFrameL:SetPoint("TOPLEFT", generalOptionsFrame, "TOPLEFT", widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameL:SetPoint("BOTTOMRIGHT", generalOptionsFrame, "BOTTOM", -widgetHorizontalSpacing, widgetVerticalSpacing)
    -- -- M
    -- local optionsFrameM = NewOptionFrame(generalOptionsFrame, generalOptionsFrame:GetName().."_Mid", 200, widgetVerticalSpacing*2, widgetHorizontalSpacing/2)
    -- optionsFrameM:SetPoint("TOPLEFT", generalOptionsFrame, "TOPLEFT", widgetHorizontalSpacing, -widgetVerticalSpacing)
    -- optionsFrameM:SetPoint("BOTTOMRIGHT", generalOptionsFrame, "BOTTOM", -widgetHorizontalSpacing, widgetVerticalSpacing)
    -- R
    local optionsFrameR = NewOptionFrame(generalOptionsFrame, generalOptionsFrame:GetName().."_Right", 200, widgetVerticalSpacing*2, widgetHorizontalSpacing/2)
    optionsFrameR:SetPoint("TOPRIGHT", generalOptionsFrame, "TOPRIGHT", -widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameR:SetPoint("LEFT", optionsFrameL, "RIGHT", widgetHorizontalSpacing, 0)
    optionsFrameR:SetPoint("BOTTOMRIGHT", generalOptionsFrame, "BOTTOMRIGHT", -widgetHorizontalSpacing, widgetVerticalSpacing)


    local mainToggle = NewCheckbox(optionsFrameL, "enabled")
    mainToggle:SetScale(1.3)
    optionsFrameL.AddWidget(mainToggle)

    -- Say
    -- local sayOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Say", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local sayOptionsParentFrame = optionsFrameL -- sayOptionsFrame
    sayOptionsParentFrame.AddWidget(NewHeader(sayOptionsParentFrame, "Say")) -- TODO: i18n
    sayOptionsParentFrame.AddWidget(NewCheckbox(sayOptionsParentFrame, "sayEnabled"))
    sayOptionsParentFrame.AddWidget(NewSlider(sayOptionsParentFrame, "sayColorMin", 0.0, 1.0, 0.05))
    sayOptionsParentFrame.AddWidget(NewSlider(sayOptionsParentFrame, "sayColorMid", 0.0, 1.0, 0.05))
    sayOptionsParentFrame.AddWidget(NewSlider(sayOptionsParentFrame, "sayColorMax", 0.0, 1.0, 0.05))

    -- Emote
    -- local emoteOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Emote", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local emoteOptionsParentFrame = optionsFrameL -- sayOptionsFrame
    emoteOptionsParentFrame.AddWidget(NewHeader(emoteOptionsParentFrame, "Emote")) -- TODO: i18n
    emoteOptionsParentFrame.AddWidget(NewCheckbox(emoteOptionsParentFrame, "emoteEnabled"))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMin", 0.0, 1.0, 0.05))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMid", 0.0, 1.0, 0.05))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMax", 0.0, 1.0, 0.05))

    -- Yell
    -- local yellOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Yell", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local yellOptionsParentFrame = optionsFrameL -- sayOptionsFrame
    yellOptionsParentFrame.AddWidget(NewHeader(yellOptionsParentFrame, "Yell")) -- TODO: i18n
    yellOptionsParentFrame.AddWidget(NewCheckbox(yellOptionsParentFrame, "yellEnabled"))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMin", 0.0, 1.0, 0.05))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMid", 0.0, 1.0, 0.05))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMax", 0.0, 1.0, 0.05))

    -- Instances
    local instanceOptionsParentFrame = optionsFrameR -- advancedOptionsFrame
    instanceOptionsParentFrame.AddWidget(NewHeader(instanceOptionsParentFrame, "Instances")) -- TODO: i18n
    instanceOptionsParentFrame.AddWidget(NewCheckbox(instanceOptionsParentFrame, "allowInDungeons"))
    instanceOptionsParentFrame.AddWidget(NewCheckbox(instanceOptionsParentFrame, "allowInRaids"))
    instanceOptionsParentFrame.AddWidget(NewCheckbox(instanceOptionsParentFrame, "allowInScenarios"))

    -- Advanced
    -- local advancedOptionsFrame = NewOptionFrame(optionsFrameL, optionsFrame:GetName().."_Advanced", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local advancedOptionsParentFrame = optionsFrameR -- advancedOptionsFrame
    local function resetNameplateTicker() KvChatDistance:ResetTicker("nameplates") end
    advancedOptionsParentFrame.AddWidget(NewHeader(advancedOptionsParentFrame, " "))
    advancedOptionsParentFrame.AddWidget(NewHeader(advancedOptionsParentFrame, "Advanced")) -- TODO: i18n
    advancedOptionsParentFrame.AddWidget(NewHeader(advancedOptionsParentFrame, " "))
    advancedOptionsParentFrame.AddWidget(NewSlider(advancedOptionsParentFrame, "unknownColor", 0.0, 1.0, 0.05))
    advancedOptionsParentFrame.AddWidget(NewCheckbox(advancedOptionsParentFrame, "useNameplateTrick", nil, resetNameplateTicker))
    advancedOptionsParentFrame.AddWidget(NewHeader(advancedOptionsParentFrame, " ", true))
    advancedOptionsParentFrame.AddWidget(NewSlider(advancedOptionsParentFrame, "nameplateTickerInterval", 1, 60, 1, resetNameplateTicker))

    -- Comms
    local commsOptionsParentFrame = optionsFrameR -- advancedOptionsFrame
    commsOptionsParentFrame.AddWidget(NewHeader(commsOptionsParentFrame, " "))
    commsOptionsParentFrame.AddWidget(NewHeader(commsOptionsParentFrame, "Communications")) -- TODO: i18n
    commsOptionsParentFrame.AddWidget(NewCheckbox(commsOptionsParentFrame, "allowComms", nil, nil))
    commsOptionsParentFrame.AddWidget(NewCheckbox(commsOptionsParentFrame, "positionBroadcastEnabled", nil, nil))

    optionsFrameL:PositionWidgets()
    optionsFrameR:PositionWidgets()
    InterfaceOptions_AddCategory(generalOptionsFrame);

    -- --------------------------------------------------------
    -- Highlights
    local highlightOptionsFrame = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Highlights", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    highlightOptionsFrame.name = "Highlights"
    highlightOptionsFrame.parent = KvChatDistance.optionsFrame.name
    highlightOptionsFrame.AddWidget(NewHeader(highlightOptionsFrame, "Highlights")) -- TODO: i18n

    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightSelf"))
    highlightOptionsFrame.AddWidget(NewColorPicker(highlightOptionsFrame, "highlightSelfColor"))

    highlightOptionsFrame.AddWidget(NewHeader(highlightOptionsFrame, "Friends", true))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightFriends"))
    highlightOptionsFrame.AddWidget(NewColorPicker(highlightOptionsFrame, "highlightFriendsColor"))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightFriendsBypassDistance"))

    highlightOptionsFrame.AddWidget(NewHeader(highlightOptionsFrame, "Guild", true))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGuild"))
    highlightOptionsFrame.AddWidget(NewColorPicker(highlightOptionsFrame, "highlightGuildColor"))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGuildBypassDistance"))

    highlightOptionsFrame.AddWidget(NewHeader(highlightOptionsFrame, "Group", true))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGroup"))
    highlightOptionsFrame.AddWidget(NewColorPicker(highlightOptionsFrame, "highlightGroupColor"))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGroupBypassDistance"))
    highlightOptionsFrame:PositionWidgets()
    InterfaceOptions_AddCategory(highlightOptionsFrame);


    -- --------------------------------------------------------
    -- Prefixes
    local prefixOptionsFrame = NewOptionFrame(KvChatDistance.optionsFrame, optionsFrame:GetName().."_Prefixes", subFrameWidth, widgetVerticalSpacing*1.3, widgetHorizontalSpacing)
    prefixOptionsFrame:SetScale(0.9)
    prefixOptionsFrame.name = "Prefixes"
    prefixOptionsFrame.parent = KvChatDistance.optionsFrame.name
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Prefixes"))

    prefixOptionsFrame.AddWidget(NewColorPicker(prefixOptionsFrame, "prefixColor"))

    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Friends", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixFriends", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixFriends_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Guild", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixGuild", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixGuild_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Group", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixGroup", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixGroup_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Strangers", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixStrangers", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixStrangers_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Target", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixTarget", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixTarget_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Focus", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixFocus", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixFocus_Str", nil, nil))
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "NPCs", true))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixNPCs", nil, nil))
    prefixOptionsFrame.AddWidget(NewEditBox(prefixOptionsFrame, "prefixNPCs_Str", nil, nil))
    prefixOptionsFrame:PositionWidgets()
    InterfaceOptions_AddCategory(prefixOptionsFrame);


    -- --------------------------------------------------------
    -- Debug Options
    if debugMode or self.constants.playerName == "Blacktongue" then
        local debugOptionsFrame = NewOptionFrame(KvChatDistance.optionsFrame, optionsFrame:GetName().."_Debug", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
        debugOptionsFrame.name = "Debug"
        debugOptionsFrame.parent = KvChatDistance.optionsFrame.name

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Debug"))
        debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "debugMode", nil, nil))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "debugLevel", 1, 4, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "unitSearchTargetDepth", 1, 10, 1))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Nameplates"))
        debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "hideNameplatesDuringTrick", nil, resetNameplateTicker))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "nameplateTickerHideDelay", 0.001, 3.00, 0.001, resetNameplateTicker))
        -- debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "showLanguage"))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Distance"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "highlightDistanceOffset", 0, 25, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "veryNearDistanceThreshold", 0, 30, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "nearDistanceThreshold", 5, 60, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "midDistanceThreshold", 25, 60, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "farDistanceThreshold", 60, 200, 1))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Position Cache"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "positionCacheTickerInterval", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "positionCacheTTL", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Range Cache"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "rangeCacheTickerInterval", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "rangeCacheTTL", 15, 600, 1))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Comms"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsBroadcastTickerInterval", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsThrottleDuration", 10, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsThrottleDuration_RV", 10, 600, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsThrottleTickerInterval", 1, 600, 1))
        debugOptionsFrame:PositionWidgets()
        -- debugOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
        -- debugOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
        -- debugOptionsFrame:SetWidth(270)
        -- optionsFrameL.AddWidget(debugOptionsFrame)
        InterfaceOptions_AddCategory(debugOptionsFrame);
    end
end
