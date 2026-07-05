local MOD_ID = "cjsForceGroundAttack"
local MANUAL_FLOOR_KEY = "ManualFloorAtk"
local SHOVE_STOMP_KEY = "Melee"

local warned = {}
local forcedPlayers = setmetatable({}, { __mode = "k" })

local function warnOnce(key, message)
    if warned[key] then return end
    warned[key] = true
    print("[" .. MOD_ID .. "] " .. message)
end

local function safeCall(key, fn)
    local ok, result = pcall(fn)
    if ok then return result end

    warnOnce(key, key .. " failed: " .. tostring(result))
    return nil
end

local function isKeyDown(keyName)
    if not GameKeyboard or not GameKeyboard.isKeyDown then return false end

    return safeCall("isKeyDown." .. keyName, function()
        return GameKeyboard.isKeyDown(keyName)
    end) == true
end

local function setPlayerVariable(player, name, value)
    safeCall("setVariable." .. name, function()
        player:setVariable(name, value)
    end)
end

local function setAimAtFloor(player, value)
    safeCall("setAimAtFloor", function()
        player:setAimAtFloor(value)
    end)
end

local function setDoShove(player, value)
    safeCall("setDoShove", function()
        player:setDoShove(value)
    end)
end

local function setAttackVars(attackVars, doShove)
    if not attackVars then return end

    local ok, result = pcall(function()
        attackVars.aimAtFloor = true
        attackVars.closeKill = false
        attackVars.doShove = doShove
    end)
    if ok then return end

    warnOnce("setAttackVars", "Could not set public AttackVars fields: " .. tostring(result))
end

local function getUseHandWeapon(player)
    if not player then return nil end

    return safeCall("getUseHandWeapon", function()
        return player:getUseHandWeapon()
    end)
end

local function isBareHands(weapon)
    if not weapon then return false end

    return safeCall("isBareHands", function()
        return weapon:isBareHands()
    end) == true
end

local function shouldDoGroundShove(player)
    if isKeyDown(SHOVE_STOMP_KEY) then return true end

    return isBareHands(getUseHandWeapon(player))
end

local function isPerformingAttack(player)
    if not player then return false end

    local performingAttack = safeCall("isPerformingAttackAnimation", function()
        return player:isPerformingAttackAnimation()
    end)
    if performingAttack == true then return true end

    return safeCall("isAttackStarted", function()
        return player:isAttackStarted()
    end) == true
end

local function applyAttackVars(player, doShove)
    if not player then return end

    local attackVars = safeCall("getAttackVars", function()
        return player:getAttackVars()
    end)
    if not attackVars then return end

    setAttackVars(attackVars, doShove)
end

local function forceGroundAttack(player, includeAttackVars)
    if not player then return end

    if not isKeyDown(MANUAL_FLOOR_KEY) then
        if forcedPlayers[player] and not isPerformingAttack(player) then
            setAimAtFloor(player, false)
            setPlayerVariable(player, "AimFloorAnim", false)
            setPlayerVariable(player, "isStompAnim", false)
            forcedPlayers[player] = nil
        end
        return
    end

    local doShove = shouldDoGroundShove(player)
    setAimAtFloor(player, true)
    setDoShove(player, doShove)
    setPlayerVariable(player, "AimFloorAnim", true)
    setPlayerVariable(player, "isStompAnim", doShove)

    if includeAttackVars then
        applyAttackVars(player, doShove)
    end

    forcedPlayers[player] = true
end

local function forEachActivePlayer(callback)
    if not getSpecificPlayer then return end

    if not getNumActivePlayers then
        callback(getSpecificPlayer(0))
        return
    end

    for playerIndex = 0, getNumActivePlayers() - 1 do
        callback(getSpecificPlayer(playerIndex))
    end
end

local function onTick()
    forEachActivePlayer(function(player)
        forceGroundAttack(player, true)
    end)
end

local function onCreatePlayer(_playerIndex, player)
    forceGroundAttack(player, false)
end

local function onWeaponSwing(player, _weapon)
    forceGroundAttack(player, true)
end

if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end

if Events and Events.OnTick then
    Events.OnTick.Add(onTick)
else
    warnOnce("missingOnTick", "Events.OnTick is not available")
end

if Events and Events.OnWeaponSwing then
    Events.OnWeaponSwing.Add(onWeaponSwing)
else
    warnOnce("missingOnWeaponSwing", "Events.OnWeaponSwing is not available")
end
