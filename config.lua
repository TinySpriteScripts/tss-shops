Config = {
    System = {
        Debug = false,            -- set true to view target/ped areas
        Menu = "ox",            -- "qb", "ox"
        Notify = "ox",            -- "qb", "ox", "esx, "okok", "gta"
        ProgressBar = "ox",     -- "qb", "ox"
    },
    Crafting = { --only here for bridge support
        showItemBox = true,--will only show if your inventory supports it
    },
}
Config.DebugPoly = false
Config.UsePeds = true
Config.CombineBlips = false --used to display shop blips as "Shop" to lower blip count
Config.ShowImages = true
Config.EnableWebhooks = true -- configure in server.lua

Config.Shops = {
    ['247'] = {
        Enable = true,
        Label = "24/7",
        Products = '24hours',
        SellPercent = 50, -- default % of buy price paid when selling items back to this shop
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "24/7"},
        shopLogo = "247.png",
        Locations = {
            {Coords = vector4(24.47, -1346.62, 29.5, 271.66),       Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(-3039.54, 584.38, 7.91, 17.27),       Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(-3242.97, 1000.01, 12.83, 357.57),    Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(1728.07, 6415.63, 35.04, 242.95),     Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(1959.82, 3740.48, 32.34, 301.57),     Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(549.13, 2670.85, 42.16, 99.39),       Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(2677.47, 3279.76, 55.24, 335.08),     Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(2556.66, 380.84, 108.62, 356.67),     Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(372.66, 326.98, 103.57, 253.73),      Ped = 's_f_y_sweatshop_01',ShowBlip = true},
        },
    },
    ['ltd'] = {
        Enable = true,
        Label = "LTD Gasoline",
        Products = 'ltd',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "LTD"},
        Locations = {
            {Coords = vector4(-47.02, -1758.23, 29.42, 45.05),      Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(-706.06, -913.97, 19.22, 88.04),      Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(-1820.02, 794.03, 138.09, 135.45),    Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(1164.71, -322.94, 69.21, 101.72),     Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(1697.87, 4922.96, 42.06, 324.71),     Ped = 'mp_m_shopkeep_01',ShowBlip = true},
        },
    },
    ['liquor'] = {
        Enable = true,
        Label = "Rob's Liquor",
        Products = 'liquor',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "Rob's Liquor"},
        Locations = {
            {Coords = vector4(-1221.58, -908.15, 12.33, 35.49),     Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(-1486.59, -377.68, 40.16, 139.51),    Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(-2966.39, 391.42, 15.04, 87.48),      Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(1165.17, 2710.88, 38.16, 179.43),     Ped = 'mp_m_shopkeep_01',ShowBlip = true},
            {Coords = vector4(1134.2, -982.91, 46.42, 277.24),      Ped = 'mp_m_shopkeep_01',ShowBlip = true},
        },
    },
    ['hardware'] = {
        Enable = true,
        Label = "Hardware Store",
        Products = 'hardware',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "Hardware"},
        Locations = {
            {Coords = vector4(45.68, -1749.04, 29.61, 53.13),       Ped = 'mp_m_waremech_01',ShowBlip = true},
            {Coords = vector4(2747.71, 3472.85, 55.67, 255.08),     Ped = 'mp_m_waremech_01',ShowBlip = true},
            {Coords = vector4(-421.83, 6136.13, 31.88, 228.2),      Ped = 'mp_m_waremech_01',ShowBlip = true},
        },
    },
    ['ammunation'] = {
        Enable = true,
        Label = "Ammunation",
        Products = 'ammunation',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 110,Colour = 0,Label = "Ammunation"},
        Locations = {
            {Coords = vector4(-661.96, -933.53, 21.83, 177.05),     Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(809.68, -2159.13, 29.62, 1.43),       Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(1692.67, 3761.38, 34.71, 227.65),     Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(-331.23, 6085.37, 31.45, 228.02),     Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(253.63, -51.02, 69.94, 72.91),        Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(23.0, -1105.67, 29.8, 162.91),        Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(2567.48, 292.59, 108.73, 349.68),     Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(-1118.59, 2700.05, 18.55, 221.89),    Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(841.92, -1035.32, 28.19, 1.56),       Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(-1304.19, -395.12, 36.7, 75.03),      Ped = 's_m_y_ammucity_01',ShowBlip = true},
            {Coords = vector4(-3173.31, 1088.85, 20.84, 244.18),    Ped = 's_m_y_ammucity_01',ShowBlip = true},
        },
    },
    ['weedshop'] = {
        Enable = true,
        Label = "Smoke On The Water",
        Products = 'weedshop',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 140,Colour = 0,Label = "Weedshop"},
        Locations = {
            {Coords = vector4(-1168.26, -1573.2, 4.66, 105.24),     Ped = 'a_m_y_hippy_01',     ShowBlip = true},
        },
    },
    ['seaword'] = {
        Enable = true,
        Label = "Sea Word",
        Products = 'gearshop',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "Sea Word"},
        Locations = {
            {Coords = vector4(-1687.03, -1072.18, 13.15, 52.93),    Ped = 'a_m_y_beach_01',     ShowBlip = true},
            {Coords = vector4(-1505.91, 1511.95, 115.29, 257.13),   Ped = 'a_m_y_beach_01',     ShowBlip = true},
        },
    },
    ['casino'] = {
        Enable = true,
        Label = "Casino Chips",
        Products = 'chips',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 617,Colour = 0,Label = "Casino Chips"},
        Locations = {
            {Coords = vector4(978.46, 39.07, 74.88, 64.0),          Ped = 'csb_tomcasino',      ShowBlip = true},
        },
    },
    ['casinobar'] = {
        Enable = true,
        Label = "Casino Bar",
        Products = 'liquor',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 52,Colour = 0,Label = "Casino Bar"},
        Locations = {
            {Coords = vector4(968.13, 29.85, 74.88, 208.86),        Ped = 'a_m_y_smartcaspat_01',   ShowBlip = true},
        },
    },
    ['burgershot'] = {
        Enable = false,
        Label = "Burgershot",
        Products = 'burgershot',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 106,Colour = 1,Label = "Burgershot"},
        Locations = {
            {Coords = vector4(-1191.91, -894.84, 13.89, 344.98),    Ped = 's_f_y_sweatshop_01',ShowBlip = true},
            {Coords = vector4(-1195.65, -893.89, 13.89, 347.69),    Ped = 's_m_m_linecook',},
        },
    },
    ['luchetti'] = {
        Enable = true,
        Label = "Luchetti",
        Products = 'luchetti',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 77,Colour = 1,Label = "Luchetti"},
        Locations = {
            {Coords = vector4(288.27, -978.0, 29.43, 358.47),    Ped = 's_m_m_movprem_01',ShowBlip = true},
        },
    },
    ['bean'] = {
        Enable = true,
        Label = "Bean Machine",
        Products = 'bean',
        Icon = "fas fa-comment-dots",
        Blip = {Sprite = 93,Colour = 10,Label = "Bean Machine"},
        Locations = {
            {Coords = vector4(-635.01, 235.02, 81.88, 277.96),    Ped = 's_f_y_bartender_01',ShowBlip = true},
        },
    },
}


