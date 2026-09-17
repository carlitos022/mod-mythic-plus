# Pruebas reales v0.1

## Estado validado

- NPC 90099 carga correctamente.
- Gossip +1 a +5 funciona.
- La seleccion crea `custom_mythic_pending`.
- Al entrar en mapa 632 se registra el `instance_id` real.
- `custom_mythic_instances` queda con estado `active`.

## Correccion de escalado

Los mobs de una instancia pueden estar creados antes de que el evento de cambio de mapa registre el reto como mitico. Por eso v0.1 ahora hace dos cosas:

1. `Map:GetCreatures()` al activar la instancia para escalar todas las criaturas ya cargadas.
2. `INSTANCE_EVENT_ON_CREATURE_CREATE` para criaturas que aparezcan despues.

## Prueba recomendada

Probar un solo nivel por instancia.

1. Salir de la instancia.
2. Resetear la instancia de WoW antes de cambiar de nivel mitico.
3. Seleccionar un nivel en NPC 90099.
4. Entrar a Forja de Almas.
5. Confirmar en consola:
   - `MAP_CHANGE ... map=632 instance=X`
   - `Registered instance X map 632 at mythic +N`
   - `Existing creature pass instance=X total=... scaled=... level=+N`
   - lineas `Scaled MOB ... HP=base->nuevo xMULTIPLICADOR`
6. Confirmar la fila en `custom_mythic_instances`.
7. Comparar HP del mismo `creature_entry` en diferentes instancias nuevas.

## Ejemplo de referencia

Para un mob con 75,600 HP base:

- +1 x1.25 = 94,500 HP
- +2 x1.50 = 113,400 HP
- +3 x2.00 = 151,200 HP
- +4 x2.75 = 207,900 HP
- +5 x3.75 = 283,500 HP

No se debe cambiar de +1 a +5 reutilizando el mismo `instance_id`: una instancia activa conserva el nivel con el que fue creada.
