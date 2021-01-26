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

-- TODO: Replace with proper i18n functionality
local i18n = {}
i18n["enabled"] = "Main Toggle"
i18n["enabled_desc"] = "Toggles all functionality of the addon."

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
i18n["useNameplateTrick"] = "Toggle Momentary Nameplate Scan"
i18n["useNameplateTrick_desc"] = "Momentarily enable all nameplates on an interval (set below) so that the addon can more accurately determine distances for non-group members."
i18n["useNameplateTrick_descextra"] = "Warning: This experimental option may interfere with other addons that control nameplate visibility."
i18n["nameplateTickerInterval"] = "Nameplate Scan Interval"
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

-- i18n["veryNearDistanceThreshold"] = "[Very Near] Range"
-- i18n["veryNearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Very Near'."

-- i18n["nearDistanceThreshold"] = "[Near] Range"
-- i18n["nearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Near'."

-- i18n["midDistanceThreshold"] = "[Mid] Range"
-- i18n["midDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Mid-Range'."

-- i18n["farDistanceThreshold"] = "[Far] Range"
-- i18n["farDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Far'."

-- --------------------------------------------------------------------------------------------------------------------
-- Checkbox
-- --------------------------------------------------------

local function CheckboxOnClick(self)
    local checked = self:GetChecked()
    PlaySound(PlaySoundKitID and "igMainMenuOptionCheckBoxOn" or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    self:SetValue(checked)
end

local function NewCheckbox(parent, variableName, onClickFunction)
    onClickFunction = onClickFunction or CheckboxOnClick
    -- local displayData = CanIMogItOptions_DisplayData[variableName]
    local checkbox = CreateFrame("CheckButton", "KVCD_Widget_" .. variableName, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.extraSpacing = 0

    checkbox.value = _G["KvChatDistance_SV"].settings[variableName]
    checkbox.GetValue = function (self)
        return _G["KvChatDistance_SV"].settings[variableName]
    end
    checkbox.SetValue = function (self, value) _G["KvChatDistance_SV"].settings[variableName] = value end

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
local function NewSlider(parent, variableName, minVal, maxVal, step)
    local widget = CreateFrame("Slider", "KVCD_Widget_" .. variableName, parent, "OptionsSliderTemplate")
    widget.extraSpacing = 8

    widget.curVal = widget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    widget.curVal:SetPoint("BOTTOM", 0, -10)

    widget.OnMinMaxChanged = function(self)
        _G[widget:GetName() .. 'Low']:SetText(minVal)
        _G[widget:GetName() .. 'High']:SetText(maxVal)
    end
    widget:SetScript("OnMinMaxChanged", widget.OnMinMaxChanged)

    widget.OnValueChanged = function(self)
        local newValue = KvChatDistance.RoundNumber(widget:GetValue(), 2)
        widget.curVal:SetText(newValue)
        _G["KvChatDistance_SV"].settings[variableName] = newValue
    end
    widget:SetScript("OnValueChanged", widget.OnValueChanged)


    widget:SetMinMaxValues(minVal, maxVal)
    widget:SetValueStep(step)
    widget:SetObeyStepOnDrag(true)
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

-- --------------------------------------------------------------------------------------------------------------------
-- CreateOptionsMenu
-- --------------------------------------------------------
function KvChatDistance:CreateOptionsMenu()
    local widgetVerticalSpacing = 8
    local widgetHorizontalSpacing = 16
    local subFrameWidth = 275
    local subFrameBGAlpha = 0.65
    local optionsFrameName = "KvChatDistance_OptionsFrame"
    local optionsFrame = NewOptionFrame(UIParent, optionsFrameName, subFrameWidth, widgetVerticalSpacing, widgetHorizontalSpacing/2)
    KvChatDistance.optionsFrame = optionsFrame
    KvChatDistance.optionsFrame.name = "KvChatDistance"
    InterfaceOptions_AddCategory(KvChatDistance.optionsFrame)
    optionsFrame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)

    -- L
    local optionsFrameL = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Left", 200, widgetVerticalSpacing*2, widgetHorizontalSpacing/2)
    optionsFrameL:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameL:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOM", -widgetHorizontalSpacing, widgetVerticalSpacing)
    -- R
    local optionsFrameR = NewOptionFrame(optionsFrame, optionsFrame:GetName().."_Right", 200, widgetVerticalSpacing/2, widgetHorizontalSpacing/2)
    optionsFrameR:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -widgetHorizontalSpacing, -widgetVerticalSpacing)
    optionsFrameR:SetPoint("LEFT", optionsFrameL, "RIGHT", widgetHorizontalSpacing, 0)
    optionsFrameR:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -widgetHorizontalSpacing, widgetVerticalSpacing)

    optionsFrameL.AddWidget(NewCheckbox(optionsFrame, "enabled"))
    optionsFrameL.AddWidget(NewCheckbox(optionsFrame, "highlightFriends"))
    optionsFrameL.AddWidget(NewCheckbox(optionsFrame, "highlightGuild"))
    optionsFrameL.AddWidget(NewCheckbox(optionsFrame, "highlightGroup"))

    -- Advanced
    local advancedOptionsFrame = NewOptionFrame(optionsFrameL, optionsFrame:GetName().."_Advanced", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    -- advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "veryNearDistanceThreshold", 0, 30, 1))
    -- advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "nearDistanceThreshold", 5, 60, 1))
    -- advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "midDistanceThreshold", 25, 60, 1))
    -- advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "farDistanceThreshold", 60, 200, 1))
    -- advancedOptionsFrame.AddWidget(NewCheckbox(advancedOptionsFrame, "showLanguage"))
    -- advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "unitSearchTargetDepth", 1, 5, 1))
    advancedOptionsFrame.AddWidget(NewCheckbox(advancedOptionsFrame, "useNameplateTrick"))
    advancedOptionsFrame.AddWidget(NewSlider(advancedOptionsFrame, "nameplateTickerInterval", 1, 60, 1))
    advancedOptionsFrame:PositionWidgets()
    advancedOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    advancedOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    advancedOptionsFrame:SetWidth(270)
    optionsFrameL.AddWidget(advancedOptionsFrame)

    -- Say
    local sayOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Say", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    sayOptionsFrame.AddWidget(NewCheckbox(sayOptionsFrame, "sayEnabled"))
    sayOptionsFrame.AddWidget(NewSlider(sayOptionsFrame, "sayColorMin", 0.0, 1.0, 0.05))
    sayOptionsFrame.AddWidget(NewSlider(sayOptionsFrame, "sayColorMid", 0.0, 1.0, 0.05))
    sayOptionsFrame.AddWidget(NewSlider(sayOptionsFrame, "sayColorMax", 0.0, 1.0, 0.05))
    sayOptionsFrame:PositionWidgets()
    sayOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    sayOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    sayOptionsFrame:SetWidth(180)
    optionsFrameR.AddWidget(sayOptionsFrame)

    -- Emote
    local emoteOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Emote", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    emoteOptionsFrame.AddWidget(NewCheckbox(emoteOptionsFrame, "emoteEnabled"))
    emoteOptionsFrame.AddWidget(NewSlider(emoteOptionsFrame, "emoteColorMin", 0.0, 1.0, 0.05))
    emoteOptionsFrame.AddWidget(NewSlider(emoteOptionsFrame, "emoteColorMid", 0.0, 1.0, 0.05))
    emoteOptionsFrame.AddWidget(NewSlider(emoteOptionsFrame, "emoteColorMax", 0.0, 1.0, 0.05))
    emoteOptionsFrame:PositionWidgets()
    emoteOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    emoteOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    emoteOptionsFrame:SetWidth(180)
    optionsFrameR.AddWidget(emoteOptionsFrame)

    -- Yell
    local yellOptionsFrame = NewOptionFrame(optionsFrameR, optionsFrame:GetName().."_SubFrame_Yell", subFrameWidth, widgetVerticalSpacing * 2, widgetHorizontalSpacing)
    yellOptionsFrame.AddWidget(NewCheckbox(yellOptionsFrame, "yellEnabled"))
    yellOptionsFrame.AddWidget(NewSlider(yellOptionsFrame, "yellColorMin", 0.0, 1.0, 0.05))
    yellOptionsFrame.AddWidget(NewSlider(yellOptionsFrame, "yellColorMid", 0.0, 1.0, 0.05))
    yellOptionsFrame.AddWidget(NewSlider(yellOptionsFrame, "yellColorMax", 0.0, 1.0, 0.05))
    yellOptionsFrame:PositionWidgets()
    yellOptionsFrame:SetBackdropColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    yellOptionsFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, subFrameBGAlpha)
    yellOptionsFrame:SetWidth(180)
    optionsFrameR.AddWidget(yellOptionsFrame)

    optionsFrameL:PositionWidgets()
    optionsFrameR:PositionWidgets()
end

function KvChatDistance:OpenOptionsMenu()
    -- Run it twice, because the first one only opens the main interface window.
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function KvChatDistance:DebugOptionsMenu()
    KvChatDistance:CreateOptionsMenu()
    KvChatDistance:OpenOptionsMenu()
end