# mod-mythic-plus

Sistema de instancias miticas progresivas para AzerothCore 3.3.5a con soporte para C++, ALE/Eluna Lua y MySQL.

## Objetivo

Permitir que un grupo seleccione una dificultad mitica de +1 a +5 mediante un NPC. La dificultad queda asociada a la instancia y modifica progresivamente vida y dano de criaturas y bosses sin alterar globalmente `creature_template`.

## Estado

**v0.1 - Fundamentos**

Incluye:

- estructura de modulo compatible con AzerothCore;
- archivo de configuracion propio;
- tablas SQL para niveles, mazmorras, bosses e instancias activas;
- niveles +1 a +5 configurables desde MySQL;
- mapa piloto 632 (The Forge of Souls / Forja de Almas);
- base Lua para consultar configuracion y preparar NPC/escalado;
- loader C++ y carga de configuracion.

Todavia pendiente en v0.1:

- NPC funcional para seleccionar +1 a +5;
- asociacion definitiva de `instanceId` con el nivel elegido;
- escalado de vida al crear criaturas;
- modificacion de dano;
- deteccion de bosses;
- finalizacion de instancia.

## Arquitectura

```text
AzerothCore
  |
  +-- mod-mythic-plus (C++)
  |     +-- configuracion
  |     +-- hooks de core
  |
  +-- ALE / Eluna
  |     +-- NPC
  |     +-- mecanicas configurables
  |
  +-- MySQL
        +-- configuracion de niveles
        +-- mapas habilitados
        +-- bosses
        +-- instancias activas
        +-- progreso (futuro)
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
|-- data/sql/db-world/base/
|   `-- mythic_plus.sql
`-- docs/
    `-- ROADMAP.md
```

## Instalacion de desarrollo

Clonar dentro de la carpeta `modules` de AzerothCore:

```bash
cd /ruta/azerothcore/modules
git clone https://github.com/carlitos022/mod-mythic-plus.git
```

Luego recompilar AzerothCore con modulos habilitados.

El SQL de desarrollo inicial se encuentra en:

```text
data/sql/db-world/base/mythic_plus.sql
```

El script Lua se copiara temporalmente a la carpeta de scripts ALE/Eluna durante las pruebas hasta que definamos el mecanismo final de despliegue.

## Versiones previstas

- **v0.1:** seleccion +1 a +5, instancia piloto y escalado basico.
- **v0.2:** bosses, finalizacion y recompensas.
- **v0.3:** temporizador y progreso por jugador/grupo.
- **v0.4:** afijos.
- **v1.0:** multiples mazmorras, administracion y sistema completo.

## Licencia

Proyecto en desarrollo para AzerothCore. La licencia definitiva se definira antes de la primera version estable.
