Config = {}

Config.Locale = 'en'

Config.RequiredItem = 'shovel'

Config.DiggingTime = 10000

Config.AntiCheat = {
    Enabled = true,
    MinTimeBetweenDigs = 8,
    MaxDigsInTimeFrame = 10,
    TimeFrameSeconds = 300
}

Config.Graves = {
    {
        coords = vector3(-1773.8339, -237.1582, 51.8043),
        label = 'Old Grave',
        icon = 'fas fa-skull-crossbones',
        distance = 2.0,
        cooldown = 300
    },
    {
        coords = vector3(-1776.5660, -235.1829, 51.6796),
        label = 'Ancient Grave',
        icon = 'fas fa-skull-crossbones',
        distance = 2.0,
        cooldown = 300
    },
}

Config.Loot = {
    {item = 'bone', label = 'Bone', min = 1, max = 3, chance = 45},
    {item = 'dirt', label = 'Dirt', min = 2, max = 5, chance = 50},
    {item = 'old_ring', label = 'Old Ring', min = 1, max = 1, chance = 25},
    {item = 'silver_coin', label = 'Silver Coin', min = 1, max = 2, chance = 20},
    {item = 'ruby', label = 'Ruby', min = 1, max = 1, chance = 10},
    {item = 'emerald', label = 'Emerald', min = 1, max = 1, chance = 10},
    {item = 'diamond', label = 'Diamond', min = 1, max = 1, chance = 5},
    {item = 'old_weapon', label = 'Old Weapon', min = 1, max = 1, chance = 8},
    {item = 'gold_necklace', label = 'Gold Necklace', min = 1, max = 1, chance = 7},
    {item = 'ancient_artifact', label = 'Ancient Artifact', min = 1, max = 1, chance = 3},
    {item = 'cursed_skull', label = 'Cursed Skull', min = 1, max = 1, chance = 2},
    {item = 'treasure_map', label = 'Treasure Map', min = 1, max = 1, chance = 1}
}

Config.MinLootItems = 1
Config.MaxLootItems = 3
