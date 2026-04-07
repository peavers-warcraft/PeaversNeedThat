local addonName, PNT = ...

--------------------------------------------------------------------------------
-- LootDialog - Styled scrollable list of loot items with whisper buttons
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

local LootDialog = {}
PNT.LootDialog = LootDialog

LootDialog.rows = {}

-- Layout constants
local ROW_HEIGHT = 48
local ROW_SPACING = 6
local ICON_SIZE = 28
local BUTTON_WIDTH = 70
local BUTTON_HEIGHT = 24
local PADDING = 12
local SCROLL_WIDTH = 6
local SCROLL_STEP = 30

--------------------------------------------------------------------------------
-- Styled button helper (matches PeaversCVars style)
--------------------------------------------------------------------------------

local function CreateStyledButton(parent, text, isPrimary)
    local C = PNT.Colors

    local bgColor = isPrimary and C.ACCENT or C.BG_TERTIARY
    local bgHover = isPrimary and C.ACCENT_DARK or C.BG_HOVER

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(bgColor))
    btn:SetBackdropBorderColor(unpack(C.BORDER_LIGHT))

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text)

    if isPrimary then
        btn.label:SetTextColor(0, 0, 0, 1)
    else
        btn.label:SetTextColor(unpack(C.TEXT_SECONDARY))
    end

    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp")

    btn.bgColor = bgColor
    btn.bgHover = bgHover

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(self.bgHover))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.bgColor))
    end)

    return btn
end

--------------------------------------------------------------------------------
-- Initialize scroll frame and content area
--------------------------------------------------------------------------------

