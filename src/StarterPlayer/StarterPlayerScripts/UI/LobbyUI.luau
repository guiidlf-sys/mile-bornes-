local Theme = require(script.Parent:WaitForChild("Theme"))
local Widgets = require(script.Parent:WaitForChild("Widgets"))

local LobbyUI = {}
LobbyUI.__index = LobbyUI

function LobbyUI.new(parent: Instance, sendAction)
	local self = setmetatable({}, LobbyUI)
	self.sendAction = sendAction

	local root = Instance.new("Frame")
	root.Name = "Lobby"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Theme.Background
	root.Parent = parent
	self.root = root

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 500, 0, 60)
	title.Position = UDim2.new(0.5, -250, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "MILLE BORNES"
	title.Font = Theme.FontBold
	title.TextColor3 = Theme.Accent
	title.TextSize = 44
	title.Parent = root

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0, 500, 0, 30)
	subtitle.Position = UDim2.new(0.5, -250, 0, 100)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Premier à 1000 km. 2 à 4 joueurs."
	subtitle.Font = Theme.Font
	subtitle.TextColor3 = Theme.SubText
	subtitle.TextSize = 18
	subtitle.Parent = root

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 420, 0, 380)
	panel.Position = UDim2.new(0.5, -210, 0, 150)
	panel.BackgroundColor3 = Theme.Panel
	Theme.RoundCorner(panel, 14)
	Theme.Pad(panel, 18)
	panel.Parent = root

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = panel

	local header = Widgets.MakeLabel("Joueurs en attente", UDim2.new(1, 0, 0, 24), 18, true)
	header.LayoutOrder = 1
	header.Parent = panel

	local playerListFrame = Instance.new("Frame")
	playerListFrame.Size = UDim2.new(1, 0, 0, 160)
	playerListFrame.BackgroundTransparency = 1
	playerListFrame.LayoutOrder = 2
	playerListFrame.Parent = panel
	local playerLayout = Instance.new("UIListLayout")
	playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerLayout.Padding = UDim.new(0, 4)
	playerLayout.Parent = playerListFrame
	self.playerListFrame = playerListFrame

	local statusLabel = Widgets.MakeLabel("", UDim2.new(1, 0, 0, 24), 15, false)
	statusLabel.LayoutOrder = 3
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextColor3 = Theme.Accent
	statusLabel.Parent = panel
	self.statusLabel = statusLabel

	local readyButton = Widgets.MakeButton("PRÊT", UDim2.new(1, 0, 0, 46))
	readyButton.LayoutOrder = 4
	readyButton.BackgroundColor3 = Theme.Good
	readyButton.Parent = panel
	self.readyButton = readyButton
	self.isReady = false

	readyButton.MouseButton1Click:Connect(function()
		self.sendAction({ action = "ToggleReady" })
	end)

	local botRow = Instance.new("Frame")
	botRow.Size = UDim2.new(1, 0, 0, 40)
	botRow.BackgroundTransparency = 1
	botRow.LayoutOrder = 5
	botRow.Parent = panel
	local botRowLayout = Instance.new("UIListLayout")
	botRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	botRowLayout.FillDirection = Enum.FillDirection.Horizontal
	botRowLayout.Padding = UDim.new(0, 8)
	botRowLayout.Parent = botRow

	local addBotButton = Widgets.MakeButton("+ AJOUTER BOT", UDim2.new(0.5, -4, 1, 0))
	addBotButton.LayoutOrder = 1
	addBotButton.Parent = botRow
	addBotButton.MouseButton1Click:Connect(function()
		self.sendAction({ action = "AddBot" })
	end)

	local removeBotButton = Widgets.MakeButton("− RETIRER BOT", UDim2.new(0.5, -4, 1, 0))
	removeBotButton.LayoutOrder = 2
	removeBotButton.Parent = botRow
	removeBotButton.MouseButton1Click:Connect(function()
		self.sendAction({ action = "RemoveBot" })
	end)

	local hint = Widgets.MakeLabel("Pas assez de joueurs ? Ajoutez des bots pour tester seul.", UDim2.new(1, 0, 0, 18), 12, false)
	hint.LayoutOrder = 6
	hint.TextColor3 = Theme.SubText
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Parent = panel

	return self
end

function LobbyUI:Show()
	self.root.Visible = true
end

function LobbyUI:Hide()
	self.root.Visible = false
end

function LobbyUI:Update(state, localUserId: number)
	for _, child in ipairs(self.playerListFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	for i, p in ipairs(state.players) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i
		row.Parent = self.playerListFrame

		local name = Widgets.MakeLabel(p.name, UDim2.new(0.7, 0, 1, 0), 16, false)
		name.Parent = row

		local ready = Widgets.MakeLabel(p.ready and "✓ Prêt" or "En attente", UDim2.new(0.3, 0, 1, 0), 14, true)
		ready.Position = UDim2.new(0.7, 0, 0, 0)
		ready.TextColor3 = p.ready and Theme.Good or Theme.SubText
		ready.Parent = row

		if p.userId == localUserId then
			self.isReady = p.ready
			self.readyButton.Text = p.ready and "ANNULER" or "PRÊT"
			self.readyButton.BackgroundColor3 = p.ready and Theme.Bad or Theme.Good
		end
	end

	local status
	if state.matchInProgress then
		status = "Une partie est en cours — vous rejoindrez la prochaine."
	elseif state.countdown then
		status = string.format("Début dans %d s…", math.ceil(state.countdown))
	else
		status = string.format("%d/%d prêts (minimum %d joueurs)", state.readyCount, #state.players, state.minPlayers)
	end
	self.statusLabel.Text = status
end

return LobbyUI
