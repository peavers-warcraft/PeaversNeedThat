--------------------------------------------------------------------------------
-- PeaversNeedThat Configuration
-- Uses PeaversCommons.ConfigManager with AceDB-3.0 for profile management
--------------------------------------------------------------------------------

local addonName, PNT = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

-- Color palette matching PeaversCVars theme
PNT.Colors = {
    ACCENT = {0.23, 0.74, 0.97, 1},
    ACCENT_DARK = {0.18, 0.59, 0.78, 1},
    BG_PRIMARY = {0.08, 0.08, 0.10, 0.97},
    BG_SECONDARY = {0.12, 0.12, 0.14, 0.95},
    BG_TERTIARY = {0.15, 0.15, 0.18, 0.9},
    BG_HOVER = {0.2, 0.4, 0.55, 0.6},
    TEXT_PRIMARY = {1, 1, 1, 1},
    TEXT_SECONDARY = {0.7, 0.7, 0.7, 1},
    TEXT_MUTED = {0.5, 0.5, 0.5, 1},
    BORDER_PRIMARY = {0.3, 0.3, 0.35, 1},
    BORDER_LIGHT = {0.4, 0.4, 0.45, 1},
}

local PNT_DEFAULTS = {
    enabled = true,
    frameWidth = 580,
    framePoint = "CENTER",
    frameX = 0,
    frameY = 0,
    lockPosition = false,
    autoShow = true,
    showOnLogin = false,
    minQuality = 3,
    whisperMessage = "Hey! Do you need {item} ({slot})? If not, I'd love it!",
    onlyInMythicPlus = true,
    DEBUG_ENABLED = false,
}

-- Create the AceDB-backed config
PNT.Config = ConfigManager:NewWithAceDB(
    PNT,
    PNT_DEFAULTS,
    {
        savedVariablesName = "PeaversNeedThatDB",
        profileType = "shared",
        onProfileChanged = function()
            if PNT.Core and PNT.Core.UpdateFrameSize then
                PNT.Core:UpdateFrameSize()
            end
        end,
    }
)

return PNT.Config
