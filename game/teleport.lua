---@param cell2 Cell
---@return LogicDelegate
return function(cell2)
    local map = Registry.map

    local cell = map.player
    local phase = 0  -- 0: teleport out, 1: tween, 2: teleport in

    map.cursorState = "disabled"

    local sfx = Sounds:sfx("teleport")
    local anim = SimpleAnim:new("teleport_out", false)   -- step 0

    local phase1started = false

    return {
        update = function()
            if phase == 0 then
                if SimpleAnim:isComplete(anim) then
                    if not map:exists(cell2) then -- if teleport target got destroyed
                        Sounds:stop(sfx)
                        Sounds:sfx("damage")
                        return true
                    end
                    phase = phase + 1
                end
            end

            if phase == 1 and not phase1started then -- step 1
                phase1started = true
                Registry.player:moveTo(cell2, nil, true) -- no audio
                Events:subscribeOnce("player_tween_complete", function()
                    cell = cell2
                    phase = phase + 1
                    anim = SimpleAnim:new("teleport_in")
                end)
            end

            if phase == 2 then
                if SimpleAnim:isComplete(anim) then
                    return true
                end
            end
        end,

        draw = function()
            Draw:draw("main", ZINDEX.map.water, function()
                -- if phase == 0 or phase == 2 then
                    local pos = map.cellCenter(cell)
                    SimpleAnim:draw(anim, pos)
                -- end
            end)
        end,

        onComplete = function()
            map.cursorState = "default"
        end
    }
end
