-- GameManager.luau
-- Owns the lobby (ready-up / countdown) and the single active Match on this
-- server, and routes the two shared RemoteEvents to the right place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Match = require(script.Parent:WaitForChild("Match"))

local ToServer = Remotes.ToServer()
local ToClient = Remotes.ToClient()

local GameManager = {}

local lobbyReady: { [number]: boolean } = {}
local lobbyOrder: { number } = {}
local currentMatch = nil

-- Bots use negative synthetic IDs so they never collide with a real Roblox
-- UserId, letting one person fill an otherwise-empty lobby to test a match.
local botNames: { [number]: string } = {}
local nextBotId = -1

local countdownEndsAt: number? = nil
local countdownToken = 0

-- Forward declarations: startMatch and checkStartConditions call each other,
-- and onFinished (created inside startMatch) needs to call checkStartConditions
-- once a match hands its players back to the lobby.
local startMatch
local checkStartConditions

local function playerName(userId: number): string
	if botNames[userId] then
		return botNames[userId]
	end
	local plr = Players:GetPlayerByUserId(userId)
	return plr and plr.Name or "Joueur"
end

local function sendTo(userId: number, msgType: string, payload)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		ToClient:FireClient(plr, { type = msgType, payload = payload })
	end
end

local function removeFromLobby(userId: number)
	for i, v in ipairs(lobbyOrder) do
		if v == userId then
			table.remove(lobbyOrder, i)
			break
		end
	end
	lobbyReady[userId] = nil
end

local function broadcastLobby()
	local playersInfo = {}
	local readyCount = 0
	for _, uid in ipairs(lobbyOrder) do
		local ready = lobbyReady[uid] == true
		if ready then
			readyCount += 1
		end
		table.insert(playersInfo, { userId = uid, name = playerName(uid), ready = ready })
	end
	local countdown = nil
	if countdownEndsAt then
		countdown = math.max(0, countdownEndsAt - os.clock())
	end
	local payload = {
		players = playersInfo,
		readyCount = readyCount,
		countdown = countdown,
		minPlayers = GameConstants.MIN_PLAYERS,
		maxPlayers = GameConstants.MAX_PLAYERS,
		matchInProgress = currentMatch ~= nil,
	}
	for _, uid in ipairs(lobbyOrder) do
		sendTo(uid, "LobbyState", payload)
	end
end

startMatch = function()
	local selected = {}
	local remaining = {}
	for _, uid in ipairs(lobbyOrder) do
		if lobbyReady[uid] and #selected < GameConstants.MAX_PLAYERS then
			table.insert(selected, uid)
		else
			table.insert(remaining, uid)
		end
	end
	if #selected < GameConstants.MIN_PLAYERS then
		return
	end

	lobbyOrder = remaining

	local entries = {}
	for _, uid in ipairs(selected) do
		table.insert(entries, { userId = uid, name = playerName(uid), isBot = uid < 0 })
	end

	local function onBroadcast(match, whisperUserId: number?, whisperMessage: string?)
		if whisperUserId and whisperMessage then
			sendTo(whisperUserId, "Notice", { message = whisperMessage })
			return
		end
		for _, p in ipairs(match.players) do
			sendTo(p.userId, "MatchState", match:Serialize(p.userId))
		end
	end

	local function onFinished(scores)
		for _, p in ipairs(currentMatch.players) do
			sendTo(p.userId, "MatchOver", { scores = scores })
		end
		task.delay(8, function()
			local finished = currentMatch
			currentMatch = nil
			for _, p in ipairs(finished.players) do
				if p.userId < 0 or Players:GetPlayerByUserId(p.userId) then
					table.insert(lobbyOrder, p.userId)
					lobbyReady[p.userId] = false
				end
			end
			broadcastLobby()
			checkStartConditions()
		end)
	end

	currentMatch = Match.new(entries, onBroadcast, onFinished)
	broadcastLobby() -- let remaining lobby players know a match has started
	currentMatch:Start()
end

local function cancelCountdown()
	countdownEndsAt = nil
	countdownToken += 1
end

checkStartConditions = function()
	if currentMatch then
		return
	end
	local readyCount = 0
	for _, uid in ipairs(lobbyOrder) do
		if lobbyReady[uid] then
			readyCount += 1
		end
	end

	if readyCount >= GameConstants.MIN_PLAYERS then
		if not countdownEndsAt then
			countdownEndsAt = os.clock() + GameConstants.LOBBY_COUNTDOWN_SECONDS
			countdownToken += 1
			local myToken = countdownToken
			task.spawn(function()
				while countdownToken == myToken and countdownEndsAt and os.clock() < countdownEndsAt do
					broadcastLobby()
					task.wait(1)
				end
				if countdownToken == myToken and countdownEndsAt then
					countdownEndsAt = nil
					startMatch()
				end
			end)
		end
	else
		if countdownEndsAt then
			cancelCountdown()
			broadcastLobby()
		end
	end
end

local function onPlayerAdded(player: Player)
	local uid = player.UserId
	lobbyReady[uid] = false
	table.insert(lobbyOrder, uid)
	broadcastLobby()
end

local function onPlayerRemoving(player: Player)
	local uid = player.UserId
	removeFromLobby(uid)

	if currentMatch then
		currentMatch:SetConnected(uid, false)
		if currentMatch.phase == "InProgress" then
			if currentMatch.activeUserId == uid then
				currentMatch:AdvanceAndStartNextTurn()
			end
			local connectedCount = 0
			for _, p in ipairs(currentMatch.players) do
				if p.connected then
					connectedCount += 1
				end
			end
			if connectedCount < GameConstants.MIN_PLAYERS then
				currentMatch:FinishMatch(nil)
			end
		end
	end

	cancelCountdown()
	broadcastLobby()
	checkStartConditions()
end

function GameManager.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	ToServer.OnServerEvent:Connect(function(player: Player, payload)
		if typeof(payload) ~= "table" then
			return
		end
		local uid = player.UserId

		if payload.action == "ToggleReady" then
			if currentMatch then
				return
			end
			lobbyReady[uid] = not lobbyReady[uid]
			broadcastLobby()
			checkStartConditions()
		elseif payload.action == "AddBot" then
			if currentMatch or #lobbyOrder >= GameConstants.MAX_PLAYERS then
				return
			end
			local botId = nextBotId
			nextBotId -= 1
			botNames[botId] = "Bot " .. tostring(-botId)
			table.insert(lobbyOrder, botId)
			lobbyReady[botId] = true
			broadcastLobby()
			checkStartConditions()
		elseif payload.action == "RemoveBot" then
			if currentMatch then
				return
			end
			for i = #lobbyOrder, 1, -1 do
				local id = lobbyOrder[i]
				if id < 0 then
					table.remove(lobbyOrder, i)
					lobbyReady[id] = nil
					botNames[id] = nil
					break
				end
			end
			cancelCountdown()
			broadcastLobby()
			checkStartConditions()
		elseif currentMatch then
			currentMatch:HandleAction(uid, payload)
		end
	end)
end

return GameManager
