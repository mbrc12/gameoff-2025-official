local RAT_TICK = 0.3
local WAIT_TIME = 0.2

return function()
    local map = Registry.map

    if map.resources < ToolCosts.rat then
        return nil
    end

    local ratSprite = "rat_1"
    local started = false

    local cell = { map.player[1], map.player[2] }
    local current = { cell[1], cell[2] }
    local oldCell = { current[1], current[2] }
    local visited = { [Util.cellToNum(current)] = true }
    local dir = { -1, 0 }
    local ratPos = map.cellCenter(current)
    local firstMove = true
    local moving = false -- is the rat currently moving between cells

    local function forbidden(cell)
        local cellData = map:get(cell)
        return (not cellData) or
                cellData.wall or
                cellData.door or
                cellData.bomb
    end

    local stepUpdate = function()
        map:reveal(current)
        if forbidden(current) then
            return true
        end

        if moving then
            return false
        end

        local options = {
            --right turn
            { -dir[2], dir[1] },
            --straight
            { dir[1], dir[2] },
        }

        if firstMove then
            table.remove(options, 1)
            firstMove = false
        end

        local success = false
        for i = 1, 2 do
            local newDir = options[i]
            local newCell = { current[1] + newDir[1], current[2] + newDir[2] }
            if not visited[Util.cellToNum(newCell)] then
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

        if not map:exists(current) then
            return true
        end

        -- map:get(current).item = nil
        local cellData = map:get(current)
        if (not cellData) or cellData.wall or cellData.door then
            Sounds:sfx("thud")
            return true
        end

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

    -- choices are "up", "down"
    local choice = "up"
    local sfx

    local function chooseUpdate()
        if Input:isJustPressed("UP") then
            choice = "up"
            return false
        elseif Input:isJustPressed("DOWN") then
            choice = "down"
            return false
        elseif Input:isJustPressed("BACK") then
            return true -- finish
        elseif Input:isJustPressed("INTERACT") then
            started = true
            if choice == "up" then
                dir = { 0, -1 }
            else
                dir = { 0, 1 }
            end
            map.resources = map.resources - ToolCosts.rat

            Sounds:sfx("rat_spawn")
            sfx = Sounds:sfx("rat_move", nil, true)

            return false
        end
    end

    local waiting = false
    local elapsed = 0

    return {
        update = function(self, dt)
            if waiting then
                if elapsed >= WAIT_TIME then
                    return true
                else
                    elapsed = elapsed + dt
                    return
                end
            end
            if not started then
                return chooseUpdate()
            end
            spriteToggle(dt)
            local stop = stepUpdate()
            if stop then
                waiting = true
            end
        end,
        draw = function()
            Draw:draw("main", ZINDEX.map.water, function()
                if not started then
                    local rot = (choice == "up") and 0 or 180
                    Draw:sprite("ui/select_arrow", ratPos.x, ratPos.y, rot)
                    return
                end
                local rota = Util.degAtan2(dir[2], dir[1]) + 90
                Draw:sprite(ratSprite, ratPos.x, ratPos.y, rota)
            end)
        end,
        onComplete = function()
            if sfx then
                Sounds:stop(sfx)
            end
        end
    }
end
