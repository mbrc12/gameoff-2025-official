local SPEED = 30
local SFX_INTERVAL = 3

---@class Dialog
local Dialog = {
    width = VIEW_WIDTH - 40,
    line = "",
    elapsed = 0,
    partial = 0,
    done = false,
    sfx = true,
}
Dialog.__index = Dialog

---@param width? number
---@param line? string
---@param sfx? boolean
---@return Dialog
function Dialog.new(width, line, sfx)
    local o = {}
    setmetatable(o, Dialog)
    o.done = false
    o.width = width or Dialog.width
    o.line = line or ""
    o.elapsed = 0
    o.partial = 0
    o.sfx = true
    if sfx ~= nil then
        o.sfx = sfx
    end
    return o
end

---@param dt number
---@return boolean?
function Dialog:update(dt)
    if self.done then
        return true
    end
    self.elapsed = self.elapsed + dt
    local playedSfx = false
    while self.elapsed > 1 / SPEED do
        self.elapsed = self.elapsed - 1 / SPEED
        if self.partial < #self.line then
            self.partial = self.partial + 1
            if self.sfx and not playedSfx and self.partial % SFX_INTERVAL == 0 then
                Sounds:shuffledSfx("typing")
                playedSfx = true
            end
        else
            self.done = true
            return true
        end
    end
end

---@param x number
---@param y number
function Dialog:draw(x, y)
    TextRender:print(self.line, x, y, self.width, "below", self.partial)
end

_G.Dialog = Dialog
