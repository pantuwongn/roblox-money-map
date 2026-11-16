-- Client: shop menu, notifications, coin multiplier display, VIP door, spinning coins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Perks = require(Shared:WaitForChild("Perks"))

local player = Players.LocalPlayer
local notifyEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local gui = create("ScreenGui", {
	Name = "MoneyMapGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

---------------------------------------------------------------------------
-- NOTIFICATIONS
---------------------------------------------------------------------------
local toastHolder = create("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0, 440, 0, 300),
	BackgroundTransparency = 1,
}, gui)
create("UIListLayout", {
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, toastHolder)

local toastCount = 0
local function toast(text)
	toastCount += 1
	local label = create("TextLabel", {
		LayoutOrder = toastCount,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.15,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextWrapped = true,
		Text = text,
	}, toastHolder)
	corner(label)
	task.delay(3.5, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		label:Destroy()
	end)
end
notifyEvent.OnClientEvent:Connect(toast)

---------------------------------------------------------------------------
-- MULTIPLIER DISPLAY + SHOP BUTTON
---------------------------------------------------------------------------
local multiplierLabel = create("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, -48),
	Size = UDim2.new(0, 170, 0, 32),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0.2,
	TextColor3 = Color3.fromRGB(255, 215, 80),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Text = "",
}, gui)
corner(multiplierLabel)

local function updateMultiplier()
	multiplierLabel.Text = string.format("💰 Coins x%.2f", Perks.GetCoinMultiplier(player))
end
updateMultiplier()
player.AttributeChanged:Connect(updateMultiplier)
player:GetPropertyChangedSignal("MembershipType"):Connect(updateMultiplier)

local shopButton = create("TextButton", {
	Name = "ShopButton",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.new(0, 170, 0, 54),
	BackgroundColor3 = Color3.fromRGB(255, 190, 40),
	Text = "🛒 SHOP",
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = Color3.fromRGB(50, 35, 0),
}, gui)
corner(shopButton, 12)

---------------------------------------------------------------------------
-- SHOP WINDOW
---------------------------------------------------------------------------
local shopFrame = create("Frame", {
	Name = "Shop",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.8),
	BackgroundColor3 = Color3.fromRGB(28, 28, 40),
}, gui)
corner(shopFrame, 14)
create("UISizeConstraint", { MaxSize = Vector2.new(500, 520) }, shopFrame)

create("TextLabel", {
	Position = UDim2.new(0, 16, 0, 8),
	Size = UDim2.new(1, -80, 0, 40),
	BackgroundTransparency = 1,
	Text = "🛒 Shop",
	Font = Enum.Font.GothamBlack,
	TextSize = 28,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
}, shopFrame)

local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.new(0, 40, 0, 40),
	BackgroundColor3 = Color3.fromRGB(220, 60, 60),
	Text = "X",
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = Color3.new(1, 1, 1),
}, shopFrame)
corner(closeButton)

local list = create("ScrollingFrame", {
	Position = UDim2.new(0, 10, 0, 58),
	Size = UDim2.new(1, -20, 1, -68),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, shopFrame)
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

shopButton.Activated:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
end)
closeButton.Activated:Connect(function()
	shopFrame.Visible = false
end)

local layoutOrder = 0
local function nextOrder()
	layoutOrder += 1
	return layoutOrder
end

local function addHeader(text)
	create("TextLabel", {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -8, 0, 28),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 205, 60),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, list)
end

local function addRow(name, description, buttonText, onBuy)
	local row = create("Frame", {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -8, 0, 66),
		BackgroundColor3 = Color3.fromRGB(45, 45, 62),
	}, list)
	corner(row)
	create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -140, 0, 24),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 30),
		Size = UDim2.new(1, -140, 0, 30),
		BackgroundTransparency = 1,
		Text = description,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(190, 190, 210),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, row)
	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 110, 0, 42),
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		Text = buttonText,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
	}, row)
	corner(button)
	button.Activated:Connect(onBuy)
	return button
end

local function sortedKeys(tbl)
	local keys = {}
	for key in tbl do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return (tbl[a].Order or 0) < (tbl[b].Order or 0)
	end)
	return keys
end

local function fetchPrice(id, infoType, callback)
	if id == 0 then
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			callback(info.PriceInRobux)
		end
	end)
end

-- Game Passes
addHeader("⭐ Game Passes (forever)")
for _, key in sortedKeys(Config.GamePasses) do
	local pass = Config.GamePasses[key]
	local price = pass.PriceHint
	local button
	local function refresh()
		if Perks.HasPass(player, key) then
			button.Text = "Owned ✓"
			button.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
			button.AutoButtonColor = false
		else
			button.Text = "R$ " .. price
		end
	end
	button = addRow(pass.Name, pass.Description, "R$ " .. price, function()
		if Perks.HasPass(player, key) then
			toast("You already own " .. pass.Name .. "!")
		elseif pass.Id == 0 then
			toast("⚠️ " .. pass.Name .. " isn't set up yet (add its ID in Config).")
		else
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		end
	end)
	refresh()
	player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh)
	fetchPrice(pass.Id, Enum.InfoType.GamePass, function(robux)
		price = robux
		refresh()
	end)
end

-- Developer Products
addHeader("💰 Items & Boosts")
for _, key in sortedKeys(Config.DevProducts) do
	local product = Config.DevProducts[key]
	local button = addRow(product.Name, product.Description, "R$ " .. product.PriceHint, function()
		if product.Id == 0 then
			toast("⚠️ " .. product.Name .. " isn't set up yet (add its ID in Config).")
			return
		end
		if product.Type == "SkipStage" then
			local stage = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Stage")
			if stage and stage.Value > Config.Obby.Stages then
				toast("You've already finished the obby!")
				return
			end
		end
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end)
	fetchPrice(product.Id, Enum.InfoType.Product, function(robux)
		button.Text = "R$ " .. robux
	end)
end

-- Premium upsell (Premium players earn you Engagement-Based Payouts)
if not Perks.IsPremium(player) then
	addHeader("💎 Roblox Premium")
	local bonus = math.floor((Config.Perks.PremiumCoinBonus - 1) * 100 + 0.5)
	addRow("Premium Bonus", "Premium members get +" .. bonus .. "% coins on everything", "Get", function()
		MarketplaceService:PromptPremiumPurchase(player)
	end)
end

---------------------------------------------------------------------------
-- VIP DOOR (only opens for VIP owners, on their own screen)
---------------------------------------------------------------------------
task.spawn(function()
	local door = Workspace:WaitForChild("Map"):WaitForChild("VIP"):WaitForChild("VIPDoor")
	local function update()
		local vip = Perks.HasPass(player, "VIP")
		door.CanCollide = not vip
		door.Transparency = if vip then 0.75 else 0.3
	end
	update()
	player:GetAttributeChangedSignal("Pass_VIP"):Connect(update)
end)

---------------------------------------------------------------------------
-- SPINNING COINS (visual only)
---------------------------------------------------------------------------
task.spawn(function()
	local coins = Workspace:WaitForChild("Coins")
	RunService.RenderStepped:Connect(function()
		local rotation = CFrame.Angles(0, os.clock() * 3, 0)
		for _, coin in coins:GetChildren() do
			coin.CFrame = CFrame.new(coin.Position) * rotation
		end
	end)
end)
