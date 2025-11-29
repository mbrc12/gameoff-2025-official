local all_decorations = { "map/decorations_1", "map/decorations_2", "map/decorations_3", "map/decorations_4", "map/decorations_5", "map/decorations_6" }

---@alias DecorationFn fun(cell: Cell)
---@return DecorationFn?
return function()
    if Util.random() < 0.3 then
        return nil
    end

    local stuff = {}
    for i = 1, Util.randint(1, 3) do
        table.insert(stuff, {
            Util.choice(all_decorations),
            Util.choice({0, 90, 180, 270})
        })
    end

    return function(cell)
        local pos = Registry.map.cellCenter(cell)
        for _, deco in ipairs(stuff) do
            Draw:sprite(deco[1], pos.x, pos.y, deco[2])
        end
    end
end
