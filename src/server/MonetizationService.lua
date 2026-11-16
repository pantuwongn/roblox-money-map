--[[
	MonetizationService — Game Passes, Developer Products (safe ProcessReceipt),
	Premium bonus, shop pads, VIP room protection.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local DataService = require(script.Parent.DataService)
local ObbyService = require(script.Parent.ObbyService)
local CoinService = require(script.Parent.CoinService)
local Remotes = require(script.Parent.Remotes)
local Util = require(script.Parent.Util)

local MonetizationService = {}

local passKeyById = {} -- [passId] = key
local productById = {} -- [productId] = product config

---------------------------------------------------------------------------
-- GAME PASS PERKS
---------------------------------------------------------------------------
local function addVipTag(character)
	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
	if not head or head:FindFirstChild("VipTag") then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "VipTag"
	billboard.Size = UDim2.fromOffset(100, 30)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.MaxDistance = 80

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "⭐ VIP"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 205, 50)
	label.TextStrokeTransparency = 0.3
	label.Parent = billboard

	billboard.Parent = head
end

local function applyPerks(player, character)
	character = character or player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end
	if Perks.HasPass(player, "Speed") then
		humanoid.WalkSpeed = Config.Perks.SpeedWalkSpeed
	end
	if Perks.HasPass(player, "SuperJump") then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Config.Perks.SuperJumpPower
	end
	if Perks.HasPass(player, "VIP") then
		addVipTag(character)
	end
end

local function grantPass(player, key, announce)
	if Perks.HasPass(player, key) then
		return
	end
	player:SetAttribute("Pass_" .. key, true)
	task.spawn(applyPerks, player)
	if announce then
		Remotes.NotifyPlayer(player, "🎉 Thanks for buying " .. Config.GamePasses[key].Name .. "!")
	end
end

local function checkOwnedPasses(player)
	if Config.GiveAllPassesInStudio and RunService:IsStudio() then
		for key in Config.GamePasses do
			grantPass(player, key, false)
		end
		return
	end
	for key, pass in Config.GamePasses do
		if pass.Id ~= 0 then
			task.spawn(function()
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
				if ok and owns then
					grantPass(player, key, false)
				elseif not ok then
					warn("[Monetization] Pass check failed:", owns)
				end
			end)
		end
	end
end

---------------------------------------------------------------------------
-- DEVELOPER PRODUCTS
---------------------------------------------------------------------------
-- Each grant returns true when the purchase was delivered.
local grants = {
	Coins = function(player, product)
		DataService.AddCoins(player, product.Amount)
		Remotes.NotifyPlayer(player, "💰 +" .. product.Amount .. " coins! Thank you!")
		return true
	end,
	SkipStage = function(player)
		return ObbyService.SkipStage(player)
	end,
	CoinRain = function(player)
		CoinService.CoinRain()
		Remotes.NotifyAll("🌧️💰 " .. player.DisplayName .. " made it RAIN COINS in the hub!")
		return true
	end,
}

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries next time they join
	end

	local data = DataService.WaitForData(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Already delivered (e.g. retry after a failed save): just make sure it's saved.
	if DataService.HasReceipt(player, info.PurchaseId) then
		return if DataService.Save(player)
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local product = productById[info.ProductId]
	local grant = product and grants[product.Type]
	if not grant then
		warn("[Monetization] Unknown product id:", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, result = pcall(grant, player, product)
	if not ok or result == false then
		warn("[Monetization] Grant failed:", result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.AddReceipt(player, info.PurchaseId)
	data.TotalRobuxSpent += info.CurrencySpent or 0

	if not DataService.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------
-- PROMPTS
---------------------------------------------------------------------------
function MonetizationService.PromptPass(player, key)
	local pass = Config.GamePasses[key]
	if not pass then
		return
	end
	if Perks.HasPass(player, key) then
		Remotes.NotifyPlayer(player, "You already own " .. pass.Name .. "!")
		return
	end
	if pass.Id == 0 then
		Remotes.NotifyPlayer(player, "⚠️ " .. pass.Name .. " isn't set up yet (add its ID in Config).")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

function MonetizationService.PromptProduct(player, key)
	local product = Config.DevProducts[key]
	if not product then
		return
	end
	if product.Id == 0 then
		Remotes.NotifyPlayer(player, "⚠️ " .. product.Name .. " isn't set up yet (add its ID in Config).")
		return
	end
	if product.Type == "SkipStage" then
		local data = DataService.Get(player)
		if data and data.Stage >= ObbyService.GetFinalStage() then
			Remotes.NotifyPlayer(player, "You've already finished the obby!")
			return
		end
	end
	MarketplaceService:PromptProductPurchase(player, product.Id)
end

local function refreshSignPrice(entry)
	local isPass = entry.Kind == "GamePass"
	local item = if isPass then Config.GamePasses[entry.Key] else Config.DevProducts[entry.Key]
	if item.Id == 0 then
		entry.Label.Text = Config.FormatShopText(item, item.PriceHint .. " (not set up)")
		return
	end
	task.spawn(function()
		local infoType = if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, item.Id, infoType)
		if ok and info and info.PriceInRobux then
			entry.Label.Text = Config.FormatShopText(item, info.PriceInRobux)
		end
	end)
end

---------------------------------------------------------------------------
function MonetizationService.Init(map)
	for key, pass in Config.GamePasses do
		if pass.Id ~= 0 then
			passKeyById[pass.Id] = key
		end
	end
	for _, product in Config.DevProducts do
		if product.Id ~= 0 then
			productById[product.Id] = product
		end
	end

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = passKeyById[passId]
		if purchased and key then
			grantPass(player, key, true)
		end
	end)

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(character)
			applyPerks(player, character)
		end)
		checkOwnedPasses(player)
		if Perks.IsPremium(player) then
			task.delay(5, function()
				if player.Parent then
					local bonus = math.floor((Config.Perks.PremiumCoinBonus - 1) * 100 + 0.5)
					Remotes.NotifyPlayer(player, "💎 Premium bonus active: +" .. bonus .. "% coins!")
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end

	Players.PlayerMembershipChanged:Connect(function(player)
		if Perks.IsPremium(player) then
			Remotes.NotifyPlayer(player, "💎 Thanks for getting Premium! Bonus coins unlocked.")
		end
	end)

	-- Shop pads
	for _, entry in map.ShopPads do
		refreshSignPrice(entry)
		local prompt = entry.Pad:FindFirstChildWhichIsA("ProximityPrompt")
		prompt.Triggered:Connect(function(player)
			if entry.Kind == "GamePass" then
				MonetizationService.PromptPass(player, entry.Key)
			else
				MonetizationService.PromptProduct(player, entry.Key)
			end
		end)
	end

	-- VIP room protection (the door is only opened on the VIP player's client,
	-- this catches anyone who glitches inside without the pass).
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and not Perks.HasPass(player, "VIP") and Util.IsInside(root.Position, map.VipZone) then
					Util.Teleport(player, map.HubSpawn.CFrame + Vector3.new(0, 4, 0))
					Remotes.NotifyPlayer(player, "⭐ The VIP room is for VIP owners. Get VIP in the shop!")
				end
			end
		end
	end)
end

return MonetizationService
