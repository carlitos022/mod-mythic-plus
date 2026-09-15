/*
 * mod-mythic-plus
 * Progressive Mythic Instances for AzerothCore 3.3.5a
 */

#include "ConfigValueCache.h"
#include "ScriptMgr.h"

namespace MythicPlus
{
enum class Config
{
    ENABLED,
    MAX_LEVEL,
    NPC_ENTRY,
    DEBUG,

    NUM_CONFIGS
};

class ConfigData : public ConfigValueCache<Config>
{
public:
    ConfigData() : ConfigValueCache(Config::NUM_CONFIGS) { }

    void BuildConfigCache() override
    {
        SetConfigValue<bool>(Config::ENABLED, "MythicPlus.Enable", true);
        SetConfigValue<uint32>(Config::MAX_LEVEL, "MythicPlus.MaxLevel", 5);
        SetConfigValue<uint32>(Config::NPC_ENTRY, "MythicPlus.NpcEntry", 90099);
        SetConfigValue<bool>(Config::DEBUG, "MythicPlus.Debug", false);
    }
};

static ConfigData sConfig;

class MythicPlusWorldScript : public WorldScript
{
public:
    MythicPlusWorldScript()
        : WorldScript("MythicPlusWorldScript", { WORLDHOOK_ON_BEFORE_CONFIG_LOAD })
    {
    }

    void OnBeforeConfigLoad(bool reload) override
    {
        sConfig.Initialize(reload);
    }
};
} // namespace MythicPlus

void AddMythicPlusScripts()
{
    new MythicPlus::MythicPlusWorldScript();
}
