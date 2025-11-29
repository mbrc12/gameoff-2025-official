local Music = {
    ---@type VolumeLevels
    volume = "medium",
    ---@type love.Source
    menu = nil,
    ---@type love.Source
    theme = nil,
    ---@type love.Source
    win = nil,
    ---@type love.Source
    current = nil,
}

function Music:init()
    self.menu = Assets.music("menu")
    self.theme = Assets.music("theme")
    self.win = Assets.music("win")
    self.ambience = Assets.music("ambience")
    self.ambience:setVolume(0.7)

    self.menu:setLooping(true)
    self.theme:setLooping(true)
    self.win:setLooping(true)
    self.ambience:setLooping(true)

    self.volume = "medium"
    self:setVolume(self.volume)

    self.ambience:play()
end

---@enum (key) VolumeLevels
local volumes = {
    low = 0.2,
    medium = 0.5,
    high = 1.0,
}

function Music:playMenu()
    if self.current and self.current:isPlaying() then
        self.current:stop()
    end
    if self.menu and not self.menu:isPlaying() then
        self.menu:seek(0)
        self.menu:play()
    end
    self.current = self.menu
end

function Music:playTheme()
    if self.current and self.current:isPlaying() then
        self.current:stop()
    end
    if self.theme and not self.theme:isPlaying() then
        self.theme:seek(0)
        self.theme:play()
    end
    self.current = self.theme
end

function Music:playWin()
    if self.current and self.current:isPlaying() then
        self.current:stop()
    end
    if self.win and not self.win:isPlaying() then
        self.win:seek(0)
        self.win:play()
    end
    self.current = self.win
end

---@param volume string
function Music:setVolume(volume)
    self.volume = volume
    if self.theme then
        self.theme:setVolume(volumes[volume])
    end
    if self.menu then
        self.menu:setVolume(volumes[volume])
    end
    if self.win then
        self.win:setVolume(volumes[volume])
    end
end

function Music:pause()
    if self.current and self.current:isPlaying() then
        self.current:pause()
    end
end

function Music:resume()
    if self.current and not self.current:isPlaying() then
        self.current:play()
    end
end

_G.Music = Music
