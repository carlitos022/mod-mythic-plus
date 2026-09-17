-- mod-mythic-plus
-- ALE / Eluna v0.1
-- NPC +1..+5, pending challenge, instance activation and basic scaling.

MythicPlus = MythicPlus or {}

MythicPlus.Config = {
    NpcEntry = 90099,
    MinLevel = 1,
    MaxLevel = 5,
    PilotMapId = 632,
    Debug = true
}

MythicPlus.Levels = MythicPlus.Levels or {}
MythicPlus.Dungeons = MythicPlus.Dungeons or {}
MythicPlus.Bosses = MythicPlus.Bosses or {}
MythicPlus.InstanceCache = MythicPlus.InstanceCache or {}
MythicPlus.ScaledCreatures = MythicPlus.ScaledCreatures or {}

local GOSSIP_EVENT_ON_HELLO = 1
local GOSSIP_EVENT_ON_SELECT = 2
local PLAYER_EVENT_ON_MAP_CHANGE = 28
local INSTANCE_EVENT_ON_CREATURE_CREATE = 5
local ALL_CREATURE_EVENT_ON_DEAL_DAMAGE = 13

local GOSSIP_TEXT_ID = 1
local MENU_LEVEL_BASE = 100

local function Debug(message)
    if MythicPlus.Config.Debug then
        print("[MythicPlus][DEBUG] " .. tostring(message))
    end
end

local function Notify(player, message)
    player:SendBroadcastMessage("|cff00ccff[Mythic+]|r " .. message)
end

function MythicPlus.ReloadLevels()
    MythicPlus.Levels = {}

    local query = WorldDBQuery([[
        SELECT
            level,
            mob_health_multiplier,
            mob_damage_multiplier,
            boss_health_multiplier,
            boss_damage_multiplier,
            reward_multiplier
        FROM custom_mythic_levels
        ORDER BY level
    ]])

    if not query then
        print("[MythicPlus] ERROR: custom_mythic_levels is empty or missing.")
        return 0
    end

    local count = 0
    repeat
        local level = query:GetUInt8(0)
        MythicPlus.Levels[level] = {
            level = level,
            mobHealth = query:GetFloat(1),
            mobDamage = query:GetFloat(2),
            bossHealth = query:GetFloat(3),
            bossDamage = query:GetFloat(4),
            reward = query:GetFloat(5)
        }
        count = count + 1
    until not query:NextRow()

    Debug("Loaded " .. count .. " mythic levels.")
    return count
end

function MythicPlus.ReloadDungeons()
    MythicPlus.Dungeons = {}

    local query = WorldDBQuery([[
        SELECT map_id, name, enabled, min_level, max_level
        FROM custom_mythic_dungeons
    ]])

    if not query then
        print("[MythicPlus] ERROR: custom_mythic_dungeons is empty or missing.")
        return 0
    end

    local count = 0
    repeat
        local mapId = query:GetUInt32(0)
        MythicPlus.Dungeons[mapId] = {
            mapId = mapId,
            name = query:GetString(1),
            enabled = query:GetUInt8(2) == 1,
            minLevel = query:GetUInt8(3),
            maxLevel = query:GetUInt8(4)
        }
        count = count + 1
    until not query:NextRow()

    Debug("Loaded " .. count .. " mythic dungeons.")
    return count
end

function MythicPlus.ReloadBosses()
    MythicPlus.Bosses = {}

    local query = WorldDBQuery([[
        SELECT map_id, creature_entry, boss_order
        FROM custom_mythic_bosses
    ]])

    if not query then
        Debug("No mythic bosses configured.")
        return 0
    end

    local count = 0
    repeat
        local mapId = query:GetUInt32(0)
        local entry = query:GetUInt32(1)
        MythicPlus.Bosses[mapId] = MythicPlus.Bosses[mapId] or {}
        MythicPlus.Bosses[mapId][entry] = query:GetUInt8(2)
        count = count + 1
    until not query:NextRow()

    Debug("Loaded " .. count .. " mythic bosses.")
    return count
end

function MythicPlus.ReloadConfig()
    local levels = MythicPlus.ReloadLevels()
    local dungeons = MythicPlus.ReloadDungeons()
    local bosses = MythicPlus.ReloadBosses()

    print(string.format(
        "[MythicPlus] Config loaded: %d levels, %d dungeons, %d bosses.",
        levels,
        dungeons,
        bosses
    ))
end

function MythicPlus.GetLevel(level)
    return MythicPlus.Levels[tonumber(level)]
end

function MythicPlus.GetDungeon(mapId)
    return MythicPlus.Dungeons[tonumber(mapId)]
end

