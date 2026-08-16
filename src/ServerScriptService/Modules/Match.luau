-- Match.luau
-- Authoritative server-side state machine for a single Mille Bornes game.
-- One Match instance manages 2-4 players from deal to scoring.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardData = require(Shared:WaitForChild("CardData"))
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local Shuffle = require(script.Parent:WaitForChild("Shuffle"))

local Match = {}
Match.__index = Match

local function newPlayerState(userId: number, name: string, isBot: boolean)
	return {
		userId = userId,
		name = name,
		isBot = isBot,
		connected = true,
		hand = {},
		distancePile = {},
		battlePile = {},
		speedPile = {},
		safeties = { DrivingAce = false, ExtraTank = false, PunctureProof = false, RightOfWay = false },
		distanceTotal = 0,
		stopped = true,
		speedLimited = false,
		hazard = nil,
		bonusScore = 0,
		coupFourreCount = 0,
	}
end

function Match.new(playerEntries, onBroadcast, onFinished)
	local self = setmetatable({}, Match)

	self.players = {}
	for _, entry in ipairs(playerEntries) do
		table.insert(self.players, newPlayerState(entry.userId, entry.name, entry.isBot == true))
	end

	self.turnIndex = 1
	self.activeUserId = nil :: number?
	self.deck = {}
	self.discard = {}
	self.targetDistance = GameConstants.TARGET_DISTANCE
	self.phase = "InProgress"
	self.pendingCoupFourre = nil
	self.winnerUserId = nil :: number?
	self.log = {}
	self.consecutivePasses = 0

	self.onBroadcast = onBroadcast
	self.onFinished = onFinished

	return self
end

function Match:AddLog(message: string)
	table.insert(self.log, message)
	while #self.log > GameConstants.MAX_LOG_ENTRIES do
		table.remove(self.log, 1)
	end
end

function Match:GetPlayer(userId: number)
	for _, p in ipairs(self.players) do
		if p.userId == userId then
			return p
		end
	end
	return nil
end

function Match:Start()
	self.deck = Shuffle.ShuffleInPlace(CardData.BuildDeck())
	for _, player in ipairs(self.players) do
		for _ = 1, GameConstants.HAND_SIZE do
			local card = table.remove(self.deck)
			if card then
				table.insert(player.hand, card)
			end
		end
	end
	self:AddLog("La partie commence ! Objectif : " .. self.targetDistance .. " km.")
	self:StartTurn(self.players[self.turnIndex].userId)
end

-- ===== Turn flow =====

function Match:StartTurn(userId: number)
	self.activeUserId = userId

	local player = self:GetPlayer(userId)
	if not player then
		return
	end

	if not player.connected then
		local anyoneConnected = false
		for _, p in ipairs(self.players) do
			if p.connected then
				anyoneConnected = true
				break
			end
		end
		if not anyoneConnected then
			self:FinishMatch(nil)
			return
		end
		self:EndAction(player, false)
		return
	end

	if #self.deck > 0 and #player.hand < (GameConstants.HAND_SIZE + 1) then
		local card = table.remove(self.deck)
		table.insert(player.hand, card)
	end

	if #player.hand == 0 then
		self:HandleEmptyHandPass(player)
		return
	end

	self:Broadcast()

	if player.isBot then
		task.delay(0.8, function()
			if self.phase == "InProgress" and self.activeUserId == userId and self.pendingCoupFourre == nil then
				self:BotTakeTurn(player)
			end
		end)
	end
end

function Match:HandleEmptyHandPass(player)
	self.consecutivePasses += 1
	self:AddLog(player.name .. " ne peut pas jouer (aucune carte).")
	if self.consecutivePasses >= #self.players then
		self:FinishMatch(nil)
		return
	end
	self:AdvanceAndStartNextTurn()
end

