--[[
	ObbyService — checkpoints, kill parts, portal, respawning at your stage,
	finish reward, restart, and the "Skip Stage" product.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Util = require(script.Parent.Util)

local ObbyService = {}

local checkpoints = {}
local finalStage = 0
local hubSpawn
local debounce = {}

local function teleportToStage(player, stage)
	local checkpoint = checkpoints[math.clamp(stage, 1, finalStage)]
	if checkpoint then
		Util.Teleport(player, checkpoint.CFrame + Vector3.new(0, 4, 0))
	end
end

local function reachStage(player, stage)
	DataService.SetStage(player, stage)
	if stage >= finalStage then
		DataService.AddCoins(player, Config.Obby.FinishReward)
		Remotes.NotifyAll("🏆 " .. player.DisplayName .. " completed the obby!")
		Remotes.NotifyPlayer(player, "+" .. Config.Obby.FinishReward .. " coins for finishing!")
	else
		Remotes.NotifyPlayer(player, "✅ Checkpoint " .. stage .. " / " .. (finalStage - 1))
	end
end

-- Touch handler with a 1-second per-player cooldown.
local function onPadTouched(part, callback)
	part.Touched:Connect(function(hit)
		local player = Util.PlayerFromPart(hit)
		if not player or debounce[player] then
			return
		end
		local data = DataService.Get(player)
		if not data then
			return
		end
		debounce[player] = true
		callback(player, data)
		task.delay(1, function()
			debounce[player] = nil
		end)
	end)
end

function ObbyService.GetFinalStage()
	return finalStage
end

ObbyService.TeleportToStage = teleportToStage

-- Used by the Skip Stage developer product. Always returns true (purchase handled).
function ObbyService.SkipStage(player)
	local data = DataService.Get(player)
	if not data then
		return false
	end
	if data.Stage >= finalStage then
		DataService.AddCoins(player, Config.Obby.SkipCompensation)
		Remotes.NotifyPlayer(player, "You already finished! Here are " .. Config.Obby.SkipCompensation .. " coins instead.")
		return true
	end
	reachStage(player, data.Stage + 1)
	player:SetAttribute("InObby", true)
	teleportToStage(player, data.Stage)
	return true
end

function ObbyService.Init(map)
	checkpoints = map.Checkpoints
	finalStage = #checkpoints
	hubSpawn = map.HubSpawn

	for stage, checkpoint in checkpoints do
		checkpoint.Touched:Connect(function(hit)
			local player = Util.PlayerFromPart(hit)
			if not player then
				return
			end
			local data = DataService.Get(player)
			if not data then
				return
			end
			player:SetAttribute("InObby", true)
			if stage == data.Stage + 1 then
				reachStage(player, stage)
			end
		end)
	end

	for _, part in map.KillParts do
		part.Touched:Connect(function(hit)
			local _, _, humanoid = Util.PlayerFromPart(hit)
			if humanoid then
				humanoid.Health = 0
			end
		end)
	end

	onPadTouched(map.ObbyPortal, function(player, data)
		player:SetAttribute("InObby", true)
		teleportToStage(player, data.Stage)
	end)

	onPadTouched(map.ExitPad, function(player)
		player:SetAttribute("InObby", false)
		Util.Teleport(player, hubSpawn.CFrame + Vector3.new(0, 4, 0))
	end)

	onPadTouched(map.RestartPad, function(player)
		DataService.SetStage(player, 1)
		player:SetAttribute("InObby", true)
		teleportToStage(player, 1)
		Remotes.NotifyPlayer(player, "Obby restarted - finish again for another reward!")
	end)

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			if not player:GetAttribute("InObby") then
				return
			end
			character:WaitForChild("HumanoidRootPart", 5)
			task.wait(0.1)
			local data = DataService.Get(player)
			if data then
				teleportToStage(player, data.Stage)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		debounce[player] = nil
	end)
end

return ObbyService
