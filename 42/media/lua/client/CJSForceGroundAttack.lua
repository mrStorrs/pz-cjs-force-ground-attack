local MOD_ID = "cjsForceGroundAttack"
local MANUAL_FLOOR_KEY = "ManualFloorAtk"
local SHOVE_STOMP_KEY = "Melee"

local warned = {}
local forcedPlayers = setmetatable({}, { __mode = "k" })
local attackVarFields = {}

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

local function isBoundKeyDown(keyName)
    if not GameKeyboard or not GameKeyboard.isKeyDown then return false end

    return safeCall("isKeyDown." .. keyName, function()
        return GameKeyboard.isKeyDown(keyName)
    end) == true
end

local function normalizeButtonDown(value)
    if value == nil then return nil end

    return value == true
end

local function isManualFloorAttackDown(player)
    if not player then return false end

    local buttonDown = normalizeButtonDown(safeCall("isManualFloorAtkButtonDown", function()
        return player:isManualFloorAtkButtonDown()
    end))
    if buttonDown ~= nil then return buttonDown end

    return isBoundKeyDown(MANUAL_FLOOR_KEY)
end

local function isShoveStompButtonDown(player)
    if not player then return false end

    local buttonDown = normalizeButtonDown(safeCall("isMeleeButtonDown", function()
        return player:isMeleeButtonDown()
    end))
    if buttonDown ~= nil then return buttonDown end

    return isBoundKeyDown(SHOVE_STOMP_KEY)
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

local function findAttackVarField(attackVars, fieldName)
    if attackVarFields[fieldName] ~= nil then
        return attackVarFields[fieldName] or nil
    end

    if not getNumClassFields or not getClassField then
        warnOnce("missingReflection", "Reflection helpers are not available; AttackVars fields cannot be forced")
        attackVarFields[fieldName] = false
        return nil
    end

    local fieldCount = safeCall("getNumClassFields.AttackVars", function()
        return getNumClassFields(attackVars)
    end)
    if not fieldCount then
        attackVarFields[fieldName] = false
        return nil
    end

    for index = 0, fieldCount - 1 do
        local field = safeCall("getClassField.AttackVars." .. tostring(index), function()
            return getClassField(attackVars, index)
        end)
        if field and tostring(field):match("%." .. fieldName .. "$") then
            attackVarFields[fieldName] = field
            return field
        end
    end

    warnOnce("missingAttackVarField." .. fieldName, "AttackVars." .. fieldName .. " field was not found")
    attackVarFields[fieldName] = false
    return nil
end

local function readAttackVarBoolean(attackVars, fieldName)
    if not getClassFieldVal then return nil end

    local field = findAttackVarField(attackVars, fieldName)
    if not field then return nil end

    return safeCall("getClassFieldVal.AttackVars." .. fieldName, function()
        return getClassFieldVal(attackVars, field)
    end) == true
end

local function setAttackVarBoolean(attackVars, fieldName, value)
    if not attackVars then return end

    if readAttackVarBoolean(attackVars, fieldName) == value then
        return true
    end

    local field = findAttackVarField(attackVars, fieldName)
    if not field then return false end

    local ok = pcall(function()
        field:setBoolean(attackVars, value)
    end)
    if ok and readAttackVarBoolean(attackVars, fieldName) == value then
        return true
    end

    warnOnce("setAttackVars." .. fieldName, "Could not set AttackVars." .. fieldName)
    return false
end

local function setAttackVarWeaponForShove(player, attackVars, doShove)
    if not doShove then return end

    local weapon = safeCall("getAttackingWeapon.groundShove", function()
        return player:getAttackingWeapon()
    end)
    if not weapon then return end

    safeCall("setAttackVars.weapon.groundShove", function()
        attackVars:setWeapon(weapon)
    end)
end

local function setAttackVars(player, attackVars, doShove)
    if not attackVars then return end

    setAttackVarBoolean(attackVars, "aimAtFloor", true)
    setAttackVarBoolean(attackVars, "closeKill", false)
    setAttackVarBoolean(attackVars, "doShove", doShove)
    setAttackVarWeaponForShove(player, attackVars, doShove)
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
    if isShoveStompButtonDown(player) then return true end

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

    setAttackVars(player, attackVars, doShove)
end

local function forceGroundAttack(player, includeAttackVars)
    if not player then return end

    if not isManualFloorAttackDown(player) then
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
