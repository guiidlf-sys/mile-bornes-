local Theme = require(script.Parent:WaitForChild("Theme"))
local Widgets = require(script.Parent:WaitForChild("Widgets"))

local GameUI = {}
GameUI.__index = GameUI

local HAZARD_NAMES = {
	Accident = "Accident",
	OutOfGas = "Panne d'essence",
	FlatTire = "Crevaison",
	SpeedLimit = "Limite de vitesse",
	Stop = "Stop",
}

local SAFETY_LABELS = {
	DrivingAce = "As du volant",
	ExtraTank = "Réservoir",
	PunctureProof = "Increvable",
	RightOfWay = "Priorité",
}

local function clearChildren(instance: Instance)
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function GameUI.new(parent: Instance, localUserId: number, sendAction)
	local self = setmetatable({}, GameUI)
	self.localUserId = localUserId
	self.sendAction = sendAction
	self.selectedCardId = nil :: string?
	self.selectedTargetUserId = nil :: number?

	local root = Instance.new("Frame")
	root.Name = "Game"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Theme.Background
	root.Visible = false
	root.Parent = parent
	self.root = root

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, -20, 0, 44)
	topBar.Position = UDim2.new(0, 10, 0, 10)
	topBar.BackgroundColor3 = Theme.Panel
	Theme.RoundCorner(topBar, 10)
	Theme.Pad(topBar, 8)
	topBar.Parent = root
	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.Padding = UDim.new(0, 20)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Parent = topBar

	self.turnLabel = Widgets.MakeLabel("", UDim2.new(0, 340, 1, 0), 18, true)
	self.turnLabel.LayoutOrder = 1
	self.turnLabel.Parent = topBar

	self.deckLabel = Widgets.MakeLabel("", UDim2.new(0, 160, 1, 0), 15, false)
	self.deckLabel.LayoutOrder = 2
	self.deckLabel.Parent = topBar

	self.targetLabel = Widgets.MakeLabel("", UDim2.new(0, 200, 1, 0), 15, false)
	self.targetLabel.LayoutOrder = 3
	self.targetLabel.Parent = topBar

	-- Opponents strip
	local opponentsFrame = Instance.new("Frame")
	opponentsFrame.Size = UDim2.new(1, -20, 0, 128)
	opponentsFrame.Position = UDim2.new(0, 10, 0, 62)
	opponentsFrame.BackgroundTransparency = 1
	opponentsFrame.Parent = root
	local opponentsLayout = Instance.new("UIListLayout")
	opponentsLayout.FillDirection = Enum.FillDirection.Horizontal
	opponentsLayout.Padding = UDim.new(0, 10)
	opponentsLayout.Parent = opponentsFrame
	self.opponentsFrame = opponentsFrame

	-- Log feed
	local logFrame = Instance.new("ScrollingFrame")
	logFrame.Size = UDim2.new(0, 260, 0, 178)
	logFrame.Position = UDim2.new(1, -270, 0, 200)
	logFrame.BackgroundColor3 = Theme.Panel
	logFrame.BorderSizePixel = 0
	logFrame.ScrollBarThickness = 6
	logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Theme.RoundCorner(logFrame, 10)
	Theme.Pad(logFrame, 8)
	logFrame.Parent = root
	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 2)
	logLayout.Parent = logFrame
	self.logFrame = logFrame

	-- Local player board
	local myBoard = Instance.new("Frame")
	myBoard.Size = UDim2.new(1, -300, 0, 178)
	myBoard.Position = UDim2.new(0, 10, 0, 200)
	myBoard.BackgroundColor3 = Theme.Panel
	Theme.RoundCorner(myBoard, 10)
	Theme.Pad(myBoard, 10)
	myBoard.Parent = root
	self.myBoard = myBoard

	-- Hand
	local handFrame = Instance.new("ScrollingFrame")
	handFrame.Size = UDim2.new(1, -20, 0, 150)
	handFrame.Position = UDim2.new(0, 10, 1, -230)
	handFrame.BackgroundColor3 = Theme.Panel
	handFrame.BorderSizePixel = 0
	handFrame.ScrollBarThickness = 8
	handFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	handFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	Theme.RoundCorner(handFrame, 10)
	Theme.Pad(handFrame, 10)
	handFrame.Parent = root
	local handLayout = Instance.new("UIListLayout")
	handLayout.FillDirection = Enum.FillDirection.Horizontal
	handLayout.Padding = UDim.new(0, 8)
	handLayout.Parent = handFrame
	self.handFrame = handFrame

	-- Action bar
	local actionBar = Instance.new("Frame")
	actionBar.Size = UDim2.new(1, -20, 0, 64)
	actionBar.Position = UDim2.new(0, 10, 1, -68)
	actionBar.BackgroundColor3 = Theme.Panel
	Theme.RoundCorner(actionBar, 10)
	Theme.Pad(actionBar, 10)
	actionBar.Parent = root
	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.Padding = UDim.new(0, 10)
	actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actionLayout.Parent = actionBar
	self.actionBar = actionBar

	self.playButton = Widgets.MakeButton("JOUER", UDim2.new(0, 140, 0, 44))
	self.playButton.LayoutOrder = 1
	self.playButton.BackgroundColor3 = Theme.Good
	self.playButton.Parent = actionBar
	self.playButton.MouseButton1Click:Connect(function()
		self:_confirmPlay()
	end)

	self.discardButton = Widgets.MakeButton("DÉFAUSSER", UDim2.new(0, 140, 0, 44))
	self.discardButton.LayoutOrder = 2
	self.discardButton.BackgroundColor3 = Theme.Bad
	self.discardButton.Parent = actionBar
	self.discardButton.MouseButton1Click:Connect(function()
		self:_confirmDiscard()
	end)

	self.hintLabel = Widgets.MakeLabel("Sélectionnez une carte.", UDim2.new(0, 500, 1, 0), 15, false)
	self.hintLabel.LayoutOrder = 3
	self.hintLabel.TextColor3 = Theme.SubText
	self.hintLabel.Parent = actionBar

	local targetRow = Instance.new("Frame")
	targetRow.Size = UDim2.new(0, 400, 1, 0)
	targetRow.BackgroundTransparency = 1
	targetRow.LayoutOrder = 4
	targetRow.Parent = actionBar
	local targetLayout = Instance.new("UIListLayout")
	targetLayout.FillDirection = Enum.FillDirection.Horizontal
	targetLayout.Padding = UDim.new(0, 6)
	targetLayout.Parent = targetRow
	self.targetRow = targetRow

	-- Toast
	local toast = Widgets.MakeLabel("", UDim2.new(0, 500, 0, 30), 15, true)
	toast.Position = UDim2.new(0.5, -250, 0, 400)
	toast.AnchorPoint = Vector2.new(0, 0)
	toast.TextXAlignment = Enum.TextXAlignment.Center
	toast.BackgroundColor3 = Theme.Panel
	toast.BackgroundTransparency = 1
	toast.TextColor3 = Theme.Accent
	toast.Visible = false
	toast.ZIndex = 50
	toast.Parent = root
	self.toast = toast

	-- Coup fourré modal
	local cf = Instance.new("Frame")
	cf.Size = UDim2.new(0, 420, 0, 180)
	cf.Position = UDim2.new(0.5, -210, 0.5, -90)
	cf.BackgroundColor3 = Theme.Panel
	cf.Visible = false
	cf.ZIndex = 100
	Theme.RoundCorner(cf, 14)
	Theme.Stroke(cf, Theme.Accent, 2)
	Theme.Pad(cf, 16)
	cf.Parent = root
	self.coupFourreModal = cf

	local cfLayout = Instance.new("UIListLayout")
	cfLayout.Padding = UDim.new(0, 10)
	cfLayout.Parent = cf

	self.cfLabel = Widgets.MakeLabel("", UDim2.new(1, 0, 0, 70), 17, true)
	self.cfLabel.TextWrapped = true
	self.cfLabel.LayoutOrder = 1
	self.cfLabel.Parent = cf

	local cfButtons = Instance.new("Frame")
	cfButtons.Size = UDim2.new(1, 0, 0, 46)
	cfButtons.BackgroundTransparency = 1
	cfButtons.LayoutOrder = 2
	cfButtons.Parent = cf
	local cfButtonsLayout = Instance.new("UIListLayout")
	cfButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
	cfButtonsLayout.Padding = UDim.new(0, 10)
	cfButtonsLayout.Parent = cfButtons

	local cfAccept = Widgets.MakeButton("RIPOSTER !", UDim2.new(0, 180, 1, 0))
	cfAccept.BackgroundColor3 = Theme.Good
	cfAccept.Parent = cfButtons
	cfAccept.MouseButton1Click:Connect(function()
		self.sendAction({ action = "RespondCoupFourre", accept = true })
	end)

	local cfDecline = Widgets.MakeButton("IGNORER", UDim2.new(0, 180, 1, 0))
	cfDecline.BackgroundColor3 = Theme.Bad
	cfDecline.Parent = cfButtons
	cfDecline.MouseButton1Click:Connect(function()
		self.sendAction({ action = "RespondCoupFourre", accept = false })
	end)

	-- Game over overlay
	local over = Instance.new("Frame")
	over.Size = UDim2.fromScale(1, 1)
	over.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	over.BackgroundTransparency = 0.35
	over.Visible = false
	over.ZIndex = 200
	over.Parent = root
	self.gameOverOverlay = over

	local overPanel = Instance.new("Frame")
	overPanel.Size = UDim2.new(0, 460, 0, 380)
	overPanel.Position = UDim2.new(0.5, -230, 0.5, -190)
	overPanel.BackgroundColor3 = Theme.Panel
	overPanel.ZIndex = 201
	Theme.RoundCorner(overPanel, 14)
	Theme.Pad(overPanel, 18)
	overPanel.Parent = over
	local overLayout = Instance.new("UIListLayout")
	overLayout.Padding = UDim.new(0, 6)
	overLayout.Parent = overPanel

	local overTitle = Widgets.MakeLabel("PARTIE TERMINÉE", UDim2.new(1, 0, 0, 30), 22, true)
	overTitle.ZIndex = 201
	overTitle.TextXAlignment = Enum.TextXAlignment.Center
	overTitle.TextColor3 = Theme.Accent
	overTitle.LayoutOrder = 1
	overTitle.Parent = overPanel

	local scoresFrame = Instance.new("Frame")
	scoresFrame.Size = UDim2.new(1, 0, 0, 260)
	scoresFrame.BackgroundTransparency = 1
	scoresFrame.LayoutOrder = 2
	scoresFrame.ZIndex = 201
	scoresFrame.Parent = overPanel
	local scoresLayout = Instance.new("UIListLayout")
	scoresLayout.Padding = UDim.new(0, 4)
	scoresLayout.Parent = scoresFrame
	self.scoresFrame = scoresFrame

	local returnLabel = Widgets.MakeLabel("Retour au lobby dans quelques secondes…", UDim2.new(1, 0, 0, 24), 14, false)
	returnLabel.ZIndex = 201
	returnLabel.TextColor3 = Theme.SubText
	returnLabel.TextXAlignment = Enum.TextXAlignment.Center
	returnLabel.LayoutOrder = 3
	returnLabel.Parent = overPanel

	return self
