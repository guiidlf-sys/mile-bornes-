local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent:WaitForChild("UI")
local LobbyUI = require(UI:WaitForChild("LobbyUI"))
local GameUI = require(UI:WaitForChild("GameUI"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MilleBornesUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local ToServer = Remotes.ToServer()
local ToClient = Remotes.ToClient()

local function sendAction(payload)
	ToServer:FireServer(payload)
end

local lobbyUI = LobbyUI.new(screenGui, sendAction)
local gameUI = GameUI.new(screenGui, localPlayer.UserId, sendAction)

lobbyUI:Show()

ToClient.OnClientEvent:Connect(function(message)
	if typeof(message) ~= "table" then
		return
	end

	if message.type == "LobbyState" then
		gameUI:Hide()
		lobbyUI:Show()
		lobbyUI:Update(message.payload, localPlayer.UserId)
	elseif message.type == "MatchState" then
		lobbyUI:Hide()
		gameUI:Show()
		gameUI:Update(message.payload)
	elseif message.type == "MatchOver" then
		gameUI:ShowGameOver(message.payload)
	elseif message.type == "Notice" then
		gameUI:ShowNotice(message.payload.message)
	end
end)
