local Anim = {
    ---@type table<number, AnimationInstance>
    animations = {},
}

function Anim:init()
    for _, spec in pairs(Assets.animations) do
        local texture = Assets.texture(spec.texture)
        if not spec.frameIndices then
            spec.frames = math.floor(texture:getWidth() / spec.frameWidth + 0.5)
            spec.duration = spec.frames * spec.frameTime
        else
            spec.frames = #spec.frameIndices
            spec.duration = spec.frames * spec.frameTime
        end
    end
end

---@param name Assets.Animations
---@param pos Vec2
---@param zindex number
---@param center? boolean whether to center the animation on (x, y)
---@param onComplete? fun()
---@return number
function Anim:play(name, pos, zindex, center, onComplete)
    -- to use the z at the time of calling this animation, we get the z from draw and store it
    -- this is restored in the update loop
    center = center or true
    onComplete = onComplete or function() end

    local id = Util.uniqueId()
    local spec = Assets.animations[name]
    ---@class AnimationInstance
    local instance = {
        spec = spec,
        pos = pos,
        r = 0,
        z = zindex,
        center = center,
        onComplete = onComplete,
        elapsed = 0,
        duration = spec.duration,
        loop = spec.loop,
        frame = 1,
        paused = false,
    }

    self.animations[id] = instance

    return id
end

---@param id number
---@param pos Vec2
function Anim:moveTo(id, pos)
    local anim = self.animations[id]
    assert(anim, "No animation with id " .. tostring(id))
    if anim then
        anim.pos = pos
    end
end

---@param id number
---@param r number
function Anim:setRotation(id, r)
    local anim = self.animations[id]
    assert(anim, "No animation with id " .. tostring(id))
    if anim then
        anim.r = r
    end
end

---@param id number
function Anim:reset(id)
    local anim = self.animations[id]
    assert(anim, "No animation with id " .. tostring(id))
    if anim then
        anim.elapsed = 0
        anim.frame = 1
    end
end

---@param id number
function Anim:pause(id)
    local anim = self.animations[id]
    anim.paused = true
end

---@param id number
function Anim:resume(id)
    local anim = self.animations[id]
    anim.paused = false
end

---@param id number
function Anim:stop(id)
    self.animations[id] = nil
end

function Anim:draw()
    for _, anim in pairs(self.animations) do
        Draw:draw("main", anim.z, function()
            Draw:simple(
                anim.spec.texture,
                anim.pos.x, anim.pos.y,
                anim.r,
                false,
                anim.center,
                (anim.frame - 1) * anim.spec.frameWidth, 0,
                anim.spec.frameWidth, anim.spec.frameHeight
            )
        end)
    end
end

function Anim:update(dt)
    local toDelete = {}

    Util.pairs(self.animations, function(id, anim)
        if anim.paused then
            return
        end

        anim.elapsed = anim.elapsed + dt
        if anim.elapsed >= anim.duration then
            anim.onComplete()
            if anim.loop then
                anim.elapsed = anim.elapsed - anim.duration
            else
                table.insert(toDelete, id)
            end
        end

        anim.frame = math.min(math.floor(anim.elapsed / anim.spec.frameTime) + 1, anim.spec.frames)
        if anim.spec.frameIndices then
            anim.frame = anim.spec.frameIndices[anim.frame]
        end
    end)

    for _, id in pairs(toDelete) do
        self:stop(id)
    end
end

_G.Anim = Anim
