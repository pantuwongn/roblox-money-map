-- RewardService — daily reward chest (keeps players coming back = more engagement payouts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Util = require(script.Parent.Util)

local RewardService = {}

function RewardService.Init(map)
	local prompt = map.DailyChest:FindFirstChildWhichIsA("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		local data = DataService.Get(player)
		if not data then
			return
		end
		local now = os.time()
		local remaining = data.LastDaily + Config.DailyReward.Cooldown - now
		if remaining > 0 then
			Remotes.NotifyPlayer(player, "🎁 Come back in " .. Util.FormatTime(remaining))
			return
		end
		data.LastDaily = now
		local amount = math.floor(Config.DailyReward.Amount * Perks.GetCoinMultiplier(player) + 0.5)
		DataService.AddCoins(player, amount)
		Remotes.NotifyPlayer(player, "🎁 Daily reward: +" .. amount .. " coins!")
	end)
end

return RewardService
