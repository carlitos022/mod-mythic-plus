-- mod-mythic-plus
-- v0.1 stable scaling override validated on the test server.
-- Loaded after mythic_plus.lua.

if not MythicPlus then
    print("[MythicPlus][SCALING] ERROR: MythicPlus table not loaded.")
    return
end

local function Log(message)
    if MythicPlus.Config and MythicPlus.Config.Debug then
        print("[MythicPlus][SCALING] " .. tostring(message))
    end
end

MythicPlus.ScaleCreature = function(creature, active)
    if not creature or not active then
        return false
    end

    local instanceId = tonumber(active.instanceId) or tonumber(creature:GetInstanceId()) or 0
    local mapId = tonumber(creature:GetMapId()) or 0

    if instanceId <= 0 or mapId ~= tonumber(active.mapId) then
        return false
    end

    -- Ignore controlled/summoned creatures. GetOwner() is reliable on this ALE build.
    local owner = creature:GetOwner()
    if owner then
        return false
    end

    MythicPlus.ScaledCreatures = MythicPlus.ScaledCreatures or {}
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

    if not originalMaxHealth or originalMaxHealth <= 0 then
        return false
    end

    local scaledHealth = math.floor(originalMaxHealth * multiplier)

    creature:SetMaxHealth(scaledHealth)
    creature:SetHealth(scaledHealth)

    MythicPlus.ScaledCreatures[instanceId][guidLow] = true

    Log(string.format(
        "Scaled %s entry=%u guid=%u instance=%u level=+%u HP=%u->%u x%.2f",
        isBoss and "BOSS" or "MOB",
        creature:GetEntry(),
        guidLow,
        instanceId,
        active.level,
        originalMaxHealth,
        scaledHealth,
        multiplier
    ))

    return true
end

print("[MythicPlus][SCALING] v0.1 stable scaling override loaded.")
