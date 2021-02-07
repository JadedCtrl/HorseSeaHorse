-- pls set tabs to width of 4 spaces
class	= require "lib/middleclass"
wind	= require "lib/windfield"
stalker	= require "lib/STALKER-X"
bitser	= require "lib/bitser"
sock	= require "lib/sock"

SWORDLENGTH = 40; KNIFELENGTH = 10
SWORDWIDTH = 3
SHIELDWIDTH = 16
SHIELDHEIGHT = 5

MP_PORT = 13371
CHATLOG = {}


-- GAME STATES
--------------------------------------------------------------------------------
-- LOVE
----------------------------------------
function love.load()
	math.randomseed(os.time())

	logMsg(nil, "Starting up...")
	love.graphics.setDefaultFilter("nearest", "nearest")
	a_ttf = love.graphics.newFont("art/font/alagard.ttf", nil, "none")
	r_ttf = love.graphics.newFont("art/font/romulus.ttf", nil, "none")

	love.resize()

	menu_load(makeMainMenu())
end


function love.update(dt)
	updateFunction(dt)
	camera:update(dt)
end


function love.draw()
	camera:attach()
	drawFunction()
	drawLogMsgs()
	camera:detach()
	camera:draw()
end


function love.resize()
	local width,height = love.window.getMode()
	logMsg("[Window]", width .. "x" .. height)
	newCamera()
end


function love.keypressed(key)
	keypressedFunction(key)
end


function love.keyreleased (key)
	keyreleasedFunction(key)
end


-- MENUS
----------------------------------------
function menu_load(menu)
	menu:install()
end


function makeMainMenu()
	return Menu:new(100, 100, 30, 50, 3, {
		{love.graphics.newText(a_ttf, "Local"),
			function () lobby_load(LocalLobby) end},
		{love.graphics.newText(a_ttf, "Net"),
			function () menu_load(makeNetMenu()) end},
		{love.graphics.newText(a_ttf, "Quit"),
			function () love.event.quit(0) end }})
end


function makeNetMenu()
	return Menu:new(100, 100, 30, 50, 3, {
		{love.graphics.newText(a_ttf, "Join"),
			function ()
				local addressBox =
					TextBox:new(100, 100, 3, 99, "192.168.254.51", "Address/Host: ",
						function (text) lobby_load(ClientLobby, text) end)
				addressBox:install()
			end},
		{love.graphics.newText(a_ttf, "Host"),
			function () lobby_load(HostLobby) end},
		{love.graphics.newText(a_ttf, "Back"),
			function () menu_load(makeMainMenu()) end}})
end


-- GAME LOBBY
----------------------------------------
function lobby_load(lobbyClass, arg)
	lobby = lobbyClass:new(arg)
	lobby:install()
end


-- IN-GAME
----------------------------------------
function game_load(game)
	game:install()
end


-- CLASSES
--------------------------------------------------------------------------------
-- Fighter		player class
----------------------------------------
Player = class('Fighter')

function Player:initialize(game, x, y, character, swordType, name)
	self.game = game
	self.name = name
	self.swordType = swordType or 'normal'
	self.character = character or math.random(1, table.maxn(CHARACTERS))

	self.directionals = {}
	self.deadPieces = {}

	self:initBody(x, y)
	self:initSword()
	self:initShield()

	self.id = math.random(1, 20000)
end


function Player:update(dt)
	local dir = self.directionals

	self:movement()
	self:glueSwordAndShield()

	if (dir['left'] == 2 and dir['right'] == 0) then dir['left'] = 1; end
	if (dir['right'] == 2 and dir['left'] == 0) then dir['right'] = 1; end
end


function Player:draw()
	local x,y = self.body:getWorldPoints(self.body.shape:getPoints())

	love.graphics.draw(CHARACTERS[self.character], x, y, self.body:getAngle(),
		1, 1)
end


function Player:movement()
end


function Player:toTable()
	local bx1,by1, bx2,by2, bx3,by3, bx4,by4 = self.body.shape:getPoints()
	local bodyVertices = {bx1,by1, bx2,by2, bx3,by3, bx4,by4}

	local sx1,sy1, sx2,sy2, sx3,sy3, sx4,sy4 = self.sword.shape:getPoints()
	local swordVertices = {sx1,sy1, sy2,sy2, sx3,by3, sx4,by4}

	local mx1,my1, mx2,my2, mx3,my3, mx4,my4 = self.shield.shape:getPoints()
	local shieldVertices = {mx1,my1, my2,my2, mx3,by3, mx4,by4}

	return {["bodyBox"] = bodyVertices, ["bodyAngle"] = self.body:getAngle(),
			["swordBox"] = swordVertices, ["swordAngle"] = self.sword:getAngle(),
			["shieldBox"] = shieldVertices, ["shieldAngle"] = self.shield:getAngle(),
			["bodyX"] = self.body:getX(), ["bodyY"] = self.body:getY(),
			["swordX"] = self.sword:getX(), ["swordY"] = self.sword:getY(),
			["shieldX"] = self.shield:getX(), ["shieldY"] = self.shield:getY(),
			["character"] = self.character, ["name"] = self.name,
			["id"] = self.id}
