local Assets = {}
local loaders = require("lib.assets.loaders")
-- local tiled = require("lib.assets.tiled")

function Assets.load()

    -- for _, asset in pairs(Assets.maps) do
    --     asset.map = tiled.loadTilemap(asset.name)
    -- end

    for _, asset in pairs(Assets.textures) do
        asset.texture = loaders.loadTexture(asset.name)
    end

    for _, asset in pairs(Assets.shaders) do
        asset.shader = loaders.loadShader(asset.name)
    end

    for _, asset in pairs(Assets.sfxs) do
        asset.sfx = loaders.loadSfx(asset.name)
        asset.sfx:setVolume(asset.volume or 1.0)
    end

    for _, asset in pairs(Assets.musics) do
        asset.music = loaders.loadMusic(asset.name)
    end

    Assets.font = loaders.loadFont(Assets.fontName, SCALED_FONT_SIZE)
    love.graphics.setFont(Assets.font)
end

function Assets.getTextWidth(text)
    return Assets.font:getWidth(text) / TEXT_UPSCALE
end

---@param name Assets.Maps
---@return TiledMap
function Assets.map(name)
    local asset = Assets.maps[name]
    if asset then
        return asset.map
    else
        error("Map not found: " .. name)
    end
end

--- @param name Assets.Textures
--- @return love.Image
function Assets.texture(name)
    local asset = Assets.textures[name]
    if asset then
        return asset.texture
    else
        error("Texture not found: " .. name)
    end
end

--- @param name Assets.Shaders
--- @return love.Shader
function Assets.shader(name)
    local asset = Assets.shaders[name]
    if asset then
        return asset.shader
    else
        error("Shader not found: " .. name)
    end
end

--- @param name Assets.Sfxs
--- @return love.Source
function Assets.sfx(name)
    local asset = Assets.sfxs[name]
    if asset then
        return asset.sfx:clone() -- autoclone
    else
        error("Sfx not found: " .. name)
    end
end

---@param name Assets.Music
---@return love.Source
function Assets.music(name)
    local asset = Assets.musics[name]
    if asset then
        return asset.music -- dont clone
    else
        error("Music not found: " .. name)
    end
end

local cachedFonts = {}

---@param size integer
---@param fn fun()
function Assets.withFontSize(size, fn)
    if not cachedFonts[size] then
        cachedFonts[size] = loaders.loadFont(Assets.fontName, size)
    end
    local prevFont = love.graphics.getFont()
    local font = cachedFonts[size]
    Assets.font = font
    love.graphics.setFont(font)

    fn()

    love.graphics.setFont(prevFont)
    Assets.font = prevFont
end

_G.Assets = Assets
