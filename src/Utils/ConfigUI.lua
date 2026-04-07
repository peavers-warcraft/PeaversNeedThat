local addonName, PNT = ...

local ConfigUI = {}
PNT.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

function ConfigUI:InitializeOptions()
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for PeaversNeedThat"
    )

    local content = panel.content
    local yPos = panel.yPos
    local baseSpacing = panel.baseSpacing
    local sectionSpacing = panel.sectionSpacing
    local controlIndent = baseSpacing + 15
    local sliderWidth = 380

    -- SECTION 1: General Settings
    local header, newY = ConfigUIUtils.CreateSectionHeader(content, "General Settings", baseSpacing, yPos)
    yPos = newY - 10

    local _, newY = ConfigUIUtils.CreateCheckbox(
        content, "PNTEnabledCheckbox", "Enable addon",
        controlIndent, yPos, PNT.Config.enabled,
        function(checked)
            PNT.Config.enabled = checked
            PNT.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = ConfigUIUtils.CreateCheckbox(
        content, "PNTAutoShowCheckbox", "Auto-show window when loot drops",
        controlIndent, yPos, PNT.Config.autoShow,
        function(checked)
            PNT.Config.autoShow = checked
            PNT.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = ConfigUIUtils.CreateCheckbox(
        content, "PNTOnlyMythicPlusCheckbox", "Only track loot in Mythic+ dungeons",
        controlIndent, yPos, PNT.Config.onlyInMythicPlus,
        function(checked)
            PNT.Config.onlyInMythicPlus = checked
            PNT.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = ConfigUIUtils.CreateCheckbox(
        content, "PNTLockPositionCheckbox", "Lock frame position",
        controlIndent, yPos, PNT.Config.lockPosition,
        function(checked)
            PNT.Config.lockPosition = checked
            PNT.Config:Save()
        end
    )
    yPos = newY - 15

    -- Separator
    local _, newY = ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 2: Loot Filtering
    local header, newY = ConfigUIUtils.CreateSectionHeader(content, "Loot Filtering", baseSpacing, yPos)
    yPos = newY - 10

    local qualityOptions = {
        [2] = "Uncommon (Green)",
        [3] = "Rare (Blue)",
        [4] = "Epic (Purple)",
    }
    local qualityContainer, qualityDropdown = ConfigUIUtils.CreateDropdown(
        content, "PNTMinQualityDropdown",
        "Minimum Item Quality", qualityOptions,
        qualityOptions[PNT.Config.minQuality] or "Rare (Blue)", sliderWidth,
        function(value)
            PNT.Config.minQuality = value
            PNT.Config:Save()
        end
    )
    qualityContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 65

    -- Separator
    local _, newY = ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 3: Whisper Message
    local header, newY = ConfigUIUtils.CreateSectionHeader(content, "Whisper Message", baseSpacing, yPos)
    yPos = newY - 10

    local defaultWhisper = "Hey! Do you need {item} ({slot})? If not, I'd love it!"

    -- Description
    local descText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", controlIndent, yPos)
    descText:SetWidth(sliderWidth)
    descText:SetText("Customize the whisper sent when you click the Need button on a loot item. Use the placeholders below to insert dynamic values into your message.")
    descText:SetTextColor(0.7, 0.7, 0.7)
    descText:SetJustifyH("LEFT")
    descText:SetWordWrap(true)
    yPos = yPos - 30

    -- Placeholder reference - one line per placeholder
    local placeholder1 = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholder1:SetPoint("TOPLEFT", controlIndent, yPos)
    placeholder1:SetWidth(sliderWidth)
    placeholder1:SetText("|cff3abdf7{item}|r  -  The item name in brackets, e.g. [Warglaive of Azzinoth]")
    placeholder1:SetTextColor(0.6, 0.6, 0.6)
    placeholder1:SetJustifyH("LEFT")
    yPos = yPos - 14

    local placeholder2 = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholder2:SetPoint("TOPLEFT", controlIndent, yPos)
    placeholder2:SetWidth(sliderWidth)
    placeholder2:SetText("|cff3abdf7{slot}|r  -  The equipment slot, e.g. Weapon, Chest, Trinket")
    placeholder2:SetTextColor(0.6, 0.6, 0.6)
    placeholder2:SetJustifyH("LEFT")
    yPos = yPos - 14

    local placeholder3 = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    placeholder3:SetPoint("TOPLEFT", controlIndent, yPos)
    placeholder3:SetWidth(sliderWidth)
    placeholder3:SetText("|cff3abdf7{player}|r  -  The name of the player who looted the item")
    placeholder3:SetTextColor(0.6, 0.6, 0.6)
    placeholder3:SetJustifyH("LEFT")
    yPos = yPos - 20

    -- Message edit box
    local editBoxContainer = CreateFrame("Frame", nil, content, "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    editBoxContainer:SetSize(sliderWidth, 28)
    editBoxContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    editBoxContainer:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
    editBoxContainer:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

    local editBox = CreateFrame("EditBox", "PNTWhisperMessageEditBox", editBoxContainer)
    editBox:SetPoint("TOPLEFT", 8, 0)
    editBox:SetPoint("BOTTOMRIGHT", -8, 0)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(255)
    editBox:SetText(PNT.Config.whisperMessage or defaultWhisper)

    editBox:SetScript("OnEnterPressed", function(self)
        PNT.Config.whisperMessage = self:GetText()
        PNT.Config:Save()
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(PNT.Config.whisperMessage or defaultWhisper)
        self:ClearFocus()
    end)

    yPos = yPos - 32

    -- Hint + Reset button row
    local hintText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hintText:SetPoint("TOPLEFT", controlIndent, yPos)
    hintText:SetText("Press Enter to save, Escape to cancel.")
    hintText:SetTextColor(0.5, 0.5, 0.5)

    local resetBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    resetBtn:SetSize(100, 20)
    resetBtn:SetPoint("LEFT", hintText, "RIGHT", 12, 0)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    resetBtn:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
    resetBtn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
    resetBtn:EnableMouse(true)
    resetBtn:RegisterForClicks("AnyUp")

    local resetBtnText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetBtnText:SetPoint("CENTER")
    resetBtnText:SetText("Reset Default")
    resetBtnText:SetTextColor(0.7, 0.7, 0.7)

    resetBtn:SetScript("OnClick", function()
        PNT.Config.whisperMessage = defaultWhisper
        PNT.Config:Save()
        editBox:SetText(defaultWhisper)
    end)
    resetBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.55, 0.6)
    end)
    resetBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
    end)

    yPos = yPos - 25

    -- Live preview
    local previewLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", controlIndent, yPos)
    previewLabel:SetWidth(sliderWidth)
    previewLabel:SetTextColor(0.5, 0.5, 0.5)
    previewLabel:SetJustifyH("LEFT")
    previewLabel:SetWordWrap(true)

    local function UpdatePreview()
        local template = editBox:GetText() or ""
        local preview = template
        preview = preview:gsub("{item}", "[Stormbringer's Runed Blade]")
        preview = preview:gsub("{slot}", "Weapon")
        preview = preview:gsub("{player}", "Thrall")
        previewLabel:SetText("|cff3abdf7Preview:|r " .. preview)
    end

    editBox:SetScript("OnTextChanged", function(self, userInput)
        UpdatePreview()
    end)
    UpdatePreview()

    yPos = yPos - 30

    -- Separator
    local _, newY = ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 4: Appearance
    local header, newY = ConfigUIUtils.CreateSectionHeader(content, "Appearance", baseSpacing, yPos)
    yPos = newY - 10

    local widthContainer, widthSlider = ConfigUIUtils.CreateSlider(
        content, "PNTFrameWidthSlider",
        "Frame Width", 250, 500, 10,
        PNT.Config.frameWidth, sliderWidth,
        function(value)
            PNT.Config.frameWidth = value
            PNT.Config:Save()
            if PNT.Core and PNT.Core.UpdateFrameSize then
                PNT.Core:UpdateFrameSize()
            end
        end
    )
    widthContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 55

    -- Separator
    local _, newY = ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 5: Debug
    local header, newY = ConfigUIUtils.CreateSectionHeader(content, "Debug", baseSpacing, yPos)
    yPos = newY - 10

    local _, newY = ConfigUIUtils.CreateCheckbox(
        content, "PNTDebugCheckbox", "Enable debug messages",
        controlIndent, yPos, PNT.Config.DEBUG_ENABLED,
        function(checked)
            PNT.Config.DEBUG_ENABLED = checked
            PNT.Config:Save()
        end
    )
    yPos = newY - 15

    panel:UpdateContentHeight(yPos)

    return panel
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

function ConfigUI:Open()
    local addon = _G[addonName]

    if Settings and Settings.OpenToCategory and addon then
        if addon.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, addon.directSettingsCategoryID)
            if success then return end
        end

        if addon.directCategoryID then
            local success = pcall(Settings.OpenToCategory, addon.directCategoryID)
            if success then return end
        end

        if addon.mainCategory then
            local success = pcall(Settings.OpenToCategory, addon.mainCategory)
            if success then return end
        end
    end

    if SettingsPanel then
        SettingsPanel:Open()
    end
end

return ConfigUI
