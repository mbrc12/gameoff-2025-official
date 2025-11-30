---@return LogicDelegate?
return function()
    local map = Registry.map

    if not (map.resources >= ToolCosts.defuser) then
        return nil
    end

    local cell = map.player

    local function checkAllowed(dx, dy)
        local new = { cell[1] + dx, cell[2] + dy }
        if not map:exists(new) then
            return nil
        elseif map:get(new).revealed and (not map:get(new).bomb) then
            return nil
        elseif map:get(new).wall then
            return nil
        end

        return new
    end

    local rot = {
        left = -90,
        right = 90,
        up = 0,
        down = 180,
    }

    local allowed = {
        left = checkAllowed(-1, 0),
        right = checkAllowed(1, 0),
        up = checkAllowed(0, -1),
        down = checkAllowed(0, 1),
    }

    -- Log(allowed)

    if Util.all(allowed, function(v) return not v end) then -- nothing allowed to defuse
        return nil
    end

    local current = "left"
    local defusing = false
    local sfx = nil
    local targetCell

    local function update(self, dt)
        if defusing then
            if Sounds:isOver(sfx) then
                map:get(targetCell).bomb = false
                if map.resources < RESOURCE_MAX then
                    map.resources = map.resources + 1
                    Registry.ui:schedulePickupResource(targetCell)
                end
                return true
            end
            return
        end

        if Input:isJustPressed("BACK") then -- cancel
            return true
        end

        if Input:isJustPressed("INTERACT") then -- confirm
            if allowed[current] then
                targetCell = allowed[current] --[[@as Cell]]
                map:get(targetCell).revealed = true

                map.resources = map.resources - ToolCosts.defuser

                if not map:get(targetCell).bomb then
                    return true
                end

                sfx = Sounds:sfx("defuse")
                defusing = true
                return
            end
        end

        local next = current

        if Input:isJustPressed("LEFT") then
            next = "left"
        elseif Input:isJustPressed("RIGHT") then
            next = "right"
        elseif Input:isJustPressed("UP") then
            next = "up"
        elseif Input:isJustPressed("DOWN") then
            next = "down"
        end

        if next ~= current then
            current = next
            Sounds:shuffledSfx("menu_move")
        end
    end

    local pos = map.cellCenter(cell)

    local function draw(self)
        Draw:draw("main", ZINDEX.map.water, function()
            ---@type Assets.Sprites
            local sprite = allowed[current] and "ui/select_arrow" or "ui/defuse_select_cross"
            local rotation = rot[current]
            Draw:sprite(sprite, pos.x, pos.y, rotation)
        end)
    end

    return {
        update = update,
        draw = draw
    }
end
