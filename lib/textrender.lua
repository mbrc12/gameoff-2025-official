local TextRender = {}

local splittable = {
    [" "] = true,
    ["."] = true,
    [","] = true,
    [";"] = true,
    [":"] = true,
    ["!"] = true,
    ["?"] = true,
    ["-"] = true,
}

---@param font love.Font
---@param text string
---@param maxWidth number
---@return number index -1 if cannot split, INFINITY if whole text fits
local function splitFirst(font, text, maxWidth)
    if font:getWidth(text) <= maxWidth then
        return INFINITY
    end

    local splitIndices = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        if splittable[char] then
            table.insert(splitIndices, i)
        end
    end

    if #splitIndices == 0 then
        return -1
    end

    if font:getWidth(text:sub(1, splitIndices[1])) > maxWidth then
        return -1
    end

    local l = 1
    local r = #splitIndices
    local steps = 0
    while l < r do
        steps = steps + 1
        if steps > 100 then
            error("Infinite loop in splitFirst")
        end
        local m = math.floor((l + r + 1) / 2)
        local substr = text:sub(1, splitIndices[m])
        local w = font:getWidth(substr)
        if w <= maxWidth then
            l = m
        else
            r = m - 1
        end
    end
    return splitIndices[l]
end

---@table <string, string[]>
local memoizedWraps = {}

---@param text string
---@param maxWidth number
---@return string[]? lines nil if cannot wrap (maxWidth too low)
function TextRender:wrap(text, maxWidth)
    local font = love.graphics.getFont()
    local str_with_font_size_and_width = text .. "%%" .. tostring(font:getHeight()) .. "%%" .. tostring(maxWidth)

    if memoizedWraps[str_with_font_size_and_width] then
        return memoizedWraps[str_with_font_size_and_width]
    end

    local current = text
    local result = {}
    while true do
        local idx = splitFirst(font, current, maxWidth)
        if idx == INFINITY then
            table.insert(result, current)
            break
        end
        if idx == -1 then
            return nil
        end
        local line = current:sub(1, idx)
        while line:sub(-1) == " " do
            line = line:sub(1, -2)
        end
        while line:sub(1, 1) == " " do
            line = line:sub(2)
        end
        table.insert(result, line)
        current = current:sub(idx + 1)
    end

    memoizedWraps[str_with_font_size_and_width] = result
    return result
end

---@enum (key) TextRenderMode
local TextRenderMode = {
    below = "below",
    above = "above",
}

---@param text string
---@param x number
---@param y number
---@param maxWidth number
---@param mode? TextRenderMode
---@param partial? number
function TextRender:print(text, x, y, maxWidth, mode, partial)
    mode = mode or "below"
    partial = partial or #text

    local wrap = self:wrap(text, maxWidth)
    if not wrap then
        error("Cannot wrap text: " .. text)
    end
    local height = love.graphics.getFont():getHeight()
    if mode == "above" then
        y = y - height * #wrap
    end

    local shown = 0
    for _, line in ipairs(wrap) do

        local lineCopy = line
        if shown + #line > partial then
            lineCopy = line:sub(1, partial - shown)
        end

        love.graphics.print(lineCopy, x, y)

        y = y + height

        shown = shown + #lineCopy
        if shown >= partial then
            break
        end
    end
end

_G.TextRender = TextRender