function LootDialog:Initialize(parentFrame)
    self.parentFrame = parentFrame
    local C = PNT.Colors

    -- Scroll container (outer bordered area)
    self.scrollContainer = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    self.scrollContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", PADDING, -PADDING)
    self.scrollContainer:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -PADDING, PADDING)
    self.scrollContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    self.scrollContainer:SetBackdropColor(unpack(C.BG_SECONDARY))
    self.scrollContainer:SetBackdropBorderColor(unpack(C.BORDER_PRIMARY))

    -- Scroll frame (inside container, room for custom scrollbar)
    self.scrollFrame = CreateFrame("ScrollFrame", "PNTLootScrollFrame", self.scrollContainer)
    self.scrollFrame:SetPoint("TOPLEFT", 4, -4)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -(SCROLL_WIDTH + 8), 4)

    -- Scroll child
    self.scrollChild = CreateFrame("Frame", "PNTLootScrollChild", self.scrollFrame)
    self.scrollChild:SetWidth(self.scrollFrame:GetWidth() or 1)
    self.scrollChild:SetHeight(1)
    self.scrollFrame:SetScrollChild(self.scrollChild)

    -- Update child width when scroll frame resizes
    self.scrollFrame:SetScript("OnSizeChanged", function(sf, width, height)
        self.scrollChild:SetWidth(width)
        self:Refresh()
    end)

    -- Scroll content width update on container size change
    self.scrollChild:SetScript("OnSizeChanged", function()
        C_Timer.After(0, function()
            self:UpdateScrollThumb()
        end)
    end)

    -- Custom scroll track
    self.scrollTrack = CreateFrame("Frame", nil, self.scrollContainer, "BackdropTemplate")
    self.scrollTrack:SetWidth(SCROLL_WIDTH)
    self.scrollTrack:SetPoint("TOPRIGHT", self.scrollContainer, "TOPRIGHT", -4, -4)
    self.scrollTrack:SetPoint("BOTTOMRIGHT", self.scrollContainer, "BOTTOMRIGHT", -4, 4)
    self.scrollTrack:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    })
    self.scrollTrack:SetBackdropColor(0.1, 0.1, 0.12, 1)

    -- Custom scroll thumb
    self.scrollThumb = CreateFrame("Button", nil, self.scrollTrack, "BackdropTemplate")
    self.scrollThumb:SetWidth(SCROLL_WIDTH)
    self.scrollThumb:SetHeight(40)
    self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, 0)
    self.scrollThumb:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    })
    self.scrollThumb:SetBackdropColor(unpack(C.ACCENT))
    self.scrollThumb:EnableMouse(true)
    self.scrollThumb:SetMovable(true)

    self.scrollThumb:SetScript("OnEnter", function(thumb)
        thumb:SetBackdropColor(unpack(C.ACCENT_DARK))
    end)
    self.scrollThumb:SetScript("OnLeave", function(thumb)
        thumb:SetBackdropColor(unpack(C.ACCENT))
    end)

    -- Mouse wheel scrolling
    self.scrollContainer:EnableMouseWheel(true)
    self.scrollContainer:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = self.scrollFrame:GetVerticalScrollRange()
        local currentScroll = self.scrollFrame:GetVerticalScroll()
        local newScroll = math.max(0, math.min(maxScroll, currentScroll - (delta * SCROLL_STEP)))
        self.scrollFrame:SetVerticalScroll(newScroll)
        self:UpdateScrollThumb()
    end)

    -- Thumb dragging
    local isDragging = false
    local dragStartY = 0
    local dragStartScroll = 0

    self.scrollThumb:SetScript("OnMouseDown", function(thumb, button)
        if button == "LeftButton" then
            isDragging = true
            dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            dragStartScroll = self.scrollFrame:GetVerticalScroll()
            thumb:SetScript("OnUpdate", function()
                if not isDragging then return end
                local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
                local deltaY = dragStartY - currentY

                local contentHeight = self.scrollChild:GetHeight() or 1
                local frameHeight = self.scrollFrame:GetHeight() or 1
                local trackHeight = self.scrollTrack:GetHeight() or 1
                local maxScroll = math.max(0, contentHeight - frameHeight)

                local scrollRatio = maxScroll / math.max(1, trackHeight - thumb:GetHeight())
                local newScroll = math.max(0, math.min(maxScroll, dragStartScroll + (deltaY * scrollRatio)))
                self.scrollFrame:SetVerticalScroll(newScroll)
                self:UpdateScrollThumb()
            end)
        end
    end)

    self.scrollThumb:SetScript("OnMouseUp", function(thumb, button)
        if button == "LeftButton" then
            isDragging = false
            thumb:SetScript("OnUpdate", nil)
        end
    end)

    -- Track click to jump
    self.scrollTrack:EnableMouse(true)
    self.scrollTrack:SetScript("OnMouseDown", function(track, button)
        if button == "LeftButton" then
            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / UIParent:GetEffectiveScale()
            local trackTop = track:GetTop()
            local clickOffset = trackTop - cursorY

            local contentHeight = self.scrollChild:GetHeight() or 1
            local frameHeight = self.scrollFrame:GetHeight() or 1
            local trackHeight = track:GetHeight() or 1
            local maxScroll = math.max(0, contentHeight - frameHeight)

            local scrollPercent = clickOffset / trackHeight
            local newScroll = math.max(0, math.min(maxScroll, scrollPercent * maxScroll))
            self.scrollFrame:SetVerticalScroll(newScroll)
            self:UpdateScrollThumb()
        end
    end)

    -- Empty state
    self.emptyContainer = CreateFrame("Frame", nil, self.scrollContainer)
    self.emptyContainer:SetSize(300, 80)
    self.emptyContainer:SetPoint("CENTER", self.scrollContainer, "CENTER", 0, 0)

    self.emptyTitle = self.emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.emptyTitle:SetPoint("TOP", self.emptyContainer, "TOP", 0, 0)
    self.emptyTitle:SetText("No Loot Tracked")
    self.emptyTitle:SetTextColor(unpack(C.TEXT_MUTED))

    self.emptyDesc = self.emptyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.emptyDesc:SetPoint("TOP", self.emptyTitle, "BOTTOM", 0, -8)
    self.emptyDesc:SetText("Equippable loot from party members\nwill appear here during M+ runs.")
    self.emptyDesc:SetTextColor(unpack(C.TEXT_MUTED))
    self.emptyDesc:SetJustifyH("CENTER")

    self:Refresh()
end

--------------------------------------------------------------------------------
-- Update scroll thumb position and size
--------------------------------------------------------------------------------

