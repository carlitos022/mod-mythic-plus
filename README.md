# mod-mythic-plus

Sistema de instancias miticas progresivas para AzerothCore 3.3.5a con soporte para C++, ALE/Eluna Lua y MySQL.

## Objetivo

Permitir que un grupo seleccione una dificultad mitica de +1 a +5 mediante un NPC. La dificultad queda asociada al `instanceId` real de la mazmorra y modifica progresivamente vida y dano de criaturas y bosses sin alterar globalmente `creature_template`.

## Estado

**v0.1 - MVP jugable**

Actualmente incluye:

- estructura de modulo compatible con AzerothCore;
- archivo de configuracion propio;
- loader C++ y carga de configuracion;
- NPC configurable, por defecto entry `90099`;
- menu +1, +2, +3, +4 y +5;
- seleccion permitida al lider del grupo o a un jugador sin grupo para pruebas;
- seleccion pendiente persistida en `characters`;
- activacion automatica al entrar a la mazmorra;
- asociacion `instanceId + mapId + mythicLevel`;
- escalado de vida al crear criaturas;
- multiplicador distinto para mobs y bosses;
- escalado de dano saliente de criaturas;
- configuracion de multiplicadores desde MySQL;
- mapa piloto `632` - Forja de Almas;
- bosses configurables desde SQL.

Pendiente para cerrar v0.1 tras pruebas reales:

- validar compilacion contra tu revision exacta de AzerothCore;
- validar carga del `.conf.dist`;
- probar NPC 90099 dentro del servidor;
- confirmar escalado de todos los tipos de dano de bosses;
- comprobar comportamiento al resetear/abandonar una instancia;
- limpiar automaticamente instancias antiguas.

## Flujo actual

```text
NPC 90099
   |
   +-- Forja de Almas +1
   +-- Forja de Almas +2
   +-- Forja de Almas +3
   +-- Forja de Almas +4
   `-- Forja de Almas +5
            |
            v
 custom_mythic_pending
            |
      jugador entra
      al mapa 632
            |
            v
 PLAYER_EVENT_ON_MAP_CHANGE
            |
            v
 instanceId real
            |
            v
 custom_mythic_instances
            |
      +-----+------+
      |            |
      v            v
  vida mobs     dano mobs
  vida bosses   dano bosses
```

## Estructura

```text
mod-mythic-plus/
|-- conf/
|   `-- mod_mythic_plus.conf.dist
|-- src/
|   |-- mod_mythic_plus_loader.cpp
|   `-- MythicPlus.cpp
|-- lua/
|   `-- mythic_plus.lua
|-- data/sql/
|   |-- db-world/
|   |   `-- mythic_plus.sql
|   `-- db-characters/
|       `-- mythic_plus.sql
`-- docs/
    `-- ROADMAP.md
```

## Instalacion de desarrollo

Clonar dentro de `modules`:

```bash
cd /ruta/azerothcore/modules
git clone https://github.com/carlitos022/mod-mythic-plus.git
```

Despues vuelve a ejecutar CMake y recompila AzerothCore con tus modulos habilitados.

### SQL

Ejecuta en la base `world`:

```text
data/sql/db-world/mythic_plus.sql
```

Ejecuta en la base `acore_characters`:

```text
data/sql/db-characters/mythic_plus.sql
```

### ALE / Lua

Para la fase de pruebas copia:

```text
lua/mythic_plus.lua
```

a la carpeta de scripts de ALE, normalmente:

```text
lua_scripts/
```

Luego reinicia el `worldserver` o recarga ALE segun tu entorno.

## Configuracion inicial

```ini
MythicPlus.Enable = 1
MythicPlus.MaxLevel = 5
MythicPlus.NpcEntry = 90099
MythicPlus.Debug = 0
```

Los multiplicadores no estan hardcodeados en el sistema de juego: se leen desde `custom_mythic_levels`.

## Niveles por defecto

| Nivel | Vida mobs | Dano mobs | Vida bosses | Dano bosses |
|---|---:|---:|---:|---:|
| +1 | x1.25 | x1.10 | x1.35 | x1.15 |
| +2 | x1.50 | x1.20 | x1.75 | x1.30 |
| +3 | x2.00 | x1.40 | x2.25 | x1.50 |
| +4 | x2.75 | x1.65 | x3.00 | x1.75 |
| +5 | x3.75 | x2.00 | x4.25 | x2.10 |

## Roadmap

- **v0.1:** seleccion +1 a +5, instancia piloto y escalado basico.
- **v0.2:** finalizacion, recompensas y limpieza de estado.
- **v0.3:** temporizador y progreso por jugador/grupo.
- **v0.4:** afijos.
- **v1.0:** multiples mazmorras, administracion y sistema completo.

## Nota de desarrollo

La v0.1 esta pensada para pruebas controladas. Antes de instalarla en el reino principal debemos probar compilacion, SQL, NPC, entrada a instancia, vida y dano en tu servidor de pruebas.
