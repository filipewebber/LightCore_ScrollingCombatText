local DB
local eventFrame = CreateFrame("Frame")
local simulationRunID = 0
local cachedMinimumDamageAmount = 0
local cachedMinimumHealingAmount = 0

local ENERGIZE_COLOR = { 0.41, 0.8, 0.94 }
local SECONDARY_LANE_SIDE_OFFSET = 120
local COMBAT_MESSAGE_WINDOW = 0.18
local MAX_COMBAT_MESSAGES_PER_WINDOW = 5

local ShowLaneMessage
local ShowLaneMessages
local ClearLaneMessages
local pendingCombatBatches = {}
local pendingCombatSequence = 0
local pendingCombatFlushToken = 0

function LightCore_ScrollingCombatText.RecalculateMinimumThresholds()
    local minDamagePct = DB.channels.damage.minimumPct
    local minHealingPct = DB.channels.healing.minimumPct
    local maxHealth = UnitHealthMax("player") or 0

    if minDamagePct > 0 and maxHealth > 0 then
        cachedMinimumDamageAmount = math.floor(maxHealth * minDamagePct * 0.01)
    else
        cachedMinimumDamageAmount = 0
    end

    if minHealingPct > 0 and maxHealth > 0 then
        cachedMinimumHealingAmount = math.floor(maxHealth * minHealingPct * 0.01)
    else
        cachedMinimumHealingAmount = 0
    end
end

local function GetLaneOffset(alignment)
    if alignment == "RIGHT" then
        return SECONDARY_LANE_SIDE_OFFSET
    elseif alignment == "CENTER" then
        return 0
    end
    return -SECONDARY_LANE_SIDE_OFFSET
end

local function ShouldShowMitigationFlag(flagText)
    return DB.channels.mitigation.flags[flagText] ~= false
end

local function SortCombatMessages(left, right)
    local leftAmount = left.amount or 0
    local rightAmount = right.amount or 0

    if leftAmount == rightAmount then
        return left.sequence < right.sequence
    end

    return leftAmount > rightAmount
end

local function GetCombatBatchKey(laneOffsetX, growDirection)
    return string.format("%s:%s", tostring(laneOffsetX or 0), (growDirection == "DOWN") and "DOWN" or "UP")
end