end

function GameUI:Show()
	self.root.Visible = true
end

function GameUI:Hide()
	self.root.Visible = false
	self.gameOverOverlay.Visible = false
end

function GameUI:ShowNotice(message: string)
	self.toast.Text = message
	self.toast.Visible = true
	self.toast.BackgroundTransparency = 1
	local id = (self._toastId or 0) + 1
	self._toastId = id
	task.delay(3, function()
		if self._toastId == id then
			self.toast.Visible = false
		end
	end)
end

local function statusText(player)
	if player.stopped then
		return "STOP", Theme.Bad
	elseif player.speedLimited then
		return "LIMITÉ 50", Color3.fromRGB(210, 150, 40)
	else
		return "EN ROUTE", Theme.Good
	end
end

local function battleText(player)
	if player.hazard then
		return HAZARD_NAMES[player.hazard] or player.hazard, Theme.Bad
	end
	return "OK", Theme.Good
end

function GameUI:_findLocalPlayer(state)
	for _, p in ipairs(state.players) do
		if p.userId == self.localUserId then
			return p
		end
	end
	return nil
end

function GameUI:_buildSafetyRow(parent, player, layoutOrder: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = row

	for _, key in ipairs({ "DrivingAce", "ExtraTank", "PunctureProof", "RightOfWay" }) do
		local owned = player.safeties[key] == true
		local chip = Widgets.MakeLabel(SAFETY_LABELS[key], UDim2.new(0.25, -5, 1, 0), 10, true)
		chip.TextXAlignment = Enum.TextXAlignment.Center
		chip.TextScaled = false
		chip.TextWrapped = true
		chip.BackgroundTransparency = 0
		chip.BackgroundColor3 = owned and Theme.Accent or Theme.PanelLight
		chip.TextColor3 = owned and Color3.fromRGB(30, 30, 30) or Theme.SubText
		Theme.RoundCorner(chip, 6)
		chip.Parent = row
	end
end

function GameUI:_buildBoardHeader(parent, player, layoutOrder: number, big: boolean)
	local displayName = player.name .. (player.connected == false and " (déconnecté)" or "")
	local speed, speedColor = statusText(player)
	local battle, battleColor = battleText(player)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, big and 40 or 44)
	header.BackgroundTransparency = 1
	header.LayoutOrder = layoutOrder
	header.Parent = parent

	if big then
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 10)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = header

		local nameLabel = Widgets.MakeLabel(displayName, UDim2.new(0, 200, 1, 0), 18, true)
		nameLabel.Parent = header

		local distLabel = Widgets.MakeLabel(player.distanceTotal .. " km", UDim2.new(0, 110, 1, 0), 18, true)
		distLabel.TextColor3 = Theme.Accent
		distLabel.Parent = header

		local speedLabel = Widgets.MakeLabel(speed, UDim2.new(0, 110, 1, 0), 14, true)
		speedLabel.TextColor3 = speedColor
		speedLabel.Parent = header

		local battleLabel = Widgets.MakeLabel(battle, UDim2.new(0, 160, 1, 0), 14, true)
		battleLabel.TextColor3 = battleColor
		battleLabel.Parent = header
	else
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 2)
		layout.Parent = header

		local row1 = Instance.new("Frame")
		row1.Size = UDim2.new(1, 0, 0, 20)
		row1.BackgroundTransparency = 1
		row1.LayoutOrder = 1
		row1.Parent = header
		local nameLabel = Widgets.MakeLabel(displayName, UDim2.new(0.65, 0, 1, 0), 14, true)
		nameLabel.Parent = row1
		local distLabel = Widgets.MakeLabel(player.distanceTotal .. " km", UDim2.new(0.35, 0, 1, 0), 14, true)
		distLabel.TextColor3 = Theme.Accent
		distLabel.TextXAlignment = Enum.TextXAlignment.Right
		distLabel.Parent = row1

		local row2 = Instance.new("Frame")
		row2.Size = UDim2.new(1, 0, 0, 18)
		row2.BackgroundTransparency = 1
		row2.LayoutOrder = 2
		row2.Parent = header
		local speedLabel = Widgets.MakeLabel(speed, UDim2.new(0.4, 0, 1, 0), 11, true)
		speedLabel.TextColor3 = speedColor
		speedLabel.Parent = row2
		local battleLabel = Widgets.MakeLabel(battle, UDim2.new(0.6, 0, 1, 0), 11, true)
		battleLabel.TextColor3 = battleColor
		battleLabel.TextXAlignment = Enum.TextXAlignment.Right
		battleLabel.Parent = row2
	end
