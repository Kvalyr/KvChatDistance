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

-- TODO: Replace with proper i18n functionality
local i18n = {}
i18n["enabled"] = "Main Toggle"
i18n["enabled_desc"] = "Toggles all functionality of the addon."

i18n["allowInDungeons"] = "Enable in Dungeons"
i18n["allowInRaids"] = "Enable in Raids"
i18n["allowInScenarios"] = "Enable in Scenarios"

i18n["highlightFriends"] = "Highlight Friends"
i18n["highlightFriends_desc"] = "Toggles highlighting of friends' messages in chat."
i18n["highlightFriends_descextra"] = "They will not be affected by distance."
i18n["highlightGuild"] = "Highlight Guild Members"
i18n["highlightGuild_desc"] = "Toggles highlighting of guild members' messages in chat."
i18n["highlightGuild_descextra"] = "They will not be affected by distance."
i18n["highlightGroup"] = "Highlight Group Members"
i18n["highlightGroup_desc"] = "Toggles highlighting of group members' messages in chat."
i18n["highlightGroup_descextra"] = "They will not be affected by distance."

i18n["unitSearchTargetDepth"] = "Target Search Depth"
i18n["unitSearchTargetDepth_desc"] = "How many targets deep to search on checked units. Higher values reduce performance."
-- i18n["unitSearchTargetDepth_descextra"] = "How many targets deep to search on checked units. Higher values reduce performance."
i18n["useNameplateTrick"] = "Momentary Nameplate Scan"
i18n["useNameplateTrick_desc"] = "Momentarily enable all nameplates on an interval."
i18n["useNameplateTrick_descextra"] = "When enabled, this option forces nameplates to show for a split-second on an interval (set with the slider below) so that range information can be grabbed from the nameplates for units visible in your field of view.\n\n|cFFFF00FFWarning: This experimental option may interfere with other addons that control nameplate visibility.|r\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"
i18n["hideNameplatesDuringTrick"] = "Hide Nameplates during scan"
i18n["hideNameplatesDuringTrick_desc"] = "Hides the nameplates when they're being scanned."
i18n["hideNameplatesDuringTrick_descextra"] = "This should reduce the visual impact of the nameplates being toggled on an interval."
i18n["nameplateTickerInterval"] = "Nameplate Scan Interval (secs)"
i18n["nameplateTickerInterval_desc"] = "Sets the interval at which nameplates are briefly enabled so that the addon can grab distance information for nearby players."
i18n["nameplateTickerInterval_descextra"] = "Lower values may result in noticeable flickering."

i18n["sayEnabled"] = "Say (/s)"
i18n["sayEnabled_desc"] = "Enable text fading by distance for the 'Say' channel (/s)"
i18n["sayColorMin"] = "Far Say Brightness"
i18n["sayColorMid"] = "Medium Say Brightness"
i18n["sayColorMax"] = "Near Say Brightness"

i18n["emoteEnabled"] = "Emote (/e)"
i18n["emoteEnabled_desc"] = "Enable text fading by distance for the 'Emote' channel (/e)"
i18n["emoteColorMin"] = "Far Emote Brightness"
i18n["emoteColorMid"] = "Medium Emote Brightness"
i18n["emoteColorMax"] = "Near Emote Brightness"

i18n["yellEnabled"] = "Yell (/y)"
i18n["yellEnabled_desc"] = "Enable text fading by distance for the 'Yell' channel (/y)"
i18n["yellColorMin"] = "Far Yell Brightness"
i18n["yellColorMid"] = "Medium Yell Brightness"
i18n["yellColorMax"] = "Near Yell Brightness"

-- Prefixes
i18n["prefixFriends"] = "Friend: Add '[F]' to say/yell messages from friends."
i18n["prefixGuild"] = "Guild: Add '[G]' to say/yell messages from members of your guild."
i18n["prefixGroup"] = "Group: Add '[P]' to say/yell messages from people in your party/raid."
i18n["prefixStrangers"] = "Strangers: Add '[S]' to say/yell messages from players not in your friends, guild or group."
i18n["prefixTarget"] = "Target: Add '[T]' to say/yell messages from your current target."
i18n["prefixFocus"] = "Focus: Add '[X]' to say/yell messages from your current focus target."
i18n["prefixNPCs"] = "NPCs: Add '[NPC]' to say/yell messages from NPCs."

