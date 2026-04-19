function LightCore_ScrollingCombatText.RegisterAnimationSettings(positionFrame, positionCategory)
    local DB = LightCore_ScrollingCombatText.InitializeDB()

    local damageLaneAlignmentSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_DAMAGE_LANE_ALIGNMENT",
        Settings.VarType.String, "Damage Lane",
        "CENTER",
        function() return DB.channels.damage.laneAlignment end,
        function(value) DB.channels.damage.laneAlignment = value end
    )
    local positionTopTitle = LightCore_ScrollingCombatText.CreateSettingsPageTitle(positionFrame, "Animation")
    local positionTestButton = LightCore_ScrollingCombatText.CreateTestButton(positionFrame)
    positionTestButton:SetPoint("TOPLEFT", positionTopTitle, "BOTTOMLEFT", 0, -18)

    local positionMoverButton = LightCore_ScrollingCombatText.CreateMoverLockButton(positionFrame)
    positionMoverButton:SetPoint("LEFT", positionTestButton, "RIGHT", 10, 0)

    local damageLaneDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        positionTestButton,
        -20,
        {
            label = "Damage Lane",
            tooltip = "Choose where damage messages appear relative to the lane.",
            setting = damageLaneAlignmentSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.HORIZONTAL_ALIGNMENT_OPTIONS) end,
        }
    )

    local healLaneAlignmentSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_HEAL_LANE_ALIGNMENT",
        Settings.VarType.String, "Heal Lane",
        "LEFT",
        function() return DB.channels.healing.laneAlignment end,
        function(value) DB.channels.healing.laneAlignment = value end
    )
    local healLaneDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        damageLaneDropdown,
        -18,
        {
            label = "Heal Lane",
            tooltip = "Choose where healing messages appear relative to damage.",
            setting = healLaneAlignmentSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.HORIZONTAL_ALIGNMENT_OPTIONS) end,
        }
    )

    local mitigationLaneAlignmentSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_MITIGATION_LANE_ALIGNMENT",
        Settings.VarType.String, "Mitigation Lane",
        "LEFT",
        function() return DB.channels.mitigation.laneAlignment end,
        function(value) DB.channels.mitigation.laneAlignment = value end
    )
    local mitigationLaneDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        healLaneDropdown,
        -18,
        {
            label = "Mitigation Lane",
            tooltip = "Choose where mitigation messages appear relative to damage.",
            setting = mitigationLaneAlignmentSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.HORIZONTAL_ALIGNMENT_OPTIONS) end,
        }
    )

    local damageGrowDirectionSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_DAMAGE_GROW_DIRECTION",
        Settings.VarType.String, "Damage Grow",
        "UP",
        function() return DB.channels.damage.growDirection end,
        function(value) DB.channels.damage.growDirection = value end
    )
    local damageGrowDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        mitigationLaneDropdown,
        -18,
        {
            label = "Damage Grow",
            tooltip = "Choose whether damage messages grow up or down.",
            setting = damageGrowDirectionSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.GROW_DIRECTION_OPTIONS) end,
        }
    )

    local healGrowDirectionSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_HEAL_GROW_DIRECTION",
        Settings.VarType.String, "Heal Grow",
        "UP",
        function() return DB.channels.healing.growDirection end,
        function(value) DB.channels.healing.growDirection = value end
    )
    local healGrowDropdown = LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        damageGrowDropdown,
        -18,
        {
            label = "Heal Grow",
            tooltip = "Choose whether healing messages grow up or down.",
            setting = healGrowDirectionSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.GROW_DIRECTION_OPTIONS) end,
        }
    )

    local mitigationGrowDirectionSetting = Settings.RegisterProxySetting(
        positionCategory,
        "LCSCT_MITIGATION_GROW_DIRECTION",
        Settings.VarType.String, "Mitigation Grow",
        "UP",
        function() return DB.channels.mitigation.growDirection end,
        function(value) DB.channels.mitigation.growDirection = value end
    )
    LightCore_ScrollingCombatText.CreateLabeledDropdown(
        positionFrame,
        healGrowDropdown,
        -18,
        {
            label = "Mitigation Grow",
            tooltip = "Choose whether mitigation messages grow up or down.",
            setting = mitigationGrowDirectionSetting,
            optionsFn = function() return LightCore_ScrollingCombatText.BuildOptionData(LightCore_ScrollingCombatText.GROW_DIRECTION_OPTIONS) end,
        }
    )
end
