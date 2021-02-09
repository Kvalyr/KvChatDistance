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
        if button and button:GetText() == self.optionsFrame.name and button.element and button.element:GetName() == self.optionsFrame:GetName() then
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
    local interfaceOptionsButtonName = "InterfaceOptionsFrameAddOnsButton"
    local generalFrameCategoryName = self.generalOptionsFrame.name
    local generalFrameName = self.generalOptionsFrame:GetName()
    for i=1, 100 do
        local buttonName = interfaceOptionsButtonName..i
        local button = _G[buttonName]
        if button and button.element then
            -- self:Debug("OptionsGetGeneralFrameButton", buttonName, button:GetText(), button.element:GetName())
            if (button:GetText() == generalFrameCategoryName) and (button.element:GetName() == generalFrameName) then
                return button
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

function KvChatDistance:OptionsExpandGeneralCategory()
    local button = KvChatDistance:OptionsGetGeneralFrameButton()
    if button then
        button:Click()
    end
end

local function optionsButtonHook(self, ...)
    if self.element ~= KvChatDistance.optionsFrame then return end
    -- KvChatDistance:Debug("optionsFrameButton OnClick", self, self.element)
    KvChatDistance:OptionsExpandCategories()
    KvChatDistance:OptionsExpandGeneralCategory()
end

function KvChatDistance.OptionsFrameRefresh()
    -- Do this on refresh with a doOnce check - Lazy
    local optionsFrameButton = KvChatDistance:OptionsGetFrameButton(false)
    if optionsFrameButton and not optionsFrameButton.kvcdHooked then
        -- KvChatDistance:Debug("OptionsFrameRefresh", "optionsFrameButton", optionsFrameButton:GetName(), optionsFrameButton.element:GetName())
        optionsFrameButton:HookScript("OnClick", optionsButtonHook)
        optionsFrameButton.kvcdHooked = true
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
    local widget = CreateFrame("CheckButton", "KVCD_Widget_" .. variableName, parent, "InterfaceOptionsCheckButtonTemplate")
    widget.extraSpacing = 0
    widget.nextWidgetBottomOffset = -5

    widget.value = _G["KvChatDistance_SV"].settings[variableName]
    widget.GetValue = function (self)
        return _G["KvChatDistance_SV"].settings[variableName]
    end
    widget.SetValue = function (self, value)
        _G["KvChatDistance_SV"].settings[variableName] = value
        if changedCallback then changedCallback(widget, value) end
    end

    local onShowFunction = function() widget:SetChecked(widget:GetValue()) end
    widget:SetScript("OnShow", onShowFunction)

    widget:SetScript("OnClick", onClickFunction)
    widget:SetChecked(widget:GetValue())

    widget.label = _G[widget:GetName() .. "Text"]
    widget.label:SetText(i18n[variableName] or variableName)

    widget.tooltipText = i18n[variableName.."_desc"] or i18n[variableName] or variableName
    widget.tooltipRequirement = i18n[variableName.."_descextra"] or ""
    return widget
end

-- --------------------------------------------------------------------------------------------------------------------
-- EditBox
-- --------------------------------------------------------

local function editBoxOnTextChanged(self, event, text, ...)
    -- KvChatDistance:Debug("editBoxOnTextChanged", self, {event, text, ...})

    if self.updateSettings then
        self.updateSettings(self:GetText())
    end
end
local function editBoxOnEnterPressed(self, event, text, ...)
    -- KvChatDistance:Debug("editBoxOnEnterPressed", self, {event, text, ...})

    self:ClearFocus()
end

function KvChatDistance.OptionsNewEditBox(parent, variableName, onEnterFunction, changedCallback, multiLine)
    local i18n = KvChatDistance.i18n

    local widget = CreateFrame("EditBox", "KVCD_Widget_" .. variableName, parent, "InputBoxTemplate")
    widget.extraSpacing = 0
    widget.horizontalOffset = 10
    widget.nextWidgetBottomOffset = 5

    widget:SetAutoFocus(false)
    widget:SetMultiLine(false)

    onEnterFunction = onEnterFunction or editBoxOnEnterPressed

    widget:SetWidth(100)
    widget:SetHeight(10)
    widget:GetTextInsets() -- BFA Hack still necessary?

    widget.updateSettings = function (newValue)
        -- KvChatDistance:Debug(widget, "updateSettings", variableName, newValue)
        _G["KvChatDistance_SV"].settings[variableName] = newValue
    end

    widget:SetScript("OnEnterPressed", onEnterFunction)
    widget:SetScript("OnEditFocusGained", function() widget.prevValue = widget:GetText() end)
    -- widget:SetScript("OnEditFocusLost", widget.Widget_EditBox_OnEditFocusLost)
    widget:SetScript("OnEscapePressed", function() if widget.prevValue then widget:SetText(widget.prevValue) end; widget:ClearFocus() end)
    widget:SetScript("OnTextChanged", editBoxOnTextChanged)
    -- widget:SetScript("OnArrowPressed", widget.Widget_OnArrowPressed)
    -- hooksecurefunc(widget, "SetText", widget.RefreshText)
    -- hooksecurefunc(widget, "SetMaxLetters", widget.Update)
    -- hooksecurefunc(widget, "SetMaxBytes", widget.Update)
    -- hooksecurefunc(widget, "AddHistoryLine", widget.History_AddLine)

    widget:SetText(_G["KvChatDistance_SV"].settings[variableName])
    widget:SetCursorPosition(0)
    widget:ClearFocus()

    -- widget.value = _G["KvChatDistance_SV"].settings[variableName]
    -- widget.GetValue = function (self)
    --     return _G["KvChatDistance_SV"].settings[variableName]
    -- end
    -- widget.SetValue = function (self, value)
    --     _G["KvChatDistance_SV"].settings[variableName] = value
    --     if changedCallback then changedCallback(widget, value) end
    -- end

    -- local onShowFunction = function() widget:SetChecked(widget:GetValue()) end
    -- widget:SetScript("OnShow", onShowFunction)

    -- widget.label = _G[widget:GetName() .. "Text"]
    -- widget.label:SetText(i18n[variableName] or variableName)

    widget.tooltipText = i18n[variableName.."_desc"] or i18n[variableName] or variableName
    widget.tooltipRequirement = i18n[variableName.."_descextra"] or ""
    return widget
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
    widget.horizontalOffset = 0
    widget.nextWidgetBottomOffset = 5
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
-- Color Picker
-- --------------------------------------------------------
local function ShowColorPicker(r, g, b, a, changedCallback)
    local ColorPickerFrame = _G["ColorPickerFrame"]
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
    ColorPickerFrame.previousValues = {r,g,b,a}
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
    ColorPickerFrame:SetColorRGB(r,g,b)

    -- Force OnShow handler
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