-- Comms
i18n["allowComms"] = "Toggle Addon Communication"
i18n["allowComms_desc"] = "Controls whether or not this addon can communicate silently with other users of the addon to improve range calculation accuracy."
i18n["allowComms_descextra"] = "Note: addon communication is fully disabled during combat, arenas and battlegrounds.\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"
i18n["positionBroadcastEnabled"] = "Toggle Sending Position to other users"
i18n["positionBroadcastEnabled_desc"] = "Controls whether or not your current world coordinates are sent to other users of the addon for more accurate range calculation."
i18n["positionBroadcastEnabled_descextra"] = "This option allows you to disable broadcasting your position in case you have privacy concerns.\n\n|cFFFF00FFNote: Your position is never sent during combat or to opposite-faction players.|r\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"

-- i18n["veryNearDistanceThreshold"] = "[Very Near] Range"
-- i18n["veryNearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Very Near'."

-- i18n["nearDistanceThreshold"] = "[Near] Range"
-- i18n["nearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Near'."

-- i18n["midDistanceThreshold"] = "[Mid] Range"
-- i18n["midDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Mid-Range'."

-- i18n["farDistanceThreshold"] = "[Far] Range"
-- i18n["farDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Far'."

function KvChatDistance:OptionsGetFrameButton(toggle)
    -- Hacky way to get the '+' button to expand options categories
    local interfaceOptionsButtonName = "InterfaceOptionsFrameAddOnsButton"
    for i=1, 100 do
        local buttonName = interfaceOptionsButtonName..i
        local button = _G[buttonName]
        -- self:Debug("OpenOptionsMenu", buttonName)
        if button and button:GetText() == self.optionsFrame.name then
            if not toggle then
                return button
            else
                local toggleButton = _G[buttonName.."Toggle"]
                if toggleButton then
                    return toggleButton
                end
                return
            end
        end
    end
end

local categoriesExpanded = false
function KvChatDistance:OptionsExpandCategories()
    local toggleButton = self:OptionsGetFrameButton(true)
    if toggleButton and not categoriesExpanded then
        toggleButton:Click()
        categoriesExpanded = true
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Checkbox
-- --------------------------------------------------------

local function CheckboxOnClick(self)
    local checked = self:GetChecked()
    PlaySound(PlaySoundKitID and "igMainMenuOptionCheckBoxOn" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    self:SetValue(checked)
end

local function NewCheckbox(parent, variableName, onClickFunction, changedCallback)
    onClickFunction = onClickFunction or CheckboxOnClick
    -- local displayData = CanIMogItOptions_DisplayData[variableName]
    local checkbox = CreateFrame("CheckButton", "KVCD_Widget_" .. variableName, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.extraSpacing = 0

    checkbox.value = _G["KvChatDistance_SV"].settings[variableName]
    checkbox.GetValue = function (self)
        return _G["KvChatDistance_SV"].settings[variableName]
    end
    checkbox.SetValue = function (self, value)
        _G["KvChatDistance_SV"].settings[variableName] = value
        if changedCallback then changedCallback(checkbox, value) end
    end

    local onShowFunction = function() checkbox:SetChecked(checkbox:GetValue()) end
    checkbox:SetScript("OnShow", onShowFunction)

    checkbox:SetScript("OnClick", onClickFunction)
    checkbox:SetChecked(checkbox:GetValue())

    checkbox.label = _G[checkbox:GetName() .. "Text"]
    checkbox.label:SetText(i18n[variableName] or variableName)

    checkbox.tooltipText = i18n[variableName.."_desc"] or i18n[variableName] or variableName
    checkbox.tooltipRequirement = i18n[variableName.."_descextra"] or ""
    return checkbox
end

-- --------------------------------------------------------------------------------------------------------------------
-- Slider
-- --------------------------------------------------------
local function NewSlider(parent, variableName, minVal, maxVal, step, changedCallback)
    local widget = CreateFrame("Slider", "KVCD_Widget_" .. variableName, parent, "OptionsSliderTemplate")
    widget.valueStep = step
    widget:SetMinMaxValues(minVal, maxVal)
    widget:SetObeyStepOnDrag(true)
    widget:SetValueStep(step)
    widget.extraSpacing = 8
    widget:SetWidth(200)

    widget.curVal = widget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    widget.curVal:SetPoint("BOTTOM", 0, -10)

    widget.OnMinMaxChanged = function(self)
        _G[widget:GetName() .. 'Low']:SetText(minVal)
        _G[widget:GetName() .. 'High']:SetText(maxVal)
    end
    widget:SetScript("OnMinMaxChanged", widget.OnMinMaxChanged)

    widget.OnShow = function(self, newValue)
        if not newValue then
            local decimalPlaces = math.min(KvChatDistance.CountDecimalPlaces(widget.valueStep), 3)
            newValue = KvChatDistance.RoundNumber(self:GetValue(), decimalPlaces)
        end
        self.curVal:SetText(newValue)
    end

    widget.OnValueChanged = function(self, newValue, ...)
        local decimalPlaces = math.min(KvChatDistance.CountDecimalPlaces(widget.valueStep), 3)
        -- KvChatDistance:Debug(widget, "OnValueChanged", newValue, ...)

        newValue = KvChatDistance.RoundNumber(newValue or self:GetValue(), decimalPlaces)

        _G["KvChatDistance_SV"].settings[variableName] = newValue
        if changedCallback then changedCallback(self, newValue) end
        self:OnShow(newValue)
    end
    widget:SetScript("OnValueChanged", widget.OnValueChanged)
    widget:SetScript("OnShow", widget.OnShow)

    widget:SetValue(_G["KvChatDistance_SV"].settings[variableName])

    widget.label = _G[widget:GetName() .. "Text"]
    widget.label:SetText(i18n[variableName] or variableName)
    widget.tooltipText = i18n[variableName.."_desc"] or i18n[variableName] or variableName
    widget.tooltipRequirement = i18n[variableName.."_descextra"] or ""

    return widget
end

-- --------------------------------------------------------------------------------------------------------------------
-- Option Frame
-- --------------------------------------------------------
local function NewOptionFrame(parent, frameName, initialWidth, widgetVerticalSpacing, widgetHorizontalSpacing)
    local subFrame = CreateFrame( "Frame", frameName, parent, BackdropTemplateMixin and "BackdropTemplate" )
    subFrame:SetWidth(initialWidth)

    subFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }}
    )
    subFrame:SetBackdropColor(0.3, 0.3, 0.3, 0.0)
    subFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.0)

    local widgets = {}
    subFrame.widgets = widgets
    subFrame.minHeightForWidgets = widgetVerticalSpacing

    subFrame.AddWidget = function(widget)
        tinsert(widgets, widget)
        local extraSpacing = (widget.extraSpacing or 0) + widgetVerticalSpacing
        subFrame.minHeightForWidgets = subFrame.minHeightForWidgets + widget:GetHeight() + extraSpacing
    end

    subFrame.PositionWidgets = function()
        -- local widgetIndex = 0
        local prevWidget
        for _, widget in pairs(widgets) do
            if not prevWidget then
                widget:SetPoint("TOPLEFT", widgetHorizontalSpacing, -((widgetVerticalSpacing / 2) + (widget.extraSpacing or 0)))
            else
                local extraSpacing = prevWidget.extraSpacing or 0
                widget:SetPoint("LEFT", widgetHorizontalSpacing, 0)
                widget:SetPoint("TOP", prevWidget, "BOTTOM", 0, -(widgetVerticalSpacing + extraSpacing))
            end
            -- widgetIndex = widgetIndex + 1
            prevWidget = widget
        end
        subFrame:SetHeight(subFrame.minHeightForWidgets)
    end

    return subFrame
end

local function NewHeader(parentFrame, headerText)
    local frameName = parentFrame:GetName().."_Header"

    -- local frame = CreateFrame("Frame", frameName, nil, BackdropTemplateMixin and "BackdropTemplate")
    -- frame:SetSize(1,1)
    -- frame:SetPoint("CENTER", 0, 0)

    local frame = parentFrame
    local fontString = frame:CreateFontString(frameName.."_FS", "OVERLAY", "GameFontNormalLarge")
    fontString:SetPoint("CENTER", 0, 0)
    fontString:SetText(headerText)

    -- frame.fontString = fontString
    -- frame:SetWidth(fontString:GetStringWidth())
    -- frame:SetHeight(fontString:GetStringHeight())

    return fontString
    -- return frame
end

-- --------------------------------------------------------------------------------------------------------------------
-- CreateOptionsMenu
-- --------------------------------------------------------
function KvChatDistance:CreateOptionsMenu()
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
    optionsFrame:SetScale(0.85)


    -- This is hacky as hell
    local buttonHooked = false
    -- Expand all the options categories when the main panel shows
    optionsFrame.refresh = function()
        -- if optionsFrame:IsVisible() then KvChatDistance:OptionsExpandCategories() end
        if buttonHooked then return end
        local optionsFrameButton = self:OptionsGetFrameButton(false)
        if optionsFrameButton then
            optionsFrameButton:HookScript("OnClick", function() KvChatDistance:OptionsExpandCategories() end)
            buttonHooked = true
        end
    end
    -- optionsFrame:SetScript("OnShow", function() KvChatDistance:OptionsExpandCategories() end)

    -- L
    local optionsFrameL = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Left", 200, widgetVerticalSpacing * 2, widgetHorizontalSpacing/2)
    optionsFrameL:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameL:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOM", -widgetHorizontalSpacing, widgetVerticalSpacing)
    -- -- M
    -- local optionsFrameM = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Mid", 200, widgetVerticalSpacing*2, widgetHorizontalSpacing/2)
    -- optionsFrameM:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", widgetHorizontalSpacing, -widgetVerticalSpacing)
    -- optionsFrameM:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOM", -widgetHorizontalSpacing, widgetVerticalSpacing)
    -- R
    local optionsFrameR = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Right", 200, widgetVerticalSpacing*2, widgetHorizontalSpacing/2)
    optionsFrameR:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameR:SetPoint("LEFT", optionsFrameL, "RIGHT", widgetHorizontalSpacing, 0)
    optionsFrameR:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -widgetHorizontalSpacing, widgetVerticalSpacing)

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
    -- sayOptionsFrame:PositionWidgets()
    -- sayOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- sayOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- sayOptionsFrame:SetWidth(180)
    -- optionsFrameR.AddWidget(sayOptionsFrame)

    -- Emote
    -- local emoteOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Emote", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local emoteOptionsParentFrame = optionsFrameL -- sayOptionsFrame
    emoteOptionsParentFrame.AddWidget(NewHeader(emoteOptionsParentFrame, "Emote")) -- TODO: i18n
    emoteOptionsParentFrame.AddWidget(NewCheckbox(emoteOptionsParentFrame, "emoteEnabled"))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMin", 0.0, 1.0, 0.05))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMid", 0.0, 1.0, 0.05))
    emoteOptionsParentFrame.AddWidget(NewSlider(emoteOptionsParentFrame, "emoteColorMax", 0.0, 1.0, 0.05))
    -- emoteOptionsFrame:PositionWidgets()
    -- emoteOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- emoteOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- emoteOptionsFrame:SetWidth(180)
    -- optionsFrameR.AddWidget(emoteOptionsFrame)

    -- Yell
    -- local yellOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Yell", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    local yellOptionsParentFrame = optionsFrameL -- sayOptionsFrame
    yellOptionsParentFrame.AddWidget(NewHeader(yellOptionsParentFrame, "Yell")) -- TODO: i18n
    yellOptionsParentFrame.AddWidget(NewCheckbox(yellOptionsParentFrame, "yellEnabled"))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMin", 0.0, 1.0, 0.05))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMid", 0.0, 1.0, 0.05))
    yellOptionsParentFrame.AddWidget(NewSlider(yellOptionsParentFrame, "yellColorMax", 0.0, 1.0, 0.05))
    -- yellOptionsFrame:PositionWidgets()
    -- yellOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- yellOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- yellOptionsFrame:SetWidth(180)
    -- optionsFrameR.AddWidget(yellOptionsFrame)

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
    -- advancedOptionsFrame.name = "Advanced"
    -- advancedOptionsFrame.parent = KvChatDistance.optionsFrame.name
    -- InterfaceOptions_AddCategory(advancedOptionsFrame);
    advancedOptionsParentFrame.AddWidget(NewHeader(advancedOptionsParentFrame, "Advanced")) -- TODO: i18n
    advancedOptionsParentFrame.AddWidget(NewCheckbox(advancedOptionsParentFrame, "useNameplateTrick", nil, resetNameplateTicker))
    advancedOptionsParentFrame.AddWidget(NewSlider(advancedOptionsParentFrame, "nameplateTickerInterval", 1, 60, 1, resetNameplateTicker))
    -- advancedOptionsFrame:PositionWidgets()
    -- advancedOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- advancedOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- advancedOptionsFrame:SetWidth(270)
    -- optionsFrameL.AddWidget(advancedOptionsFrame)


    -- Comms
    local commsOptionsParentFrame = optionsFrameR -- advancedOptionsFrame
    commsOptionsParentFrame.AddWidget(NewHeader(commsOptionsParentFrame, "Communications")) -- TODO: i18n
    commsOptionsParentFrame.AddWidget(NewCheckbox(commsOptionsParentFrame, "allowComms", nil, nil))
    commsOptionsParentFrame.AddWidget(NewCheckbox(commsOptionsParentFrame, "positionBroadcastEnabled", nil, nil))

    local highlightOptionsFrame = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Highlights", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    highlightOptionsFrame.name = "Highlights"
    highlightOptionsFrame.parent = KvChatDistance.optionsFrame.name
    InterfaceOptions_AddCategory(highlightOptionsFrame);
    highlightOptionsFrame.AddWidget(NewHeader(highlightOptionsFrame, "Highlights")) -- TODO: i18n
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGuild"))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightFriends"))
    highlightOptionsFrame.AddWidget(NewCheckbox(highlightOptionsFrame, "highlightGroup"))
    highlightOptionsFrame:PositionWidgets()
    -- highlightOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- highlightOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    -- optionsFrameL.AddWidget(highlightOptionsFrame)

    -- Prefixes
    local prefixOptionsFrame = NewOptionFrame(KvChatDistance.optionsFrame, optionsFrame:GetName().."_Prefixes", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    prefixOptionsFrame.name = "Prefixes"
    prefixOptionsFrame.parent = KvChatDistance.optionsFrame.name
    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "Prefixes"))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixFriends", nil, nil))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixGuild", nil, nil))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixGroup", nil, nil))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixStrangers", nil, nil))

    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixTarget", nil, nil))
    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixFocus", nil, nil))

    prefixOptionsFrame.AddWidget(NewCheckbox(prefixOptionsFrame, "prefixNPCs", nil, nil))

    prefixOptionsFrame.AddWidget(NewHeader(prefixOptionsFrame, "[ Configurable Prefixes Not Implemented Yet ]"))
    prefixOptionsFrame:PositionWidgets()
    InterfaceOptions_AddCategory(prefixOptionsFrame);

    -- Debug Options
    if debugMode or self.constants.playerName == "Blacktongue" then
        local debugOptionsFrame = NewOptionFrame(KvChatDistance.optionsFrame, optionsFrame:GetName().."_Debug", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
        debugOptionsFrame.name = "Debug"
        debugOptionsFrame.parent = KvChatDistance.optionsFrame.name
        InterfaceOptions_AddCategory(debugOptionsFrame);

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Debug"))
        debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "debugMode", nil, nil))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "debugLevel", 1, 4, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "unitSearchTargetDepth", 1, 10, 1))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Nameplates"))
        debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "hideNameplatesDuringTrick", nil, resetNameplateTicker))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "nameplateTickerHideDelay", 0.001, 3.00, 0.001, resetNameplateTicker))
        -- debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "prefixStrangers", nil, nil))
        -- debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "prefixNPCs", nil, nil))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "veryNearDistanceThreshold", 0, 30, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "nearDistanceThreshold", 5, 60, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "midDistanceThreshold", 25, 60, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "farDistanceThreshold", 60, 200, 1))
        -- debugOptionsFrame.AddWidget(NewCheckbox(debugOptionsFrame, "showLanguage"))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Position Cache"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "positionCacheTickerInterval", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "positionCacheTTL", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Range Cache"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "rangeCacheTickerInterval", 15, 600, 1))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "rangeCacheTTL", 15, 600, 1))

        debugOptionsFrame.AddWidget(NewHeader(debugOptionsFrame, "Comms"))
        debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsBroadcastTickerInterval", 15, 600, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsThrottleDuration", 1, 600, 1))
        -- debugOptionsFrame.AddWidget(NewSlider(debugOptionsFrame, "commsThrottleTickerInterval", 1, 600, 1))
        debugOptionsFrame:PositionWidgets()
        -- debugOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
        -- debugOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
        -- debugOptionsFrame:SetWidth(270)
        -- optionsFrameL.AddWidget(debugOptionsFrame)
    end
    optionsFrameL:PositionWidgets()
    optionsFrameR:PositionWidgets()
end

function KvChatDistance:OpenOptionsMenu()
    -- Run it twice, because the first one only opens the main interface window.
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)

end
