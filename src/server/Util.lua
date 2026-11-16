local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Util = {}

-- Returns player, character, humanoid if `part` belongs to a living player's character.
function Util.PlayerFromPart(part)
	local current = part.Parent
	while current and current ~= Workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				local humanoid = current:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return player, current, humanoid
				end
				return nil
			end
		end
		current = current.Parent
	end
	return nil
end

function Util.Teleport(player, cframe)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(cframe)
end

function Util.IsInside(position, part)
	local rel = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end

function Util.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

return Util
