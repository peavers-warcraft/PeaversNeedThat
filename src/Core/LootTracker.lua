local addonName, PNT = ...

--------------------------------------------------------------------------------
-- LootTracker - Monitors CHAT_MSG_LOOT for items looted by group members
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

local LootTracker = {}
PNT.LootTracker = LootTracker

-- Current dungeon loot history
LootTracker.lootHistory = {}

-- Track the current M+ run to know when to clear
LootTracker.currentRunID = nil

-- Track whether a run just completed (so we keep tracking end-of-run chest loot)
LootTracker.runCompleted = false

--------------------------------------------------------------------------------
-- Equipment slot lookup
--------------------------------------------------------------------------------

local SLOT_NAMES = {
    INVTYPE_HEAD = "Head",
    INVTYPE_NECK = "Neck",
    INVTYPE_SHOULDER = "Shoulder",
    INVTYPE_CHEST = "Chest",
    INVTYPE_ROBE = "Chest",
    INVTYPE_WAIST = "Waist",
    INVTYPE_LEGS = "Legs",
    INVTYPE_FEET = "Feet",
    INVTYPE_WRIST = "Wrist",
    INVTYPE_HAND = "Hands",
    INVTYPE_FINGER = "Ring",
    INVTYPE_TRINKET = "Trinket",
    INVTYPE_CLOAK = "Back",
    INVTYPE_WEAPON = "Weapon",
    INVTYPE_2HWEAPON = "Two-Hand",
    INVTYPE_WEAPONMAINHAND = "Main Hand",
    INVTYPE_WEAPONOFFHAND = "Off Hand",
    INVTYPE_HOLDABLE = "Off Hand",
    INVTYPE_SHIELD = "Shield",
    INVTYPE_RANGED = "Ranged",
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function DebugPrint(msg)
    if PNT.Config and PNT.Config.DEBUG_ENABLED then
        Utils.Print(PNT, "|cff888888[Debug]|r " .. msg)
    end
end

-- Check if we are currently in a Mythic+ dungeon (or one just completed)
local function IsInMythicPlus()
    -- If a run just completed, keep tracking loot from the end chest
    if LootTracker.runCompleted then
        return true
    end
    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        return mapID ~= nil and mapID ~= 0
    end
    return false
end

-- Strip realm name from "Player-Realm" format, returning just the name
local function StripRealm(name)
    if not name then return nil end
    local stripped = name:match("^([^%-]+)")
    return stripped or name
end

-- Get the player's name (without realm)
local function GetPlayerName()
    local name = UnitName("player")
    return name
end

-- Parse item ID from an item link
local function GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local id = itemLink:match("item:(%d+)")
    if id then return tonumber(id) end
    return nil
end

--------------------------------------------------------------------------------
-- Parse CHAT_MSG_LOOT message to extract player name and item link
--------------------------------------------------------------------------------

local function ParseLootMessage(message, sender)
    -- The message argument of CHAT_MSG_LOOT contains the full formatted string
    -- It may look like:
    --   "You receive loot: |cff...|Hitem:...|h[Item Name]|h|r."
    --   "|Hplayer:Name-Realm|h[Name-Realm]|h receives loot: |cff...|Hitem:...|h[Item Name]|h|r."
    -- Or with the sender arg being the actual player name

    -- Extract the item link (the |Hitem:...|h[...]|h pattern)
    local itemLink = message:match("(|c%x+|Hitem:.-%|h%[.-%]|h|r)")

    -- If no link found, try alternate pattern
    if not itemLink then
        itemLink = message:match("(|Hitem:.-%|h%[.-%]|h)")
    end

    -- The sender (second arg of CHAT_MSG_LOOT) is the player who looted
    -- It may be "Player" or "Player-Realm"
    local playerName = sender

    -- If sender is empty or nil, try to parse from message
    if not playerName or playerName == "" then
        -- Try to extract from player link in message
        playerName = message:match("|Hplayer:([^|]+)|h")
        if not playerName then
            -- Check if it's the current player ("You receive loot")
            if message:find("You receive") then
                playerName = GetPlayerName()
            end
        end
    end

    return itemLink, playerName
end

--------------------------------------------------------------------------------
-- Process a loot event
--------------------------------------------------------------------------------

function LootTracker:ProcessLoot(message, sender)
    if not PNT.Config or not PNT.Config.enabled then return end

    -- Check if we should only track in M+
    if PNT.Config.onlyInMythicPlus and not IsInMythicPlus() then
        DebugPrint("Not in M+, ignoring loot event")
        return
    end

    local itemLink, playerName = ParseLootMessage(message, sender)

    if not itemLink or not playerName then
        DebugPrint("Could not parse loot message: " .. (message or "nil"))
        return
    end

    local playerShort = StripRealm(playerName)
    local myName = GetPlayerName()

    -- Don't track our own loot
    if playerShort == myName then
        DebugPrint("Ignoring own loot: " .. itemLink)
        return
    end

    local itemID = GetItemIDFromLink(itemLink)
    if not itemID then
        DebugPrint("Could not extract item ID from: " .. itemLink)
        return
    end

    -- Use GetItemInfo to check quality and get details
    -- GetItemInfo may return nil if the item is not cached; use a callback to retry
    self:ProcessItemInfo(itemLink, itemID, playerName)
end

function LootTracker:ProcessItemInfo(itemLink, itemID, playerName)
    local itemName, _, itemQuality, _, _, _, _, _, itemEquipLoc, itemTexture = C_Item.GetItemInfo(itemLink)

    if not itemName then
        -- Item not cached yet, wait and retry
        DebugPrint("Item not cached, retrying for ID: " .. itemID)
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            self:ProcessItemInfo(itemLink, itemID, playerName)
        end)
        return
    end

    -- Check minimum quality
    local minQuality = PNT.Config.minQuality or 3
    if itemQuality and itemQuality < minQuality then
        DebugPrint("Item below quality threshold: " .. itemName .. " (quality " .. itemQuality .. ")")
        return
    end

    -- Only track equippable items (have an equipment slot)
    local slotName = SLOT_NAMES[itemEquipLoc]
    if not slotName then
        DebugPrint("Non-equippable item ignored: " .. itemName .. " (slot: " .. (itemEquipLoc or "none") .. ")")
        return
    end

    -- Build loot entry
    local entry = {
        itemLink = itemLink,
        playerName = playerName,
        playerShort = StripRealm(playerName),
        itemID = itemID,
        itemName = itemName,
        itemQuality = itemQuality,
        itemEquipLoc = itemEquipLoc,
        slotName = slotName,
        itemTexture = itemTexture or GetItemIcon(itemID),
        timestamp = time(),
        asked = false,
    }

    -- Insert at the beginning (newest first)
    table.insert(self.lootHistory, 1, entry)

    DebugPrint("Tracked loot: " .. itemLink .. " from " .. playerName .. " (" .. slotName .. ")")

    -- Notify the dialog to update
    if PNT.LootDialog then
        PNT.LootDialog:Refresh()
    end

    -- Auto-show the frame if configured
    if PNT.Config.autoShow and PNT.Core then
        PNT.Core:Show()
    end
