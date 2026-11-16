--[[
	DataService — loads/saves player data with DataStoreService.
	Data: Coins, Stage, LastDaily, Receipts (for safe Developer Product handling).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

local TEMPLATE = {
	Coins = 0,
	Stage = 1,
	LastDaily = 0,
	Receipts = {},
	TotalRobuxSpent = 0,
}
local MAX_RECEIPTS = 100
local AUTOSAVE_INTERVAL = 120

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore unavailable:", result)
	end
end

local sessions = {} -- [player] = data
local canSave = {} -- [player] = bool

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function reconcile(data)
	for key, value in TEMPLATE do
		if data[key] == nil then
			data[key] = deepCopy(value)
		end
	end
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function syncStat(player, name, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat then
		stat.Value = value
	end
end

local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = data.Stage
	stage.Parent = leaderstats

	leaderstats.Parent = player
end

local function loadData(player)
	if not store then
		return nil, false
	end
	for attempt = 1, 3 do
		local ok, result = pcall(store.GetAsync, store, keyFor(player))
		if ok then
			return result, true
		end
		warn(string.format("[DataService] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
		task.wait(attempt * 2)
	end
	return nil, false
end

function DataService.OnPlayerAdded(player)
	local data, ok = loadData(player)
	if not player.Parent then
		return
	end

	if not ok then
		if RunService:IsStudio() then
			warn("[DataService] Using temporary data. Enable 'Studio Access to API Services' in Game Settings to test saving.")
		else
			player:Kick("We couldn't load your data. Please rejoin!")
			return
		end
	end

	if type(data) ~= "table" then
		data = deepCopy(TEMPLATE)
	end
	reconcile(data)

	sessions[player] = data
	canSave[player] = ok
	createLeaderstats(player, data)
	player:SetAttribute("DataLoaded", true)
end

function DataService.Save(player)
	local data = sessions[player]
	if not data then
		return false
	end
	if not canSave[player] then
		return true -- temporary Studio data, nothing to save
	end
	local ok, err = pcall(store.UpdateAsync, store, keyFor(player), function()
		return data
	end)
	if not ok then
		warn("[DataService] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function DataService.Get(player)
	return sessions[player]
end

function DataService.WaitForData(player, timeout)
	local start = os.clock()
	while player.Parent and not sessions[player] do
		if timeout and os.clock() - start > timeout then
			break
		end
		task.wait(0.1)
	end
	return sessions[player]
end

function DataService.AddCoins(player, amount)
	local data = sessions[player]
	if not data then
		return false
	end
	data.Coins = math.max(0, data.Coins + math.floor(amount))
	syncStat(player, "Coins", data.Coins)
	return true
end

function DataService.SetStage(player, stage)
	local data = sessions[player]
	if not data then
		return false
	end
	data.Stage = stage
	syncStat(player, "Stage", stage)
	return true
end

function DataService.HasReceipt(player, purchaseId)
	local data = sessions[player]
	return data ~= nil and table.find(data.Receipts, purchaseId) ~= nil
end

function DataService.AddReceipt(player, purchaseId)
	local data = sessions[player]
	if not data then
		return
	end
	table.insert(data.Receipts, purchaseId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
end

function DataService.Init()
	Players.PlayerAdded:Connect(DataService.OnPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(DataService.OnPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		sessions[player] = nil
		canSave[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in sessions do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in sessions do
				task.spawn(DataService.Save, player)
			end
		end
	end)
end

return DataService
