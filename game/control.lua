local water = require("game.water")
local rat = require("game.rat")
local defuse = require("game.defuse")
local teleport = require("game.teleport")
local dialog = require("game.dialog")

---@param dt number
return function(dt)
    local map = Registry.map

    if Input:isJustPressed("HIDE") then
        Registry.ui:toggle()
    end

    if Registry.player:isMoving() then
        --- not the same as the previous frame and not empty input
        if Input:holding() or Input:nothing() then
            return
        end
    end

    local cellData = map:get(map.player)

    if Input:isJustPressed("TELEPORT") then
        if cellData.teleport then
            map:pause(teleport(cellData.teleport))
            return
        end
    end

    if Input:isJustPressed("INTERACT") then
        if map.tool == nil then
            return
        end

        if map.tool == "water" then
            map:pause(water())
        elseif map.tool == "rat" then
            map:pause(rat())
        elseif map.tool == "defuser" then
            map:pause(defuse())
        end
        return
    end

    if Input:isJustPressed("SWITCH") then
        if #map.allowedTools <= 1 then
            return
        end

        local index = 0
        for i, tool in ipairs(map.allowedTools) do
            if tool == map.tool then
                index = i
            end
        end
        index = index % #map.allowedTools + 1
        map.tool = map.allowedTools[index]
        Sounds:sfx("switch")
    end

    local dir = Input:direction()

    if not Util.aeq(dir.x, 0) and not Util.aeq(dir.y, 0) then
        dir.x = 0
    end

    if Util.aeq(dir.x, 0) and Util.aeq(dir.y, 0) then
        return
    end

    local new = { map.player[1] + dir.x, map.player[2] + dir.y }
    local newCellData = map:get(new)

    local noaudio = false

    if not newCellData then
        return
    elseif newCellData.bomb and newCellData.revealed then
        return
    elseif newCellData.wall then
        --- perhaps thud for wall
        return
    elseif newCellData.door then
        if not Registry.player.keys[newCellData.door] then
            map:pause(dialog({"Need the key of " .. newCellData.door .. "."}))
            return
        else
            Sounds:sfx("door_open")
            noaudio = true
            map:pause(dialog({"Used the key of " .. newCellData.door .. "."}))

            newCellData.door = nil
        end
    end

    Registry.player:moveTo(new, nil, noaudio)
end