function Match:AdvanceAndStartNextTurn()
	self.turnIndex = (self.turnIndex % #self.players) + 1
	self:StartTurn(self.players[self.turnIndex].userId)
end

-- Called after a play/discard resolves. wasSafety grants the player an
-- immediate extra turn per the official rules.
function Match:EndAction(player, wasSafety: boolean)
	if self.phase == "Finished" then
		return
	end
	self.consecutivePasses = 0
	if wasSafety then
		self:StartTurn(player.userId)
	else
		self:AdvanceAndStartNextTurn()
	end
end

-- ===== Rules =====

local function findCardIndex(hand, cardId: string): number?
	for i, c in ipairs(hand) do
		if c.id == cardId then
			return i
		end
	end
	return nil
end

function Match:CanPlayDistance(player, card): (boolean, string?)
	if player.hazard ~= nil then
		return false, "Votre voiture est immobilisée."
	end
	if player.stopped and not player.safeties.RightOfWay then
		return false, "Vous devez d'abord jouer une carte Bornes."
	end
	if player.speedLimited and not player.safeties.RightOfWay and card.value > GameConstants.SPEED_LIMIT_CAP then
		return false, "Limite de vitesse : 50 km maximum."
	end
	if player.distanceTotal + card.value > self.targetDistance then
		return false, "Cette carte dépasserait l'objectif de " .. self.targetDistance .. " km."
	end
	return true
end

function Match:CanPlayRemedy(player, card): (boolean, string?)
	local rt = card.remedyType
	if rt == "Repairs" then
		if player.hazard ~= "Accident" then
			return false, "Aucun accident à réparer."
		end
	elseif rt == "Gasoline" then
		if player.hazard ~= "OutOfGas" then
			return false, "Vous n'êtes pas en panne d'essence."
		end
	elseif rt == "SpareTire" then
		if player.hazard ~= "FlatTire" then
			return false, "Aucune crevaison à réparer."
		end
	elseif rt == "EndOfLimit" then
		if not player.speedLimited then
			return false, "Aucune limite de vitesse en vigueur."
		end
	elseif rt == "Go" then
		if not player.stopped then
			return false, "Vous roulez déjà."
		end
	end
	return true
end

function Match:CanPlayHazard(target, card): (boolean, string?)
	local ht = card.hazardType
	if ht == "Stop" or ht == "SpeedLimit" then
		if target.stopped then
			return false, "La cible est déjà arrêtée."
		end
		if target.safeties.RightOfWay then
			return false, "La cible a la Priorité (immunisée)."
		end
		if ht == "SpeedLimit" and target.speedLimited then
			return false, "La cible est déjà limitée en vitesse."
		end
	else
		-- Accident / OutOfGas / FlatTire
		if target.stopped then
			return false, "La cible est arrêtée."
		end
		if target.hazard ~= nil then
			return false, "La cible a déjà un problème."
		end
		local protectingSafety = nil
		for safetyType, hazardType in pairs(CardData.SafetyProtects) do
			if hazardType == ht and safetyType ~= "RightOfWay" then
				protectingSafety = safetyType
			end
		end
		if protectingSafety and target.safeties[protectingSafety] then
			return false, "La cible est immunisée."
		end
	end
	return true
end

-- ===== Bot AI =====
-- Simple heuristic, no lookahead: advance if possible, else fix a problem,
-- else play a held safety, else attack an opponent, else discard.

function Match:BotTakeTurn(player)
	if self.phase ~= "InProgress" or self.activeUserId ~= player.userId then
		return
	end
	if #player.hand == 0 then
		return
	end

	local bestDistance = nil
	for _, c in ipairs(player.hand) do
		if c.kind == "Distance" then
			local ok = self:CanPlayDistance(player, c)
			if ok and (not bestDistance or c.value > bestDistance.value) then
				bestDistance = c
			end
		end
	end
	if bestDistance then
		self:TryPlayCard(player, bestDistance.id, nil)
		return
	end

	for _, c in ipairs(player.hand) do
		if c.kind == "Remedy" then
			local ok = self:CanPlayRemedy(player, c)
			if ok then
				self:TryPlayCard(player, c.id, nil)
				return
			end
		end
	end

	for _, c in ipairs(player.hand) do
		if c.kind == "Safety" and not player.safeties[c.safetyType] then
			self:TryPlayCard(player, c.id, nil)
			return
		end
	end

	for _, c in ipairs(player.hand) do
		if c.kind == "Hazard" then
			local targets = {}
			for _, opp in ipairs(self.players) do
				if opp.userId ~= player.userId then
					local ok = self:CanPlayHazard(opp, c)
					if ok then
						table.insert(targets, opp)
					end
				end
			end
			if #targets > 0 then
				local target = targets[math.random(1, #targets)]
				self:TryPlayCard(player, c.id, target.userId)
				return
			end
		end
	end

	self:TryDiscard(player, player.hand[1].id)
end

-- ===== Actions =====

function Match:HandleAction(userId: number, payload)
	if self.phase == "Finished" then
		return
	end

	if payload.action == "RespondCoupFourre" then
		self:ResolveCoupFourreResponse(userId, payload.accept == true)
		return
	end

	if self.pendingCoupFourre ~= nil then
		-- A coup fourré window is open; only the RespondCoupFourre action (handled above) is valid.
		return
	end
	if self.activeUserId ~= userId then
		return
	end

	local player = self:GetPlayer(userId)
	if not player then
		return
	end

	if payload.action == "PlayCard" then
		self:TryPlayCard(player, payload.cardId, payload.targetUserId)
	elseif payload.action == "Discard" then
		self:TryDiscard(player, payload.cardId)
	end
end

function Match:TryPlayCard(player, cardId: string, targetUserId: number?)
	local idx = findCardIndex(player.hand, cardId)
	if not idx then
		return
	end
	local card = player.hand[idx]

	if card.kind == "Distance" then
		local ok, reason = self:CanPlayDistance(player, card)
		if not ok then
			self:Whisper(player.userId, reason)
			return
		end
		table.remove(player.hand, idx)
		table.insert(player.distancePile, card)
		player.distanceTotal += card.value
		self:AddLog(player.name .. " avance de " .. card.value .. " km (" .. player.distanceTotal .. " km).")
		if player.distanceTotal >= self.targetDistance then
			self:FinishMatch(player.userId)
			return
		end
		self:EndAction(player, false)
	elseif card.kind == "Remedy" then
		local ok, reason = self:CanPlayRemedy(player, card)
		if not ok then
			self:Whisper(player.userId, reason)
			return
		end
		table.remove(player.hand, idx)
		local rt = card.remedyType
		if rt == "Go" then
			player.stopped = false
			table.insert(player.speedPile, card)
		elseif rt == "EndOfLimit" then
			player.speedLimited = false
			table.insert(player.speedPile, card)
		else
			player.hazard = nil
			table.insert(player.battlePile, card)
		end
		self:AddLog(player.name .. " joue " .. card.name .. ".")
		self:EndAction(player, false)
	elseif card.kind == "Safety" then
		table.remove(player.hand, idx)
		self:ApplySafety(player, card)
		self:AddLog(player.name .. " joue une carte Sécurité : " .. card.name .. " (tour supplémentaire).")
		self:EndAction(player, true)
	elseif card.kind == "Hazard" then
		if not targetUserId then
			self:Whisper(player.userId, "Choisissez une cible.")
			return
		end
		local target = self:GetPlayer(targetUserId)
		if not target or target.userId == player.userId then
			return
		end
		local ok, reason = self:CanPlayHazard(target, card)
		if not ok then
			self:Whisper(player.userId, reason)
			return
		end
		table.remove(player.hand, idx)
		local ht = card.hazardType
		if ht == "Stop" then
			target.stopped = true
			table.insert(target.speedPile, card)
		elseif ht == "SpeedLimit" then
			target.speedLimited = true
			table.insert(target.speedPile, card)
		else
			target.hazard = ht
			table.insert(target.battlePile, card)
		end
		self:AddLog(player.name .. " joue " .. card.name .. " contre " .. target.name .. " !")

		local matchingSafety = self:FindMatchingSafetyInHand(target, ht)
		if matchingSafety then
			self:OpenCoupFourreWindow(target.userId, ht)
		else
			self:EndAction(player, false)
		end
	end
end

function Match:FindMatchingSafetyInHand(player, hazardType): string?
	for _, c in ipairs(player.hand) do
		if c.kind == "Safety" then
			local protects = CardData.SafetyProtects[c.safetyType]
			if protects == hazardType or (c.safetyType == "RightOfWay" and hazardType == "SpeedLimit") then
				return c.id
			end
		end
	end
	return nil
end

function Match:ApplySafety(player, card)
	local st = card.safetyType
	player.safeties[st] = true
	if st == "RightOfWay" then
		player.stopped = false
		player.speedLimited = false
	else
		local protects = CardData.SafetyProtects[st]
		if player.hazard == protects then
			player.hazard = nil
		end
	end
end

function Match:TryDiscard(player, cardId: string)
	local idx = findCardIndex(player.hand, cardId)
	if not idx then
		return
	end
	local card = table.remove(player.hand, idx)
	table.insert(self.discard, card)
	self:AddLog(player.name .. " défausse une carte.")
	self:EndAction(player, false)
end

-- ===== Coup Fourré =====

function Match:OpenCoupFourreWindow(targetUserId: number, hazardType)
	self.pendingCoupFourre = {
		targetUserId = targetUserId,
		hazardType = hazardType,
		expiresAt = os.clock() + GameConstants.COUP_FOURRE_WINDOW_SECONDS,
	}
	local token = self.pendingCoupFourre
	self:Broadcast()

	local target = self:GetPlayer(targetUserId)
	if target and target.isBot then
		task.delay(0.8, function()
			if self.pendingCoupFourre == token then
				self:ResolveCoupFourreResponse(targetUserId, true)
			end
		end)
		return
	end

	task.delay(GameConstants.COUP_FOURRE_WINDOW_SECONDS, function()
		if self.pendingCoupFourre == token then
			self:ResolveCoupFourreResponse(targetUserId, false)
		end
	end)
end

function Match:ResolveCoupFourreResponse(userId: number, accept: boolean)
	local info = self.pendingCoupFourre
	if not info or info.targetUserId ~= userId then
		return
	end
	self.pendingCoupFourre = nil

	local player = self:GetPlayer(userId)
	if not player then
		return
	end

	if accept then
		local cardId = self:FindMatchingSafetyInHand(player, info.hazardType)
		if cardId then
			local idx = findCardIndex(player.hand, cardId)
			local card = table.remove(player.hand, idx)
			self:ApplySafety(player, card)
			player.bonusScore += GameConstants.SCORE_COUP_FOURRE
			player.coupFourreCount += 1
			self:AddLog(player.name .. " réplique par un Coup Fourré avec " .. card.name .. " ! (+300)")
			self:StartTurn(player.userId)
			return
		end
	end

	-- Declined, timed out, or card no longer available.
	self:AdvanceAndStartNextTurn()
end

-- ===== Scoring / finish =====

function Match:ComputeScore(player, winnerUserId: number?)
	local base = player.distanceTotal
	local bonus = player.bonusScore

	local safetyCount = 0
	for _, owned in pairs(player.safeties) do
		if owned then
			safetyCount += 1
		end
	end
	bonus += safetyCount * GameConstants.SCORE_PER_SAFETY
	if safetyCount == 4 then
		bonus += GameConstants.SCORE_ALL_SAFETIES_BONUS
	end

	if winnerUserId and player.userId == winnerUserId then
		bonus += GameConstants.SCORE_TRIP_COMPLETED
		local shutout = true
		for _, p in ipairs(self.players) do
			if p.userId ~= winnerUserId and p.distanceTotal > 0 then
				shutout = false
				break
			end
		end
		if shutout then
			bonus += GameConstants.SCORE_SHUTOUT
		end
	end

	return base + bonus, { base = base, bonus = bonus, safetyCount = safetyCount }
end

function Match:FinishMatch(winnerUserId: number?)
	self.phase = "Finished"
	self.activeUserId = nil

	if not winnerUserId then
		local best, bestDist = nil, -1
		for _, p in ipairs(self.players) do
			if p.distanceTotal > bestDist then
				best, bestDist = p.userId, p.distanceTotal
			end
		end
		winnerUserId = best
	end
	self.winnerUserId = winnerUserId

	local scores = {}
	for _, p in ipairs(self.players) do
		local total, breakdown = self:ComputeScore(p, winnerUserId)
		table.insert(scores, {
			userId = p.userId,
			name = p.name,
			total = total,
			distance = breakdown.base,
			bonus = breakdown.bonus,
			safetyCount = breakdown.safetyCount,
			isWinner = p.userId == winnerUserId,
		})
	end
	table.sort(scores, function(a, b)
		return a.total > b.total
	end)

	local winnerName = "?"
	for _, p in ipairs(self.players) do
		if p.userId == winnerUserId then
			winnerName = p.name
		end
	end
	self:AddLog(winnerName .. " remporte la partie !")

	self:Broadcast()
	if self.onFinished then
		self.onFinished(scores)
	end
end

-- ===== Networking =====

function Match:SetConnected(userId: number, connected: boolean)
	local player = self:GetPlayer(userId)
	if player then
		player.connected = connected
	end
end

function Match:Whisper(userId: number, message: string?)
	if not message then
		return
	end
	if self.onBroadcast then
		self.onBroadcast(self, userId, message)
	end
end

function Match:Serialize(forUserId: number)
	local players = {}
	for _, p in ipairs(self.players) do
		table.insert(players, {
			userId = p.userId,
			name = p.name,
			connected = p.connected,
			handCount = #p.hand,
			hand = (p.userId == forUserId) and p.hand or nil,
			distancePile = p.distancePile,
			battlePile = p.battlePile,
			speedPile = p.speedPile,
			safeties = p.safeties,
			distanceTotal = p.distanceTotal,
			stopped = p.stopped,
			speedLimited = p.speedLimited,
			hazard = p.hazard,
		})
	end

	return {
		phase = self.phase,
		targetDistance = self.targetDistance,
		activeUserId = self.activeUserId,
		pendingCoupFourre = self.pendingCoupFourre,
		deckCount = #self.deck,
		discardTop = self.discard[#self.discard],
		winnerUserId = self.winnerUserId,
		players = players,
		log = self.log,
	}
end

function Match:Broadcast()
	if self.onBroadcast then
		self.onBroadcast(self, nil, nil)
	end
end

return Match
