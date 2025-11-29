---@return LogicDelegate?
return function ()
    local map = Registry.map

    if map.resources < ToolCosts.water then
        return nil
    end
    map.resources = map.resources - ToolCosts.water

    local WATER_TICK = 0.1

    local distL = 1
    local distR = 1

    local function allowed(cell)
        local data = map:get(cell)
        if not data then
            return false
        end
        if data.wall or data.door then
            return false
        end
        return true
    end

    local function doWater(cell)
        if not allowed(cell) then
            return false
        end
        map:reveal(cell)
        return true
    end

    Sounds:sfx("water")
    waiting = false
    waitTicks = 5

    return {
        update = Timer:every(WATER_TICK, function()
            if waiting then
                waitTicks = waitTicks - 1
                if waitTicks <= 0 then
                    return true
                end
                return false
            end

            local successL = doWater({ map.player[1] - distL, map.player[2] })
            local successR = doWater({ map.player[1] + distR, map.player[2] })
            if successL then
                distL = distL + 1
            end
            if successR then
                distR = distR + 1
            end

            if not (successL or successR) then
                waiting = true
            end

            return false
        end, nil, nil, true),

        draw = function()
            Draw:draw("main", ZINDEX.map.water, function()
                local cellL = { map.player[1] - (distL - 1), map.player[2] }
                local leftend = map.cellCenter(cellL).x - CELL_SIZE / 2

                local cellR = { map.player[1] + (distR - 1), map.player[2] }
                local rightend = map.cellCenter(cellR).x + CELL_SIZE / 2
                Ninepatch:centerToCenter(Assets.ninepatches["sea"],
                    map.playerPos.x, map.playerPos.y,
                    leftend, map.playerPos.y, CELL_SIZE)
                Ninepatch:centerToCenter(Assets.ninepatches["sea"],
                    map.playerPos.x, map.playerPos.y,
                    rightend, map.playerPos.y, CELL_SIZE)
            end)
        end
    }
end