end


function Player:applyTable(pTable)
	self.body.shape = love.physics.newPolygonShape(pTable["bodyBox"])
	self.body:setAngle(pTable["bodyAngle"])
	self.body:setX(pTable["bodyX"])
	self.body:setY(pTable["bodyY"])

	self.sword.shape = love.physics.newPolygonShape(pTable["swordBox"])
	self.sword:setAngle(pTable["swordAngle"])
	self.sword:setX(pTable["swordX"])
	self.sword:setY(pTable["swordY"])

	self.shield.shape = love.physics.newPolygonShape(pTable["shieldBox"])
	self.shield:setAngle(pTable["shieldAngle"])
	self.shield:setX(pTable["shieldX"])
	self.shield:setY(pTable["shieldY"])

	self.character = pTable["character"]
	self.id = pTable["id"]
	self.name = pTable["name"]
end


function Player:initBody(x, y)
	self.body = self.game.world:newRectangleCollider(x, y, 16, 16);
	self.body:setCollisionClass('Player')
	self.body:setObject(self)
	self.body:setAngularDamping(2)
	self.body:setLinearDamping(.5)
	self.body:setPostSolve(self.makePostSolve())
end


function Player:initShield()
	self.shield = self.game.world:newRectangleCollider(0, 0, 20, 5);
	self.shield:setCollisionClass('Shield')
	self.shield:setObject(self)
end


function Player:initSword()
	self.swordLength = SWORDLENGTH 

	if (self.swordType == 'normal') then
		self.sword = self.game.world:newRectangleCollider(0, 0, 3, self.swordLength);
	else
		self.sword = self.game.world:newRectangleCollider(0, 0, 3, KNIFELENGTH);
	end
	self.sword:setCollisionClass('Sword')
	self.sword:setObject(self)
	self.sword:setPostSolve(self:makeSwordPostSolve())
end


function Player:glueSwordAndShield()
	local x, y = self.body:getPosition()
	local angle = self.body:getAngle()

	self.shield:setAngle(angle)
	self.shield:setPosition(x - (math.sin(angle) * 16),
		y + (math.cos(angle) * 16))

	if (self.swordType == 'normal') then
		local offset = self.swordLength - 10
		self.sword:setAngle(angle)
		self.sword:setPosition(x + (math.sin(angle) * offset),
			y - (math.cos(angle) * offset))

	elseif (self.swordType == 'knife') then
		local offset = self.swordLength * 2
		self.sword:setAngle(angle)
		self.sword:setPosition(x + (math.sin(angle) * 4.5 * offset),
			y - (math.cos(angle) * 1.5 * offset))
	end
end


function Player:makePostSolve()
	return function(col1, col2, contact)
		if (col1.collision_class == "Player"
			and col2.collision_class == "Sword")
		then
--			print(col2.shape)
--			print("THEY DEEED, dude")
		end
	end
end


function Player:makeSwordPostSolve()
	return function(col1, col2, contact)
		if (col1.collision_class == "Sword"
			and col2.collision_class == "Shield")
		then
--			print("SWORD CLASH!!!!")
		end
	end
end


-- LocalPlayer	for local players (ofc)
----------------------------------------
LocalPlayer = class("LocalPlayer", Player)

function LocalPlayer:initialize(game, x, y, keymap, character, swordType, name)
	self.keymap = keymap or KEYMAPS[1]
	Player.initialize(self, game, x, y, character, swordType, name)
end


function LocalPlayer:movement()
	local x, y = self.body:getPosition()
	local dir = self.directionals
	local angle = self.body:getAngle()

	if (dir['left'] == 1) then
		self.body:applyAngularImpulse(-.5, 1)
	elseif (dir['right'] == 1) then
		self.body:applyAngularImpulse(.5, 1)
	end

	if (dir['up'] == 1) then
   		self.body:applyLinearImpulse(math.sin(angle) * 0.5, math.cos(angle) * -0.5)
	elseif (dir['down'] == 1) then
		self.body:setAngle(angle - (math.pi * .70))
		self.body:applyAngularImpulse(-45, 1)
		dir['down'] = 0
	end
end


