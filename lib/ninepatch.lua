local Ninepatch = {}

---@class NinePatchConfig
---@field asset Assets.Textures
---@field tiledX? boolean
---@field tiledY? boolean
---@field texture? { x : number, y : number, w : number, h : number }
---@field padding { left : number, right : number, top : number, bottom : number }

---@param cfg NinePatchConfig | Assets.Ninepatches
---@param x number anchor x top-left
---@param y number anchor y top-left
---@param w number
---@param h number
---@param r? number rotation in degrees

function Ninepatch:draw(cfg, x, y, w, h, r)
    if type(cfg) == "string" then
        cfg = Assets.ninepatches[cfg]
    end

    r = r or 0
    r = math.rad(r)

    local img = Assets.texture(cfg.asset)
    local iw, ih = img:getDimensions()

    if not cfg.texture then
        cfg.texture = { x = 0, y = 0, w = iw, h = ih }
    end

    local tw, th = cfg.texture.w, cfg.texture.h
    local tx, ty = cfg.texture.x, cfg.texture.y
    local pl, pr = cfg.padding.left, cfg.padding.right
    local pt, pb = cfg.padding.top, cfg.padding.bottom

    local scalex = w / tw
    local scaley = h / th

    Draw:withShader("ninepatch", {
        pl = pl,
        pr = pr,
        pt = pt,
        pb = pb,
        portionSize = { tw, th },
        portionPos = { tx, ty },
        scale = { scalex, scaley },
        texSize = { iw, ih },
        tiledX = cfg.tiledX and 1 or 0,
        tiledY = cfg.tiledY and 1 or 0,
    }, function()
        local quad = love.graphics.newQuad(tx, ty, tw, th, iw, ih)
        love.graphics.draw(img, quad, x, y, r, scalex, scaley)
    end)
end

function Ninepatch:_draw(cfg, x, y, w, h, r)
    if type(cfg) == "string" then
        cfg = Assets.ninepatches[cfg]
    end

    r = r or 0
    r = math.rad(r)

    local img = Assets.texture(cfg.asset)
    local iw, ih = img:getDimensions()

    if not cfg.texture then
        cfg.texture = { x = 0, y = 0, w = iw, h = ih }
    end

    local tw, th = cfg.texture.w, cfg.texture.h
    local tx, ty = cfg.texture.x, cfg.texture.y
    local pl, pr = cfg.padding.left, cfg.padding.right
    local pt, pb = cfg.padding.top, cfg.padding.bottom

    local scaleX = (w - pl - pr) / (tw - pl - pr)
    local scaleY = (h - pt - pb) / (th - pt - pb)

    -- Top Left
    local quad_tl = love.graphics.newQuad(tx, ty, pl, pt, iw, ih)
    love.graphics.draw(img, quad_tl, x, y, r)
    -- Top Middle
    local quad_tm = love.graphics.newQuad(tx + pl, ty, tw - pl - pr, pt, iw, ih)
    love.graphics.draw(img, quad_tm, x + pl * math.cos(r), y + pl * math.sin(r), r, scaleX, 1)
    -- Top Right
    local quad_tr = love.graphics.newQuad(tx + tw - pr, ty, pr, pt, iw, ih)
    love.graphics.draw(img, quad_tr, x + w * math.cos(r) - pr * math.cos(r), y + w * math.sin(r) - pr * math.sin(r), r)
    -- Middle Left
    local quad_ml = love.graphics.newQuad(tx, ty + pt, pl, th - pt - pb, iw, ih)
    love.graphics.draw(img, quad_ml, x - pt * math.sin(r), y + pt * math.cos(r), r, 1, scaleY)
    -- Middle Middle
    local quad_mm = love.graphics.newQuad(tx + pl, ty + pt, tw - pl - pr, th - pt - pb, iw, ih)
    love.graphics.draw(img, quad_mm, x + pl * math.cos(r) - pt * math.sin(r), y + pl * math.sin(r) + pt * math.cos(r), r,
        scaleX, scaleY)
    -- Middle Right
    local quad_mr = love.graphics.newQuad(tx + tw - pr, ty + pt, pr, th - pt - pb, iw, ih)
    love.graphics.draw(img, quad_mr, x + (w - pr) * math.cos(r), y + (w - pr) * math.sin(r) + pt * math.cos(r), r, 1,
        scaleY)
    -- Bottom Left
    local quad_bl = love.graphics.newQuad(tx, ty + th - pb, pl, pb, iw, ih)
    love.graphics.draw(img, quad_bl, x, y + (h - pb) * math.cos(r) + (w - pr) * math.sin(r), r, 1)
    -- Bottom Middle
    local quad_bm = love.graphics.newQuad(tx + pl, ty + th - pb, tw - pl - pr, pb, iw, ih)
    love.graphics.draw(img, quad_bm, x + pl * math.cos(r), y + (h - pb) * math.cos(r) + (w - pr) * math.sin(r), r, scaleX,
        1)
    -- Bottom Right
    local quad_br = love.graphics.newQuad(tx + tw - pr, ty + th - pb, pr, pb, iw, ih)
    love.graphics.draw(img, quad_br, x + w * math.cos(r) - pr * math.cos(r),
        y + (h - pb) * math.cos(r) + (w - pr) * math.sin(r), r, 1)
end

---@param cfg NinePatchConfig
---@param x1 number center x1
---@param y1 number center y1
---@param x2 number center x2
---@param y2 number center y2
---@param height number height of the ninepatch
function Ninepatch:centerToCenter(cfg, x1, y1, x2, y2, height)
    local rot = math.atan2(y2 - y1, x2 - x1)
    local width = math.sqrt((y2 - y1) ^ 2 + (x2 - x1) ^ 2)
    self:draw(cfg, x1 + height / 2 * math.sin(rot), y1 - height / 2 * math.cos(rot), width, height, math.deg(rot))
    -- love.graphics.line(x1 + height/2 * math.sin(rot), y1 - height/2 * math.cos(rot), x2 + height/2 * math.sin(rot), y2 - height/2 * math.cos(rot))
    -- love.graphics.line(x1 - height/2 * math.sin(rot), y1 + height/2 * math.cos(rot), x2 - height/2 * math.sin(rot), y2 + height/2 * math.cos(rot))
end

_G.Ninepatch = Ninepatch
