-- Boots the Mille Bornes game server.

local Modules = script.Parent:WaitForChild("Modules")
local GameManager = require(Modules:WaitForChild("GameManager"))
local MapBuilder = require(Modules:WaitForChild("MapBuilder"))

MapBuilder.Build()
GameManager.Init()