function LocalPlayer:keypressed(key)
	local dir = self.directionals

	if (key == self.keymap["right"]) then
		dir['right'] = 1
		if (dir['left'] == 1) then dir['left'] = 2; end

	elseif (key == self.keymap["left"]) then
		dir['left'] = 1
		if (dir['right'] == 1) then dir['right'] = 2; end

	elseif (key == self.keymap["accel"]) then
		dir['up'] = 1
		if (dir['down'] == 1) then dir['down'] = 2; end

	elseif (key == self.keymap["flip"]) then
		dir['down'] = 1
		if (dir['up'] == 1) then dir['up'] = 2; end
	end	
end


function LocalPlayer:keyreleased(key)
	local dir = self.directionals

	if (key == self.keymap["right"]) then
		dir['right'] = 0

	elseif (key == self.keymap["left"]) then
		dir['left'] = 0

	elseif (key == self.keymap["accel"]) then
		dir['up'] = 0

	elseif (key == self.keymap["flip"]) then
		dir['down'] = 0
	end
end


-- NetPlayer	for network players
----------------------------------------
NetPlayer = class("NetPlayer", Player)

function NetPlayer:initialize(ptable, game)
	Player.initialize(self, game, 0, 0, 1, 'normal', "sldkfj")

	self:applyTable(ptable)
end


-- HostPlayer	for from-server players
----------------------------------------
HostPlayer = class("HostPlayer", NetPlayer)

function HostPlayer:intialize(ptable, game)
	NetPlayer.initialize(self, ptable, game)
end


-- ClientPlayer	for from-client players
----------------------------------------
ClientPlayer = class("ClientPlayer", NetPlayer)

function ClientPlayer:intialize(ptable, game)
	NetPlayer.initialize(self, ptable, game)
end


-- GAME superclass for matches
----------------------------------------
Game = class("Game")

function Game:initialize(lobbiests)
	self.world = wind.newWorld(0, 0, true)
	self.world:addCollisionClass('Player')
	self.world:addCollisionClass('Shield')
	self.world:addCollisionClass('Sword')

	self.localPlayers = {}
	self.localPlayersN = 0

	self:addLobbiests(lobbiests)
end


function Game:install(update, draw, press, release)
	hookInstall(function (dt) self:update(dt) end,
		function () self:draw() end,
		function (key) self:keypressed(key) end,
		function (key) self:keyreleased(key) end,
		update, draw, press, release)
end


function Game:update(dt)
	self.world:update(dt)

	for k,player in pairs(self:players()) do
		player:update(dt)
	end
end


function Game:draw()
	self.world:draw()
	for k,player in pairs(self:players()) do
		player:draw()
	end
end


function Game:keypressed(key)
	local dir = self.localPlayers[1].directionals

	-- if a player presses the left key, then holds the right key, they should
	-- go right until they let go, then they should go left.
	if (key == "=" and camera.scale < 10) then
		camera.scale = camera.scale + .5
	elseif (key == "-" and camera.scale > .5) then
		camera.scale = camera.scale - .5

	elseif (key == "t") then
		local chatbox = TextBox:new(10,770, 2, 99, nil, nil,
			function (text)
				self:sendChat(text)
				self:install()
			end)
		chatbox:install(false, drawFunction, nil, false)

	elseif (key == "escape") then
		menu_load(makeMainMenu())
	else
		for i, player in pairs(self.localPlayers) do
			player:keypressed(key)
		end
	end
end


function Game:keyreleased (key)
	for i, player in pairs(self.localPlayers) do
		player:keyreleased(key)
	end
end


function Game:players()
	return self.localPlayers
end


function Game:sendChat(message)
	local author = "AGhost"
	if (self.localPlayersN > 0) then
		author = self.localPlayers[1].name
	end
	logMsg(author, message)
	return author,message
end


function Game:addLobbiests(localLobbiests)
	for k,lobbiest in pairs(localLobbiests) do
		local i = self.localPlayersN + 1
		self.localPlayers[i] = LocalPlayer:new(self, 0 + i * 50, 0 + i * 50,
			KEYMAPS[i], lobbiest.character, lobbiest.swordType, lobbiest.name)
		self.localPlayersN = i
	end
end


-- NETGAME superclass for online matches
----------------------------------------
NetGame = class("NetGame", Game)

function NetGame:initialize(localLobbiests, sock)
	self.remotePlayers = {}
	self.remotePlayersN = 0
	self.sock = sock

	Game.initialize(self, localLobbiests)
	self:sockCallbacks()
end


function NetGame:sockCallbacks()
	self.sock:on("newPlayers",
		function(playerTables, client)
			self:addNewPlayers(playerTables, client)
		end)
	self.sock:on("playerPing",
		function(playerTables, client)
			self:receivePlayers(playerTables, client)
		end)
end


