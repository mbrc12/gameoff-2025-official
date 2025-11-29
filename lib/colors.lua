local function hex(s)
    if s:sub(1, 1) == "#" then
        s = s:sub(2)
    end
    local r = tonumber(s:sub(1, 2), 16) / 255
    local g = tonumber(s:sub(3, 4), 16) / 255
    local b = tonumber(s:sub(5, 6), 16) / 255
    return { r, g, b }
end

_G.Colors = {
    Transparent = { 0, 0, 0, 0 },
    Overlay = { 0, 0, 0, 0.5 },

    Heather = hex("9badb7"),

    ErogeBlack = hex("0d080d"),
    ErogeNightBlue = hex("2a2349"),
    DarkBlue = hex("32535f"),
    MediumBlue = hex("4180a0"),
    LightBlue = hex("74adbb"),
    ErogeWhite = hex("fff9e4"),

    -- MonitorBlack = hex("222323"),
    -- CC29Black = hex("212123"),
    -- CC29LightGreen = hex("c2d368"),
    -- CC29Green = hex("8AB060"),
    -- CC29DarkGreen = hex("567b79"),
    -- CC29Violet = hex("352B42"),
    -- CC29Gray = hex("868188"),
    -- CC29LightGray = hex("b8b5b9"),
    -- CC29DarkGray = hex("646365"),
    -- CC29Purple = hex("6a536e"),
    -- CC29Yellow = hex("ede19e"),
    -- CC29Olive = hex("4e584a"),
    --
    -- VioletBlack = hex("0C0B16"),
    --
    -- Gray = hex("868188"),
    -- DarkGray = hex("646365"),
    --
    -- DarkViolet = hex("2A173B"),

    Black = hex("000000"),
    White = hex("FFFFFF"),
    Yellow = hex("F7CF91"),
    EerieBlack = hex("1B1B1B"),
    RaisinBlack = hex("242124"),
    Alabaster = hex("F2F2F3"),
    SteelBlue = hex("486B7F"),
    Greenery = hex("7BB24E"),
    LincolnGreen = hex("195905"),
    Rosewood = hex("7D3840"),
    Teracotta = hex("C16C5B"),
    DarkMauve = hex("452e3f"),

    -- SakuraPink = hex("F2C1D1"),
    -- CrayonPink = hex("ff708d"),
    -- DeepPink = hex("7b3277"),
}

local Sweetie16 = {
    -- dark neutrals
    jet = hex("1a1c2c"),
    slate = hex("333c57"),
    steel = hex("29366f"),
    pewter = hex("566c86"),

    -- purples
    plum = hex("5d275d"),
    indigo = hex("3b5dc9"),

    -- reds / warm
    rose = hex("b13e53"),
    coral = hex("ef7d57"),
    sunshine = hex("ffcd75"),

    -- greens / teals
    lime = hex("a7f070"),
    emerald = hex("38b764"),
    teal = hex("257179"),

    -- blues / cyan
    sky = hex("41a6f6"),
    aqua = hex("73eff7"),

    -- neutrals / accents
    paper = hex("f4f4f4"),
    mist = hex("94b0c2"),
}

local CC29 = {
    -- neutrals / off_whites
    eggshell     = hex("f2f0e5"),
    silver       = hex("b8b5b9"),
    storm_gray   = hex("868188"),
    ash          = hex("646365"),
    charcoal     = hex("45444f"),

    -- cool deep/blues & indigos
    slate_indigo = hex("3a3858"),
    onyx_black   = hex("212123"),
    plum         = hex("352b42"),
    periwinkle   = hex("43436a"),
    azure        = hex("4b80ca"),
    aqua         = hex("68c2d3"),
    seafoam      = hex("a2dcc7"),

    -- warm yellows & tans
    pale_gold    = hex("ede19e"),
    burnt_sienna = hex("d3a068"),
    brick        = hex("b45252"),

    -- muted purples & mauves
    dusty_mauve  = hex("6a536e"),
    eggplant     = hex("4b4158"),
    rustic_brown = hex("80493a"),
    mocha        = hex("a77b5b"),
    almond       = hex("e5ceb4"),

    -- greens & olives
    chartreuse   = hex("c2d368"),
    pea_green    = hex("8ab060"),
    teal         = hex("567b79"),
    olive        = hex("4e584a"),
    khaki        = hex("7b7243"),
    sage         = hex("b2b47e"),

    -- pinks & lavenders
    blush        = hex("edc8c4"),
    orchid       = hex("cf8acb"),
    grape        = hex("5f556a"),
}

SteamLords = {
    forest_green    = hex("#213b25"),
    deep_fern       = hex("#3a604a"),
    moss_green      = hex("#4f7754"),
    muted_olive     = hex("#a19f7c"),
    taupe_green     = hex("#77744f"),
    sienna_brown    = hex("#775c4f"),
    mahogany        = hex("#603b3a"),
    aubergine       = hex("#3b2137"),
    midnight_black  = hex("#170e19"),
    indigo_berry    = hex("#2f213b"),
    eggplant_purple = hex("#433a60"),
    slate_violet    = hex("#4f5277"),
    steel_blue      = hex("#65738c"),
    storm_blue      = hex("#7c94a1"),
    sea_glass       = hex("#a0b9ba"),
    pale_teal       = hex("#c0d1cc"),

    additional_blue = hex("#495b6e"),
    additional_crimson = hex("#4e1e1d"),
    additional_green = hex("#5d6040")
}

Colors.CC29 = CC29
Colors.Sweetie16 = Sweetie16
Colors.SteamLords = SteamLords

function Colors.withAlpha(color, alpha)
    local c = { color[1], color[2], color[3], alpha }
    return c
end
