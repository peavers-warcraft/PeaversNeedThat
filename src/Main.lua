local addonName, PNT = ...

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r " .. addonName .. " requires PeaversCommons.")
    return
end

local Utils = PeaversCommons.Utils

PNT = PNT or {}
PNT.name = addonName
PNT.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Toggle display function (used by slash command default)
function PNT:ToggleDisplay()
    if PNT.Core then
        PNT.Core:Toggle()
    end
end

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pnt", {
    default = function()
        PNT:ToggleDisplay()
    end,
    clear = function()
        if PNT.LootTracker then
            PNT.LootTracker:Clear()
        end
    end,
    config = function()
        if PNT.ConfigUI then
            PNT.ConfigUI:Open()
        end
    end,
    debug = function()
        PNT.Config.DEBUG_ENABLED = not PNT.Config.DEBUG_ENABLED
        PNT.Config:Save()
        Utils.Print(PNT, "Debug mode " .. (PNT.Config.DEBUG_ENABLED and "enabled" or "disabled"))
    end,
    test = function()
        -- Simulate a loot event for testing outside of M+
        if PNT.Config.DEBUG_ENABLED then
            local testLink = "|cff0070dd|Hitem:237627::::::::80:::::|h[Test Item]|h|r"
            Utils.Print(PNT, "Simulating loot event (debug mode)")
            local entry = {
                itemLink = testLink,
                playerName = "TestPlayer-TestRealm",
                playerShort = "TestPlayer",
                itemID = 237627,
                itemName = "Test Item",
                itemQuality = 3,
                itemEquipLoc = "INVTYPE_CHEST",
                slotName = "Chest",
                itemTexture = 134400,
                timestamp = time(),
                asked = false,
            }
            table.insert(PNT.LootTracker.lootHistory, 1, entry)
            PNT.LootDialog:Refresh()
            if PNT.Config.autoShow and PNT.Core then
                PNT.Core:Show()
            end
        else
            Utils.Print(PNT, "Test command requires debug mode. Use /pnt debug first.")
        end
    end,
    help = function()
        Utils.Print(PNT, "Commands:")
        print("  /pnt - Toggle loot window")
        print("  /pnt clear - Clear current loot list")
        print("  /pnt config - Open settings")
        print("  /pnt debug - Toggle debug mode")
        print("  /pnt test - Simulate loot event (requires debug mode)")
        print("  /pnt help - Show this help")
    end
})

-- Initialize the addon
PeaversCommons.Events:Init(addonName, function()
    -- Initialize config (handled by ConfigManager, but ensure loaded)
    PNT.Config:Initialize()

    -- Migrate old whisper message format (%s → {placeholder})
    if PNT.Config.whisperMessage and PNT.Config.whisperMessage:find("%%s") then
        PNT.Config.whisperMessage = "Hey! Do you need {item} ({slot})? If not, I'd love it!"
        PNT.Config:Save()
    end

    -- Initialize ConfigUI
    if PNT.ConfigUI and PNT.ConfigUI.Initialize then
        PNT.ConfigUI:Initialize()
    end

    -- Initialize core UI
    if PNT.Core and PNT.Core.Initialize then
        PNT.Core:Initialize()
    end

    -- Initialize loot tracker (registers events)
    if PNT.LootTracker and PNT.LootTracker.Initialize then
        PNT.LootTracker:Initialize()
    end

    -- Create settings pages
    C_Timer.After(0.5, function()
        PeaversCommons.SettingsUI:CreateSettingsPages(
            PNT,
            "PeaversNeedThat",
            "Peavers Need That",
            "Monitors loot drops in M+ dungeons and provides quick whisper dialogs to ask for items.",
            {
                "/pnt - Toggle loot window",
                "/pnt clear - Clear current loot list",
                "/pnt config - Open settings",
                "/pnt debug - Toggle debug mode",
                "/pnt help - Show available commands"
            }
        )
    end)

end, {
    suppressAnnouncement = true
})

-- Export addon table
_G.PeaversNeedThat = PNT

return PNT