function NetGame:update(dt)
	Game.update(self, dt)
	self:sendPlayers()
	self.sock:update()
end


function NetGame:players()
	local players = {}
	table.foreach(self.localPlayers,
		function(k, v)	table.insert(players, v) end)
	table.foreach(self.remotePlayers,
		function(k, v)	table.insert(players, v) end)
	return players
end


function NetGame:receivePlayers(playerTables, client)
	for i,ptable in pairs(playerTables) do
		local id = ptable["id"]
		if (self.remotePlayers[id] == nil) then
			self:addNewPlayer(ptable)
		end
		self.remotePlayers[id]:applyTable(ptable)
	end
end


-- HOSTGAME for server matches
----------------------------------------
HostGame = class("HostGame", NetGame)

function HostGame:initialize(localLobbiests, server)
	NetGame.initialize(self, localLobbiests, server)

	self.sock:sendToAll("newGame", nil)
end


function HostGame:sockCallbacks()
	NetGame.sockCallbacks(self)
end


function HostGame:sendChat(message)
	local author,text = Game.sendChat(self, message)
	self.sock:sendToAll("chat", {["author"] = author, ["text"] = text})
end


function HostGame:addNewPlayer(ptable)
	self.remotePlayersN = self.remotePlayersN + 1
	self.remotePlayers[ptable["id"]] = ClientPlayer:new(ptable, self)
end


function HostGame:sendPlayers()
	local ptables = {}

	for i,player in pairs(self.localPlayers) do
		table.insert(ptables, player:toTable())
	end

	self.sock:sendToAll("playerPing", ptables)
end


function HostGame:receivePlayers(playerTables, client)
	NetGame.receivePlayers(self, playerTables)
	self.sock:sendToAllBut(client, "playerPing", playerTables)
end


-- CLIENTGAME for client-side matches
----------------------------------------
ClientGame = class("ClientGame", NetGame)

function ClientGame:initialize(localLobbiests, client)
	NetGame.initialize(self, localLobbiests, client)
end


function ClientGame:sendChat(message)
	local author,text = Game.sendChat(self, message)
	self.sock:send("chat", {["author"] = author, ["text"] = text})
end


function ClientGame:sendPlayers()
	local ptables = {}

	for i,player in pairs(self.localPlayers) do
		table.insert(ptables, player:toTable())
	end

	self.sock:send("playerPing", ptables)
end


function ClientGame:addNewPlayer(ptable)
	self.remotePlayersN = self.remotePlayersN + 1
	self.remotePlayers[ptable["id"]] = HostPlayer:new(ptable, self)
end


-- LOBBY superclass for pre-matches
----------------------------------------
Lobby = class("Lobby")

function Lobby:initialize()
	self.localLobbiests = {}
	self.localLobbiestsN = 0
	self.remoteLobbiests = {}
	self.remoteLobbiestsN = 0

	self.ttf = r_ttf
	self.scale = 3
end


function Lobby:draw()
	love.graphics.draw(love.graphics.newText(self.ttf, self.class.name), 10, 10, 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf,
		self:lobbiestsN() .. " players"), 500, 10, 0, self.scale)

	for i,lobbiest in pairs(self:lobbiests()) do
		local rowX = 10
		local rowY = (25 * i) + 50

		love.graphics.draw(CHARACTERS[lobbiest.character], rowX, rowY, 0, 1, 1)
		if (lobbiest.swordType == "normal") then
			love.graphics.rectangle("fill", rowX + 18, rowY + SWORDWIDTH,
				SWORDLENGTH, SWORDWIDTH)
		else
			love.graphics.rectangle("fill", rowX + 18, rowY + SWORDWIDTH,
				KNIFELENGTH, SWORDWIDTH)
		end

		love.graphics.draw(love.graphics.newText(self.ttf, lobbiest.name),
			rowX + SWORDLENGTH + 30, rowY, 0, self.scale)
		love.graphics.draw(love.graphics.newText(self.ttf, lobbiest.class.name),
			rowX + 550, rowY, 0, self.scale)

		if (lobbiest.class.name == "LocalLobbiest") then
			local keymap = lobbiest.keymap
			local text = keymap["accel"] .. " " .. keymap["left"] .. " "
				.. keymap["flip"] .. " " .. keymap["right"]

			love.graphics.draw(love.graphics.newText(self.ttf, text),
				rowX + 350, rowY + 5, 0, self.scale * (2/3))
		end
	end

	local rowX = 470
	local rowY = 500
	love.graphics.draw(love.graphics.newText(self.ttf, "SPACE: Add player"),
		rowX, rowY + (40 * 1), 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "DELETE: Del player"),
		rowX, rowY + (40 * 2), 0, self.scale)

	rowY = 560
	love.graphics.draw(love.graphics.newText(self.ttf, "LEFT: Edit name"),
		rowX, rowY + (40 * 2), 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "RIGHT: Change sprite"),
		rowX, rowY + (40 * 3), 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "ACCEL: Change sword"),
		rowX, rowY + (40 * 4), 0, self.scale)
