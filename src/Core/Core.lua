local addonName, PNT = ...

--------------------------------------------------------------------------------
-- Core - Main UI frame with custom title bar and loot dialog
--------------------------------------------------------------------------------

local Core = {}
PNT.Core = Core

Core.mainFrame = nil
Core.titleBar = nil
Core.contentFrame = nil
Core.titleText = nil

local TITLE_HEIGHT = 32
local HEADER_HEIGHT = 24
local PADDING = 12
local MIN_HEIGHT = 180
local MAX_HEIGHT = 500
local ROW_TOTAL = 32 -- 30px row + 2px spacing

--------------------------------------------------------------------------------
-- Create the main frame
--------------------------------------------------------------------------------

function Core:CreateMainFrame()
    if self.mainFrame then return end

    local config = PNT.Config
    local C = PNT.Colors

    -- Main frame
    local frame = CreateFrame("Frame", "PeaversNeedThatFrame", UIParent, "BackdropTemplate")
    frame:SetSize(config.frameWidth or 580, MIN_HEIGHT)
    frame:SetPoint(
        config.framePoint or "CENTER",
        config.frameX or 0,
        config.frameY or 0
    )
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(C.BG_PRIMARY))
    frame:SetBackdropBorderColor(unpack(C.BORDER_PRIMARY))

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetHeight(TITLE_HEIGHT)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    })
    titleBar:SetBackdropColor(0.05, 0.05, 0.07, 1)

    -- Title text
    self.titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.titleText:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    self.titleText:SetText("|cff3abdf7Peavers|r NeedThat")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(TITLE_HEIGHT - 8, TITLE_HEIGHT - 8)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -6, 0)
    closeBtn:EnableMouse(true)
    closeBtn:RegisterForClicks("AnyUp")

    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtnText:SetPoint("CENTER")
    closeBtnText:SetText("x")
    closeBtnText:SetTextColor(unpack(C.TEXT_SECONDARY))

    closeBtn:SetScript("OnEnter", function() closeBtnText:SetTextColor(1, 0.4, 0.4, 1) end)
    closeBtn:SetScript("OnLeave", function() closeBtnText:SetTextColor(unpack(C.TEXT_SECONDARY)) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Make draggable via title bar
    frame:SetMovable(true)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not config.lockPosition then
            frame:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        config.framePoint = point
        config.frameX = x
        config.frameY = y
        config:Save()
    end)

    -- Content frame (below title bar)
    local contentFrame = CreateFrame("Frame", "PNTContentFrame", frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -TITLE_HEIGHT)
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    self.mainFrame = frame
    self.titleBar = titleBar
    self.contentFrame = contentFrame

    -- Initialize the loot dialog inside the content frame
    PNT.LootDialog:Initialize(contentFrame)

    -- Start hidden unless showOnLogin
    if not config.showOnLogin then
        frame:Hide()
    end

    -- Close via Escape
    table.insert(UISpecialFrames, "PeaversNeedThatFrame")
end

--------------------------------------------------------------------------------
-- Update item count in title
--------------------------------------------------------------------------------

function Core:UpdateItemCount(count)
    if not self.titleText then return end

    if count and count > 0 then
        self.titleText:SetText("|cff3abdf7Peavers|r NeedThat (" .. count .. ")")
    else
        self.titleText:SetText("|cff3abdf7Peavers|r NeedThat")
    end
end

--------------------------------------------------------------------------------
-- Dynamic frame height based on item count
--------------------------------------------------------------------------------

function Core:UpdateFrameHeight(itemCount)
    if not self.mainFrame then return end

    local contentHeight = (itemCount or 0) * ROW_TOTAL + HEADER_HEIGHT + PADDING * 2 + 8
    local totalHeight = TITLE_HEIGHT + contentHeight
    totalHeight = math.max(totalHeight, MIN_HEIGHT)
    totalHeight = math.min(totalHeight, MAX_HEIGHT)

    self.mainFrame:SetHeight(totalHeight)
end

--------------------------------------------------------------------------------
-- Update frame width from config
--------------------------------------------------------------------------------

function Core:UpdateFrameSize()
    if not self.mainFrame then return end
    self.mainFrame:SetWidth(PNT.Config.frameWidth or 580)
end

--------------------------------------------------------------------------------
-- Show / Hide / Toggle
--------------------------------------------------------------------------------

function Core:Show()
    if self.mainFrame then
        self.mainFrame:Show()
        PNT.LootDialog:Refresh()
    end
end

function Core:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function Core:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function Core:IsShown()
    return self.mainFrame and self.mainFrame:IsShown()
end

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

function Core:Initialize()
    self:CreateMainFrame()
end

return Core
