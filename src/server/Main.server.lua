-- Server entry point.

local Server = script.Parent

local Remotes = require(Server.Remotes) -- creates ReplicatedStorage.Remotes first
local MapBuilder = require(Server.MapBuilder)
local DataService = require(Server.DataService)
local ObbyService = require(Server.ObbyService)
local CoinService = require(Server.CoinService)
local MonetizationService = require(Server.MonetizationService)
local RewardService = require(Server.RewardService)

local _ = Remotes

local map = MapBuilder.Build()

DataService.Init()
ObbyService.Init(map)
CoinService.Init(map)
MonetizationService.Init(map)
RewardService.Init(map)

print("[MoneyMap] Server ready")