end

function GameUI:Update(state)
	local localPlayer = self:_findLocalPlayer(state)
	if not localPlayer then
		return
	end

	local isMyTurn = state.activeUserId == self.localUserId and state.pendingCoupFourre == nil
	local activeName = "?"
	for _, p in ipairs(state.players) do
		if p.userId == state.activeUserId then
			activeName = p.name
		end
	end
	self.turnLabel.Text = isMyTurn and "★ À VOUS DE JOUER" or ("Tour de " .. activeName)
	self.turnLabel.TextColor3 = isMyTurn and Theme.Good or Theme.Text
	self.deckLabel.Text = "Pioche : " .. state.deckCount
	self.targetLabel.Text = "Objectif : " .. state.targetDistance .. " km"

	-- Opponents
	clearChildren(self.opponentsFrame)
	local order = 0
	for _, p in ipairs(state.players) do
		if p.userId ~= self.localUserId then
			order += 1
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0, 240, 1, 0)
			card.BackgroundColor3 = Theme.Panel
			card.LayoutOrder = order
			Theme.RoundCorner(card, 10)
			Theme.Pad(card, 8)
			card.Parent = self.opponentsFrame
			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 4)
			layout.Parent = card
			self:_buildBoardHeader(card, p, 1, false)
			self:_buildSafetyRow(card, p, 2)
			local handLabel = Widgets.MakeLabel("Main : " .. p.handCount .. " cartes", UDim2.new(1, 0, 0, 18), 12, false)
			handLabel.LayoutOrder = 3
			handLabel.TextColor3 = Theme.SubText
			handLabel.Parent = card
		end
	end

	-- Log
	clearChildren(self.logFrame)
	for i, entry in ipairs(state.log) do
		local label = Widgets.MakeLabel(entry, UDim2.new(1, 0, 0, 0), 12, false)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextWrapped = true
		label.LayoutOrder = i
		label.TextColor3 = Theme.SubText
		label.Parent = self.logFrame
	end

	-- My board
	clearChildren(self.myBoard)
	local myLayout = Instance.new("UIListLayout")
	myLayout.Padding = UDim.new(0, 6)
	myLayout.Parent = self.myBoard
	self:_buildBoardHeader(self.myBoard, localPlayer, 1, true)
	self:_buildSafetyRow(self.myBoard, localPlayer, 2)

	-- Hand
	clearChildren(self.handFrame)
	local hand = localPlayer.hand or {}
	for i, card in ipairs(hand) do
		local widget = Widgets.MakeCard(card)
		widget.LayoutOrder = i
		widget.Parent = self.handFrame
		if card.id == self.selectedCardId then
			Theme.Stroke(widget, Theme.Accent, 3)
		end
		widget.MouseButton1Click:Connect(function()
			if self.selectedCardId == card.id then
				self.selectedCardId = nil
			else
				self.selectedCardId = card.id
			end
			self.selectedTargetUserId = nil
			self:Update(self._lastState)
		end)
	end

	-- Action bar / targets
	clearChildren(self.targetRow)
	local selectedCard = nil
	for _, c in ipairs(hand) do
		if c.id == self.selectedCardId then
			selectedCard = c
		end
	end

	local needsTarget = selectedCard ~= nil and selectedCard.kind == "Hazard"
	if needsTarget then
		local i = 0
		for _, p in ipairs(state.players) do
			if p.userId ~= self.localUserId then
				i += 1
				local btn = Widgets.MakeButton(p.name, UDim2.new(0, 110, 1, 0))
				btn.LayoutOrder = i
				btn.BackgroundColor3 = (self.selectedTargetUserId == p.userId) and Theme.Accent or Theme.PanelLight
				btn.Parent = self.targetRow
				btn.MouseButton1Click:Connect(function()
					self.selectedTargetUserId = p.userId
					self:Update(self._lastState)
				end)
			end
		end
	end

	local canAct = isMyTurn and selectedCard ~= nil and (not needsTarget or self.selectedTargetUserId ~= nil)
	self.playButton.BackgroundColor3 = canAct and Theme.Good or Theme.PanelLight
	self.discardButton.BackgroundColor3 = isMyTurn and selectedCard ~= nil and Theme.Bad or Theme.PanelLight
	self._canPlay = canAct
	self._canDiscard = isMyTurn and selectedCard ~= nil

	if not isMyTurn then
		self.hintLabel.Text = state.pendingCoupFourre and "Un Coup Fourré est possible…" or "En attente de votre tour."
	elseif not selectedCard then
		self.hintLabel.Text = "Sélectionnez une carte dans votre main."
	elseif needsTarget and not self.selectedTargetUserId then
		self.hintLabel.Text = "Choisissez une cible pour cette carte."
	else
		self.hintLabel.Text = "Prêt à jouer " .. selectedCard.name .. "."
	end

	-- Coup fourré modal
	if state.pendingCoupFourre and state.pendingCoupFourre.targetUserId == self.localUserId then
		self.coupFourreModal.Visible = true
		self.cfLabel.Text = "Vous êtes touché par : " .. (HAZARD_NAMES[state.pendingCoupFourre.hazardType] or "")
			.. "\nJouez votre carte Sécurité maintenant pour un Coup Fourré (+300 points) !"
	else
		self.coupFourreModal.Visible = false
	end

	self._lastState = state
