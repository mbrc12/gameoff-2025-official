local BASE_PATH = "assets/tiled/"
local TILESET_EXT = ".tsj"
local TILEMAP_EXT = ".tmj"

local loaders = require("lib.assets.loaders")

local Tiled = {}

---get filename and extension from path
---@param path string
---@return string name without extension
---@return string extension
function extract(path)
    --- get filename without extension
    local path_ = "/" .. path
    local name, ext = path_:match(".*/(.*)%.(%w+)$")
    if not name or not ext then
        error("Invalid path: " .. path)
    end
    return name, "." .. ext
end

---@alias TilePos number[]

---@class Tile
---@field id number
---@field hitbox Geo.Shape | nil
---@field tx number
---@field ty number

---@class Tileset
---@field image love.Image
---@field tileWidth number
---@field tileHeight number
---@field tiles table<number, Tile> localID to tile

---@param name string
---@return Tileset
function Tiled.loadTileset(name)
    local fullPath = BASE_PATH .. name .. TILESET_EXT
    local data = Util.readJson(fullPath)

    local tileWidth = data.tilewidth
    local tileHeight = data.tileheight

    local widthInTiles = Util.round(data.imagewidth / tileWidth)

    ---@type table<number, Tile>
    local tiles = {}
    for _, tile in ipairs(data.tiles) do
        local hitbox
        if tile.objectgroup and #tile.objectgroup.objects > 0 then
            local obj = tile.objectgroup.objects[1]
            if obj.polygon then
                local points = {}
                for _, point in ipairs(obj.polygon) do
                    table.insert(points, Vec2.new(point.x + obj.x, point.y + obj.y))
                end
                Geo.sortCCW(points)
                hitbox = Geo.Shape.convex(points)
            else
                hitbox = Geo.Shape.rectangle(obj.width, obj.height, false):move(Vec2.new(obj.x, obj.y))
            end
        end
        tiles[tile.id] = {
            id = tile.id,
            hitbox = hitbox,
            tx = (tile.id % widthInTiles) * tileWidth,
            ty = math.floor(tile.id / widthInTiles) * tileHeight,
        }
    end

    local imageName = extract(data.image) -- ignore ext
    local image = loaders.loadTexture(imageName)

    Log("Loaded tileset:", name, "with", #tiles, "tiles")

    return {
        image = image,
        tileWidth = tileWidth,
        tileHeight = tileHeight,
        tiles = tiles,
    }
end

---@class TileLayer
---@field name string
---@field width number
---@field height number
---@field data number[] array of global tile IDs
---@field parentMap TiledMap
local TileLayer = {}

---@param data table
---@param parentMap TiledMap
---@return TileLayer
function Tiled.parseTileLayer(data, parentMap)
    local result = {
        name = data.name,
        width = data.width,
        height = data.height,
        data = data.data,
        parentMap = parentMap,
    }
    setmetatable(result, { __index = TileLayer })
    return result
end

---@class TiledObject
---@field kind "point" | "rectangle"
---@field x number
---@field y number
---@field width number
---@field height number
---@field type string
---@field properties table<string, string>
local TiledObject = {}

---@param props table
---@return table<string, string>
function Tiled.parseProps(props)
    local result = {}
    if props then
        for _, prop in ipairs(props) do
            result[prop.name] = prop.value
        end
    end
    return result
end

---@param data table
---@return TiledObject
function Tiled.parseObject(data)
    if data.point and data.point == true then
        return {
            kind = "point",
            x = data.x,
            y = data.y,
            width = 0,
            height = 0,
            type = data.type,
            properties = Tiled.parseProps(data.properties),
        }
    else
        return {
            kind = "rectangle",
            x = data.x,
            y = data.y,
            width = data.width,
            height = data.height,
            type = data.type,
            properties = Tiled.parseProps(data.properties),
        }
    end
end

---@class ObjectLayer
---@field name string
---@field objects TiledObject[]
---@field objectsByName table<string, TiledObject>
local ObjectLayer = {}

---@param nameOrId string|number
---@return TiledObject?
function ObjectLayer:object(nameOrId)
    if type(nameOrId) == "string" then
        return self.objectsByName[nameOrId]
    elseif type(nameOrId) == "number" then
        return self.objects[nameOrId]
    else
        error("Invalid object identifier: " .. tostring(nameOrId))
    end
end

---@param typeName string
---@return TiledObject[]
function ObjectLayer:objectsOfType(typeName)
    local result = {}
    for _, obj in ipairs(self.objects) do
        if obj.type == typeName then
            table.insert(result, obj)
        end
    end
    return result
end

---@param data table
---@return ObjectLayer
function Tiled.parseObjectLayer(data)
    local objects = {}
    local objectsByName = {}

    for _, obj in ipairs(data.objects) do
        local parsedObj = Tiled.parseObject(obj)
        table.insert(objects, parsedObj)
        if obj.name then
            objectsByName[obj.name] = parsedObj
        end
    end

    local ol = {
        name = data.name,
        objects = objects,
        objectsByName = objectsByName,
    }

    setmetatable(ol, { __index = ObjectLayer })

    return ol
end

---@alias TiledLayer TileLayer | ObjectLayer

---@class TiledMap
---@field gridWidth number
---@field gridHeight number
---@field tileWidth number
---@field tileHeight number
---@field tilesets table<number, Tileset> firstgid to tileset
---@field layers TiledLayer[]
---@field layersByName table<string, TiledLayer>
local TiledMap = {}

---@param nameOrId string|number
function TiledMap:layer(nameOrId)
    if type(nameOrId) == "string" then
        return self.layersByName[nameOrId]
    elseif type(nameOrId) == "number" then
        return self.layers[nameOrId]
    else
        error("Invalid layer identifier: " .. tostring(nameOrId))
    end
end

---@param name string
---@return TiledMap
function Tiled.loadTilemap(name)
    local fullPath = BASE_PATH .. name .. TILEMAP_EXT
    local data = Util.readJson(fullPath)

    local result = {
        gridHeight = data.height,
        gridWidth = data.width,
        tileWidth = data.tilewidth,
        tileHeight = data.tileheight,
    }
    setmetatable(result, { __index = TiledMap })

    local tilesets = {}
    for _, ts in ipairs(data.tilesets) do
        local tsName = extract(ts.source) -- ignore extension
        tilesets[ts.firstgid] = Tiled.loadTileset(tsName)
    end

    result.tilesets = tilesets

    local layers = {}
    for _, layer in ipairs(data.layers) do
        if layer.type == "tilelayer" then
            table.insert(layers, Tiled.parseTileLayer(layer, result))
        elseif layer.type == "objectgroup" then
            table.insert(layers, Tiled.parseObjectLayer(layer))
        else
            error("Unsupported layer type: " .. layer.type)
        end
    end

    result.layers = layers

    local layersByName = {}
    for _, layer in ipairs(layers) do
        layersByName[layer.name] = layer
    end

    result.layersByName = layersByName

    Log("Loaded tilemap:", name, "with", #layers, "layers and", #Util.keys(tilesets), "tilesets")

    return result
end

---@param gid number
---@return Tileset? tileset
---@return number? local tile id
function TiledMap:getTilesetForGid(gid)
    local lastFirstGid = nil
    for firstGid, _ in pairs(self.tilesets) do
        if gid >= firstGid then
            if not lastFirstGid or firstGid > lastFirstGid then
                lastFirstGid = firstGid
            end
        end
    end
    if lastFirstGid then
        return self.tilesets[lastFirstGid], gid - lastFirstGid
    end
    return nil
end

---@param pos TilePos
---@return { tile: Tile, tileset: Tileset, flipx: boolean, flipy: boolean, flipd: boolean, flip120: boolean } | nil
function TileLayer:tileAt(pos)
    local x, y = pos[1], pos[2]
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return nil
    end

    local index = y * self.width + x + 1
    local gid = self.data[index]

    if gid == 0 then
        return nil
    end

    local flipx = bit.band(gid, 0x80000000) ~= 0
    local flipy = bit.band(gid, 0x40000000) ~= 0
    local flipd = bit.band(gid, 0x20000000) ~= 0
    local flip120 = bit.band(gid, 0x10000000) ~= 0
    gid = bit.band(gid, 0x0FFFFFFF)

    assert(flipx == false, "flipx not supported")
    assert(flipy == false, "flipy not supported")
    assert(flipd == false, "flipd not supported")
    assert(flip120 == false, "flip120 not supported")

    local tileset, localId = self.parentMap:getTilesetForGid(gid)
    assert(tileset, "No tileset found for gid " .. gid)

    return {
        tile = tileset.tiles[localId],
        tileset = tileset,
        flipx = flipx,
        flipy = flipy,
        flipd = flipd,
        flip120 = flip120,
    }
end

return Tiled