local function FlushCombatBatch(batchKey, flushToken)
    local batch = pendingCombatBatches[batchKey]
    local messages = {}

    if flushToken and flushToken ~= pendingCombatFlushToken then
        return
    end

    if not batch or #batch.messages == 0 then
        return
    end

    table.sort(batch.messages, SortCombatMessages)

    for index = 1, math.min(MAX_COMBAT_MESSAGES_PER_WINDOW, #batch.messages) do
        messages[index] = batch.messages[index]
    end

    pendingCombatBatches[batchKey] = nil
    ShowLaneMessages(messages)
end

local function ClearPendingCombatMessages()
    pendingCombatFlushToken = pendingCombatFlushToken + 1
    pendingCombatBatches = {}
end

local function QueueCombatMessage(text, color, isCrit, laneOffsetX, growDirection, amount)
    local batchKey = GetCombatBatchKey(laneOffsetX, growDirection)
    local batch = pendingCombatBatches[batchKey]

    if not batch then
        batch = {
            flushToken = pendingCombatFlushToken,
            messages = {},
        }
        pendingCombatBatches[batchKey] = batch

        C_Timer.After(COMBAT_MESSAGE_WINDOW, function()
            FlushCombatBatch(batchKey, batch.flushToken)
        end)
    end

    pendingCombatSequence = pendingCombatSequence + 1
    batch.messages[#batch.messages + 1] = {
        amount = amount,
        color = color,
        growDirection = (growDirection == "DOWN") and "DOWN" or "UP",
        isCrit = isCrit,
        laneOffsetX = laneOffsetX or 0,
        sequence = pendingCombatSequence,
        text = text,
    }
end

local function HandleMitigation(flagText)
    if not ShouldShowMitigationFlag(flagText) then
        return
    end

    QueueCombatMessage(
        _G[flagText] or flagText,
        DB.channels.mitigation.color,
        false,
        GetLaneOffset(DB.channels.mitigation.laneAlignment),
        DB.channels.mitigation.growDirection
    )
end

local function HandleWound(flagText, amount, schoolMask)
    local isBlockReduced = (flagText == "BLOCK_REDUCED")

    if isBlockReduced and not ShouldShowMitigationFlag("BLOCK_REDUCED") then
        return
    end

    if not amount or amount <= 0 then
        if isBlockReduced then
            return
        end
        HandleMitigation(flagText)
        return
    end

    if not DB.channels.damage.enabled then
        return
    end

    if cachedMinimumDamageAmount > 0 and amount < cachedMinimumDamageAmount then
        return
    end

    local text = "-" .. BreakUpLargeNumbers(amount)
    local color
    local isCrit = (flagText == "CRITICAL" or flagText == "CRUSHING")

    if isBlockReduced then
        text = string.format("%s [BR]", text)
    end

    if schoolMask == Enum.Damageclass.MaskPhysical then
        color = DB.channels.damage.color
    else
        color = DB.channels.damage.magicColor
    end

    QueueCombatMessage(text, color, isCrit, GetLaneOffset(DB.channels.damage.laneAlignment), DB.channels.damage.growDirection, amount)
end

local function HandleHeal(flagText, amount)
    if not DB.channels.healing.enabled or not amount or amount <= 0 then
        return
    end

    if cachedMinimumHealingAmount > 0 and amount < cachedMinimumHealingAmount then
        return
    end

    local text = "+" .. BreakUpLargeNumbers(amount)
    QueueCombatMessage(
        text,
        DB.channels.healing.color,
        flagText == "CRITICAL",
        GetLaneOffset(DB.channels.healing.laneAlignment),
        DB.channels.healing.growDirection,
        amount
    )
end

local function HandleEnergize(flagText, amount)
    if not amount or amount <= 0 then
        return
    end

    local text = "+" .. BreakUpLargeNumbers(amount)
    QueueCombatMessage(
        text,
        ENERGIZE_COLOR,
        flagText == "CRITICAL",
        GetLaneOffset(DB.channels.healing.laneAlignment),
        DB.channels.healing.growDirection,
        amount
    )
end

local function HandleUnitCombat(_unitTarget, combatEvent, flagText, amount, schoolMask)
    if combatEvent == "WOUND" then
        HandleWound(flagText, amount, schoolMask)
    elseif combatEvent == "BLOCK" and amount and amount > 0 then
        HandleWound("BLOCK_REDUCED", amount, schoolMask)
    elseif combatEvent == "HEAL" then
        HandleHeal(flagText, amount)
    elseif combatEvent == "ENERGIZE" then
        HandleEnergize(flagText, amount)
    else
        HandleMitigation(combatEvent)
    end
end

function LightCore_ScrollingCombatText.RunSimulation()
    local runID

    simulationRunID = simulationRunID + 1
    runID = simulationRunID
    ClearPendingCombatMessages()
    ClearLaneMessages()

    C_Timer.After(0.0, function()
        if runID == simulationRunID then
            ShowLaneMessage("-12,480", DB.channels.damage.color, false, GetLaneOffset(DB.channels.damage.laneAlignment), DB.channels.damage.growDirection)
        end
    end)

    C_Timer.After(0.6, function()
        if runID == simulationRunID then
            ShowLaneMessage("-28,945", DB.channels.damage.magicColor, true, GetLaneOffset(DB.channels.damage.laneAlignment), DB.channels.damage.growDirection)
        end
    end)

    C_Timer.After(1.2, function()
        if runID == simulationRunID then
            ShowLaneMessage("+9,320", DB.channels.healing.color, false, GetLaneOffset(DB.channels.healing.laneAlignment), DB.channels.healing.growDirection)
        end
    end)

    C_Timer.After(1.8, function()
        if runID == simulationRunID then
            ShowLaneMessage(ABSORB, DB.channels.mitigation.color, false, GetLaneOffset(DB.channels.mitigation.laneAlignment), DB.channels.mitigation.growDirection)
        end
    end)

    C_Timer.After(2.4, function()
        if runID == simulationRunID then
            ShowLaneMessage("-41,275", DB.channels.damage.color, true, GetLaneOffset(DB.channels.damage.laneAlignment), DB.channels.damage.growDirection)
        end
    end)
end

local function InitializeCombatEvents()
    DB = LightCore_ScrollingCombatText.InitializeDB()
    ShowLaneMessage = LightCore_ScrollingCombatText.ShowLaneMessage
    ShowLaneMessages = LightCore_ScrollingCombatText.ShowLaneMessages
    ClearLaneMessages = LightCore_ScrollingCombatText.ClearLaneMessages

    eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player", "vehicle")
    eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_COMBAT" then
            HandleUnitCombat(...)
        elseif event == "UNIT_MAXHEALTH" or event == "PLAYER_ENTERING_WORLD" then
            LightCore_ScrollingCombatText.RecalculateMinimumThresholds()
            LightCore_ScrollingCombatText.UpdateMoverFrameLayout()
        end
    end)
end

EventUtil.ContinueOnAddOnLoaded("LightCore_ScrollingCombatText", InitializeCombatEvents)