end


function Lobby:install(update, draw, press, release)
	hookInstall(function (dt) self:update(dt) end,
		function () self:draw() end,
		function (key) self:keypressed(key) end,
		function (key) self:keyreleased(key) end,
		update, draw, press, release)
end


function Lobby:update(dt)
end


function Lobby:keypressed(key)
	if (key == "space" and self.localLobbiestsN < table.maxn(KEYMAPS)) then
		self:newLocalLobbiest()

	elseif (key == "t") then
		local chatbox = TextBox:new(10,770, 2, 99, nil, nil,
			function (text)
				self:sendChat(text)
				self:install()
			end)
		chatbox:install(false, drawFunction, nil, false)
			
	elseif (key == "escape") then
		self:toMainMenu()
	else
		for i,lobbiest in pairs(self.localLobbiests) do
			lobbiest:keypressed(key, self)
		end
	end
end


function Lobby:keyreleased(key)
end


function Lobby:toMainMenu()
	menu_load(makeMainMenu())
end


function Lobby:sendChat(message)
	local author = "AGhost"
	if (self.localLobbiestsN > 0) then
		author = self.localLobbiests[1].name
	end
	logMsg(author, message)
	return author,message
end


function Lobby:newLocalLobbiest()
	local i = self.localLobbiestsN + 1
	self.localLobbiestsN = i

	self.localLobbiests[i] = LocalLobbiest:new(self, nil, KEYMAPS[i])
end


function Lobby:lobbiests()
	local lobbiests = {}
	table.foreach(self.localLobbiests,
		function(k, v)	table.insert(lobbiests, v) end)
	table.foreach(self.remoteLobbiests,
		function(k, v)	table.insert(lobbiests, v) end)
	return lobbiests
end


function Lobby:lobbiestsN()
	return self.remoteLobbiestsN + self.localLobbiestsN
end


function Lobby:localLobbiestTables()
	local lobbiests = {}
	table.foreach(self.localLobbiests,
		function (k, lobbiest)
			table.insert(lobbiests, lobbiest:toTable())
		end)
	return lobbiests	
end




-- LOCAL LOBBY
----------------------------------------
LocalLobby = class("LocalLobby", Lobby)

function LocalLobby:initialize()
	Lobby.initialize(self)
end


function LocalLobby:keypressed(key)
	if (key == "return" and self:lobbiestsN() > 1) then
		game_load(Game:new(self:lobbiests()))
	else
		Lobby.keypressed(self, key)
	end
end


-- NET - NET LOBBY
----------------------------------------
NetLobby = class("NetLobby", Lobby)

function NetLobby:initialize()
	Lobby.initialize(self)
end


function NetLobby:install()
	Lobby.install(self)
	self:sendLobbiests()
end


function NetLobby:update(dt)
	self.sock:update()
end


function NetLobby:keypressed(key)
	Lobby.keypressed(self, key)
	self:sendLobbiests()
end


function NetLobby:sockCallbacks()
	self.sock:on("chat",
		function (chatData, client)
			self:chatReceived(chatData, client)
		end)
	self.sock:on("lobbiests",
		function (localLobbiests, client)
			self:receiveLobbiests(localLobbiests, client)
		end)
end


function NetLobby:chatReceived(chatData, client)
	logMsg(chatData["author"], chatData["text"])
end


-- NET - HOST LOBBY
----------------------------------------
HostLobby = class("HostLobby", NetLobby)

function HostLobby:initialize()
	NetLobby.initialize(self)
	self.sock = sock.newServer("*", MP_PORT)
	self.sock:setSerialization(bitser.dumps, bitser.loads)
	self:sockCallbacks()
end


function HostLobby:sockCallbacks()
	NetLobby.sockCallbacks(self)

	self.sock:on("connect",
		function (data, client)
--			self:sendLobbiests()
--			st
		end)

	self.sock:on("disconnect",
		function (data, client)
			self:removeLobbiestsOfClient(client)
		end)
end


function HostLobby:keypressed(key)
	if (key == "return" and self:lobbiestsN() > 1) then
		game_load(HostGame:new(self.localLobbiests, self.sock))
	else
		Lobby.keypressed(self, key)
	end
end


function HostLobby:toMainMenu()
--	self.sock:destroy()
--	Lobby.toMainMenu(self)
end


function HostLobby:sendChat(message)
	local author,text = Lobby.sendChat(self, message)
	self.sock:sendToAll("chat", {["author"] = author, ["text"] = text})
