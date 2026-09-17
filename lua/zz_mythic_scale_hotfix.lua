-- mod-mythic-plus
-- v0.1 temporary scaling hotfix
-- Loads after mythic_plus.lua and replaces ScaleCreature diagnostics.

if not MythicPlus then
    print("[MythicPlus][HOTFIX] ERROR: MythicPlus table not loaded.")
    return
end

local function HotfixDebug(message)
    print("[MythicPlus][HOTFIX] " .. tostring(message))
end

MythicPlus.ScaleCreature = function(creature, active)
    if not creature then
        HotfixDebug("REJECT reason=nil_creature")
        return false
    end

    if not active then
        HotfixDebug("REJECT entry=" .. tostring(creature:GetEntry()) .. " reason=nil_active")
        return false
    end

    local instanceId = tonumber(active.instanceId) or tonumber(creature:GetInstanceId()) or 0
    local mapId = tonumber(creature:GetMapId()) or 0

    if instanceId <= 0 then
        HotfixDebug("REJECT entry=" .. tostring(creature:GetEntry()) .. " reason=invalid_instance")
        return false
    end

    if mapId ~= tonumber(active.mapId) then
        HotfixDebug(string.format(
            "REJECT entry=%u reason=map_mismatch creatureMap=%u activeMap=%s",
            creature:GetEntry(),
            mapId,
            tostring(active.mapId)
        ))
        return false
    end

    -- GetOwner() returns a Unit when the creature is actually owned/summoned.
    -- This is safer than comparing GetOwnerGUID() against numeric 0 because
    -- some ALE builds may return nil for units without an owner.
    local owner = creature:GetOwner()
    if owner then
        HotfixDebug("REJECT entry=" .. tostring(creature:GetEntry()) .. " reason=has_owner")
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
        HotfixDebug("REJECT entry=" .. tostring(creature:GetEntry()) .. " reason=no_level_cfg level=" .. tostring(active.level))
        return false
    end

    local isBoss = MythicPlus.IsBoss(mapId, creature:GetEntry())
    local multiplier = isBoss and levelCfg.bossHealth or levelCfg.mobHealth
    local originalMaxHealth = creature:GetMaxHealth()

    if not originalMaxHealth or originalMaxHealth <= 0 then
        HotfixDebug("REJECT entry=" .. tostring(creature:GetEntry()) .. " reason=invalid_health")
        return false
    end

    local scaledHealth = math.floor(originalMaxHealth * multiplier)

    creature:SetMaxHealth(scaledHealth)
    creature:SetHealth(scaledHealth)

    MythicPlus.ScaledCreatures[instanceId][guidLow] = true

    HotfixDebug(string.format(
        "SCALED %s entry=%u guid=%u instance=%u level=+%u HP=%u->%u x%.2f",
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

HotfixDebug("ScaleCreature override loaded. Owner filtering now uses GetOwner().")
