--[[
	MapBuilder — generates the whole map from code every time the server starts.

	Zones:
	  Hub (spawn)        center (0, 0, 0)
	  Obby (12 stages)   east, up in the sky, entered via the purple portal
	  VIP room           west, Game Pass door
	  Shop               north, walk-up purchase pads
	  Coin field         south, collect coins
	  Daily reward chest inside the hub

	Put your own hand-built decorations in a separate Workspace folder (not "Map"),
	because "Map" is deleted and rebuilt on start.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local COLORS = {
	Grass = Color3.fromRGB(86, 160, 72),
	Hub = Color3.fromRGB(205, 205, 212),
	Gold = Color3.fromRGB(255, 200, 40),
	Lava = Color3.fromRGB(255, 70, 30),
	Start = Color3.fromRGB(80, 220, 100),
	Checkpoint = Color3.fromRGB(70, 160, 255),
	Platform = Color3.fromRGB(240, 240, 240),
	Portal = Color3.fromRGB(160, 80, 255),
	Product = Color3.fromRGB(60, 140, 255),
	Wood = Color3.fromRGB(120, 80, 45),
	Leaves = Color3.fromRGB(60, 140, 60),
	VipWall = Color3.fromRGB(45, 30, 70),
	SignBg = Color3.fromRGB(28, 28, 40),
}

local function create(className, props, parent)
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function block(parent, props)
	local part = create("Part", props)
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Invisible region used for logic (coin spawning, VIP check).
local function zone(parent, name, cframe, size)
	return block(parent, {
		Name = name,
		CFrame = cframe,
		Size = size,
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	})
end

-- A board whose front faces `lookAt` (horizontal only). Returns board, label.
local function sign(parent, text, position, lookAt, size, color)
	local target = Vector3.new(lookAt.X, position.Y, lookAt.Z)
	local board = block(parent, {
		Name = "Sign",
		Size = size or Vector3.new(14, 6, 0.6),
		CFrame = CFrame.lookAt(position, target),
		Color = color or COLORS.SignBg,
		Material = Enum.Material.SmoothPlastic,
	})
	local gui = create("SurfaceGui", {
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 40,
		LightInfluence = 0,
	}, board)
	local label = create("TextLabel", {
		Name = "Info",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
	}, gui)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, label)
	return board, label
end

local function topLabel(part, text)
	local gui = create("SurfaceGui", { Face = Enum.NormalId.Top, LightInfluence = 0 }, part)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
	}, gui)
end

---------------------------------------------------------------------------
-- GROUND + HUB
---------------------------------------------------------------------------
local function buildGround(map)
	block(map, {
		Name = "Ground",
		Size = Vector3.new(1200, 2, 700),
		CFrame = CFrame.new(200, -1, 0),
		Color = COLORS.Grass,
		Material = Enum.Material.Grass,
	})
end

local function buildHub(map, out)
	local hub = create("Folder", { Name = "Hub" }, map)

	out.Hub = block(hub, {
		Name = "HubFloor",
		Size = Vector3.new(84, 0.4, 84),
		CFrame = CFrame.new(0, 0.2, 0),
		Color = COLORS.Hub,
		Material = Enum.Material.Concrete,
	})

	out.HubSpawn = create("SpawnLocation", {
		Name = "HubSpawn",
		Size = Vector3.new(12, 1, 12),
		CFrame = CFrame.new(0, 0.9, 0),
		Anchored = true,
		Neutral = true,
		Duration = 2,
		Color = COLORS.Start,
		Material = Enum.Material.SmoothPlastic,
		TopSurface = Enum.SurfaceType.Smooth,
	}, hub)

	sign(
		hub,
		"Welcome!\nCollect coins • Beat the obby • Visit the shop",
		Vector3.new(24, 7, -24),
		Vector3.new(0, 7, 0),
		Vector3.new(18, 6, 0.5)
	)

	-- Obby portal (east)
	out.ObbyPortal = block(hub, {
		Name = "ObbyPortal",
		Size = Vector3.new(6, 1, 6),
		CFrame = CFrame.new(36, 0.9, 0),
		Color = COLORS.Portal,
		Material = Enum.Material.Neon,
	})
	topLabel(out.ObbyPortal, "OBBY")
	sign(hub, "OBBY ➜\nStep on the portal!\nProgress saves", Vector3.new(36, 7, 0), Vector3.new(0, 7, 0), Vector3.new(10, 6, 0.5), COLORS.Portal)

	-- Daily reward chest
	local chestCFrame = CFrame.new(-24, 1.9, 24) * CFrame.Angles(0, math.rad(45), 0)
	out.DailyChest = block(hub, {
		Name = "DailyChest",
		Size = Vector3.new(5, 3, 3.5),
		CFrame = chestCFrame,
		Color = COLORS.Wood,
		Material = Enum.Material.Wood,
	})
	block(hub, {
		Name = "ChestLid",
		Size = Vector3.new(5.2, 0.8, 3.7),
		CFrame = chestCFrame * CFrame.new(0, 1.9, 0),
		Color = COLORS.Gold,
		Material = Enum.Material.Metal,
	})
	create("ProximityPrompt", {
		ActionText = "Claim",
		ObjectText = "Daily Reward",
		HoldDuration = 0.5,
		MaxActivationDistance = 10,
		RequiresLineOfSight = false,
	}, out.DailyChest)
	sign(hub, "🎁 Daily Reward", Vector3.new(-24, 7, 24), Vector3.new(0, 7, 0), Vector3.new(10, 3, 0.5), COLORS.Wood)