function KvChatDistance.OptionsNewColorPicker(parent, variableName, useAlpha)
    local i18n = KvChatDistance.i18n
    local frameName = "KVCD_Widget_" .. variableName
    local widget = CreateFrame("Button", frameName, parent, BackdropTemplateMixin and "BackdropTemplate" )--, "ChatConfigBorderBoxTemplate")
    widget:SetSize(24,24)

    widget:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }}
    )
    widget:SetBackdropColor(1.0, 1.0, 1.0, 0.0)
    widget:SetBackdropBorderColor(1.0, 1.0, 1.0, 0.5)

    widget.UpdateColor = function(self, r, g, b, a)
        self.texture:SetVertexColor(r, g, b, a or 1.0)
    end

    local function onChanged()
        local newR, newG, newB= _G["ColorPickerFrame"]:GetColorRGB()
        local newA = (useAlpha and _G["OpacitySliderFrame"]:GetValue()) or 1.0
        local newHex
        if useAlpha then
            newHex = KvChatDistance.RGBDecToHex(newR, newG, newB, newA)
        else
            newHex = KvChatDistance.RGBDecToHex(newR, newG, newB)
        end
        widget:UpdateColor(newR, newG, newB, newA)
        -- KvChatDistance:Debug("ColorPicker onChanged()", widget, {newR, newG, newB, newA}, newHex)
        _G["KvChatDistance_SV"].settings[variableName] = newHex or "FFFFFF"
    end

    widget:SetScript("OnClick", function(self)
        local colorHex = _G["KvChatDistance_SV"].settings[variableName] or "FFFFFF"
        local r, g, b, a = KvChatDistance.HexToDec(colorHex)
        a = (useAlpha and (a or 1.0)) or nil
        ShowColorPicker(r, g, b, a or 1.0, onChanged)
    end)

    widget:SetScript("OnShow", function(self)
        self:UpdateColor(KvChatDistance.HexToDec(_G["KvChatDistance_SV"].settings[variableName] or "FFFFFF"))
    end)

    -- Color Texture
    local texture = widget:CreateTexture(nil)
    widget.texture = texture
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")

    local initialColorHex = _G["KvChatDistance_SV"].settings[variableName] or "FFFFFF"
    local initialR, initialG, initialB, initialA = KvChatDistance.HexToDec(initialColorHex)
    widget:UpdateColor(initialR, initialG, initialB, initialA)

    -- Label
    local label = widget:CreateFontString(frameName.."_FS", "OVERLAY", "GameFontNormal")
    label:SetText(i18n[variableName] or variableName)
    label:SetPoint("LEFT", widget, "RIGHT", 4, 0)
    label:SetTextColor(1,1,1,1)

    return widget
end

-- --------------------------------------------------------------------------------------------------------------------
-- Header
-- --------------------------------------------------------
function KvChatDistance.OptionsNewHeader(parentFrame, headerText, subHeader)
    local i18n = KvChatDistance.i18n

    local frameName = parentFrame:GetName().."_Header"

    local frame = parentFrame
    local fontString
    if subHeader then
        fontString = frame:CreateFontString(frameName.."_FS", "OVERLAY", "GameFontNormal")
    else
        fontString = frame:CreateFontString(frameName.."_FS", "OVERLAY", "GameFontNormalLarge")
    end
    fontString:SetPoint("CENTER", 0, 0)
    fontString:SetText(headerText)
    fontString.extraSpacing = 5
    fontString.nextWidgetBottomOffset = -10

    return fontString
end

function KvChatDistance:OpenOptionsMenu()
    -- Run it twice, because the first one only opens the main interface window.
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)

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
        local prevWidget
        for _, widget in pairs(widgets) do
            local horizontalOffset = widgetHorizontalSpacing + (widget.horizontalOffset or 0)
            if not prevWidget then
                widget:SetPoint("TOPLEFT", horizontalOffset, -((widgetVerticalSpacing / 2) + (widget.extraSpacing or 0)))
            else
                local extraSpacing = (prevWidget.extraSpacing or 0) + (prevWidget.nextWidgetBottomOffset or 0)
                widget:SetPoint("LEFT", horizontalOffset, 0)
                widget:SetPoint("TOP", prevWidget, "BOTTOM", 0, -(widgetVerticalSpacing + extraSpacing))
            end
            prevWidget = widget
        end
        subFrame:SetHeight(subFrame.minHeightForWidgets)
    end

    return subFrame
end