function LootDialog:UpdateScrollThumb()
    if not self.scrollTrack or not self.scrollThumb then return end

    local contentHeight = self.scrollChild:GetHeight() or 1
    local frameHeight = self.scrollFrame:GetHeight() or 1
    local trackHeight = self.scrollTrack:GetHeight() or 1

    if contentHeight <= frameHeight then
        self.scrollThumb:Hide()
        return
    end

    self.scrollThumb:Show()

    local thumbHeight = math.max(20, (frameHeight / contentHeight) * trackHeight)
    self.scrollThumb:SetHeight(thumbHeight)

    local maxScroll = contentHeight - frameHeight
    local currentScroll = self.scrollFrame:GetVerticalScroll()
    local scrollPercent = currentScroll / maxScroll
    local maxThumbOffset = trackHeight - thumbHeight
    local thumbOffset = scrollPercent * maxThumbOffset

    self.scrollThumb:ClearAllPoints()
    self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, -thumbOffset)
end

--------------------------------------------------------------------------------
-- Create a loot row
--------------------------------------------------------------------------------

local function CreateRow(parent, index)
    local C = PNT.Colors

    local row = CreateFrame("Frame", "PNTLootRow" .. index, parent, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    row:SetBackdropColor(unpack(C.BG_SECONDARY))
    row:SetBackdropBorderColor(unpack(C.BORDER_PRIMARY))

    -- Item icon with quality-colored border
    row.iconBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.iconBorder:SetSize(ICON_SIZE + 2, ICON_SIZE + 2)
    row.iconBorder:SetPoint("LEFT", row, "LEFT", PADDING, 0)
    row.iconBorder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    row.iconBorder:SetBackdropColor(0, 0, 0, 1)
    row.iconBorder:SetBackdropBorderColor(unpack(C.BORDER_PRIMARY))

    row.icon = row.iconBorder:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("CENTER")

    -- Item name (quality colored)
    row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.itemText:SetPoint("TOPLEFT", row.iconBorder, "TOPRIGHT", 8, -4)
    row.itemText:SetJustifyH("LEFT")
    row.itemText:SetWordWrap(false)

    -- Player name + slot
    row.infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.infoText:SetPoint("BOTTOMLEFT", row.iconBorder, "BOTTOMRIGHT", 8, 4)
    row.infoText:SetJustifyH("LEFT")
    row.infoText:SetWordWrap(false)
    row.infoText:SetTextColor(unpack(C.TEXT_SECONDARY))

    -- Styled "Need?" button
    row.needButton = CreateStyledButton(row, "Need?", true)
    row.needButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    row.needButton:SetPoint("RIGHT", row, "RIGHT", -PADDING, 0)
    row.needButton:SetFrameLevel(row:GetFrameLevel() + 5)

    -- Tooltip on row hover (clicks pass through to button)
    row:EnableMouse(true)
    if row.SetMouseClickEnabled then
        row:SetMouseClickEnabled(false)
    end
    row:SetScript("OnEnter", function(self)
        if self.entry and self.entry.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.entry.itemLink)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return row
end

--------------------------------------------------------------------------------
-- Send the whisper using {placeholder} template
--------------------------------------------------------------------------------

local function SendNeedWhisper(entry)
    if not entry or not entry.itemName or not entry.playerName then return end

    local template = PNT.Config.whisperMessage or "Hey! Do you need {item} ({slot})? If not, I'd love it!"
    local msg = template
    msg = msg:gsub("{item}", "[" .. entry.itemName .. "]")
    msg = msg:gsub("{slot}", entry.slotName or "item")
    msg = msg:gsub("{player}", entry.playerShort or "")

    entry.asked = true

    local ok, err = pcall(SendChatMessage, msg, "WHISPER", nil, entry.playerName)
    if ok then
        Utils.Print(PNT, "Whispered " .. (entry.playerShort or "unknown") .. " about [" .. entry.itemName .. "]")
    else
        Utils.Print(PNT, "Failed to whisper " .. (entry.playerShort or "unknown") .. ": " .. tostring(err))
    end
end

--------------------------------------------------------------------------------
-- Refresh the list
--------------------------------------------------------------------------------

function LootDialog:Refresh()
    if not self.scrollChild then return end

    local lootHistory = PNT.LootTracker and PNT.LootTracker.lootHistory or {}
    local count = #lootHistory
    local C = PNT.Colors

    -- Empty state
    if self.emptyContainer then
        if count == 0 then
            self.emptyContainer:Show()
        else
            self.emptyContainer:Hide()
        end
    end

    -- Update title with count
    if PNT.Core and PNT.Core.UpdateItemCount then
        PNT.Core:UpdateItemCount(count)
    end

    -- Hide all existing rows
    for _, row in ipairs(self.rows) do
        row:Hide()
    end

    local contentWidth = self.scrollChild:GetWidth()

    -- Create/update rows
    for i, entry in ipairs(lootHistory) do
        local row = self.rows[i]
        if not row then
            row = CreateRow(self.scrollChild, i)
            self.rows[i] = row
        end

        -- Position
        local yOffset = -((i - 1) * (ROW_HEIGHT + ROW_SPACING)) - 4
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, yOffset)
        row:SetPoint("RIGHT", self.scrollChild, "RIGHT", -4, 0)

        -- Store entry for tooltip
        row.entry = entry

        -- Icon
        if entry.itemTexture then
            row.icon:SetTexture(entry.itemTexture)
        else
            row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        -- Icon border color = item quality color
        local qualityColor = ITEM_QUALITY_COLORS[entry.itemQuality]
        if qualityColor then
            row.iconBorder:SetBackdropBorderColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
        else
            row.iconBorder:SetBackdropBorderColor(unpack(C.BORDER_PRIMARY))
        end

        -- Item name with quality color
        if qualityColor and entry.itemName then
            row.itemText:SetText(qualityColor.hex .. entry.itemName .. "|r")
        else
            row.itemText:SetText(entry.itemName or "Unknown Item")
        end

        -- Clamp text width to not overlap button
        local maxTextWidth = contentWidth - ICON_SIZE - BUTTON_WIDTH - PADDING * 3 - 20
        if maxTextWidth > 0 then
            row.itemText:SetWidth(maxTextWidth)
            row.infoText:SetWidth(maxTextWidth)
        end

        -- Player and slot info
        row.infoText:SetText((entry.playerShort or "Unknown") .. "  \194\183  " .. (entry.slotName or ""))

        -- Button state
        if entry.asked then
            row.needButton.bgColor = C.BG_TERTIARY
            row.needButton.bgHover = C.BG_TERTIARY
            row.needButton:SetBackdropColor(unpack(C.BG_TERTIARY))
            row.needButton:SetBackdropBorderColor(unpack(C.BORDER_LIGHT))
            row.needButton.label:SetText("Asked")
            row.needButton.label:SetTextColor(unpack(C.TEXT_MUTED))
            row.needButton:SetScript("OnClick", nil)
            row.needButton:SetScript("OnEnter", nil)
            row.needButton:SetScript("OnLeave", nil)
        else
            row.needButton.bgColor = C.ACCENT
            row.needButton.bgHover = C.ACCENT_DARK
            row.needButton:SetBackdropColor(unpack(C.ACCENT))
            row.needButton:SetBackdropBorderColor(unpack(C.BORDER_LIGHT))
            row.needButton.label:SetText("Need?")
            row.needButton.label:SetTextColor(0, 0, 0, 1)
            row.needButton:SetScript("OnClick", function()
                SendNeedWhisper(entry)
                LootDialog:Refresh()
            end)
            row.needButton:SetScript("OnEnter", function(btn)
                btn:SetBackdropColor(unpack(btn.bgHover))
            end)
            row.needButton:SetScript("OnLeave", function(btn)
                btn:SetBackdropColor(unpack(btn.bgColor))
            end)
        end

        row:Show()
    end

    -- Update scroll child height
    local totalHeight = math.max(1, count * (ROW_HEIGHT + ROW_SPACING) + 8)
    self.scrollChild:SetHeight(totalHeight)

    -- Update main frame height
    if PNT.Core and PNT.Core.UpdateFrameHeight then
        PNT.Core:UpdateFrameHeight(count)
    end

    -- Update scrollbar
    self:UpdateScrollThumb()
end

return LootDialog