end


function HostLobby:chatReceived(chatData, client)
	NetLobby.chatReceived(self, chatData)
	self.sock:sendToAllBut(client, "chat", chatData)
end


function HostLobby:sendLobbiests()
	for k,client in pairs(self.sock:getClients()) do
		client:send("lobbiests", self:lobbiestTables(client))
	end
end


function HostLobby:receiveLobbiests(localLobbiestTables, client)
	self:removeLobbiestsOfClient(client)

	for k,lobbiestTable in pairs(localLobbiestTables) do
		table.insert(self.remoteLobbiests,
			ClientLobbiest:new(self, client, lobbiestTable))
		self.remoteLobbiestsN = self.remoteLobbiestsN + 1
	end

	self:sendLobbiests()
end


function HostLobby:newLocalLobbiest()
	Lobby.newLocalLobbiest(self)
	self:sendLobbiests()
end


function HostLobby:removeLobbiestsOfClient(client)
	local lobbiests = {}
	local n = 0

	for k,lobbiest in pairs(self.remoteLobbiests) do
		if not (lobbiest.client == client) then
			table.insert(lobbiests, lobbiest)
			n = n + 1
		end
	end
	self.remoteLobbiests  = lobbiests
	self.remoteLobbiestsN = n
end


function HostLobby:remoteLobbiestTables(client)
	local lobbiests = {}
	table.foreach(self.remoteLobbiests,
		function (k, lobbiest)
			if not (lobbiest.client == client) then
				table.insert(lobbiests, lobbiest:toTable())
			end
		end)
	return lobbiests	
end


function HostLobby:lobbiestTables(client)
	local lobbiests = {}
	table.foreach(self:localLobbiestTables(),
		function(k, v)	table.insert(lobbiests, v) end)
	table.foreach(self:remoteLobbiestTables(client),
		function(k, v)	table.insert(lobbiests, v) end)
	return lobbiests
end


-- NET - CLIENT LOBBY
----------------------------------------
ClientLobby = class("ClientLobby", NetLobby)

function ClientLobby:initialize(address)
	NetLobby.initialize(self)
	self.status = "Connecting..."

	self.sock = sock.newClient(address, MP_PORT)
	self.sock:setSerialization(bitser.dumps, bitser.loads)
	self:sockCallbacks()

	self.sock:connect()
end


function ClientLobby:sockCallbacks()
	NetLobby.sockCallbacks(self)

	self.sock:on("connect",
		function (ignoredData)
			self.status = "Connected!"
			self.sock:send("lobbiests", self:localLobbiestTables())
		end)

	self.sock:on("disconnect",
		function (ignoredData)
			self.status = "Disconnected"
		end)

	self.sock:on("newGame",
		function (data, client)
			game_load(ClientGame:new(self.localLobbiests, self.sock))
		end)
end


function ClientLobby:update(dt)
	self.sock:update()
end


function ClientLobby:draw()
	Lobby.draw(self)
	
	love.graphics.draw(love.graphics.newText(self.ttf, self.status),
		200, 10, 0, self.scale)
end


function ClientLobby:toMainMenu()
	self.sock:disconnect()
	Lobby.toMainMenu(self)
end


function ClientLobby:sendChat(message)
	local author,text = Lobby.sendChat(self, message)
	self.sock:send("chat", {["author"] = author, ["text"] = text})
end


function ClientLobby:sendLobbiests()
	self.sock:send("lobbiests", self:localLobbiestTables())
end


function ClientLobby:receiveLobbiests(remoteLobbiestTables)
	self.remoteLobbiests = {}
	self.remoteLobbiestsN = 0

	for i,lobbiestTable in pairs(remoteLobbiestTables) do
		table.insert(self.remoteLobbiests, HostLobbiest:new(nil, lobbiestTable))
		self.remoteLobbiestsN = self.remoteLobbiestsN + 1
	end
end


function ClientLobby:newLocalLobbiest()
	Lobby.newLocalLobbiest(self)
	self:sendLobbiests()
end


-- LOBBIEST	proposed fighter
----------------------------------------
Lobbiest = class("Lobbiest")

function Lobbiest:initialize(lobby, name)
	self.name = name or NAMES[math.random(1, table.maxn(NAMES))]
	self.character = math.random(1, table.maxn(CHARACTERS))
	self.swordType = "normal"
end


function Lobbiest:toTable()
	return {["name"] = self.name, ["character"] = self.character,
		["swordType"] = self.swordType}
end


-- LOCAL LOBBIEST
----------------------------------------
LocalLobbiest = class("LocalLobbiest", Lobbiest)