end

---------------------------------------------------------------------------
-- OBBY
---------------------------------------------------------------------------
local function buildObby(map, out)
	local O = Config.Obby
	local L = O.StageLength
	local folder = create("Folder", { Name = "Obby" }, map)
	local rng = Random.new(2024)

	local checkpoints, kills, fading, spinners = {}, {}, {}, {}

	local function heightOf(stage)
		return O.BaseHeight + (stage - 1) * O.RiseRate
	end
	local function xOf(stage)
		return O.StartX + (stage - 1) * L
	end
	local function platform(size, cframe, color)
		return block(folder, {
			Name = "Platform",
			Size = size,
			CFrame = cframe,
			Color = color or COLORS.Platform,
			Material = Enum.Material.SmoothPlastic,
		})
	end
	local function killPart(size, cframe)
		local part = block(folder, {
			Name = "Lava",
			Size = size,
			CFrame = cframe,
			Color = COLORS.Lava,
			Material = Enum.Material.Neon,
		})
		table.insert(kills, part)
		return part
	end

	-- Each variant fills the gap between x=a and x=b at top-height h.
	local variants = {}

	function variants.jumps(a, b, h)
		local n = 4
		for i = 1, n do
			local x = a + (b - a) * i / (n + 1)
			local z = if i % 2 == 0 then 3 else -3
			platform(Vector3.new(4, 1, 4), CFrame.new(x, h - 0.5, z))
		end
	end

	function variants.beam(a, b, h)
		platform(Vector3.new(b - a, 1, 1.2), CFrame.new((a + b) / 2, h - 0.5, 0), Color3.fromRGB(255, 170, 60))
	end

	function variants.lava(a, b, h)
		local n = 5
		for i = 1, n do
			local x = a + (b - a) * i / (n + 1)
			platform(Vector3.new(3, 1, 3), CFrame.new(x, h - 0.5, rng:NextNumber(-3, 3)), Color3.fromRGB(90, 90, 90))
		end
		killPart(Vector3.new(b - a, 1, 16), CFrame.new((a + b) / 2, h - 5, 0))
	end

	function variants.disappearing(a, b, h)
		local n = 4
		for i = 1, n do
			local x = a + (b - a) * i / (n + 1)
			local part = platform(Vector3.new(5, 1, 5), CFrame.new(x, h - 0.5, 0), Color3.fromRGB(255, 120, 200))
			table.insert(fading, { Part = part, Phase = i * 0.7 })
		end
	end

	function variants.spinner(a, b, h)
		platform(Vector3.new(b - a, 1, 10), CFrame.new((a + b) / 2, h - 0.5, 0), Color3.fromRGB(200, 200, 255))
		for i = 1, 2 do
			local center = CFrame.new(a + (b - a) * i / 3, h + 0.6, 0)
			local bar = killPart(Vector3.new(1, 1, 11), center)
			table.insert(spinners, { Part = bar, Center = center, Speed = if i == 1 then 2.2 else -2.6 })
		end
	end

	local order = { "jumps", "beam", "lava", "disappearing", "spinner" }
	local finalStage = O.Stages + 1

	for stage = 1, finalStage do
		local isFinal = stage == finalStage
		local h = heightOf(stage)
		local x = xOf(stage)
		local size = if isFinal then Vector3.new(24, 1, 24) else Vector3.new(8, 1, 8)
		local cx = if isFinal then x + 8 else x

		local checkpoint = block(folder, {
			Name = if isFinal then "Finish" else "Checkpoint" .. stage,
			Size = size,
			CFrame = CFrame.new(cx, h - 0.5, 0),
			Color = if isFinal then COLORS.Gold elseif stage == 1 then COLORS.Start else COLORS.Checkpoint,
			Material = Enum.Material.SmoothPlastic,
		})
		checkpoint:SetAttribute("Stage", stage)
		topLabel(checkpoint, if isFinal then "🏆 FINISH" else tostring(stage))
		checkpoints[stage] = checkpoint

		if isFinal then
			out.ExitPad = block(folder, {
				Name = "ExitPad",
				Size = Vector3.new(5, 0.2, 5),
				CFrame = CFrame.new(cx + 6, h + 0.1, -6),
				Color = COLORS.Start,
				Material = Enum.Material.Neon,
			})
			out.RestartPad = block(folder, {
				Name = "RestartPad",
				Size = Vector3.new(5, 0.2, 5),
				CFrame = CFrame.new(cx + 6, h + 0.1, 6),
				Color = Color3.fromRGB(255, 140, 40),
				Material = Enum.Material.Neon,
			})
			local facing = Vector3.new(cx - 50, 0, 0)
			sign(folder, "Back to Hub", Vector3.new(cx + 9, h + 4, -6), facing + Vector3.new(0, 0, -6), Vector3.new(6, 3, 0.5))
			sign(folder, "Restart Obby", Vector3.new(cx + 9, h + 4, 6), facing + Vector3.new(0, 0, 6), Vector3.new(6, 3, 0.5))
		else
			local variant = order[(stage - 1) % #order + 1]
			variants[variant](x + 4, x + L - 4, h)
		end
	end

	-- Lava on the ground under the whole obby
	killPart(Vector3.new(O.Stages * L + 40, 1, 60), CFrame.new(O.StartX + O.Stages * L / 2, 0.5, 0))

	-- Animate disappearing platforms
	task.spawn(function()
		while true do
			local t = os.clock()
			for _, f in fading do
				local p = (t + f.Phase) % 3
				if p < 1.6 then
					f.Part.Transparency = 0
					f.Part.CanCollide = true
				elseif p < 2.1 then
					f.Part.Transparency = 0.5
					f.Part.CanCollide = true
				else
					f.Part.Transparency = 0.9
					f.Part.CanCollide = false
				end
			end
			task.wait(0.1)
		end
	end)

	-- Animate spinners
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, s in spinners do
			s.Part.CFrame = s.Center * CFrame.Angles(0, t * s.Speed, 0)
		end
	end)

	out.Checkpoints = checkpoints
	out.KillParts = kills
