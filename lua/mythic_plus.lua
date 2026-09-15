-- mod-mythic-plus
-- Shared ALE / Eluna layer.
-- v0.1 foundation: configuration cache and persistent instance helpers.

MythicPlus = MythicPlus or {}

MythicPlus.Config = {
    NpcEntry = 90099,
    MinLevel = 1,
    MaxLevel = 5,
    PilotMapId = 632,
    Debug = false
}

MythicPlus.Levels = MythicPlus.Levels or {}
MythicPlus.Dungeons = MythicPlus.Dungeons or {}
MythicPlus.Bosses = MythicPlus.Bosses or {}

local function Debug(message)
    if MythicPlus.Config.Debug then
        print("[MythicPlus] " .. tostring(message))
    end
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
    local dungeon = MythicPlus.GetDungeon(mapId)
    local levelConfig = MythicPlus.GetLevel(level)

    if not dungeon or not dungeon.enabled or not levelConfig then
        return false
    end

    return level >= dungeon.minLevel and level <= dungeon.maxLevel
end

function MythicPlus.GetInstance(instanceId)
    local id = tonumber(instanceId)
    if not id or id <= 0 then
        return nil
    end

    local query = CharDBQuery(string.format([[
        SELECT instance_id, map_id, mythic_level, leader_guid, group_guid, status
        FROM custom_mythic_instances
        WHERE instance_id = %u
        LIMIT 1
    ]], id))

    if not query then
        return nil
    end

    return {
        instanceId = query:GetUInt32(0),
        mapId = query:GetUInt32(1),
        level = query:GetUInt8(2),
        leaderGuid = query:GetUInt32(3),
        groupGuid = query:GetUInt32(4),
        status = query:GetString(5)
    }
end

function MythicPlus.RegisterInstance(instanceId, mapId, level, leaderGuid, groupGuid)
    instanceId = tonumber(instanceId)
    mapId = tonumber(mapId)
    level = tonumber(level)
    leaderGuid = tonumber(leaderGuid)
    groupGuid = tonumber(groupGuid) or 0

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
        (instance_id, map_id, mythic_level, leader_guid, group_guid, status, created_at)
        VALUES (%u, %u, %u, %u, %u, 'created', CURRENT_TIMESTAMP)
    ]], instanceId, mapId, level, leaderGuid, groupGuid))

    Debug(string.format(
        "Registered instance %u map %u at mythic +%u.",
        instanceId,
        mapId,
        level
    ))

    return true
end

-- Initial cache load. ALE/Eluna loads scripts after database connections exist.
MythicPlus.ReloadConfig()
