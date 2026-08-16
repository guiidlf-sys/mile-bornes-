--!strict
-- Creates (server) or fetches (client) the two RemoteEvents used for all
-- client<->server traffic. Kept to a minimal surface: one event in each
-- direction, carrying a typed payload table, to keep networking simple.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getOrCreateFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder :: Folder
end

local function getOrCreateEvent(folder: Folder, name: string): RemoteEvent
	local event = folder:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
	end
	return event :: RemoteEvent
end

function Remotes.ToServer(): RemoteEvent
	local folder = getOrCreateFolder()
	return getOrCreateEvent(folder, "ToServer")
end

function Remotes.ToClient(): RemoteEvent
	local folder = getOrCreateFolder()
	return getOrCreateEvent(folder, "ToClient")
end

return Remotes
