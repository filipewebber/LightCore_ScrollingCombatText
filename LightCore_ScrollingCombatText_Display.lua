LightCore_ScrollingCombatText = LightCore_ScrollingCombatText or {}

local DB
local moverFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
local displayFrame = CreateFrame("Frame")
local activeMessages = {}
local messagePool = {}

local MESSAGE_DURATION = 1.9
local FADE_START = 1.3
local TRAVEL_DISTANCE = 225
local STACK_STEP = 18
local MAX_STACK_OFFSET = 130
local BATCH_COLUMN_STEP = 105
local BATCH_ROW_SCALE = 0.85
local BATCH_SLOT_LAYOUTS = {
    [1] = {
        { 0, 0 },
    },
    [2] = {
        { -0.5, 0 },
        { 0.5, 0 },
    },
    [3] = {
        { -0.5, 0 },
        { 0.5, 0 },
        { 0, 1 },
    },
    [4] = {
        { -1, 0 },
        { 0, 0 },
        { 1, 0 },
        { 0, 1 },
    },
    [5] = {
        { -1, 0 },
        { 0, 0 },
        { 1, 0 },
        { -0.5, 1 },
        { 0.5, 1 },
    },
}
local MOVER_MIN_WIDTH = 180
local MOVER_MIN_HEIGHT = 28
local MOVER_PADDING_X = 20
local MOVER_PADDING_Y = 10

local FONT_PATHS = {
    FONT_2002 = "Fonts\\2002.TTF",
    FONT_2002B = "Fonts\\2002B.TTF",
    ARIALN = "Fonts\\ARIALN.TTF",
    FRIZQT = "Fonts\\FRIZQT__.TTF",
    MORPHEUS = "Fonts\\MORPHEUS.ttf",
    SKURRI = "Fonts\\skurri.ttf",
}

moverFrame:SetSize(MOVER_MIN_WIDTH, MOVER_MIN_HEIGHT)
moverFrame:SetClampedToScreen(true)
moverFrame:SetMovable(true)
moverFrame:EnableMouse(true)
moverFrame:RegisterForDrag("LeftButton")
moverFrame:SetFrameStrata("DIALOG")
moverFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
moverFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.75)
moverFrame:SetBackdropBorderColor(0.9, 0.8, 0.2, 0.95)
moverFrame.text = moverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
moverFrame.text:SetPoint("CENTER")
moverFrame.text:SetWordWrap(false)
moverFrame.text:SetMaxLines(1)
moverFrame.text:SetText("LightCore ScrollingCombatText")

function LightCore_ScrollingCombatText.UpdateMoverFrameLayout()
    local textWidth = moverFrame.text:GetStringWidth() or 0
    local textHeight = moverFrame.text:GetStringHeight() or 0
    local width = math.max(MOVER_MIN_WIDTH, math.ceil(textWidth + MOVER_PADDING_X))
    local height = math.max(MOVER_MIN_HEIGHT, math.ceil(textHeight + MOVER_PADDING_Y))

    moverFrame:SetSize(width, height)
end

local function SaveMoverPosition()
    local centerX, centerY = moverFrame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()

    if centerX and centerY and parentCenterX and parentCenterY then
        DB.positionX = math.floor((centerX - parentCenterX + 0.5))
        DB.positionY = math.floor((centerY - parentCenterY + 0.5))
    end
end

local function UpdateLaneAnchor()
    moverFrame:ClearAllPoints()
    moverFrame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        DB.positionX,
        DB.positionY
    )
    moverFrame:SetShown(not DB.moverLocked)
end

local function AcquireMessageFontString()
    local fontString = tremove(messagePool)

    if not fontString then
        fontString = UIParent:CreateFontString(nil, "BACKGROUND", "CombatTextFont")
    end

    fontString:SetWidth(0)
    fontString:SetWordWrap(false)
    fontString:SetMaxLines(1)
    fontString:SetAlpha(1)
    fontString:Show()
    return fontString
end

local function ApplyFontAppearance(fontString, textHeight)
    local style = DB.textStyle
    local fontPath = FONT_PATHS[DB.font] or FONT_PATHS["FRIZQT"]
    local outlineFlags

    if style == "OUTLINE" then
        outlineFlags = "OUTLINE"
    end

    fontString:SetFont(fontPath, textHeight, outlineFlags)

    if style == "SHADOW" then
        fontString:SetShadowOffset(1.2, -1.2)
        fontString:SetShadowColor(0, 0, 0, 1)
    else
        fontString:SetShadowOffset(0, 0)
        fontString:SetShadowColor(0, 0, 0, 0)
    end
