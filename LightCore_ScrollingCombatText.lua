LightCore_ScrollingCombatText = LightCore_ScrollingCombatText or {}
local DEFAULTS = {
    positionX = 0,
    positionY = 180,
    font = "FRIZQT",
    fontSize = 25,
    critFontSize = 36,
    textStyle = "SHADOW",
    moverLocked = true,

    channels = {
        damage = {
            enabled = true,
            minimumPct = 0,
            growDirection = "UP",
            laneAlignment = "CENTER",
            color = { 1.0, 0.1, 0.1 },
            magicColor = { 0.79, 0.3, 0.85 },
        },
        healing = {
            enabled = true,
            minimumPct = 0,
            growDirection = "UP",
            laneAlignment = "LEFT",
            color = { 0.0, 1.0, 0.0 },
        },
        mitigation = {
            growDirection = "UP",
            laneAlignment = "LEFT",
            color = { 0.7, 0.7, 1.0 },
            flags = {},
        },
    },
}

local function ApplyDefault(destination, key, value)
    if destination[key] == nil then
        destination[key] = value
    end
end

local function EnsureTable(destination, key)
    if type(destination[key]) ~= "table" then
        destination[key] = {}
    end
    return destination[key]
end

local function CopyColor(color)
    return { color[1], color[2], color[3] }
end

local function ApplyChannelDefaults(channelName)
    local channels = EnsureTable(LightCore_ScrollingCombatText.DB, "channels")
    local channel = EnsureTable(channels, channelName)
    local defaults = DEFAULTS.channels[channelName]

    ApplyDefault(channel, "enabled", defaults.enabled)
    ApplyDefault(channel, "minimumPct", defaults.minimumPct)
    ApplyDefault(channel, "growDirection", defaults.growDirection)
    ApplyDefault(channel, "laneAlignment", defaults.laneAlignment)

    if channel.color == nil then
        channel.color = CopyColor(defaults.color)
    end
    if defaults.magicColor and channel.magicColor == nil then
        channel.magicColor = CopyColor(defaults.magicColor)
    end

    if defaults.flags and channel.flags == nil then
        channel.flags = {}
    end
end

local function ApplyDefaults()
    local DB = LightCore_ScrollingCombatText.DB

    ApplyDefault(DB, "positionX", DEFAULTS.positionX)
    ApplyDefault(DB, "positionY", DEFAULTS.positionY)
    ApplyDefault(DB, "font", DEFAULTS.font)
    ApplyDefault(DB, "fontSize", DEFAULTS.fontSize)
    ApplyDefault(DB, "critFontSize", DEFAULTS.critFontSize)
    ApplyDefault(DB, "textStyle", DEFAULTS.textStyle)
    ApplyDefault(DB, "moverLocked", DEFAULTS.moverLocked)

    ApplyChannelDefaults("damage")
    ApplyChannelDefaults("healing")
    ApplyChannelDefaults("mitigation")
end

function LightCore_ScrollingCombatText.InitializeDB()
    LightCore_ScrollingCombatTextDB = LightCore_ScrollingCombatTextDB or {}
    LightCore_ScrollingCombatText.DB = LightCore_ScrollingCombatTextDB
    ApplyDefaults()
    return LightCore_ScrollingCombatText.DB
end

function LightCore_ScrollingCombatText.OpenSettings()
    if InCombatLockdown() then
        return
    end

    if not LightCore_ScrollingCombatText.settingsCategoryID then
        return
    end

    local category = Settings.GetCategory(LightCore_ScrollingCombatText.settingsCategoryID)
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end

SLASH_LIGHTCORESCROLLINGCOMBATTEXT1 = "/lcs"
SLASH_LIGHTCORESCROLLINGCOMBATTEXT2 = "/lcsct"

SlashCmdList.LIGHTCORESCROLLINGCOMBATTEXT = function(msg)
    local command = strlower(strtrim(msg or ""))

    if command == "simulate" or command == "preview" or command == "test" then
        LightCore_ScrollingCombatText.RunSimulation()
        return
    end

    LightCore_ScrollingCombatText.OpenSettings()
end

EventUtil.ContinueOnAddOnLoaded("LightCore_ScrollingCombatText", LightCore_ScrollingCombatText.InitializeDB)