end

--------------------------------------------------------------------------------
-- Clear loot history
--------------------------------------------------------------------------------

function LootTracker:Clear()
    wipe(self.lootHistory)
    if PNT.LootDialog then
        PNT.LootDialog:Refresh()
    end
    Utils.Print(PNT, "Loot history cleared.")
end

--------------------------------------------------------------------------------
-- Check for new M+ run (clear on new run)
--------------------------------------------------------------------------------

function LootTracker:CheckNewRun()
    if not C_ChallengeMode then return end

    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    if mapID and mapID ~= 0 then
        if self.currentRunID ~= mapID then
            -- New run detected, clear old data
            if self.currentRunID then
                DebugPrint("New M+ run detected, clearing old loot history")
                wipe(self.lootHistory)
                if PNT.LootDialog then
                    PNT.LootDialog:Refresh()
                end
            end
            self.currentRunID = mapID
        end
    else
        -- Not in M+ anymore
        self.currentRunID = nil
        self.runCompleted = false
    end
end

--------------------------------------------------------------------------------
-- Initialize - register events
--------------------------------------------------------------------------------

function LootTracker:Initialize()
    -- Register for loot events
    -- Note: Events wrapper passes (event, ...) so first arg is the event name
    PeaversCommons.Events:RegisterEvent("CHAT_MSG_LOOT", function(event, message, sender, ...)
        self:ProcessLoot(message, sender)
    end)

    -- Check for new M+ runs on zone changes
    PeaversCommons.Events:RegisterEvent("ZONE_CHANGED_NEW_AREA", function(event)
        self:CheckNewRun()
    end)

    PeaversCommons.Events:RegisterEvent("CHALLENGE_MODE_START", function(event)
        DebugPrint("M+ run started, clearing loot history")
        wipe(self.lootHistory)
        self.currentRunID = C_ChallengeMode.GetActiveChallengeMapID()
        self.runCompleted = false
        if PNT.LootDialog then
            PNT.LootDialog:Refresh()
        end
    end)

    -- When M+ run completes, keep tracking loot and auto-show window
    PeaversCommons.Events:RegisterEvent("CHALLENGE_MODE_COMPLETED", function(event)
        DebugPrint("M+ run completed, showing loot summary")
        self.runCompleted = true

        -- Auto-show the window so the user sees what dropped
        if PNT.Core then
            PNT.Core:Show()
        end
    end)

    DebugPrint("LootTracker initialized")
end

return LootTracker
