local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function get(name, className)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

Remotes.Notify = get("Notify", "RemoteEvent")

function Remotes.NotifyPlayer(player, text)
	Remotes.Notify:FireClient(player, text)
end

function Remotes.NotifyAll(text)
	Remotes.Notify:FireAllClients(text)
end

return Remotes
