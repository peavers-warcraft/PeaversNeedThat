local addonName, PNT = ...

local ConfigUI = {}
PNT.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
local W = PeaversCommons.Widgets
local C = W.Colors

local pageOpts = {
    indent = 25,
    width = 360,
}

local function GetPageOpts(parentFrame)
    local opts = {}
    for k, v in pairs(pageOpts) do opts[k] = v end
    local frameWidth = parentFrame:GetWidth()
    if frameWidth and frameWidth > 100 then
        opts.width = frameWidth - (opts.indent * 2) - 10
    end
    return opts
end

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    local _, newY = W:CreateSectionHeader(parentFrame, "General Settings", indent, y)
    y = newY - 8

    local toggle1 = W:CreateCheckbox(parentFrame, "Enable addon", {
        checked = PNT.Config.enabled,
        width = width,
        onChange = function(checked)
            PNT.Config.enabled = checked
            PNT.Config:Save()
        end,
    })
    toggle1:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    local toggle2 = W:CreateCheckbox(parentFrame, "Auto-show window when loot drops", {
        checked = PNT.Config.autoShow,
        width = width,
        onChange = function(checked)
            PNT.Config.autoShow = checked
            PNT.Config:Save()
        end,
    })
    toggle2:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    local toggle3 = W:CreateCheckbox(parentFrame, "Only track loot in Mythic+ dungeons", {
        checked = PNT.Config.onlyInMythicPlus,
        width = width,
        onChange = function(checked)
            PNT.Config.onlyInMythicPlus = checked
            PNT.Config:Save()
        end,
    })
    toggle3:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    local toggle4 = W:CreateCheckbox(parentFrame, "Lock frame position", {
        checked = PNT.Config.lockPosition,
        width = width,
        onChange = function(checked)
            PNT.Config.lockPosition = checked
            PNT.Config:Save()
        end,
    })
    toggle4:SetPoint("TOPLEFT", indent, y)
    y = y - 40

    _, newY = W:CreateSectionHeader(parentFrame, "Loot Filtering", indent, y)
    y = newY - 8

    local qualityOptions = {
        { value = 2, label = "Uncommon (Green)" },
        { value = 3, label = "Rare (Blue)" },
        { value = 4, label = "Epic (Purple)" },
    }

    local qualityDropdown = W:CreateDropdown(parentFrame, "Minimum Item Quality", {
        options = qualityOptions,
        selected = PNT.Config.minQuality or 3,
        width = width,
        onChange = function(value)
            PNT.Config.minQuality = value
            PNT.Config:Save()
        end,
    })
    qualityDropdown:SetPoint("TOPLEFT", indent, y)
    y = y - 58

    _, newY = W:CreateSectionHeader(parentFrame, "Appearance", indent, y)
    y = newY - 8

    local widthSlider = W:CreateSlider(parentFrame, "Frame Width", {
        min = 450, max = 750, step = 1,
        value = PNT.Config.frameWidth or 580,
        width = width,
        onChange = function(value)
            PNT.Config.frameWidth = value
            PNT.Config:Save()
            if PNT.Core and PNT.Core.UpdateFrameSize then
                PNT.Core:UpdateFrameSize()
            end
        end,
    })
    widthSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 52

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI.BuildWhisperPage(_, parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width
    local defaultWhisper = "Hey! Do you need {item} ({slot})? If not, I'd love it!"

    local _, newY = W:CreateSectionHeader(parentFrame, "Whisper Message", indent, y)
    y = newY - 8

    local desc = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", indent, y)
    desc:SetWidth(width)
    desc:SetText("Customize the whisper sent when you click the Need button. Use placeholders to insert dynamic values.")
    desc:SetTextColor(C.textSec[1], C.textSec[2], C.textSec[3])
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    y = y - 30

    local placeholders = {
        { tag = "{item}", desc = "The item name in brackets, e.g. [Warglaive of Azzinoth]" },
        { tag = "{slot}", desc = "The equipment slot, e.g. Weapon, Chest, Trinket" },
        { tag = "{player}", desc = "The name of the player who looted the item" },
    }

    for _, p in ipairs(placeholders) do
        local line = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", indent, y)
        line:SetWidth(width)
        line:SetText("|cff" .. string.format("%02x%02x%02x",
            C.accent[1] * 255, C.accent[2] * 255, C.accent[3] * 255) .. p.tag .. "|r  -  " .. p.desc)
        line:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
        line:SetJustifyH("LEFT")
        y = y - 14
    end
    y = y - 6

    local editBoxContainer = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", indent, y)
    editBoxContainer:SetSize(width, 28)
    editBoxContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    editBoxContainer:SetBackdropColor(C.bgInput[1], C.bgInput[2], C.bgInput[3], C.bgInput[4])
    editBoxContainer:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])

    local editBox = CreateFrame("EditBox", nil, editBoxContainer)
    editBox:SetPoint("TOPLEFT", 8, 0)
    editBox:SetPoint("BOTTOMRIGHT", -8, 0)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(255)
    editBox:SetText(PNT.Config.whisperMessage or defaultWhisper)

    local function SaveWhisperMessage()
        local text = editBox:GetText()
        if text and text ~= "" then
            PNT.Config.whisperMessage = text
            PNT.Config:Save()
        end
    end

    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    editBox:SetScript("OnEnterPressed", function(self) SaveWhisperMessage(); self:ClearFocus() end)
    editBox:SetScript("OnEditFocusLost", function() SaveWhisperMessage() end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(PNT.Config.whisperMessage or defaultWhisper)
        self:ClearFocus()
    end)
    y = y - 32

    local hintText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("TOPLEFT", indent, y)
    hintText:SetText("Press Enter to save, Escape to cancel.")
    hintText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

    local resetBtn = W:CreateButton(parentFrame, "Reset Default", {
        style = "secondary",
        width = 100,
        onClick = function()
            PNT.Config.whisperMessage = defaultWhisper
            PNT.Config:Save()
            editBox:SetText(defaultWhisper)
        end,
    })
    resetBtn:SetPoint("LEFT", hintText, "RIGHT", 12, 0)
    y = y - 25

    local previewLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", indent, y)
    previewLabel:SetWidth(width)
    previewLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    previewLabel:SetJustifyH("LEFT")
    previewLabel:SetWordWrap(true)

    local function UpdatePreview()
        local template = editBox:GetText() or ""
        local preview = template
        preview = preview:gsub("{item}", "[Stormbringer's Runed Blade]")
        preview = preview:gsub("{slot}", "Weapon")
        preview = preview:gsub("{player}", "Thrall")
        previewLabel:SetText("|cff" .. string.format("%02x%02x%02x",
            C.accent[1] * 255, C.accent[2] * 255, C.accent[3] * 255) .. "Preview:|r " .. preview)
    end

    editBox:SetScript("OnTextChanged", function() UpdatePreview() end)
    UpdatePreview()
    y = y - 30

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildDebugPage(parentFrame)
    local y = -10
    local opts = GetPageOpts(parentFrame)
    local indent = opts.indent
    local width = opts.width

    local _, newY = W:CreateSectionHeader(parentFrame, "Debug", indent, y)
    y = newY - 8

    local toggle = W:CreateCheckbox(parentFrame, "Enable debug messages", {
        checked = PNT.Config.DEBUG_ENABLED,
        width = width,
        onChange = function(checked)
            PNT.Config.DEBUG_ENABLED = checked
            PNT.Config:Save()
        end,
    })
    toggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Need That", {
        "Watches loot drops in Mythic+ dungeons and detects items that would be " ..
            "an upgrade for your character. When one drops for someone else, a " ..
            "small window lets you send a polite whisper asking for it.",
        { command = "/pnt", desc = "toggle the loot window" },
        { command = "/pnt clear", desc = "clear the current loot list" },
        { command = "/pnt config", desc = "open the configuration panel" },

        { header = "How it decides what is an upgrade" },
        "Dropped items are compared against what you have equipped in the same " ..
            "slot. Only items your class and spec can actually use are considered, " ..
            "so the window stays quiet unless something is genuinely relevant.",

        { header = "Whispering" },
        "Nothing is ever sent automatically. The window only pre-writes a " ..
            "courteous message - you choose whether to send it, and to whom.",
    })
end

function ConfigUI:GetPages()
    return {
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
        { key = "whisper", label = "Whisper", builder = function(f) ConfigUI:BuildWhisperPage(f) end },
        { key = "debug", label = "Debug", builder = function(f) ConfigUI:BuildDebugPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildGeneralPage(parentFrame)
    return parentFrame
end

function ConfigUI:Initialize()
end

function ConfigUI:Open()
    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversNeedThat")
        return
    end

    if Settings and Settings.OpenToCategory then
        local addon = _G[addonName]
        if addon and addon.directSettingsCategoryID then
            pcall(Settings.OpenToCategory, addon.directSettingsCategoryID)
        end
    end
end

return ConfigUI