end

---------------------------------------------------------------------------
-- VIP ROOM (west)
---------------------------------------------------------------------------
local function buildVip(map, out)
	local folder = create("Folder", { Name = "VIP" }, map)
	local cx = -95
	local wall = { Color = COLORS.VipWall, Material = Enum.Material.SmoothPlastic }

	local function wallPart(name, size, cframe)
		return block(folder, { Name = name, Size = size, CFrame = cframe, Color = wall.Color, Material = wall.Material })
	end

	block(folder, {
		Name = "VipFloor",
		Size = Vector3.new(40, 0.4, 40),
		CFrame = CFrame.new(cx, 0.2, 0),
		Color = COLORS.Gold,
		Material = Enum.Material.Marble,
	})
	wallPart("WestWall", Vector3.new(1, 14, 40), CFrame.new(cx - 20, 7, 0))
	wallPart("NorthWall", Vector3.new(40, 14, 1), CFrame.new(cx, 7, -20))
	wallPart("SouthWall", Vector3.new(40, 14, 1), CFrame.new(cx, 7, 20))
	wallPart("EastWallA", Vector3.new(1, 14, 16), CFrame.new(cx + 20, 7, -12))
	wallPart("EastWallB", Vector3.new(1, 14, 16), CFrame.new(cx + 20, 7, 12))
	wallPart("Lintel", Vector3.new(1, 4, 8), CFrame.new(cx + 20, 12, 0))
	local roof = wallPart("Roof", Vector3.new(42, 1, 42), CFrame.new(cx, 14.5, 0))
	create("PointLight", { Brightness = 2, Range = 40, Color = COLORS.Gold }, roof)

	-- The client makes this door passable for VIP owners only.
	out.VipDoor = block(folder, {
		Name = "VIPDoor",
		Size = Vector3.new(1, 10, 8),
		CFrame = CFrame.new(cx + 20, 5, 0),
		Color = COLORS.Gold,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	})

	sign(folder, "⭐ VIP ONLY ⭐\nBuy VIP in the shop", Vector3.new(cx + 21, 18, 0), Vector3.new(0, 18, 0), Vector3.new(16, 5, 0.6), COLORS.VipWall)

	out.VipZone = zone(folder, "VipZone", CFrame.new(cx, 7, 0), Vector3.new(40, 14, 40))
	out.VipCoinZone = zone(folder, "VipCoinZone", CFrame.new(cx, 0.4, 0), Vector3.new(32, 0.4, 32))
end

