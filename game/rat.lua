local RAT_TICK = 0.3

return function()
    local map = Registry.map

    if map.resources < ToolCosts.rat then
        return nil
    end
    map.resources = map.resources - ToolCosts.rat

    local cell = { map.player[1], map.player[2] }
    local current = { cell[1], cell[2] }
    local oldCell = { current[1], current[2] }
    local visited = { [Util.cellToNum(current)] = true }
    local dir = { -1, 0 }
    local ratPos = map.cellCenter(current)
    local ratSprite = "rat_1"
    Sounds:sfx("rat_spawn")
    local sfx = Sounds:sfx("rat_move", nil, true)
    local moving = false

    local stepUpdate = function()
        if not map:exists(current) then
            return true
        end

        if moving then
            return false
        end
        map:reveal(current)
        if map:isBomb(current) then
            return true
        end
        local options = {
            --right turn
            { -dir[2], dir[1] },
            --straight
            { dir[1], dir[2] },
        }
        local success = false
        for i = 1, 2 do
            local newDir = options[i]
            local newCell = { current[1] + newDir[1], current[2] + newDir[2] }
            local cellData = map:get(newCell)
            local forbid = (not cellData) or
                    cellData.wall or
                    cellData.door
            if not forbid and not visited[Util.cellToNum(newCell)] then
                dir = newDir
                oldCell = { current[1], current[2] }
                current = newCell
                visited[Util.cellToNum(current)] = true
                success = true
                break
            end
        end
        if not success then
            return true
        end

        map:get(current).item = nil

        moving = true
        Tweens:new({
            duration = RAT_TICK,
            ease = "Linear",
            step = function(t)
                ratPos = map.cellCenter(oldCell):lerp(map.cellCenter(current), t)
            end,
            onComplete = function()
                moving = false
            end,
        })
        return false
    end

    local spriteToggle = Timer:every(RAT_TICK / 2, function()
        if ratSprite == "rat_1" then
            ratSprite = "rat_2"
        else
            ratSprite = "rat_1"
        end
    end)


    return {
        update = function(self, dt)
            spriteToggle(dt)
            return stepUpdate()
        end,
        draw = function()
            Draw:draw("main", ZINDEX.map.water, function()
                local rota = Util.degAtan2(dir[2], dir[1]) + 90
                Draw:sprite(ratSprite, ratPos.x, ratPos.y, rota)
            end)
        end,
        onComplete = function()
            Sounds:stop(sfx)
        end
    }
end
