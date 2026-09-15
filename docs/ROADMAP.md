# Roadmap - mod-mythic-plus

## v0.1 - MVP jugable

Objetivo: demostrar el flujo completo de una instancia mitica sin modificar globalmente `creature_template`.

- [x] Modulo C++ base.
- [x] Configuracion `.conf.dist`.
- [x] Tablas SQL de niveles, mazmorras y bosses.
- [x] Tablas SQL de seleccion pendiente e instancias activas.
- [x] NPC 90099 con menu +1 a +5.
- [x] Restriccion de seleccion al lider del grupo.
- [x] Activacion al entrar al mapa 632.
- [x] Persistencia por `instanceId`.
- [x] Escalado de vida de mobs.
- [x] Escalado de vida de bosses.
- [x] Escalado de dano de mobs.
- [x] Escalado de dano de bosses.
- [ ] Pruebas reales en AzerothCore del servidor.
- [ ] Revisar comportamiento tras wipe/reset.
- [ ] Limpieza de registros antiguos.

## v0.2 - Ciclo de finalizacion

- Detectar bosses muertos.
- Detectar mazmorra completada.
- Cambiar estado a `completed`.
- Recompensas configurables.
- Historial de completadas.
- Prevencion de recompensa duplicada.

## v0.3 - Tiempo y progreso

- Temporizador por mazmorra.
- Tiempo limite configurable.
- Mejor tiempo por personaje.
- Mayor nivel completado.
- Estadisticas por mazmorra.
- Ranking opcional.

## v0.4 - Afijos

- Framework de afijos desacoplado del core.
- Afijos configurables por nivel.
- Rotaciones.
- Fortificado.
- Tiranico.
- Volcanico.
- Sanguinario.
- Enfurecido.

## v0.5 - Llaves miticas

- Item llave.
- Nivel almacenado en DB.
- Mazmorra asociada.
- Subida/bajada de nivel segun resultado.
- Proteccion contra duplicacion.

## v1.0

- Multiples mazmorras WotLK.
- Panel de administracion por comandos/NPC.
- Configuracion sin recompilar.
- Recompensas completas.
- Afijos.
- Timer.
- Ranking.
- Documentacion de instalacion.
- Migraciones SQL estables.
