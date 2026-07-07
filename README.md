# CJS Force Ground Attack

Build 42 Project Zomboid mod that makes the Manual Floor Attack key authoritative while held.

Behavior:

- Holding the Manual Floor Attack key forces `setAimAtFloor(true)` during player update and tick passes.
- When an attack starts while the key is held, the mod also forces the current attack vars to target the floor and disables close-kill selection.
- Armed attacks stay weapon attacks unless the Shove/Stomp input is held.
- Shove/Stomp ground attacks force shove state, mark the attack vars as bare-hands, and keep vanilla's `meleePressed` latch aligned before vanilla weapon durability checks.
- Bare-hands attacks are treated as stomp/shove so the no-weapon path still attacks the ground.
- The hook clears its forced animation variables after the key is released and the current attack is finished.

The mod uses B42.19 `AttackVars` field names, including `isBareHeadsWeapon`, and `IsoPlayer.meleePressed` with reflected boolean setters to match vanilla attack-state gates.
