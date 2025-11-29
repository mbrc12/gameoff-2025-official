---@enum (key) Assets.Maps
Assets.maps = {
    -- ["map"] = { name = "map-1" },
    -- ["map-2"] = { name = "map-2" },
}

---@enum (key) Assets.Textures
Assets.textures = {
    ss = { name = "ss" },
    snow = { name = "snow" },
    title = { name = "maintext" },

    story1 = { name = "story/1" },
    story2 = { name = "story/2" },
    story3 = { name = "story/3" },
    story3_5 = { name = "story/3_5" },
    story4 = { name = "story/4" },
    story5 = { name = "story/5" },
    story6 = { name = "story/6" },
    story_frame = { name = "story/frame" },
}

local function scaled(cfg)
    cfg.tw = cfg.tw or 1
    cfg.th = cfg.th or 1
    cfg.tx = cfg.tx * CELL_SIZE
    cfg.ty = cfg.ty * CELL_SIZE
    cfg.tw = cfg.tw * CELL_SIZE
    cfg.th = cfg.th * CELL_SIZE
    return cfg
end

---@enum (key) Assets.Sprites
Assets.sprites = {
    ["title"] = { asset = "title", center = true },

    ["map/bomb"] = scaled({ asset = "ss", tx = 1, ty = 0 }),
    ["map/hidden"] = scaled({ asset = "ss", tx = 0, ty = 0 }),
    ["map/wall"] = scaled({ asset = "ss", tx = 0, ty = 2 }),
    ["map/key"] = scaled({ asset = "ss", tx = 2, ty = 1 }),
    ["map/door"] = scaled({ asset = "ss", tx = 2, ty = 2}),
    ["map/unexplored"] = scaled({ asset = "ss", tx = 1, ty = 1 }),
    ["map/water"] = scaled({ asset = "ss", tx = 0, ty = 1 }),
    ["map/locator"] = scaled({ asset = "ss", tx = 3, ty = 0 }),
    ["map/locator_paused"] = scaled({ asset = "ss", tx = 2, ty = 0 }),
    ["map/item"] = scaled({ asset = "ss", tx = 0, ty = 3 }),
    -- ["map/item_red"] = scaled({ asset = "ss", tx = 1, ty = 3 }),
    ["map/cross"] = scaled({ asset = "ss", tx = 3, ty = 3 }),
    ["map/teleport"] = scaled({ asset = "ss", tx = 1, ty = 4 }),

    ["map/decorations_1"] = scaled({ asset = "ss", tx = 6, ty = 0 }),
    ["map/decorations_2"] = scaled({ asset = "ss", tx = 7, ty = 0 }),
    ["map/decorations_3"] = scaled({ asset = "ss", tx = 6, ty = 1 }),
    ["map/decorations_4"] = scaled({ asset = "ss", tx = 7, ty = 1 }),
    ["map/decorations_5"] = scaled({ asset = "ss", tx = 6, ty = 1 }),
    ["map/decorations_6"] = scaled({ asset = "ss", tx = 7, ty = 2 }),

    ["ui/rat"] = scaled({ asset = "ss", tx = 6, ty = 2 }),
    ["ui/water"] = scaled({ asset = "ss", tx = 6, ty = 3 }),
    ["ui/defuser"] = scaled({ asset = "ss", tx = 6, ty = 4 }),
    ["ui/defuse_select"] = scaled({ asset = "ss", tx = 7, ty = 4 }),
    ["ui/defuse_select_cross"] = scaled({ asset = "ss", tx = 7, ty = 5 }),

    ["uilist/marker"] = scaled({ asset = "ss", tx = 8, ty = 0 }),

    ["ui/badge"] = scaled({ asset = "ss", tx = 8, ty = 4, tw = 6, th = 2, center = false }),
    ["ui/badge_cross"] = scaled({ asset = "ss", tx = 4, ty = 4, tw = 2, th = 2 }),

    ["player"] = scaled({ asset = "ss", tx = 2, ty = 0 }),

    ["rat_1"] = scaled({ asset = "ss", tx = 3, ty = 1 }),
    ["rat_2"] = scaled({ asset = "ss", tx = 3, ty = 2 }),

    ["bird"] = scaled({ asset = "ss", tx = 1, ty = 2 }),

    -- ["ui/cursor"] = { asset = "ui/cursor", tx = 0, ty = 0, center = false },
}

---@enum (key) Assets.Shaders
Assets.shaders = {
    default = { name = "default" }, -- has blink effect
    fader = { name = "fader" },
    ninepatch = { name = "ninepatch" },
    -- slab = { name = "slab" },

    -- waves = { name = "waves" },
    -- water = { name = "water" },
}

-- Many sounds from https://firahfabe.itch.io/chiptune-8-bit-sfx-pack

