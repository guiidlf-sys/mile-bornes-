--!strict
-- Creates (server) or fetches (client) the two RemoteEvents used for all
-- client<->server traffic. Kept to a minimal surface: one event in each
-- direction, carrying a typed payload table, to keep networking simple.
--
-- Only the server is allowed to create these instances. If the client also
-- tried to create-on-missing, a client running before the server's Remotes
-- folder has replicated down to it would end up creating its own local,
-- disconnected copy — a RemoteEvent nobody on the server is listening to,
-- so every FireServer call would silently go nowhere. The client instead
-- blocks on WaitForChild until the server's real instances arrive.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local function getEvent(folder: Folder, name: string): RemoteEvent
	if RunService:IsServer() then
		local event = folder:FindFirstChild(name)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
		return event :: RemoteEvent
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.ToServer(): RemoteEvent
	local folder = getFolder()
	return getEvent(folder, "ToServer")
end

function Remotes.ToClient(): RemoteEvent
	local folder = getFolder()
	return getEvent(folder, "ToClient")
end

return Remotes
