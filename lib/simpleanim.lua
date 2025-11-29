local SimpleAnim = {
    ---@type table<number, AnimationInstance>
    animations = {},
}

---@class AnimationSpec
---@field texture Assets.Textures
---@field frameTime number time per frame in seconds
---@field tx number
---@field ty number
---@field frameWidth? number
---@field frameHeight? number
---@field frameIndices? number[] list of frame indices to use
---@field center? boolean whether to center the texture
---@field frames number total number of frames
---@field duration number total duration in seconds

function SimpleAnim:init()
    for _, spec in pairs(Assets.animations) do
        ---@cast spec AnimationSpec
        local texture = Assets.texture(spec.texture)
        spec.tx = spec.tx or 0
        spec.ty = spec.ty or 0
        spec.center = spec.center or true
        if not spec.frameHeight then
            spec.frameHeight = texture:getHeight()
        end
        if not spec.frameWidth then
            spec.frameWidth = spec.frameHeight
        end
        if not spec.frameIndices then
            spec.frames = spec.frames or math.floor(texture:getWidth() / spec.frameWidth + 0.5)
            spec.duration = spec.frames * spec.frameTime
            -- print("Animation '" .. spec.texture .. "' has " .. spec.frames .. " frames with duration " .. spec.duration)
        else
            spec.frames = #spec.frameIndices
            spec.duration = spec.frames * spec.frameTime
        end
    end
end

---@param name Assets.Animations
---@param loop? boolean whether to loop the animation
---@return number
function SimpleAnim:new(name, loop)
    -- to use the z at the time of calling this animation, we get the z from draw and store it
    -- this is restored in the update loop

    local id = Util.uniqueId()
    local spec = Assets.animations[name]
    ---@class AnimationInstance
    local instance = {
        spec = spec,
        r = 0,
        center = spec.center,
        elapsed = 0,
        lastTick = -1,
        duration = spec.duration,
        loop = loop or false,
        frame = 1,
    }

    self.animations[id] = instance

    return id
end

---@param id number
function SimpleAnim:reset(id)
    local anim = self.animations[id]
    assert(anim, "No animation with id " .. tostring(id))
    if anim then
        anim.elapsed = 0
        anim.frame = 1
        anim.lastTick = love.timer.getTime()
    end
end

---@param id number
function SimpleAnim:isComplete(id)
    return (not self.animations[id])
end

---@param id number
function SimpleAnim:remove(id)
    self.animations[id] = nil
end

---@param id number
---@param pos Vec2
---@param r? number rotation in degrees
---@param tint? number[]
---@return boolean completed
function SimpleAnim:draw(id, pos, r, tint)
    r = r or 0
    local anim = self.animations[id]
    if not anim then
        return true
    end
    if anim.lastTick < 0 then -- first frame
        anim.lastTick = love.timer.getTime()
    end
    anim.elapsed = anim.elapsed + (love.timer.getTime() - anim.lastTick)
    anim.lastTick = love.timer.getTime()

    if anim.elapsed >= anim.duration then
        if anim.loop then
            anim.elapsed = anim.elapsed - anim.duration
        else
            self.animations[id] = nil
            return true
        end
    end

    local frame = math.min(math.floor(anim.elapsed / anim.spec.frameTime) + 1, anim.spec.frames)
    if anim.spec.frameIndices then
        frame = anim.spec.frameIndices[frame]
    end

    if tint then
        love.graphics.setColor(tint[1], tint[2], tint[3])
    end
    Draw:simple(
        anim.spec.texture,
        pos.x, pos.y,
        r,
        false,
        anim.center,
        anim.spec.tx + (frame - 1) * anim.spec.frameWidth, anim.spec.ty,
        anim.spec.frameWidth, anim.spec.frameHeight
    )
    if tint then
        love.graphics.setColor(Colors.White)
    end
    return false
end

_G.SimpleAnim = SimpleAnim