---@enum (key) Assets.Sfxs
Assets.sfxs = {
    -- boxland = { name = "boxland.ogg" },
    -- thud = { name = "thud.mp3" }, -- from https://pixabay.com/sound-effects/thud-291047/

    -- confirm = { name = "Confirm_3.ogg" },
    damage = { name = "Explosion.wav" },
    defuse = { name = "Radar_Use.wav" },
    drowning = { name = "drowning.ogg" },
    -- broken = { name = "BigDamage.ogg" },

    -- tick = { name = "tick.wav" },
    -- hit = { name = "hit.wav" },
    -- miss = { name = "miss.wav" },
    -- step = { name = "step.wav" },
    rat_spawn = { name = "Rat_Spawn.wav" },
    rat_move=  { name = "Rat_Move.wav" },
    pickup = { name = "pickup-2.wav" },
    switch = { name = "Skill_Change.ogg" },
    teleport = { name = "teleport-2.ogg" },

    -- char_1 = { name = "Char_Move_1.wav" },
    -- char_2 = { name = "Char_Move_2.wav" },
    -- char_3 = { name = "Char_Move_3.wav" },
    -- char_4 = { name = "Char_Move_4.wav" },
    -- char_5 = { name = "Char_Move_5.wav" },

    menu_move_1 = { name = "Menu_Click_1.ogg" },
    menu_move_2 = { name = "Menu_Click_2.ogg" },
    menu_move_3 = { name = "Menu_Click_3.ogg" },
    menu_select_1 = { name = "Menu_Select_1.ogg" },
    menu_select_2 = { name = "Menu_Select_2.ogg" },
    menu_back_1 = { name = "Menu_Back1.ogg" },
    menu_back_2 = { name = "Menu_Back2.ogg" },

    dialog_next = { name = "Menu_Click_1.ogg" },
    dialog_skip = { name = "Menu_Back2.ogg" },
    key_pickup = { name = "Key_Pickup.wav" },
    door_open = { name = "Door_Unlock.wav" },

    powerup_1 = { name = "powerup-1.ogg" },
    powerup_2 = { name = "powerup-2.ogg" },
    powerup_3 = { name = "powerup-3.ogg" },

    typing_1 = { name = "Typing_1.wav", volume = 0.5 },
    typing_2 = { name = "Typing_2.wav", volume = 0.5 },
    typing_3 = { name = "Typing_3.wav", volume = 0.5 },
    typing_4 = { name = "Typing_4.wav", volume = 0.5 },

    water = { name = "Wave_Skill.ogg" },

    move = { name = "move-2.ogg", volume = 0.5 },
}

---@enum (key) Assets.SfxGroups
Assets.sfxGroups = {
    -- char = { "char_1", "char_2", "char_3", "char_4", "char_5" },
    menu_move = { "menu_move_1", "menu_move_2", "menu_move_3" },
    menu_select = { "menu_select_1", "menu_select_2" },
    menu_back = { "menu_back_1", "menu_back_2" },
    powerup = { "powerup_1", "powerup_2", "powerup_3" },
    typing = { "typing_1", "typing_2", "typing_3", "typing_4" },
}

---@enum (key) Assets.Music
Assets.musics = {
    theme = { name = "theme.ogg" },

    menu = { name = "menu.ogg" },

    win = { name = "win.ogg" },

    ambience = { name = "ambience.ogg" },
}

---@enum (key) Assets.Animations
Assets.animations = {
    -- ["enemy/spawn"] = { texture = "enemy/spawn", frameTime = 0.07 }
    ["map/flag"] = { texture = "ss", tx = 0, ty = 7*16, frameHeight = 16, center = true, frameTime = 0.2, frames = 4 },
    ["map/delete"] = { texture = "ss", tx = 8*16, ty = 7*16, frameHeight = 16, center = true, frameTime = 0.1, frames = 5 },

    ["glint"] = { texture = "ss", tx = 8*16, ty = 6*16, frameHeight = 16, center = true, frameTime = 0.2, frames = 4 },

    ["teleport_out"] = { texture = "ss", tx = 4*16, ty=7*16, frameHeight = 16, center = true, frameTime = 0.07, frames = 4 },
    ["teleport_in"] = { texture = "ss", tx = 4*16, ty=6*16, frameHeight = 16, center = true, frameTime = 0.07, frames = 4 },

    ["story/wait"] = { texture = "ss", tx = 7*16, ty=3*16, frameHeight = 16, center = true, frameTime = 0.3, frames = 4},

    ["tutorial_highlight"] = { texture = "ss", tx = 8*16, ty=16, frameHeight = 16, center = true, frameTime = 0.2, frames = 5},
}

---@enum (key) Assets.Ninepatches
Assets.ninepatches = {
    ["sea"] = { 
        asset = "ss",
        texture = { x = 64, y = 0, w = 32, h = 16 },
        padding = { left = 4, right = 16, top = 1, bottom = 4 },
    },
    ["dialog"] = {
        asset = "ss",
        tiledX = true,
        tiledY = true,
        texture = { x = 0, y = 16*5, w = 32, h = 32 },
        padding = { left = 5, right = 5, top = 5, bottom = 5 },
    }
}

-- Assets.fontName = "pixellari"
Assets.fontName = "capitalhill"
