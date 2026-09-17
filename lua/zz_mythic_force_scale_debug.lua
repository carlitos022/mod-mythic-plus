-- mod-mythic-plus
-- v0.1 temporary forced scaling diagnostic.
-- Purpose: verify SetMaxHealth on already-loaded creatures in the active mythic instance.

local PLAYER_EVENT_ON_MAP_CHANGE = 28
local PILOT_MAP_ID = 632

local function Log(message)
    print("[MythicPlus][FORCE] " .. tostring(message))
end

local function ScaleNow(eventId, delay, calls, player)
    if not player or player:GetMapId() ~= PILOT_MAP_ID then
        return
    end

    local instanceId = player:GetInstanceId()
    if not instanceId or instanceId <= 0 then
        Log("No valid instance id.")
        return
    end

    local query = CharDBQuery(string.format([[
        SELECT mythic_level, status
        FROM custom_mythic_instances
        WHERE instance_id = %u AND map_id = %u
        LIMIT 1
    ]], instanceId, PILOT_MAP_ID))

    if not query then
        Log("No mythic DB row yet for instance=" .. tostring(instanceId))
        return
    end

    local level = query:GetUInt8(0)
    local status = query:GetString(1)

    if status ~= "active" then
        Log("Instance is not active. instance=" .. tostring(instanceId) .. " status=" .. tostring(status))
        return
    end

    local levelQuery = WorldDBQuery(string.format([[
        SELECT mob_health_multiplier, boss_health_multiplier
        FROM custom_mythic_levels
        WHERE level = %u
        LIMIT 1
    ]], level))

    if not levelQuery then
        Log("Missing level config for +" .. tostring(level))
        return
    end

    local mobMultiplier = levelQuery:GetFloat(0)
    local bossMultiplier = levelQuery:GetFloat(1)
    local map = player:GetMap()
    local creatures = map and map:GetCreatures() or nil

    if not creatures then
        Log("Map:GetCreatures returned nil.")
        return
    end

    local total = 0
    local scaled = 0
    local samples = 0

    for _, creature in pairs(creatures) do
        total = total + 1

        if creature and creature:GetMapId() == PILOT_MAP_ID then
            local oldHp = creature:GetMaxHealth()

            if oldHp and oldHp > 0 then
                local isBoss = false
                if MythicPlus and MythicPlus.IsBoss then
                    isBoss = MythicPlus.IsBoss(PILOT_MAP_ID, creature:GetEntry())
                end

                local multiplier = isBoss and bossMultiplier or mobMultiplier
                local newHp = math.floor(oldHp * multiplier)

                creature:SetMaxHealth(newHp)
                creature:SetHealth(newHp)
                scaled = scaled + 1

                if samples < 8 then
                    Log(string.format(
                        "SCALED entry=%u guid=%u boss=%s HP=%u->%u x%.2f",
                        creature:GetEntry(),
                        creature:GetGUIDLow(),
                        tostring(isBoss),
                        oldHp,
                        newHp,
                        multiplier
                    ))
                    samples = samples + 1
                end
            end
        end
    end

    Log(string.format(
        "PASS COMPLETE instance=%u level=+%u total=%u scaled=%u",
        instanceId,
        level,
        total,
        scaled
    ))
end

local function OnMapChange(event, player)
    if player:GetMapId() ~= PILOT_MAP_ID then
        return
    end

    Log("MAP_CHANGE seen. Scheduling forced scale in 1000 ms. instance=" .. tostring(player:GetInstanceId()))
    player:RegisterEvent(ScaleNow, 1000, 1)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_MAP_CHANGE, OnMapChange)
Log("Forced scaling diagnostic loaded.")
