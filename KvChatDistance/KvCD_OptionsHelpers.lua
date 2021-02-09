-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local tinsert = _G["tinsert"]
local CreateFrame = _G["CreateFrame"]
local PlaySound = _G["PlaySound"]
local PlaySoundKitID = _G["PlaySoundKitID"]
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

function KvChatDistance:OptionsGetGeneralFrameButton()
    -- Hacky way to get the '+' button to expand options categories
    local interfaceOptionsButtonName = "InterfaceOptionsFrameAddOnsButton"
    for i=1, 100 do
        local buttonName = interfaceOptionsButtonName..i
        local button = _G[buttonName]
        -- self:Debug("OpenOptionsMenu", buttonName)
        if button and button:GetText() == self.generalOptionsFrame.name and button.element == self.generalOptionsFrame then
            return button
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

function KvChatDistance:OptionsExpandGeneralCategory()
    local button = KvChatDistance:OptionsGetGeneralFrameButton():Click()
    if button then
        button:Click()
    end
end

local buttonHooked = false
function KvChatDistance.OptionsFrameRefresh()
    -- Do this on refresh with a doOnce check - Lazy
    if buttonHooked then return end
    local optionsFrameButton = KvChatDistance:OptionsGetFrameButton(false)
    if optionsFrameButton then
        optionsFrameButton:HookScript("OnClick",
            function()
                KvChatDistance:OptionsExpandCategories()
                KvChatDistance:OptionsExpandGeneralCategory()
            end)
        buttonHooked = true
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

function KvChatDistance.OptionsNewCheckbox(parent, variableName, onClickFunction, changedCallback)
    local i18n = KvChatDistance.i18n

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
function KvChatDistance.OptionsNewSlider(parent, variableName, minVal, maxVal, step, changedCallback)
    local i18n = KvChatDistance.i18n

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
function KvChatDistance.OptionsNewOptionFrame(parent, frameName, initialWidth, widgetVerticalSpacing, widgetHorizontalSpacing)
    -- local i18n = KvChatDistance.i18n

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

function KvChatDistance.OptionsNewHeader(parentFrame, headerText)
    local i18n = KvChatDistance.i18n

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

function KvChatDistance:OpenOptionsMenu()
    -- Run it twice, because the first one only opens the main interface window.
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)

end