end

local function ReleaseMessage(index)
    local message = activeMessages[index]
    if not message then
        return
    end

    message.fontString:Hide()
    message.fontString:ClearAllPoints()
    activeMessages[index] = nil
    tinsert(messagePool, message.fontString)
end

local function CompactActiveMessages()
    local compacted = {}

    for index = 1, #activeMessages do
        local message = activeMessages[index]
        if message then
            compacted[#compacted + 1] = message
        end
    end

    activeMessages = compacted
end

function LightCore_ScrollingCombatText.ClearLaneMessages()
    for index = #activeMessages, 1, -1 do
        ReleaseMessage(index)
    end
    activeMessages = {}
end

local function RefreshActiveMessageAnchors()
    local baseX, baseY = DB.positionX, DB.positionY

    for _, message in ipairs(activeMessages) do
        message.startX = baseX + (message.laneOffsetX or 0) + (message.batchOffsetX or 0)
        message.startY = baseY + (message.anchorOffsetY or 0) + (message.batchOffsetY or 0)
        local direction = (message.growDirection == "DOWN") and -1 or 1
        message.endY = message.startY + (TRAVEL_DISTANCE * direction)
    end
end

local function GetNextMessageOffset(growDirection)
    local baseY = DB.positionY
    growDirection = (growDirection == "DOWN") and "DOWN" or "UP"

    if growDirection == "DOWN" then
        local startY = baseY
        local maxY = baseY + MAX_STACK_OFFSET

        for _, message in ipairs(activeMessages) do
            if message.growDirection == growDirection then
                local currentY = message.currentY or message.startY or baseY
                local candidateY = currentY + STACK_STEP
                if candidateY > startY then
                    startY = candidateY
                end
            end
        end

        if startY > maxY then
            startY = baseY
        end

        return startY - baseY
    end

    local startY = baseY
    local minY = baseY - MAX_STACK_OFFSET

    for _, message in ipairs(activeMessages) do
        if message.growDirection == growDirection then
            local currentY = message.currentY or message.startY or baseY
            local candidateY = currentY - STACK_STEP
            if candidateY < startY then
                startY = candidateY
            end
        end
    end

    if startY < minY then
        startY = baseY
    end

    return startY - baseY
end

local function GetBatchSlotOffset(messageCount, messageIndex, rowStep)
    local layout = BATCH_SLOT_LAYOUTS[messageCount] or BATCH_SLOT_LAYOUTS[5]
    local slot = layout[messageIndex] or layout[#layout]

    return slot[1] * BATCH_COLUMN_STEP, slot[2] * rowStep
end

function LightCore_ScrollingCombatText.ShowLaneMessage(text, color, isCrit, laneOffsetX, growDirection, batchOffsetX, batchOffsetY, anchorOffsetY)
    local baseX, baseY
    local fontString
    local message
    local textHeight

    baseX, baseY = DB.positionX, DB.positionY
    fontString = AcquireMessageFontString()
    textHeight = isCrit and DB.critFontSize or DB.fontSize
    fontString:SetText(text)
    fontString:SetTextColor(color[1], color[2], color[3])
    fontString:SetJustifyH("CENTER")
    ApplyFontAppearance(fontString, textHeight)

    message = {
        growDirection = (growDirection == "DOWN") and "DOWN" or "UP",
        anchorOffsetY = anchorOffsetY or 0,
        currentY = 0,
        elapsed = 0,
        fontString = fontString,
        batchOffsetX = batchOffsetX or 0,
        batchOffsetY = batchOffsetY or 0,
        laneOffsetX = laneOffsetX or 0,
        startX = baseX + (laneOffsetX or 0) + (batchOffsetX or 0),
        startY = 0,
        endY = 0,
        textHeight = textHeight,
        isCrit = isCrit and true or false,
    }
    if anchorOffsetY == nil then
        message.anchorOffsetY = GetNextMessageOffset(message.growDirection)
    end

    message.startY = baseY + message.anchorOffsetY + (batchOffsetY or 0)
    message.currentY = message.startY
    local direction = (message.growDirection == "DOWN") and -1 or 1
    message.endY = message.startY + (TRAVEL_DISTANCE * direction)

    tinsert(activeMessages, 1, message)
end

function LightCore_ScrollingCombatText.ShowLaneMessages(messages)
    local messageCount = math.min(#messages, 5)
    local maxTextHeight = DB.fontSize
    local anchorOffsetY
    local rowStep

    if messageCount == 0 then
        return
    end

    for index = 1, messageCount do
        if messages[index].isCrit then
            maxTextHeight = math.max(maxTextHeight, DB.critFontSize)
        end
    end

    rowStep = math.max(STACK_STEP, math.floor((maxTextHeight * BATCH_ROW_SCALE) + 0.5))
    anchorOffsetY = GetNextMessageOffset((messages[1].growDirection == "DOWN") and "DOWN" or "UP")

    for index = 1, messageCount do
        local message = messages[index]
        local batchOffsetX, batchOffsetY = GetBatchSlotOffset(messageCount, index, rowStep)

        LightCore_ScrollingCombatText.ShowLaneMessage(
            message.text,
            message.color,
            message.isCrit,
            message.laneOffsetX,
            message.growDirection,
            batchOffsetX,
            batchOffsetY,
            anchorOffsetY
        )
    end
end

local function OnUpdate(_, elapsed)
    local needsCompact = false

    for index = #activeMessages, 1, -1 do
        local message = activeMessages[index]
        local progress
        local alpha
        local yPos

        if message then
            message.elapsed = message.elapsed + elapsed
            if message.elapsed >= MESSAGE_DURATION then
                ReleaseMessage(index)
                needsCompact = true
            else
                progress = message.elapsed / MESSAGE_DURATION
                yPos = message.startY + ((message.endY - message.startY) * progress)
                message.currentY = yPos
                message.fontString:ClearAllPoints()
                message.fontString:SetPoint("CENTER", UIParent, "CENTER", message.startX, yPos)

                if message.elapsed >= FADE_START then
                    alpha = 1 - ((message.elapsed - FADE_START) / (MESSAGE_DURATION - FADE_START))
                    if alpha < 0 then
                        alpha = 0
                    end
                    message.fontString:SetAlpha(alpha)
                end
            end
        end
    end

    if needsCompact then
        CompactActiveMessages()
    end
end

function LightCore_ScrollingCombatText.ApplyFont(value)
    DB.font = value

    for _, message in ipairs(activeMessages) do
        ApplyFontAppearance(message.fontString, message.textHeight or DB.fontSize)
    end
end

function LightCore_ScrollingCombatText.ApplyTextStyle(value)
    DB.textStyle = value

    for _, message in ipairs(activeMessages) do
        ApplyFontAppearance(message.fontString, message.textHeight or DB.fontSize)
    end
end

function LightCore_ScrollingCombatText.ApplyFontSize(value)
    local size = math.max(8, math.min(128, tonumber(value) or DB.fontSize))
    size = math.floor(size + 0.5)
    DB.fontSize = size

    for _, message in ipairs(activeMessages) do
        if not message.isCrit then
            message.textHeight = size
            ApplyFontAppearance(message.fontString, size)
        end
    end
end

function LightCore_ScrollingCombatText.ApplyCritFontSize(value)
    local size = math.max(8, math.min(128, tonumber(value) or DB.critFontSize))
    size = math.floor(size + 0.5)
    DB.critFontSize = size

    for _, message in ipairs(activeMessages) do
        if message.isCrit then
            message.textHeight = size
            ApplyFontAppearance(message.fontString, size)
        end
    end
end

function LightCore_ScrollingCombatText.ToggleMoverLock()
    DB.moverLocked = not DB.moverLocked
    UpdateLaneAnchor()
end

local function InitializeDisplay()
    DB = LightCore_ScrollingCombatText.InitializeDB()
    LightCore_ScrollingCombatText.UpdateMoverFrameLayout()
    UpdateLaneAnchor()

    moverFrame:SetScript("OnDragStart", function(self)
        if not DB.moverLocked then
            self:StartMoving()
        end
    end)

    moverFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveMoverPosition()
        UpdateLaneAnchor()
        RefreshActiveMessageAnchors()
    end)

    displayFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    displayFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    displayFrame:RegisterEvent("UI_SCALE_CHANGED")
    displayFrame:SetScript("OnEvent", function()
        LightCore_ScrollingCombatText.UpdateMoverFrameLayout()
        UpdateLaneAnchor()
    end)
    displayFrame:SetScript("OnUpdate", OnUpdate)
end

EventUtil.ContinueOnAddOnLoaded("LightCore_ScrollingCombatText", InitializeDisplay)