function LocalLobbiest:initialize(lobby, name, keymap)
	Lobbiest.initialize(self, lobby, name)
	self.keymap = keymap or KEYMAPS[math.random(1, table.maxn(KEYMAPS))]
end


function LocalLobbiest:keypressed(key, lobby)
	if (key == self.keymap["accel"]) then
		if (self.swordType == "normal")		then self.swordType = "knife"
		elseif (self.swordType == "knife")	then self.swordType = "normal"
		end

	elseif (key == self.keymap["left"]) then
		local textBox = TextBox:new(20, 400, 3, 10, self.name, "Name: ",
			function (text)
				self.name = text
				lobby:install()
			end)

		textBox:install(false, drawFunction, nil, false)

	elseif (key == self.keymap["right"]) then
		if (self.character == table.maxn(CHARACTERS)) then
			self.character = 1
		else
			self.character = self.character + 1
		end
	end
end


function LocalLobbiest:toTable()
	local tablo = Lobbiest.toTable(self)
	tablo["keymap"] = self.keymap
	return tablo
end


-- CLIENT LOBBIEST used by HostLobby
----------------------------------------
ClientLobbiest = class("ClientLobbiest", Lobbiest)

function ClientLobbiest:initialize(lobby, client, lobbiestTable)
	self.client = client

	self.name = lobbiestTable["name"]
	self.keymap = lobbiestTable["keymap"]
	self.swordType = lobbiestTable["swordType"]
	self.character = lobbiestTable["character"]
end


-- HOST LOBBIEST used by ClientLobby
----------------------------------------
HostLobbiest = class("HostLobbiest", Lobbiest)

function HostLobbiest:initialize(lobby, lobbiestTable)
	self.name = lobbiestTable["name"]
	self.swordType = lobbiestTable["swordType"]
	self.character = lobbiestTable["character"]
end


-- MENU	used for creating menus (lol)
----------------------------------------
Menu = class("Menu")
function Menu:initialize(x, y, offset_x, offset_y, scale, menuItems)
	self.x,self.y = x,y
	self.offset_x,self.offset_y = offset_x,offset_y
	self.options = menuItems
	self.selected = 1
	self.scale = scale

	self.keys = {}
	self.keys['up'] = false
	self.keys['down'] = false
	self.keys['enter'] = false

	self.ttf = r_ttf
end


function Menu:install(update, draw, press, release)
	hookInstall(function (dt) self:update(dt) end,
		function () self:draw() end,
		function (key) self:keypressed(key) end,
		function (key) self:keyreleased(key) end,
		update, draw, press, release)
end


function Menu:update()
end


function Menu:draw()
	for i=1,table.maxn(self.options) do
		local this_y = self.y + (self.offset_y * i)

		love.graphics.draw(self.options[i][1],
				    self.x, this_y, 0, self.scale, self.scale)
		if (i == self.selected) then
			love.graphics.draw(love.graphics.newText(self.ttf, ">>"),
				self.x - self.offset_x, this_y, 0, self.scale, self.scale)
		end
	end
end


function Menu:keypressed(key)
	maxn = table.maxn(self.options)

	if (key == "return" or key == "space") then
		self.keys['enter'] = true
		if(self.options[self.selected][2]) then
			self.options[self.selected][2]()
		end

	elseif (key == "up"  and  self.selected > 1
			and  self.keys['up'] == false) then
		self.keys['up'] = true
		self.selected = self.selected - 1
	elseif (key == "up"  and  self.keys['up'] == false) then
		self.keys['up'] = true
		self.selected = maxn

	elseif (key == "down" and self.selected < maxn
			and  self.keys['down'] == false) then
		self.keys['down'] = true
		self.selected = self.selected + 1
	elseif (key == "down" and  self.keys['down'] == false) then
		self.keys['down'] = true
		self.selected = 1
	end
end


function Menu:keyreleased(key)
	if (key == "return" or key == "space") then
		self.keys['enter'] = false
	elseif (key == "up") then
		self.keys['up'] = false
	elseif (key == "down") then
		self.keys['down'] = false
	end
end


-- TEXT ENTRY
----------------------------------------
TextBox = class("TextBox")

function TextBox:initialize(x, y, scale, max, initialText, label, onEnter)
	self.x,self.y = x,y
	self.scale = scale
	self.onEnter = onEnter
	self.text = initialText or ""
	self.label = label or ""
	self.max = max or 999

	self.ttf = r_ttf
end


function TextBox:install(update, draw, press, release)
	hookInstall(function (dt) self:update(dt) end,
		function () self:draw() end,
		function (key) self:keypressed(key) end,
		function (key) self:keyreleased(key) end,
		update, draw, press, release)
end


function TextBox:update()
end


