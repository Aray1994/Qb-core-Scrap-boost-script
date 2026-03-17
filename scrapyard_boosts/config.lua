Config = {}

-- =========================
-- Scrap yard locations
-- =========================
Config.ScrapYards = {
    {
        name = "Sandy Scrapyard",
        center = vector3(2398.23, 3110.71, 48.13),
        radius = 6.0,
        markerColor = {r = 0, g = 200, b = 80, a = 180},
        markerType = 1
    }
}

-- Map blip appearance for scrapyards
Config.ScrapBlip = {
    sprite = 365, -- wrench
    color = 2,
    scale = 0.9,
    label = "Scrapyard"
}

-- Prevent scrapping registered player vehicles (toggleable).
Config.BlockOwnedVehicles = true

-- Items rewarded for scrapping. Using the same baseline parts as the restore script.
Config.ScrapRewards = {
    { item = 'metalscrap', min = 25, max = 45 },
    { item = 'steel',      min = 10, max = 20 },
    { item = 'engineoil',  min = 2,  max = 5  }
}

Config.ScrapTime = 12000 -- ms progress bar for dismantling

-- =========================
-- Illegal boosting side
-- =========================
Config.BoostPed = {
    model = `a_m_m_hasjew_01`,
    coords = vector4(2338.06, 3048.39, 48.15, 310.02)
}

-- Cooldown between taking contracts (seconds)
Config.ContractCooldown = 1800 -- 30 minutes

-- Contract spawn locations (add more as needed)
Config.BoostSpawns = {
    { coords = vector4(1245.61, -3348.97, 5.90, 177.0) },
    { coords = vector4(-457.27, -1689.54, 18.70, 219.0) },
    { coords = vector4(841.21, -1028.11, 27.91, 87.0) },
    { coords = vector4(-1486.51, -500.72, 32.09, 215.0) },
    { coords = vector4(1533.86, 3780.55, 34.52, 200.0) }
}

-- Blip for active contract vehicle
Config.ContractBlip = {
    sprite = 225, -- car
    color = 5,
    scale = 0.9,
    label = "Boosting Vehicle"
}

-- Vehicles used for contracts (can add more)
Config.BoostVehicles = { 'sultan', 'elegy', 'f620', 'comet2', 'infernus' }

Config.LockpickItem = 'advancedlockpick'
Config.HotwireTime  = 8000 -- ms

-- Police alert settings (qb-policejob)
Config.SendPoliceAlert = true
Config.AlertMessage    = "Possible boosted vehicle being hotwired"

-- Payout multiplier when the car came from a contract
Config.BoostPayoutMultiplier = 2.0
