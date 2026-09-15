-- mod-mythic-plus
-- Characters database: persistent runtime state for mythic instances.

CREATE TABLE IF NOT EXISTS `custom_mythic_pending` (
    `leader_guid` INT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `mythic_level` TINYINT UNSIGNED NOT NULL,
    `selected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`leader_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `custom_mythic_instances` (
    `instance_id` INT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `mythic_level` TINYINT UNSIGNED NOT NULL,
    `leader_guid` INT UNSIGNED NOT NULL,
    `group_guid` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `status` ENUM('created','active','completed','failed','abandoned') NOT NULL DEFAULT 'created',
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`instance_id`),
    KEY `idx_map_level` (`map_id`, `mythic_level`),
    KEY `idx_leader` (`leader_guid`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `custom_mythic_progress` (
    `guid` INT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `highest_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `best_time_ms` INT UNSIGNED DEFAULT NULL,
    `completions` INT UNSIGNED NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`guid`, `map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
