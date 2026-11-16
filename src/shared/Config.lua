--[[
	Config — EVERYTHING you need to edit is here.

	1. Publish your place, then create Game Passes and Developer Products on
	   https://create.roblox.com  ->  your experience  ->  Monetization.
	2. Paste each ID into the matching `Id = 0` below.
	   Items with Id = 0 still show in the map, but tell players "not set up yet".
]]

local Config = {}

Config.DataStoreName = "MoneyMap_PlayerData_v1"

-- Gives you every Game Pass while testing in Studio so you can try the perks.
Config.GiveAllPassesInStudio = true

-- Removes the default "Baseplate" from the Studio template (the map has its own ground).
Config.RemoveDefaultBaseplate = true

---------------------------------------------------------------------------
-- GAME PASSES (one-time purchase, permanent perk)
---------------------------------------------------------------------------
Config.GamePasses = {
	VIP = {
		Id = 0,
		Order = 1,
		Name = "VIP",
		Description = "VIP room with rare coins, VIP tag, +50% coins",
		PriceHint = 199,
	},
	DoubleCoins = {
		Id = 0,
		Order = 2,
		Name = "2x Coins",
		Description = "Double every coin you earn, forever",
		PriceHint = 149,
	},
	Speed = {
		Id = 0,
		Order = 3,
		Name = "Speed Boost",
		Description = "Run 50% faster",
		PriceHint = 79,
	},
	SuperJump = {
		Id = 0,
		Order = 4,
		Name = "Super Jump",
		Description = "Jump much higher",
		PriceHint = 79,
	},
}

---------------------------------------------------------------------------
-- DEVELOPER PRODUCTS (can be bought again and again)
-- Type: "Coins" | "SkipStage" | "CoinRain"
---------------------------------------------------------------------------
Config.DevProducts = {
	Coins100 = {
		Id = 0,
		Order = 1,
		Type = "Coins",
		Amount = 100,
		Name = "100 Coins",
		Description = "A small bag of coins",
		PriceHint = 25,
	},
	Coins500 = {
		Id = 0,
		Order = 2,
		Type = "Coins",
		Amount = 500,
		Name = "500 Coins",
		Description = "A big bag of coins",
		PriceHint = 99,
	},
	Coins2500 = {
		Id = 0,
		Order = 3,
		Type = "Coins",
		Amount = 2500,
		Name = "2500 Coins",
		Description = "A chest of coins - best value!",
		PriceHint = 399,
	},
	SkipStage = {
		Id = 0,
		Order = 4,
		Type = "SkipStage",
		Name = "Skip Obby Stage",
		Description = "Instantly skip your current obby stage",
		PriceHint = 15,
	},
	CoinRain = {
		Id = 0,
		Order = 5,
		Type = "CoinRain",
		Name = "Coin Rain",
		Description = "Make coins rain on the hub for EVERYONE",
		PriceHint = 49,
	},
}

---------------------------------------------------------------------------
-- PERKS
---------------------------------------------------------------------------
Config.Perks = {
	SpeedWalkSpeed = 24, -- default is 16
	SuperJumpPower = 75, -- default is 50
	DoubleCoinMultiplier = 2,
	VipCoinBonus = 1.5,
	PremiumCoinBonus = 1.25, -- rewards Roblox Premium players (boosts Premium Payouts)
}

---------------------------------------------------------------------------
-- COINS
---------------------------------------------------------------------------
Config.Coins = {
	FieldMax = 40,
	FieldValue = 1,
	VipMax = 20,
	VipValue = 5,
	RespawnTime = 8,
	RainCount = 60,
	RainValue = 3,
	RainRadius = 36,
	RainLifetime = 30,
}

---------------------------------------------------------------------------
-- OBBY
---------------------------------------------------------------------------
Config.Obby = {
	Stages = 12,
	StageLength = 40,
	StartX = 80,
	BaseHeight = 40,
	RiseRate = 2,
	FinishReward = 250,
	SkipCompensation = 50, -- coins given if someone buys a skip after finishing
}

---------------------------------------------------------------------------
-- DAILY REWARD
---------------------------------------------------------------------------
Config.DailyReward = {
	Amount = 100,
	Cooldown = 24 * 60 * 60,
}

function Config.FormatShopText(item, price)
	return string.format("%s\n%s\nR$ %s", item.Name, item.Description, tostring(price))
end

return Config
