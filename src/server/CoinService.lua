--[[
	CoinService — collectible coins in zones (coin field, VIP room) plus the
	"Coin Rain" event triggered by the developer product.
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local DataService = require(script.Parent.DataService)
local Util = require(script.Parent.Util)

local CoinService = {}

local coinsFolder
local rainCenter
local rng = Random.new()

local GOLD = Color3.fromRGB(255, 205, 50)
local DIAMOND = Color3.fromRGB(90, 230, 255)
local RAIN = Color3.fromRGB(255, 150, 255)

local function createCoin(cframe, value, color, onCollected)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 2.6, 2.6)
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.Material = Enum.Material.Neon
	coin.Color = color
	coin.CFrame = cframe
	coin:SetAttribute("Value", value)

	local taken = false
	coin.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = Util.PlayerFromPart(hit)
		if not player or not DataService.Get(player) then
			return
		end
		taken = true
		local amount = math.max(1, math.floor(value * Perks.GetCoinMultiplier(player) + 0.5))
		DataService.AddCoins(player, amount)
		coin:Destroy()
		if onCollected then
			onCollected()
		end
	end)

	coin.Parent = coinsFolder
	return coin
end

local function randomPointOn(zonePart, heightAbove)
	local half = zonePart.Size / 2
	local offset = Vector3.new(rng:NextNumber(-half.X, half.X), half.Y + heightAbove, rng:NextNumber(-half.Z, half.Z))
	return zonePart.CFrame * CFrame.new(offset)
end

-- Keeps `opts.Max` coins alive in a zone, respawning each one after it is collected.
function CoinService.AddZone(zonePart, opts)
	local function spawnOne()
		if not zonePart.Parent then
			return
		end
		createCoin(randomPointOn(zonePart, 2), opts.Value, opts.Color, function()
			task.delay(opts.RespawnTime, spawnOne)
		end)
	end
	for _ = 1, opts.Max do
		spawnOne()
	end
end

function CoinService.CoinRain()
	local C = Config.Coins
	task.spawn(function()
		for i = 1, C.RainCount do
			local target = rainCenter.CFrame
				* CFrame.new(rng:NextNumber(-C.RainRadius, C.RainRadius), 2.5, rng:NextNumber(-C.RainRadius, C.RainRadius))
			local coin = createCoin(target + Vector3.new(0, rng:NextNumber(30, 60), 0), C.RainValue, RAIN)
			TweenService:Create(
				coin,
				TweenInfo.new(rng:NextNumber(1.2, 2.2), Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{ CFrame = target }
			):Play()
			task.delay(C.RainLifetime, function()
				if coin.Parent then
					coin:Destroy()
				end
			end)
			if i % 10 == 0 then
				task.wait(0.1)
			end
		end
	end)
end

function CoinService.Init(map)
	local old = Workspace:FindFirstChild("Coins")
	if old then
		old:Destroy()
	end
	coinsFolder = Instance.new("Folder")
	coinsFolder.Name = "Coins"
	coinsFolder.Parent = Workspace

	rainCenter = map.Hub

	local C = Config.Coins
	CoinService.AddZone(map.CoinFieldZone, { Max = C.FieldMax, Value = C.FieldValue, RespawnTime = C.RespawnTime, Color = GOLD })
	CoinService.AddZone(map.VipCoinZone, { Max = C.VipMax, Value = C.VipValue, RespawnTime = C.RespawnTime, Color = DIAMOND })
end

return CoinService
