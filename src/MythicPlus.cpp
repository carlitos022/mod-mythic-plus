/*
 * mod-mythic-plus
 * Progressive Mythic Instances for AzerothCore 3.3.5a
 */

#include "Config.h"
#include "ScriptMgr.h"

namespace MythicPlus
{
static bool sEnable = true;
static uint32 sMaxLevel = 5;
static uint32 sNpcEntry = 90099;
static bool sDebug = false;

inline void LoadConfig(bool reload = false)
{
    sEnable = sConfigMgr->GetOption<bool>("MythicPlus.Enable", true);
    sMaxLevel = sConfigMgr->GetOption<uint32>("MythicPlus.MaxLevel", 5);
    sNpcEntry = sConfigMgr->GetOption<uint32>("MythicPlus.NpcEntry", 90099);
    sDebug = sConfigMgr->GetOption<bool>("MythicPlus.Debug", false);
}

class MythicPlusWorldScript : public WorldScript
{
public:
    MythicPlusWorldScript()
        : WorldScript("MythicPlusWorldScript", { WORLDHOOK_ON_BEFORE_CONFIG_LOAD })
    {
    }

    void OnBeforeConfigLoad(bool reload) override
    {
        LoadConfig(reload);
    }
};
} // namespace MythicPlus

void AddMythicPlusScripts()
{
    new MythicPlus::MythicPlusWorldScript();
}