function TextBox:draw()
	love.graphics.draw(love.graphics.newText(self.ttf,
		self.label .. self.text .. "_"),
		self.x, self.y, 0, self.scale, self.scale)
end


function TextBox:keypressed(key)
	if (key == "return") then
		self.onEnter(self.text)

	elseif (key == "backspace") then
		self.text = self.text:sub(1, string.len(self.text) - 1)
	elseif (string.len(self.text) > self.max) then
		return
	elseif (key == "space") then
		self.text = self.text .. " "
	elseif (string.len(key) == 1) then
		self.text = self.text .. key
	end
end


function TextBox:keyreleased(key)
end


-- CHAT/LOGGING
--------------------------------------------------------------------------------
function logMsg(source, text)
	local string = text
	if not (source == nil) then
		string = source .. ": " .. text
	end

	print(string)
	table.remove(CHATLOG, 5)
	table.insert(CHATLOG, 1, string)
end


function drawLogMsgs()
	local x,y = 10,600
	local offset_y = 30
	local scale = 1.7
	local chatCount = table.maxn(CHATLOG)

	for i=1,chatCount  do
		local this_y = y + (offset_y * (chatCount - i))

		love.graphics.draw(love.graphics.newText(a_ttf, CHATLOG[i]),
			x, this_y, 0, scale, scale)
	end
end


-- UTIL
--------------------------------------------------------------------------------
-- Install the important 'hook' functions (draw, update, keypressed/released)
-- If any of the 'old' functions passed are not nil, then both the new and
-- old will be added into the new corresponding hook function
-- This function is too god damn long and it makes me want to cry
-- Could be pretty easily shortened, now that I think about it
function hookInstall(newUpdate, newDraw, newPress, newRelease,
		oldUpdate, oldDraw, oldPress, oldRelease)
	local ignored = 1

	if (oldUpdate == false) then
	elseif (oldUpdate == nil and not (newUpdate == nil)) then
		updateFunction = function (dt) newUpdate(dt) end
	elseif not (newUpdate == nil) then
		updateFunction = function (dt) oldUpdate(dt) newUpdate(dt) end
	end

	if (oldDraw == false) then
	elseif (oldDraw == nil and not (newDraw == nil)) then
		drawFunction = function () newDraw() end
	elseif not (newDraw == nil) then
		drawFunction = function () oldDraw() newDraw() end
	end

	if (oldPress == false) then
	elseif (oldPress == nil and not (newPress == nil)) then
		keypressedFunction = function (key) newPress(key) end
	elseif not (newPress == nil) then
		keypressedFunction = function (key) oldPress(key) newPress(key) end
	end

	if (oldRelease == false) then
	elseif (oldRelease == nil and not (newRelease == nil)) then
		keyreleasedFunction = function (key) newRelease(key) end
	elseif not (newPress == nil) then
		keyreleasedFunction = function (key) oldRelease(key) newRelease(key) end
	end
end


function newCamera()
	local width,height = love.window.getMode()
	local scale =  height / 800
	logMsg("[Camera]", "Scale: " .. scale)

	camera = stalker()
	camera.scale = scale
	camera:setFollowStyle('NO_DEADZONE')
	camera:follow(400, 400)
end


-- MISC DATA
--------------------------------------------------------------------------------
-- CHARACTERS
------------------------------------------
CHARACTERS = {}
-- Lion Jellyfish by rapidpunches, CC-BY-SA 4.0
CHARACTERS[1] = love.graphics.newImage("art/sprites/jellyfish-lion.png")
-- N Jellyfish by rapidpunches, CC-BY-SA 4.0
CHARACTERS[2] = love.graphics.newImage("art/sprites/jellyfish-n.png")
-- Something Indecipherable by my little brother (<3<3), CC-BY-SA 4.0
CHARACTERS[3] = love.graphics.newImage("art/sprites/shark-unicorn.png")

-- DEFAULT NAMES
------------------------------------------
NAMES = {"Ignucius", "Splashers", "Penguin", "Tux", "Puffy", "Doktoro",
	"Espero", "<3", "</3", "Blublub", "Hase-ian"}

-- LOCAL KEYMAPS
------------------------------------------
KEYMAPS = {}
KEYMAPS[1] = {["accel"] = "up", ["left"] = "left", ["right"] = "right", ["flip"] = "down"}
KEYMAPS[2] = {["accel"] = "w", ["left"] = "a", ["right"] = "d", ["flip"] = "s"}
KEYMAPS[3] = {["accel"] = "i", ["left"] = "j", ["right"] = "l", ["flip"] = "k"}
KEYMAPS[4] = {["accel"] = "kp8", ["left"] = "kp4", ["right"] = "kp6", ["flip"] = "kp5"}