function MythicPlus.IsBoss(mapId, creatureEntry)
    local mapBosses = MythicPlus.Bosses[tonumber(mapId)]
    return mapBosses ~= nil and mapBosses[tonumber(creatureEntry)] ~= nil
end

function MythicPlus.IsValidLevel(mapId, level)
    mapId = tonumber(mapId)
    level = tonumber(level)

    local dungeon = MythicPlus.GetDungeon(mapId)
    local levelConfig = MythicPlus.GetLevel(level)

    if not dungeon or not dungeon.enabled or not levelConfig then
        return false
    end

    return level >= dungeon.minLevel and level <= dungeon.maxLevel
end

function MythicPlus.GetLeaderLowGuid(player)
    local group = player:GetGroup()
    if group then
        return GetGUIDLow(group:GetLeaderGUID()), group
    end
    return player:GetGUIDLow(), nil
end

function MythicPlus.GetInstance(instanceId)
    local id = tonumber(instanceId)
    if not id or id <= 0 then
        return nil
    end

    if MythicPlus.InstanceCache[id] ~= nil then
        return MythicPlus.InstanceCache[id] or nil
    end

    local query = CharDBQuery(string.format([[
        SELECT instance_id, map_id, mythic_level, leader_guid, status
        FROM custom_mythic_instances
        WHERE instance_id = %u
        LIMIT 1
    ]], id))

    if not query then
        MythicPlus.InstanceCache[id] = false
        return nil
    end

    local data = {
        instanceId = query:GetUInt32(0),
        mapId = query:GetUInt32(1),
        level = query:GetUInt8(2),
        leaderGuid = query:GetUInt32(3),
        status = query:GetString(4)
    }

    MythicPlus.InstanceCache[id] = data
    return data
end

