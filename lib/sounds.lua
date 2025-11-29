local Sounds = {
    ---@type table<string, love.Source>
    sfxs = {},
    ---@type table<Assets.SfxGroups, string>
    last = {},
}

--- does not support pitch/loop/id
---@param group Assets.SfxGroups
function Sounds:shuffledSfx(group)
    local options = Assets.sfxGroups[group]
    if not options then
        error("No such sfx group: " .. tostring(group))
    end

    local choice = nil
    repeat
        choice = options[Util.randint(1, #options)]
    until choice ~= self.last[group] or #options == 1

    self.last[group] = choice
    self:sfx(choice)
end

---@param name Assets.Sfxs
---@param pitchRange? number
---@param loop? boolean
---@param identifier? string
---@return string id
function Sounds:sfx(name, pitchRange, loop, identifier)
    pitchRange = pitchRange or 0

    local id = identifier or tostring(Util.uniqueId())
    if self.sfxs[id] then
        return id
    end

    loop = loop or false

    local sfx = Assets.sfx(name):clone()
    sfx:setPitch(1 + Util.random()*pitchRange - pitchRange/2)
    sfx:setLooping(loop)

    self.sfxs[id] = sfx

    sfx:play()
    return id
end

---@param id string
function Sounds:stop(id)
    local sfx = self.sfxs[id]
    if sfx then
        sfx:stop()
        self.sfxs[id] = nil
    end
end

function Sounds:isOver(id)
    local sfx = self.sfxs[id]
    if sfx then
        return not sfx:isPlaying()
    end
    return true
end

---@param dt number
function Sounds:update(dt)
    Util.eraseIf(self.sfxs, function(sfx)
        return sfx:isPlaying() == false
    end)
end

_G.Sounds = Sounds