end

function GameUI:_confirmPlay()
	if not self._canPlay or not self.selectedCardId then
		return
	end
	self.sendAction({ action = "PlayCard", cardId = self.selectedCardId, targetUserId = self.selectedTargetUserId })
	self.selectedCardId = nil
	self.selectedTargetUserId = nil
end

function GameUI:_confirmDiscard()
	if not self._canDiscard or not self.selectedCardId then
		return
	end
	self.sendAction({ action = "Discard", cardId = self.selectedCardId })
	self.selectedCardId = nil
	self.selectedTargetUserId = nil
end

function GameUI:ShowGameOver(payload)
	self.gameOverOverlay.Visible = true
	clearChildren(self.scoresFrame)
	for i, s in ipairs(payload.scores) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.ZIndex = 201
		row.LayoutOrder = i
		row.Parent = self.scoresFrame
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 10)
		layout.Parent = row

		local rank = Widgets.MakeLabel((s.isWinner and "🏆 " or (i .. ". ")) .. s.name, UDim2.new(0, 200, 1, 0), 16, s.isWinner)
		rank.ZIndex = 201
		rank.TextColor3 = s.isWinner and Theme.Accent or Theme.Text
		rank.Parent = row

		local detail = Widgets.MakeLabel(
			string.format("%d km + %d = %d pts", s.distance, s.bonus, s.total),
			UDim2.new(0, 240, 1, 0),
			14,
			false
		)
		detail.ZIndex = 201
		detail.TextColor3 = Theme.SubText
		detail.Parent = row
	end
end

function GameUI:HideGameOver()
	self.gameOverOverlay.Visible = false
end

return GameUI