function MythicPlus.RegisterInstance(instanceId, mapId, level, leaderGuid)
    instanceId = tonumber(instanceId)
    mapId = tonumber(mapId)
    level = tonumber(level)
    leaderGuid = tonumber(leaderGuid)

    if not instanceId or instanceId <= 0 then
        return false, "invalid_instance_id"
    end

    if not MythicPlus.IsValidLevel(mapId, level) then
        return false, "invalid_level"
    end

    if not leaderGuid or leaderGuid <= 0 then
        return false, "invalid_leader"
    end

    CharDBExecute(string.format([[
        REPLACE INTO custom_mythic_instances
        (instance_id, map_id, mythic_level, leader_guid, group_guid, status, started_at, created_at)
        VALUES (%u, %u, %u, %u, 0, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    ]], instanceId, mapId, level, leaderGuid))

    MythicPlus.InstanceCache[instanceId] = {
        instanceId = instanceId,
        mapId = mapId,
        level = level,
        leaderGuid = leaderGuid,
        status = "active"
    }

    MythicPlus.ScaledCreatures[instanceId] = {}

    Debug(string.format(
        "Registered instance %u map %u at mythic +%u.",
        instanceId,
        mapId,
        level
    ))

    return true
end

function MythicPlus.SetPendingChallenge(player, mapId, level)
    mapId = tonumber(mapId)
    level = tonumber(level)

    if not MythicPlus.IsValidLevel(mapId, level) then
        return false, "invalid_level"
    end

    local leaderLow, group = MythicPlus.GetLeaderLowGuid(player)

    if group and not group:IsLeader(player:GetGUID()) then
        return false, "not_group_leader"
    end

    CharDBExecute(string.format([[
        REPLACE INTO custom_mythic_pending
        (leader_guid, map_id, mythic_level, selected_at)
        VALUES (%u, %u, %u, CURRENT_TIMESTAMP)
    ]], leaderLow, mapId, level))

    Debug(string.format(
        "Pending challenge saved: leader=%u map=%u level=+%u",
        leaderLow,
        mapId,
        level
    ))

    return true
end

function MythicPlus.GetPendingChallenge(player, mapId)
    local leaderLow = MythicPlus.GetLeaderLowGuid(player)

    local query = CharDBQuery(string.format([[
        SELECT map_id, mythic_level
        FROM custom_mythic_pending
        WHERE leader_guid = %u AND map_id = %u
        LIMIT 1
    ]], leaderLow, mapId))

    if not query then
        return nil
    end

    return {
        leaderGuid = leaderLow,
        mapId = query:GetUInt32(0),
        level = query:GetUInt8(1)
    }
end

function MythicPlus.ClearPendingChallenge(leaderGuid)
    CharDBExecute(string.format(
        "DELETE FROM custom_mythic_pending WHERE leader_guid = %u",
        tonumber(leaderGuid) or 0
    ))
end

local function BroadcastToGroup(player, message)
    local group = player:GetGroup()

    if not group then
        Notify(player, message)
        return
    end

    local members = group:GetMembers()
    for _, member in pairs(members) do
        if member then
            Notify(member, message)
        end
    end
end

function MythicPlus.ScaleCreature(creature, active)
    if not creature or not active then
        return false
    end

    local instanceId = tonumber(active.instanceId) or creature:GetInstanceId()
    local mapId = creature:GetMapId()

    if instanceId <= 0 or mapId ~= active.mapId then
        return false
    end

    if creature:GetOwnerGUID() ~= 0 then
        return false
    end

    MythicPlus.ScaledCreatures[instanceId] = MythicPlus.ScaledCreatures[instanceId] or {}

    local guidLow = creature:GetGUIDLow()
    if MythicPlus.ScaledCreatures[instanceId][guidLow] then
        return false
    end

    local levelCfg = MythicPlus.GetLevel(active.level)
    if not levelCfg then
        return false
    end

    local isBoss = MythicPlus.IsBoss(mapId, creature:GetEntry())
    local multiplier = isBoss and levelCfg.bossHealth or levelCfg.mobHealth
    local originalMaxHealth = creature:GetMaxHealth()

    if originalMaxHealth <= 0 then
        return false
    end

    local scaledHealth = math.floor(originalMaxHealth * multiplier)

    creature:SetMaxHealth(scaledHealth)
    creature:SetHealth(scaledHealth)

    MythicPlus.ScaledCreatures[instanceId][guidLow] = true

    Debug(string.format(
        "Scaled %s entry=%u guid=%u instance=%u HP=%u->%u x%.2f",
        isBoss and "BOSS" or "MOB",
        creature:GetEntry(),
        guidLow,
        instanceId,
        originalMaxHealth,
        scaledHealth,
        multiplier
    ))

    return true
end

function MythicPlus.ScaleExistingCreatures(map, active)
    if not map or not active then
        return 0
    end

    local creatures = map:GetCreatures()
    if not creatures then
        Debug("Map:GetCreatures returned nil for instance=" .. tostring(active.instanceId))
        return 0
    end

    local total = 0
    local scaled = 0

    for _, creature in pairs(creatures) do
        total = total + 1
        if MythicPlus.ScaleCreature(creature, active) then
            scaled = scaled + 1
        end
    end

    Debug(string.format(
        "Existing creature pass instance=%u total=%u scaled=%u level=+%u",
        active.instanceId,
        total,
        scaled,
        active.level
    ))

    return scaled
end

local function OnMythicNpcHello(event, player, creature)
    Debug("Gossip HELLO fired for player=" .. player:GetName() .. " npc=" .. creature:GetEntry())

    player:GossipClearMenu()

    local dungeon = MythicPlus.GetDungeon(MythicPlus.Config.PilotMapId)
    if not dungeon or not dungeon.enabled then
        Notify(player, "No hay mazmorras miticas habilitadas.")
        player:GossipComplete()
        return true
    end

    local added = 0

    for level = dungeon.minLevel, dungeon.maxLevel do
        local cfg = MythicPlus.GetLevel(level)

        if cfg then
            local label = string.format(
                "|cff00ff00%s +%d|r  |cffffffffVida x%.2f / Dano x%.2f|r",
                dungeon.name,
                level,
                cfg.mobHealth,
                cfg.mobDamage
            )

            player:GossipMenuAddItem(0, label, 0, MENU_LEVEL_BASE + level)
            added = added + 1
        end
    end

    Debug("Gossip items added=" .. added)
    player:GossipSendMenu(GOSSIP_TEXT_ID, creature)
    return true
end

local function OnMythicNpcSelect(event, player, creature, sender, intid)
    Debug("Gossip SELECT fired sender=" .. tostring(sender) .. " intid=" .. tostring(intid))

    local level = tonumber(intid) - MENU_LEVEL_BASE

    if level < MythicPlus.Config.MinLevel or level > MythicPlus.Config.MaxLevel then
        player:GossipComplete()
        return true
    end

    local ok, reason = MythicPlus.SetPendingChallenge(
        player,
        MythicPlus.Config.PilotMapId,
        level
    )

    player:GossipComplete()

    if not ok then
        if reason == "not_group_leader" then
            Notify(player, "Solo el lider del grupo puede seleccionar la dificultad mitica.")
        else
            Notify(player, "No se pudo preparar la instancia mitica. Motivo: " .. tostring(reason))
        end

        Debug("Pending challenge failed reason=" .. tostring(reason))
        return true
    end

    local dungeon = MythicPlus.GetDungeon(MythicPlus.Config.PilotMapId)
    BroadcastToGroup(player, string.format(
        "%s +%d preparada. Entra a la instancia para activarla.",
        dungeon.name,
        level
    ))

    Debug("Mythic +" .. level .. " selected successfully.")
    return true
end

local function OnPlayerMapChange(event, player)
    local mapId = player:GetMapId()
    local instanceId = player:GetInstanceId()

    Debug("MAP_CHANGE player=" .. player:GetName() .. " map=" .. tostring(mapId) .. " instance=" .. tostring(instanceId))

    local dungeon = MythicPlus.GetDungeon(mapId)
    if not dungeon or not dungeon.enabled then
        return
    end

    if not instanceId or instanceId <= 0 then
        Debug("Map is mythic-enabled but instanceId is invalid.")
        return
    end

    local active = MythicPlus.GetInstance(instanceId)
    if active then
        Debug("Instance already registered at mythic +" .. tostring(active.level))
        MythicPlus.ScaleExistingCreatures(player:GetMap(), active)
        return
    end

    local pending = MythicPlus.GetPendingChallenge(player, mapId)
    if not pending then
        Debug("No pending mythic challenge found for this player/group.")
        return
    end

    local ok, reason = MythicPlus.RegisterInstance(
        instanceId,
        mapId,
        pending.level,
        pending.leaderGuid
    )

    if not ok then
        Debug("RegisterInstance failed reason=" .. tostring(reason))
        return
    end

    MythicPlus.ClearPendingChallenge(pending.leaderGuid)

    active = MythicPlus.GetInstance(instanceId)
    local scaledCount = MythicPlus.ScaleExistingCreatures(player:GetMap(), active)

    BroadcastToGroup(player, string.format(
        "%s +%d ACTIVADA. Instance ID: %u. Criaturas escaladas: %u",
        dungeon.name,
        pending.level,
        instanceId,
        scaledCount
    ))
end

local function OnCreatureCreate(event, instanceData, map, creature)
    local mapId = map:GetMapId()
    local instanceId = map:GetInstanceId()

    if instanceId <= 0 then
        return
    end

    local active = MythicPlus.GetInstance(instanceId)
    if not active or active.mapId ~= mapId or active.status ~= "active" then
        return
    end

    MythicPlus.ScaleCreature(creature, active)
end

local function OnCreatureDealDamage(event, creature, target, damage, damageType)
    if not creature or not target or damage <= 0 then
        return damage
    end

    if creature:GetOwnerGUID() ~= 0 then
        return damage
    end

    local mapId = creature:GetMapId()
    local dungeon = MythicPlus.GetDungeon(mapId)

    if not dungeon or not dungeon.enabled then
        return damage
    end

    local instanceId = creature:GetInstanceId()
    if instanceId <= 0 then
        return damage
    end

    local active = MythicPlus.GetInstance(instanceId)
    if not active or active.status ~= "active" then
        return damage
    end

    local levelCfg = MythicPlus.GetLevel(active.level)
    if not levelCfg then
        return damage
    end

    local isBoss = MythicPlus.IsBoss(mapId, creature:GetEntry())
    local multiplier = isBoss and levelCfg.bossDamage or levelCfg.mobDamage
    local scaledDamage = math.floor(damage * multiplier)

    Debug(string.format(
        "Damage %s entry=%u instance=%u %u->%u x%.2f",
        isBoss and "BOSS" or "MOB",
        creature:GetEntry(),
        instanceId,
        damage,
        scaledDamage,
        multiplier
    ))

    return scaledDamage
end

MythicPlus.ReloadConfig()

RegisterCreatureGossipEvent(
    MythicPlus.Config.NpcEntry,
    GOSSIP_EVENT_ON_HELLO,
    OnMythicNpcHello
)

RegisterCreatureGossipEvent(
    MythicPlus.Config.NpcEntry,
    GOSSIP_EVENT_ON_SELECT,
    OnMythicNpcSelect
)

RegisterPlayerEvent(
    PLAYER_EVENT_ON_MAP_CHANGE,
    OnPlayerMapChange
)

for mapId, dungeon in pairs(MythicPlus.Dungeons) do
    if dungeon.enabled then
        RegisterMapEvent(
            mapId,
            INSTANCE_EVENT_ON_CREATURE_CREATE,
            OnCreatureCreate
        )
        Debug("Registered creature-create hook for map=" .. tostring(mapId))
    end
end

RegisterAllCreatureEvent(
    ALL_CREATURE_EVENT_ON_DEAL_DAMAGE,
    OnCreatureDealDamage
)

print("[MythicPlus] v0.1 loaded - existing creature scaling enabled.")
