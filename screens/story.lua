local GAP = (VIEW_HEIGHT - 128) / 2
local PIC_X = 64 + GAP
local PIC_Y = 64 + GAP
local TEXT_X = 128 + GAP + 10
local TEXT_Y = GAP - 4

---@class StoryScreen : Screen
local StoryScreen = {
    current = 1,
    canProceed = false,
    ---@type Dialog?
    dialog = nil,
    ---@type number
    anim = nil
}

local dialog_lines = {
    "It was a bit windy that day. Lost in my thoughts, I had perhaps strolled a bit too far on the beach.",

    "Suddenly alerted by their roar, I noticed that the waves were growing ever so erratic and violent.",
    "It was not wise to stay there longer.",

    "I decided to turn around and quickly head towards the hills in the distance. I remember it had become rather dark.",

    "However, my journey was soon impeded in its first steps. The ground shook powerfully, challenging my balance.",
    "A thunderous rumble asserted that I was in the immense presence of a structure colossal.",

    "As my sight adjusted to the new reality, I found the developments quite difficult to accept.",

    [[Columns of nondescript buildings, spaced with an eerie regularity, stood before me.
Their brutal geometry was only punctuated by a few vines wrapping around.]],
    "A large entrance was my only path forward.",

    "The light was faint inside, for its only source was the moonlight seeping in through the doors in all four directions.",
    "The floor, carefully tiled, appeared to move and readjust under the slightest pressure.",

    "Outside, the consecutive buildings and spaces in between felt like a maze. But I couldn't shake an ominous feeling, beyond the mere strangeness of it all.",
}

local images = {
    "1",

    "2",
    "2",

    "3",

    "3_5",
    "3_5",

    "",

    "4",
    "4",

    "5",
    "5",

    "6",
}

function StoryScreen:enter()
    Music:playTheme()
    self.current = 1
    self.canProceed = false
    assert(#dialog_lines == #images, "dialog_lines and images must have the same length")
end

function StoryScreen:leave()
end

function StoryScreen:update(dt)
    if love.keyboard.isDown("f6") then
        switchScreen(Fader.new(HomeScreen))
        return
    end

    if not self.dialog then
        local text = dialog_lines[self.current]
        text = text:gsub("\n", " ")
        self.dialog = Dialog.new(VIEW_WIDTH - GAP - TEXT_X, text, false)
        self.anim = SimpleAnim:new("story/wait", true)
    end
    local stat = self.dialog:update(dt)
    if stat then
        self.canProceed = true
    end

    if Input:isJustPressed("BACK") then
        if self.current == 1 then
            switchScreen(Fader.new(HomeScreen))
            return
        end
        self.current = math.max(self.current - 1, 1)
        self.dialog = nil
        self.canProceed = false
    end

    if self.canProceed and Input:isJustPressed("INTERACT") then
    -- if Input:isJustPressed("INTERACT") then
        self.current = self.current + 1

        self.dialog = nil
        self.canProceed = false

        Sounds:sfx("dialog_next")

        if self.current > #dialog_lines then
            switchScreen(Fader.new(HomeScreen))
        end
    end
end

function StoryScreen:draw()
    local panel = images[self.current]
    local frame = "story" .. panel

    Draw:draw("ui", ZINDEX.ui.story, function()
        love.graphics.setColor({ 0.8, 0.8, 0.8, 1 }) -- darken to offset glow
        if panel ~= "" then
            Draw:simple(frame, PIC_X, PIC_Y, 0, false, true)
            Draw:simple("story_frame", PIC_X, PIC_Y, 0, false, true)
        end

        if self.dialog then
            self.dialog:draw(TEXT_X, TEXT_Y)
        end
        if self.canProceed and self.anim then
            SimpleAnim:draw(self.anim, Vec2.new(VIEW_WIDTH - GAP - 8, VIEW_HEIGHT - GAP - 8))
        end
        love.graphics.setColor(Colors.SteamLords.slate_violet)
        Draw:centeredText("F6 to skip", VIEW_WIDTH/2, VIEW_HEIGHT - 14)
        love.graphics.setColor(Colors.White)
    end)
end

_G.StoryScreen = StoryScreen
