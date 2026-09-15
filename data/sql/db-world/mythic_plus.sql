-- mod-mythic-plus
-- World database: static configuration for mythic instances.

CREATE TABLE IF NOT EXISTS `custom_mythic_levels` (
    `level` TINYINT UNSIGNED NOT NULL,
    `mob_health_multiplier` DECIMAL(8,3) UNSIGNED NOT NULL DEFAULT 1.000,
    `mob_damage_multiplier` DECIMAL(8,3) UNSIGNED NOT NULL DEFAULT 1.000,
    `boss_health_multiplier` DECIMAL(8,3) UNSIGNED NOT NULL DEFAULT 1.000,
    `boss_damage_multiplier` DECIMAL(8,3) UNSIGNED NOT NULL DEFAULT 1.000,
    `reward_multiplier` DECIMAL(8,3) UNSIGNED NOT NULL DEFAULT 1.000,
    PRIMARY KEY (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

REPLACE INTO `custom_mythic_levels`
(`level`, `mob_health_multiplier`, `mob_damage_multiplier`, `boss_health_multiplier`, `boss_damage_multiplier`, `reward_multiplier`)
VALUES
(1, 1.250, 1.100, 1.350, 1.150, 1.000),
(2, 1.500, 1.200, 1.750, 1.300, 1.250),
(3, 2.000, 1.400, 2.250, 1.500, 1.500),
(4, 2.750, 1.650, 3.000, 1.750, 2.000),
(5, 3.750, 2.000, 4.250, 2.100, 3.000);

CREATE TABLE IF NOT EXISTS `custom_mythic_dungeons` (
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `min_level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `max_level` TINYINT UNSIGNED NOT NULL DEFAULT 5,
    PRIMARY KEY (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pilot dungeon: The Forge of Souls / Forja de Almas.
REPLACE INTO `custom_mythic_dungeons`
(`map_id`, `name`, `enabled`, `min_level`, `max_level`)
VALUES
(632, 'Forja de Almas', 1, 1, 5);

CREATE TABLE IF NOT EXISTS `custom_mythic_bosses` (
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `creature_entry` MEDIUMINT UNSIGNED NOT NULL,
    `boss_order` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`map_id`, `creature_entry`),
    KEY `idx_creature_entry` (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Forge of Souls bosses. Entries are kept configurable in SQL so the Lua/C++
-- layer never needs hard-coded boss lists.
REPLACE INTO `custom_mythic_bosses`
(`map_id`, `creature_entry`, `boss_order`)
VALUES
(632, 36497, 1),
(632, 36502, 2);
