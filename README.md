# CJS Force Ground Attack

Build 42 Project Zomboid mod that makes the Manual Floor Attack key authoritative while held.

Behavior:

- Holding the Manual Floor Attack key forces `setAimAtFloor(true)` every tick.
- When an attack starts while the key is held, the mod also forces the current attack vars to target the floor and disables close-kill selection.
- Armed attacks stay weapon attacks unless the Shove/Stomp input is held.
- Shove/Stomp ground attacks force shove state before vanilla attack-var selection so stomps do not consume equipped weapon condition.
- While forcing a stomp, the mod restores any condition, head-condition, or sharpness loss applied to the primary held item by the engine.
- Bare-hands attacks are treated as stomp/shove so the no-weapon path still attacks the ground.
- The hook clears its forced animation variables after the key is released and the current attack is finished.

The mod uses B42.19 `AttackVars` field names with reflected boolean setters to avoid noisy Kahlua public-field assignment failures.
