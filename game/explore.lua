local DIRECTIONS = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

---@param cell Cell
---@return LogicDelegate?
return function(cell)
    local map = Registry.map

    if map:adjacentBombs(cell) > 0 or map:get(cell).explored then
        return nil
    end

    local EXPLORE_TICK = 0.1
    local check = { cell }
    local next = { cell }

    local considered = { [Util.cellToNum(cell)] = true }

    return {
        update = Timer:every(EXPLORE_TICK, function()
            check = next
            next = {}
            for i = 1, #check do
                local c = check[i]
                local cellData = map:get(c)
                cellData.explored = true
                cellData.revealed = true
                if map:adjacentBombs(c) == 0 then
                    for _, dir in ipairs(DIRECTIONS) do
                        local adjacent = { c[1] + dir[1], c[2] + dir[2] }
                        local adjCell = map:get(adjacent)
                        if adjCell and not adjCell.explored and not adjCell.wall and not adjCell.door then
                            if not considered[Util.cellToNum(adjacent)] then
                                considered[Util.cellToNum(adjacent)] = true
                                table.insert(next, adjacent)
                            end
                        end
                    end
                    -- map:iterateAdjacent(c, function(adjacent)
                    --     local adjCell = map:get(adjacent)
                    --     if not adjCell.explored and not adjCell.wall and not adjCell.door then
                    --         if not considered[Util.cellToNum(adjacent)] then
                    --             considered[Util.cellToNum(adjacent)] = true
                    --             table.insert(next, adjacent)
                    --         end
                    --     end
                    -- end)
                end
            end -- for i

            if #next == 0 then
                return true
            end
            return false
        end, nil, nil, true),
    }
end