--EXAMPLE ITEM LAYOUT
-- [1] = numbers must be in order
-- name = itemcode
-- price = price of item when buying
-- stock = starting shop stock. Leave nil for unlimited stock
-- canSell = true to allow players to sell this item to shops using this product list
-- sellPercent = optional % of buy price paid when selling. Overrides shop SellPercent
-- requiredJob = can be single job { 'mechanic' } or multiple like { 'mechanic', 'police' }
-- requiredGang = same as job but with gang codes
-- requiresLicense = must be the license code needed to purchase

Config.Products = {
    ['24hours'] = {
        [1] = {name = "tosti",              price = 2,        stock = 80, },
        [2] = {name = "water_bottle",       price = 2,        stock = 120, canSell = true, },
        [3] = {name = "cola",               price = 2,        stock = 120, canSell = true, },
        [4] = {name = "twerks_candy",       price = 2,        stock = 75, canSell = true, },
        [5] = {name = "snikkel_candy",      price = 2,        stock = 75, canSell = true, },
        [6] = {name = "sandwich",           price = 2,        stock = 80, },
        [7] = {name = "beer",               price = 7,        stock = 45, canSell = true, sellPercent = 65, },
        [8] = {name = "whiskey",            price = 10,       stock = 35, canSell = true, sellPercent = 60, },
        [9] = {name = "vodka",              price = 12,       stock = 35, canSell = true, sellPercent = 60, },
        [10] = {name = "bandage",           price = 100,      stock = 30, canSell = true, sellPercent = 35, },
        [11] = {name = "lighter",           price = 2,        stock = 60, },
        [12] = {name = "rolling_paper",     price = 2,        stock = 60, },
        [13] = {name = "ticket1",           price = 10,       stock = 50, },
        [14] = {name = "ticket2",           price = 20,       stock = 50, },
        [15] = {name = "ticket3",           price = 50,       stock = 50, },
    },
    ["burgershot"] = {
        [1] = {name = "milkshake",          price = 7,        },
        [2] = {name = "cola",               price = 8,        },
        [3] = {name = "nuggets",            price = 12,       },
        [4] = {name = "burger",             price = 15,       },
        [5] = {name = "chickenwrap",        price = 18,       },
        [6] = {name = "fries",              price = 10,       },
    },	
    ["bean"] = {
        [1] = {name = "coffee",             price = 12,        },
        [2] = {name = "latte",              price = 15,        },
        [3] = {name = "cappuccino",         price = 21,       },
        [4] = {name = "mocha",              price = 25,       },
        [5] = {name = "hotchoc",            price = 30,       },
        [6] = {name = "tea",                price = 15,       },
    },
    ["luchetti"] = {
        [1] = {name = "ambeer",          price = 7,        },
        [2] = {name = "dusche",          price = 8,        },
        [3] = {name = "logger",          price = 12,       },
        [4] = {name = "pisswasser",      price = 15,       },
        [5] = {name = "pisswasser2",     price = 18,       },
        [6] = {name = "pisswasser3",     price = 10,       },
        [7] = {name = "amarone",         price = 50,       },
        [8] = {name = "barbera",         price = 50,       },
        [9] = {name = "dolceto",         price = 50,       },
        [10] = {name = "housered",       price = 50,       },
        [11] = {name = "housewhite",     price = 50,       },
        [12] = {name = "rosso",          price = 65,       },
        [13] = {name = "tiramisu",       price = 65,       },
        [14] = {name = "gelato",         price = 65,       },
        [15] = {name = "medfruits",      price = 65,       },
        [16] = {name = "bolognese",      price = 95,       },
        [17] = {name = "calamari",       price = 95,       },
        [18] = {name = "meatball",       price = 95,       },
        [19] = {name = "alla",           price = 95,       },
        [20] = {name = "pescatore",      price = 95,       },
        [21] = {name = "capricciosa",    price = 95,       },
        [22] = {name = "diavola",        price = 120,       },
        [23] = {name = "marinara",       price = 120,       },
        [24] = {name = "margherita",     price = 120,       },
        [25] = {name = "prosciuttio",    price = 120,       },
        [26] = {name = "vegetariana",    price = 120,       },
    },	
    ["liquor"] = {
        [1] = {name = "beer",               price = 7,        cansell = {Price = 5},},
        [2] = {name = "whiskey",            price = 10,       cansell = {Price = 5},},
        [3] = {name = "vodka",              price = 12,       cansell = {Price = 5},},
    },
    ["hardware"] = {
        [1] = {name = "lockpick",           price = 200,      },
        [2] = {name = "weapon_wrench",      price = 250,      requiredGang = { 'lostmc','ballas' },   },
        [3] = {name = "weapon_hammer",      price = 250,      cansell = {Price = 5},},
        [4] = {name = "repairkit",          price = 250,      requiredJob = { "mechanic", "police" }, },
        [5] = {name = "screwdriverset",     price = 350,      },
        [6] = {name = "phone",              price = 850,      },
        [7] = {name = "radio",              price = 250,      },
        [8] = {name = "binoculars",         price = 50,       },
        [9] = {name = "firework1",          price = 50,       cansell = {Price = 5},},
        [10] = {name = "firework2",         price = 50,       cansell = {Price = 5},},
        [11] = {name = "firework3",         price = 50,       cansell = {Price = 5},},
        [12] = {name = "firework4",         price = 50,       cansell = {Price = 5},},
        [13] = {name = "fitbit",            price = 400,      },
        [14] = {name = "cleaningkit",       price = 150,      },
        [15] = {name = "advancedrepairkit", price = 500,      cansell = {Price = 5},  requiredJob = { "mechanic" },    },
    },
    ["weedshop"] = {
        [1] = {name = "joint",              price = 10,      },
        [2] = {name = "weapon_poolcue",     price = 100,     },
        [3] = {name = "weed_nutrition",     price = 20,      },
        [4] = {name = "empty_weed_bag",     price = 2,       },
        [5] = {name = "rolling_paper",      price = 2,       },
    },
    ["gearshop"] = {
        [1] = {name = "diving_gear",        price = 2500,   cansell = {Price = 5}, },
        [2] = {name = "jerry_can",          price = 200,    },
        [3] = {name = "parachute",          price = 200,    },
        [4] = {name = "binoculars",         price = 200,    },
        [5] = {name = "diving_fill",        price = 200,    },
    },
    ["ammunation"] = {
        [1] = {name = "weapon_knife",       price = 250,    },
        [2] = {name = "weapon_bat",         price = 250,    },
        [3] = {name = "weapon_hatchet",     price = 250,    requiredJob = { "mechanic", "police" },  },
        [4] = {name = "weapon_pistol",      price = 2500,   requiresLicense = 'weapon',  },
        [5] = {name = "weapon_snspistol",   price = 1500,   requiresLicense = 'weapon',  },
        [6] = {name = "weapon_vintagepistol",price = 4000,  requiresLicense = 'weapon',  },
        [7] = {name = "pistol_ammo",        price = 250,    requiresLicense = 'weapon',  },
    },
    ["chips"] = {
        [1] = {name = 'casinochips',        price = 2,      cansell = {Price = 1},  },
    },
}

