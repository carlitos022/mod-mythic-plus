-- mod-mythic-plus
-- Diagnostic script for NPC 90099 gossip binding.
-- Temporary v0.1 troubleshooting helper.

local NPC_ENTRY = 90099
local GOSSIP_HELLO = 1
local GOSSIP_SELECT = 2
local unpack_args = table.unpack or unpack

local function Log(msg)
    print("[MythicPlus][DEBUG] " .. tostring(msg))
end

local function SafeCall(label, fn, ...)
    local args = {...}
    local ok, result = xpcall(function()
        return fn(unpack_args(args))
    end, debug.traceback)

    if not ok then
        Log(label .. " ERROR:\n" .. tostring(result))
        return nil, false
    end

    return result, true
end

local function DebugHello(event, player, creature)
    Log("HELLO fired: event=" .. tostring(event)
        .. " player=" .. tostring(player and player:GetName() or "nil")
        .. " creatureEntry=" .. tostring(creature and creature:GetEntry() or "nil"))

    local _, ok = SafeCall("HELLO callback", function()
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "|cff00ff00[DEBUG] Mythic +1|r", 0, 9001)
        player:GossipMenuAddItem(0, "|cffffff00[DEBUG] Mythic +3|r", 0, 9003)
        player:GossipMenuAddItem(0, "|cffff8000[DEBUG] Mythic +5|r", 0, 9005)
        player:GossipSendMenu(1, creature)
    end)

    Log("HELLO finished. menu_ok=" .. tostring(ok))
    return true
end

local function DebugSelect(event, player, creature, sender, intid, code)
    Log("SELECT fired: sender=" .. tostring(sender)
        .. " intid=" .. tostring(intid)
        .. " code=" .. tostring(code))

    local _, ok = SafeCall("SELECT callback", function()
        player:SendBroadcastMessage("|cff00ccff[Mythic+ DEBUG]|r Seleccion recibida: " .. tostring(intid))
        player:GossipComplete()
    end)

    Log("SELECT finished. ok=" .. tostring(ok))
    return true
end

local function DebugSpawn(event, creature)
    Log("SPAWN fired for NPC entry=" .. tostring(creature:GetEntry())
        .. " guidLow=" .. tostring(creature:GetGUIDLow())
        .. " map=" .. tostring(creature:GetMapId()))
end

Log("Loading isolated NPC gossip diagnostics...")

local okHello, cancelHello = pcall(RegisterCreatureGossipEvent, NPC_ENTRY, GOSSIP_HELLO, DebugHello)
Log("RegisterCreatureGossipEvent HELLO: ok=" .. tostring(okHello)
    .. " return=" .. tostring(cancelHello))

local okSelect, cancelSelect = pcall(RegisterCreatureGossipEvent, NPC_ENTRY, GOSSIP_SELECT, DebugSelect)
Log("RegisterCreatureGossipEvent SELECT: ok=" .. tostring(okSelect)
    .. " return=" .. tostring(cancelSelect))

local okSpawn, cancelSpawn = pcall(RegisterCreatureEvent, NPC_ENTRY, 5, DebugSpawn)
Log("RegisterCreatureEvent SPAWN: ok=" .. tostring(okSpawn)
    .. " return=" .. tostring(cancelSpawn))

Log("Diagnostic script loaded for NPC 90099.")
