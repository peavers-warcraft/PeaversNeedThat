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
        -- Populate with sample loot data for testing UI and whisper message
        Utils.Print(PNT, "Loading test data. Whispers will be sent to yourself.")
        PNT.Config._testMode = true

        wipe(PNT.LootTracker.lootHistory)

        local myName = UnitName("player")
        local myFullName = myName
        local _, myRealm = UnitFullName("player")
        if myRealm and myRealm ~= "" then
            myFullName = myName .. "-" .. myRealm
        end

        local testItems = {
            { name = "Stormbreaker's Warhelm",      quality = 4, slot = "INVTYPE_HEAD",           slotName = "Head",      icon = 133077, player = "Thrall" },
            { name = "Vestments of the Eternal",     quality = 4, slot = "INVTYPE_CHEST",          slotName = "Chest",     icon = 132680, player = "Jaina" },
            { name = "Signet of Fading Light",       quality = 4, slot = "INVTYPE_FINGER",         slotName = "Ring",      icon = 133345, player = "Anduin" },
            { name = "Greatsword of the Fallen",     quality = 4, slot = "INVTYPE_2HWEAPON",       slotName = "Two-Hand",  icon = 135274, player = "Saurfang" },
            { name = "Drape of Frozen Dreams",       quality = 3, slot = "INVTYPE_CLOAK",          slotName = "Back",      icon = 133762, player = "Sylvanas" },
        }

        for i, item in ipairs(testItems) do
            local entry = {
                itemLink = "|cff" .. (item.quality == 4 and "a335ee" or "0070dd") .. "|Hitem:" .. (200000 + i) .. "::::::::80:::::|h[" .. item.name .. "]|h|r",
                playerName = myFullName,
                playerShort = item.player,
                itemID = 200000 + i,
                itemName = item.name,
                itemQuality = item.quality,
                itemEquipLoc = item.slot,
                slotName = item.slotName,
                itemTexture = item.icon,
                timestamp = time() - (i * 30),
                asked = false,
            }
            table.insert(PNT.LootTracker.lootHistory, entry)
        end

        PNT.LootDialog:Refresh()
        if PNT.Core then
            PNT.Core:Show()
        end
    end,
    help = function()
        Utils.Print(PNT, "Commands:")
        print("  /pnt - Toggle loot window")
        print("  /pnt clear - Clear current loot list")
        print("  /pnt config - Open settings")
        print("  /pnt test - Load sample data (whispers sent to yourself)")
        print("  /pnt debug - Toggle debug mode")
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
                "/pnt test - Load sample data for testing",
                "/pnt debug - Toggle debug mode",
                "/pnt help - Show available commands"
            }
        )
    end)

    -- Register with PeaversConfig registry
    if PeaversCommons.ConfigRegistry then
        PeaversCommons.ConfigRegistry:Register({
            name = "PeaversNeedThat",
            displayName = "Need That",
            description = "Loot tracking and whisper dialogs for M+",
            addonRef = PNT,
            config = PNT.Config,
            pages = PNT.ConfigUI:GetPages(),
            order = 6,
        })
    end
end, {
    suppressAnnouncement = true
})

-- Export addon table
_G.PeaversNeedThat = PNT

return PNT