Config.VendingMachines = {
    --red drink machine
    ['prop_vend_fridge01'] = { --model of the vending machine
        Enable = true,
        Label = "Drinks Fridge",
        ExtraLocations = { --if you want to spawn extra vending machines
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "cola",       price = 5,    },
            [2] = {name = "sprunk",     price = 5,    },
        },
    },
    --grey snack machine
    ['prop_vend_snak_01'] = { 
        Enable = true,
        Label = "Snack Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "twerks_candy",    price = 5,    },
            [2] = {name = "snikkel_candy",   price = 5,    },
        },
    },
    -- coffee vending cart
    ['p_ld_coffee_vend_01'] = { 
        Enable = true,
        Label = "Coffee Vendor",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "coffee",   price = 5,    },
        },
    },
    -- coffee machine
    ['prop_vend_coffe_01'] = { 
        Enable = true,
        Label = "Coffee Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "coffee",   price = 5,    },
        },
    },
    -- cigarette vending machine
    ['prop_vend_fags_01'] = { 
        Enable = false,
        Label = "Cigarette Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "changeme",   price = 5,    },
            [2] = {name = "changeme",   price = 5,    },
            [3] = {name = "changeme",   price = 5,    },
        },
    },
    -- red ecola vending machine
    ['prop_vend_soda_01'] = { 
        Enable = true,
        Label = "Drinks Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "cola",       price = 5,    },
            [2] = {name = "sprunk",     price = 5,    },
        },
    },
    -- green sprunk vending machine
    ['prop_vend_soda_02'] = { 
        Enable = true,
        Label = "Drinks Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "cola",       price = 5,    },
            [2] = {name = "sprunk",     price = 5,    },
        },
    },
    --water vending machine
    ['prop_vend_water_01'] = { 
        Enable = true,
        Label = "Water Machine",
        ExtraLocations = {
            {Coords = vector4(0,0,0,0)},
        },
        Products = {
            [1] = {name = "water_bottle",   price = 5,    },
        },
    },
}
