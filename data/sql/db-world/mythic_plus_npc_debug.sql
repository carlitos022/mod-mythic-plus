-- mod-mythic-plus
-- v0.1 diagnostic patch for NPC 90099.
-- Run this in the WORLD database.

UPDATE `creature_template`
SET
    `npcflag` = 1,
    `gossip_menu_id` = 0,
    `AIName` = '',
    `ScriptName` = ''
WHERE `entry` = 90099;

-- Diagnostic query: verify the fields after the UPDATE.
SELECT
    `entry`,
    `name`,
    `subname`,
    `npcflag`,
    `gossip_menu_id`,
    `AIName`,
    `ScriptName`
FROM `creature_template`
WHERE `entry` = 90099;
