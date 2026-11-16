-- Shared perk helpers (used by both server and client).
-- Pass ownership is stored as player attributes "Pass_<Key>" set by the server.

local Config = require(script.Parent.Config)

local Perks = {}

function Perks.HasPass(player, key)
	return player:GetAttribute("Pass_" .. key) == true
end

function Perks.IsPremium(player)
	return player.MembershipType == Enum.MembershipType.Premium
end

function Perks.GetCoinMultiplier(player)
	local multiplier = 1
	if Perks.HasPass(player, "DoubleCoins") then
		multiplier *= Config.Perks.DoubleCoinMultiplier
	end
	if Perks.HasPass(player, "VIP") then
		multiplier *= Config.Perks.VipCoinBonus
	end
	if Perks.IsPremium(player) then
		multiplier *= Config.Perks.PremiumCoinBonus
	end
	return multiplier
end

return Perks
