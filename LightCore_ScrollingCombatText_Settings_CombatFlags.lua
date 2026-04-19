local MITIGATION_FLAG_OPTIONS = {
    { flag = "ABSORB", label = "Absorb", tooltip = "Show absorb mitigation messages." },
    { flag = "BLOCK", label = "Block", tooltip = "Show block mitigation messages." },
    { flag = "BLOCK_REDUCED", label = "Block Reduced [BR]", tooltip = "Show [BR] marker on partially blocked damage." },
    { flag = "DEFLECT", label = "Deflect", tooltip = "Show deflect mitigation messages." },
    { flag = "DODGE", label = "Dodge", tooltip = "Show dodge mitigation messages." },
    { flag = "EVADE", label = "Evade", tooltip = "Show evade mitigation messages." },
    { flag = "IMMUNE", label = "Immune", tooltip = "Show immune mitigation messages." },
    { flag = "INTERRUPT", label = "Interrupt", tooltip = "Show interrupt mitigation messages." },
    { flag = "MISS", label = "Miss", tooltip = "Show miss mitigation messages." },
    { flag = "PARRY", label = "Parry", tooltip = "Show parry mitigation messages." },
    { flag = "REFLECT", label = "Reflect", tooltip = "Show reflect mitigation messages." },
    { flag = "RESIST", label = "Resist", tooltip = "Show resist mitigation messages." },
}

function LightCore_ScrollingCombatText.RegisterCombatFlagSettings(combatFrame, combatCategory)
    local DB = LightCore_ScrollingCombatText.InitializeDB()

    local combatTopTitle = LightCore_ScrollingCombatText.CreateSettingsPageTitle(combatFrame, "Combat Flags")
    local combatTestButton = LightCore_ScrollingCombatText.CreateTestButton(combatFrame)
    combatTestButton:SetPoint("TOPLEFT", combatTopTitle, "BOTTOMLEFT", 0, -18)

    local combatMoverButton = LightCore_ScrollingCombatText.CreateMoverLockButton(combatFrame)
    combatMoverButton:SetPoint("LEFT", combatTestButton, "RIGHT", 10, 0)

    local showDamageSetting = Settings.RegisterProxySetting(
        combatCategory,
        "LCSCT_SHOW_DAMAGE",
        Settings.VarType.Boolean, "Damage",
        true,
        function() return DB.channels.damage.enabled end,
        function(value) DB.channels.damage.enabled = value end
    )
    local showHealingSetting = Settings.RegisterProxySetting(
        combatCategory,
        "LCSCT_SHOW_HEALING",
        Settings.VarType.Boolean, "Heal",
        true,
        function() return DB.channels.healing.enabled end,
        function(value) DB.channels.healing.enabled = value end
    )
    local minimumDamageSetting = Settings.RegisterProxySetting(
        combatCategory,
        "LCSCT_MIN_DAMAGE",
        Settings.VarType.Number, "Minimum Damage",
        0,
        function() return DB.channels.damage.minimumPct end,
        function(value)
            DB.channels.damage.minimumPct = value
            LightCore_ScrollingCombatText.RecalculateMinimumThresholds()
        end
    )
    local minimumHealingSetting = Settings.RegisterProxySetting(
        combatCategory,
        "LCSCT_MIN_HEALING",
        Settings.VarType.Number, "Minimum Healing",
        0,
        function() return DB.channels.healing.minimumPct end,
        function(value)
            DB.channels.healing.minimumPct = value
            LightCore_ScrollingCombatText.RecalculateMinimumThresholds()
        end
    )

    local damageCheckbox = LightCore_ScrollingCombatText.CreateCheckbox(
        combatFrame,
        combatTestButton,
        0,
        -20,
        "Damage",
        "Show incoming damage events.",
        showDamageSetting
    )
    local minimumDamageSlider = LightCore_ScrollingCombatText.CreateInlineSlider(
        combatFrame,
        combatTestButton,
        260,
        -18,
        {
            label = "Minimum Damage",
            tooltip = "Ignore damage below this percentage of your max health.",
            setting = minimumDamageSetting,
            minValue = 0,
            maxValue = 100,
            step = 1,
            formatter = function(value) return string.format("%d%%", value) end,
        }
    )

    local healCheckbox = LightCore_ScrollingCombatText.CreateCheckbox(
        combatFrame,
        combatTestButton,
        0,
        -50,
        "Heal",
        "Show incoming healing events.",
        showHealingSetting
    )
    local minimumHealingSlider = LightCore_ScrollingCombatText.CreateInlineSlider(
        combatFrame,
        combatTestButton,
        260,
        -48,
        {
            label = "Minimum Healing",
            tooltip = "Ignore healing below this percentage of your max health.",
            setting = minimumHealingSetting,
            minValue = 0,
            maxValue = 100,
            step = 1,
            formatter = function(value) return string.format("%d%%", value) end,
        }
    )

    local mitigationFlagStates = {}
    for index, option in ipairs(MITIGATION_FLAG_OPTIONS) do
        local flag = option.flag
        local settingKey = "LCSCT_MIT_" .. flag
        local label = option.label
        local tooltip = option.tooltip

        local flagSetting = Settings.RegisterProxySetting(
            combatCategory,
            settingKey,
            Settings.VarType.Boolean, label,
            true,
            function() return DB.channels.mitigation.flags[flag] ~= false end,
            function(value) DB.channels.mitigation.flags[flag] = value end
        )

        local col = (index - 1) % 2
        local row = math.floor((index - 1) / 2) + 2
        local check = LightCore_ScrollingCombatText.CreateCheckbox(
            combatFrame,
            combatTestButton,
            col * 260,
            -20 - (row * 30),
            label,
            tooltip,
            flagSetting
        )

        mitigationFlagStates[#mitigationFlagStates + 1] = { setting = flagSetting, checkbox = check }
    end

    function combatFrame:OnRefresh()
        damageCheckbox:SetChecked(showDamageSetting:GetValue())
        healCheckbox:SetChecked(showHealingSetting:GetValue())
        minimumDamageSlider:SetValue(minimumDamageSetting:GetValue())
        minimumHealingSlider:SetValue(minimumHealingSetting:GetValue())
        for _, state in ipairs(mitigationFlagStates) do
            state.checkbox:SetChecked(state.setting:GetValue())
        end
    end
end
