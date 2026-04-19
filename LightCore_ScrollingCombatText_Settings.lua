local OPTION_CONTROL_X_OFFSET = 150
local OPTION_DROPDOWN_WIDTH = 220
local OPTION_SLIDER_X_OFFSET = 120
local OPTION_SLIDER_WIDTH = 260

LightCore_ScrollingCombatText.HORIZONTAL_ALIGNMENT_OPTIONS = {
    { value = "LEFT", label = "Left" },
    { value = "CENTER", label = "Center" },
    { value = "RIGHT", label = "Right" },
}

LightCore_ScrollingCombatText.GROW_DIRECTION_OPTIONS = {
    { value = "UP", label = "Up" },
    { value = "DOWN", label = "Down" },
}

function LightCore_ScrollingCombatText.BuildOptionData(options)
    local container = Settings.CreateControlTextContainer()
    for _, option in ipairs(options) do
        container:Add(option.value, option.label)
    end
    return container:GetData()
end

function LightCore_ScrollingCombatText.AttachTooltip(widget, title, tooltip)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function LightCore_ScrollingCombatText.CreateCheckbox(parentFrame, relativeTo, x, y, label, tooltip, setting)
    local checkbox = CreateFrame("CheckButton", nil, parentFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)
    checkbox:SetChecked(setting:GetValue())
    checkbox:SetScript("OnClick", function(self)
        setting:SetValue(self:GetChecked())
    end)
    local labelRegion = checkbox.Text or checkbox.text
    if labelRegion then
        labelRegion:SetText(label)
    end
    setting:SetValueChangedCallback(function(_, value)
        checkbox:SetChecked(value)
    end)
    LightCore_ScrollingCombatText.AttachTooltip(checkbox, label, tooltip)
    return checkbox
end

local function CreateSlider(parentFrame, config, defaultWidth)
    local slider = CreateFrame("Frame", nil, parentFrame, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(config.width or defaultWidth or OPTION_SLIDER_WIDTH)
    local options = Settings.CreateSliderOptions(config.minValue, config.maxValue, config.step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, config.formatter)
    slider:Init(config.setting:GetValue(), options.minValue, options.maxValue, options.steps, options.formatters)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        config.setting:SetValue(value)
    end)
    config.setting:SetValueChangedCallback(function(_, value)
        slider:SetValue(value)
    end)
    LightCore_ScrollingCombatText.AttachTooltip(slider.Slider or slider, config.title or config.label, config.tooltip)
    return slider
end

function LightCore_ScrollingCombatText.CreateInlineSlider(parentFrame, relativeTo, x, y, config)
    local slider = CreateSlider(parentFrame, config, 240)
    slider:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)
    return slider
end

function LightCore_ScrollingCombatText.CreateLabeledSlider(parentFrame, relativeTo, yOffset, config)
    local row = CreateFrame("Frame", nil, parentFrame)
    row:SetSize(560, 34)
    row:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, yOffset)

    local labelFS = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)
    labelFS:SetText(config.label)

    local slider = CreateSlider(row, config)
    slider:SetPoint("LEFT", row, "LEFT", OPTION_SLIDER_X_OFFSET, 0)
    return row
end

function LightCore_ScrollingCombatText.CreateLabeledDropdown(parentFrame, relativeTo, yOffset, config)
    local row = CreateFrame("Frame", nil, parentFrame)
    row:SetSize(560, 34)
    row:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, yOffset)

    local labelFS = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelFS:SetPoint("LEFT", row, "LEFT", 0, 0)
    labelFS:SetText(config.label)

    local control = CreateFrame("Frame", nil, row, "SettingsDropdownWithButtonsTemplate")
    control:SetPoint("LEFT", row, "LEFT", OPTION_CONTROL_X_OFFSET, 0)
    control.Dropdown:SetWidth(config.width or OPTION_DROPDOWN_WIDTH)
    if not control.Dropdown.SetTooltipFunc then
        Mixin(control.Dropdown, DefaultTooltipMixin)
        control.Dropdown:SetDefaultTooltipAnchors()
        control.Dropdown:InitDefaultTooltipScriptHandlers()
    end

    local function RefreshDropdown()
        local inserter = Settings.CreateDropdownOptionInserter(config.setting, config.optionsFn)
        local function InitTip()
            Settings.InitTooltip(config.label, config.tooltip)
        end
        Settings.InitDropdown(control.Dropdown, config.setting, inserter, InitTip)
    end

    RefreshDropdown()
    config.setting:SetValueChangedCallback(function()
        RefreshDropdown()
    end)
    LightCore_ScrollingCombatText.AttachTooltip(control.Dropdown, config.label, config.tooltip)
    return row
end

function LightCore_ScrollingCombatText.CreateTestButton(parentFrame)
    local testButton = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    testButton:SetSize(180, 24)
    testButton:SetText("Test")
    testButton:SetScript("OnClick", function()
        LightCore_ScrollingCombatText.RunSimulation()
    end)
    return testButton
end

function LightCore_ScrollingCombatText.CreateMoverLockButton(parentFrame)
    local moverButton = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    moverButton:SetSize(180, 24)
    moverButton:SetText("Toggle Mover Lock")
    moverButton:SetScript("OnClick", function()
        LightCore_ScrollingCombatText.ToggleMoverLock()
    end)
    return moverButton
end

function LightCore_ScrollingCombatText.CreateSettingsPageTitle(parentFrame, text)
    local title = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 7, -22)
    title:SetJustifyH("LEFT")
    title:SetText(text)
    return title
end

local function AddFullFrameAnchors(layout)
    layout:AddAnchorPoint("TOPLEFT", 0, 0)
    layout:AddAnchorPoint("BOTTOMRIGHT", 0, 0)
end

local function CreateSettingsOverview(frame)
    local title = LightCore_ScrollingCombatText.CreateSettingsPageTitle(frame, "LightCore ScrollingCombatText")

    local description = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
    description:SetJustifyH("LEFT")
    description:SetText("Slash commands")

    local commands = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commands:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
    commands:SetJustifyH("LEFT")
    commands:SetText("/lcs, /lcsct")
end

local function CreateSettingsCategory()
    local frame = CreateFrame("Frame")
    frame:SetClipsChildren(true)
    CreateSettingsOverview(frame)

    local category, layout = Settings.RegisterCanvasLayoutCategory(frame, "LightCore ScrollingCombatText")
    AddFullFrameAnchors(layout)
    LightCore_ScrollingCombatText.settingsCategoryID = category:GetID()

    return category
end

local function CreateSettingsSubcategory(parentCategory, name)
    local frame = CreateFrame("Frame")
    frame:SetClipsChildren(true)

    local category, layout = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, name)
    AddFullFrameAnchors(layout)

    return frame, category
end

local function RegisterSettings()
    LightCore_ScrollingCombatText.InitializeDB()

    local category = CreateSettingsCategory()

    local textStyleFrame, textStyleCategory = CreateSettingsSubcategory(category, "Text Styles")
    LightCore_ScrollingCombatText.RegisterTextStyleSettings(textStyleFrame, textStyleCategory)

    local animationFrame, animationCategory = CreateSettingsSubcategory(category, "Animation")
    LightCore_ScrollingCombatText.RegisterAnimationSettings(animationFrame, animationCategory)

    local combatFrame, combatCategory = CreateSettingsSubcategory(category, "Combat Flags")
    LightCore_ScrollingCombatText.RegisterCombatFlagSettings(combatFrame, combatCategory)

    Settings.RegisterAddOnCategory(category)
end

EventUtil.ContinueOnAddOnLoaded("LightCore_ScrollingCombatText", RegisterSettings)