---------------------------------------------------------------------------
-- SHOP (north)
---------------------------------------------------------------------------
local function buildShop(map, out)
	local folder = create("Folder", { Name = "Shop" }, map)

	block(folder, {
		Name = "ShopFloor",
		Size = Vector3.new(104, 0.4, 26),
		CFrame = CFrame.new(0, 0.2, 72),
		Color = Color3.fromRGB(245, 230, 200),
		Material = Enum.Material.WoodPlanks,
	})
	sign(folder, "🛒 SHOP", Vector3.new(0, 14, 84), Vector3.new(0, 14, 0), Vector3.new(30, 6, 0.6), COLORS.Gold)

	local items = {}
	for key, pass in Config.GamePasses do
		table.insert(items, { Kind = "GamePass", Key = key, Cfg = pass })
	end
	for key, product in Config.DevProducts do
		table.insert(items, { Kind = "Product", Key = key, Cfg = product })
	end
	table.sort(items, function(a, b)
		if a.Kind ~= b.Kind then
			return a.Kind == "GamePass"
		end
		return (a.Cfg.Order or 0) < (b.Cfg.Order or 0)
	end)

	local spacing = 11
	local startX = -(#items - 1) * spacing / 2
	out.ShopPads = {}

	for i, item in items do
		local x = startX + (i - 1) * spacing
		local pad = block(folder, {
			Name = item.Key .. "Pad",
			Size = Vector3.new(6, 0.6, 6),
			CFrame = CFrame.new(x, 0.7, 70),
			Color = if item.Kind == "GamePass" then COLORS.Gold else COLORS.Product,
			Material = Enum.Material.Neon,
		})
		pad:SetAttribute("Kind", item.Kind)
		pad:SetAttribute("Key", item.Key)
		create("ProximityPrompt", {
			ActionText = "Buy",
			ObjectText = item.Cfg.Name,
			HoldDuration = 0,
			MaxActivationDistance = 10,
			RequiresLineOfSight = false,
		}, pad)

		local _, label = sign(
			folder,
			Config.FormatShopText(item.Cfg, item.Cfg.PriceHint),
			Vector3.new(x, 5, 78),
			Vector3.new(x, 5, 0),
			Vector3.new(10, 6, 0.5),
			if item.Kind == "GamePass" then Color3.fromRGB(70, 50, 10) else Color3.fromRGB(15, 35, 70)
		)
		table.insert(out.ShopPads, { Pad = pad, Label = label, Kind = item.Kind, Key = item.Key })
	end
end

---------------------------------------------------------------------------
-- COIN FIELD (south)
---------------------------------------------------------------------------
local function buildCoinField(map, out)
	local folder = create("Folder", { Name = "CoinField" }, map)
	block(folder, {
		Name = "FieldFloor",
		Size = Vector3.new(110, 0.4, 60),
		CFrame = CFrame.new(0, 0.2, -95),
		Color = Color3.fromRGB(230, 210, 140),
		Material = Enum.Material.Sand,
	})
	sign(folder, "💰 COIN FIELD 💰", Vector3.new(0, 8, -62), Vector3.new(0, 8, 0), Vector3.new(20, 5, 0.5), COLORS.Gold)
	out.CoinFieldZone = zone(folder, "CoinFieldZone", CFrame.new(0, 0.4, -95), Vector3.new(100, 0.4, 50))
end

---------------------------------------------------------------------------
-- DECORATION
---------------------------------------------------------------------------
local function buildTrees(map)
	local folder = create("Folder", { Name = "Trees" }, map)
	local rng = Random.new(1337)
	local placed = 0
	while placed < 60 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(140, 330)
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		if not (x > 40 and math.abs(z) < 60) then -- keep the area under the obby clear
			placed += 1
			local height = rng:NextNumber(8, 16)
			local tree = create("Model", { Name = "Tree" }, folder)
			block(tree, {
				Name = "Trunk",
				Size = Vector3.new(2, height, 2),
				CFrame = CFrame.new(x, height / 2, z),
				Color = COLORS.Wood,
				Material = Enum.Material.Wood,
			})
			local leafSize = rng:NextNumber(8, 13)
			block(tree, {
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(leafSize, leafSize, leafSize),
				CFrame = CFrame.new(x, height + leafSize * 0.3, z),
				Color = COLORS.Leaves,
				Material = Enum.Material.Grass,
			})
		end
	end
end

---------------------------------------------------------------------------
function MapBuilder.Build()
	local old = Workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	if Config.RemoveDefaultBaseplate then
		local baseplate = Workspace:FindFirstChild("Baseplate")
		if baseplate then
			baseplate:Destroy()
		end
	end

	Lighting.ClockTime = 14
	Lighting.Brightness = 2

	local map = Instance.new("Folder")
	map.Name = "Map"

	local out = { Folder = map }
	buildGround(map)
	buildHub(map, out)
	buildObby(map, out)
	buildVip(map, out)
	buildShop(map, out)
	buildCoinField(map, out)
	buildTrees(map)

	map.Parent = Workspace
	return out
end

return MapBuilder
