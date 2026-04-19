local FONT_OPTIONS = {
    { value = "FRIZQT", label = "Friz Quadrata" },
    { value = "ARIALN", label = "Arial Narrow" },
    { value = "MORPHEUS", label = "Morpheus" },
    { value = "SKURRI", label = "Skurri" },
    { value = "FONT_2002", label = "2002 (Classic UI)" },
    { value = "FONT_2002B", label = "2002 Bold (Classic UI)" },
}

local TEXT_STYLE_OPTIONS = {
    { value = "SHADOW", label = "Shadow" },
    { value = "OUTLINE", label = "Outline" },
    { value = "NONE", label = "None" },
}

function LightCore_ScrollingCombatText.RegisterTextStyleSettings(generalFrame, generalCategory)
    local DB = LightCore_ScrollingCombatText.InitializeDB()

    local topTitle = LightCore_ScrollingCombatText.CreateSettingsPageTitle(generalFrame, "Text Styles")

    local testButton = LightCore_ScrollingCombatText.CreateTestButton(generalFrame)
    testButton:SetPoint("TOPLEFT", topTitle, "BOTTOMLEFT", 0, -18)

    local moverButton = LightCore_ScrollingCombatText.CreateMoverLockButton(generalFrame)
    moverButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0)

    local fontSetting = Settings.RegisterProxySetting(
        generalCategory,
        "LCSCT_FONT",
        Settings.VarType.String, "Font",
        "FRIZQT",
        function() return DB.font end,
        function(value) LightCore_ScrollingCombatText.ApplyFont(value) end
    )
    local fontDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        generalFrame,
        testButton,
        -20,
        {
            label = "Font",
            tooltip = "Choose the font used by combat text.",
            setting = fontSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(FONT_OPTIONS) end,
        }
    )

    local textStyleSetting = Settings.RegisterProxySetting(
        generalCategory,
        "LCSCT_TEXT_STYLE",
        Settings.VarType.String, "Text Effect",
        "SHADOW",
        function() return DB.textStyle end,
        function(value) LightCore_ScrollingCombatText.ApplyTextStyle(value) end
    )
    local textStyleDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        generalFrame,
        fontDropdown,
        -18,
        {
            label = "Text Effect",
            tooltip = "Visual effect applied to text.",
            setting = textStyleSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(TEXT_STYLE_OPTIONS) end,
        }
    )

    local fontSizeSetting = Settings.RegisterProxySetting(
        generalCategory,
        "LCSCT_FONT_SIZE",
        Settings.VarType.Number, "Font Size",
        25,
        function() return DB.fontSize end,
        function(value) LightCore_ScrollingCombatText.ApplyFontSize(value) end
    )
    local fontSizeSlider = LightCore_ScrollingCombatText.CreateLabeledSlider(
        generalFrame,
        textStyleDropdown,
        -18,
        {
            label = "Font Size",
            tooltip = "Size used for normal hit messages.",
            setting = fontSizeSetting,
            minValue = 8,
            maxValue = 128,
            step = 1,
            formatter = function(value) return string.format("%d", value) end,
        }
    )

    local critSizeSetting = Settings.RegisterProxySetting(
        generalCategory,
        "LCSCT_CRIT_FONT_SIZE",
        Settings.VarType.Number, "Crit Size",
        36,
        function() return DB.critFontSize end,
        function(value) LightCore_ScrollingCombatText.ApplyCritFontSize(value) end
    )
    LightCore_ScrollingCombatText.CreateLabeledSlider(
        generalFrame,
        fontSizeSlider,
        -20,
        {
            label = "Crit Size",
            tooltip = "Size used for critical hit messages.",
            setting = critSizeSetting,
            minValue = 8,
            maxValue = 128,
            step = 1,
            formatter = function(value) return string.format("%d", value) end,
        }
    )
end
