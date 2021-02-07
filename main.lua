-- pls set tabs to width of 4 spaces
class	= require "lib/middleclass"
wind	= require "lib/windfield"
stalker	= require "lib/STALKER-X"

SWORDLENGTH = 40; KNIFELENGTH = 10
SWORDWIDTH = 3
SHIELDWIDTH = 16
SHIELDHEIGHT = 5


-- GAME STATES
--------------------------------------------------------------------------------
-- LOVE
----------------------------------------
function love.load()
	math.randomseed(os.time())

	love.graphics.setDefaultFilter("nearest", "nearest")
	a_ttf = love.graphics.newFont("art/font/alagard.ttf", nil, "none")
	r_ttf = love.graphics.newFont("art/font/romulus.ttf", nil, "none")

	camera = stalker()

	mainmenu_load()
end


function love.update(dt)
	updateFunction(dt)
	camera:update(dt)
end


function love.draw()
	camera:attach()
	drawFunction()
	camera:detach()
	camera:draw()
end


function love.resize()
	camera = stalker()
end


function love.keypressed(key)
	keypressedFunction(key)
end


function love.keyreleased (key)
	keyreleasedFunction(key)
end


-- MAIN-MENU
----------------------------------------
function mainmenu_load()
	local mainMenu = makeMainMenu()
	mainMenu:install()

	camera = stalker()
end


function makeMainMenu()
	return Menu:new(100, 100, 30, 50, 3, {
		{love.graphics.newText(a_ttf, "Local"),
			function () lobby_load(LocalLobby) end},
		{love.graphics.newText(a_ttf, "Quit"),
			function () love.event.quit(0) end }})
end


-- GAME LOBBY
----------------------------------------
function lobby_load(lobbyClass)
	lobby = lobbyClass:new()
	lobby:install()
end


-- IN-GAME
----------------------------------------
Game = class("Game")

function game_load(lobbiests)
	game = Game:new(lobbiests)
	game:install()
end


-- CLASSES
--------------------------------------------------------------------------------
-- Fighter		player class
----------------------------------------
Fighter = class('Fighter')

function Fighter:initialize(game, x, y, character, swordType, swordSide)
	self.game = game
	self.swordType = swordType or 'normal'
	self.swordSide = swordSide or 'top'
	self.character = character or math.random(1, table.maxn(CHARACTERS))

	self.directionals = {}
	self.deadPieces = {}

	self.sprite = love.graphics.newImage("art/sprites/"
		.. CHARACTERS[self.character]["file"])

	self:initBody(x, y)
	self:initSword()
	self:initShield()
end


function Fighter:update(dt)
	local dir = self.directionals

	self:movement()
	self:glueSwordAndShield()

	if (dir['left'] == 2 and dir['right'] == 0) then dir['left'] = 1; end
	if (dir['right'] == 2 and dir['left'] == 0) then dir['right'] = 1; end
end


function Fighter:draw()
	local x,y = self.body:getWorldPoints(self.body.shape:getPoints())

	love.graphics.draw(self.sprite, x, y, self.body:getAngle(), 1, 1)
end


function Fighter:movement()
end


function Fighter:initBody(x, y)
	self.body = self.game.world:newRectangleCollider(x, y, 16, 16);
	self.body:setCollisionClass('Fighter')
	self.body:setObject(self)
	self.body:setAngularDamping(2)
	self.body:setLinearDamping(.5)
	self.body:setPostSolve(self.makePostSolve())
end


function Fighter:initShield()
	self.shield = self.game.world:newRectangleCollider(0, 0, 20, 5);
	self.shield:setCollisionClass('Shield')
	self.shield:setObject(self)
end


function Fighter:initSword()
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


function Fighter:glueSwordAndShield()
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


function Fighter:makePostSolve()
	return function(col1, col2, contact)
		if (col1.collision_class == "Fighter"
			and col2.collision_class == "Sword")
		then
--			print(col2.shape)
--			print("THEY DEEED, dude")
		end
	end
end


function Fighter:makeSwordPostSolve()
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
LocalPlayer = class("LocalPlayer", Fighter)

function LocalPlayer:initialize(game, x, y, keymap, character, swordType, swordSide)
	self.keymap = keymap or KEYMAPS[1]
	Fighter.initialize(self, game, x, y, character, swordType, swordSide)
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


-- LocalBot	andddd for bots too
----------------------------------------
LocalBot = class("LocalBot", Fighter)

function LocalBot:initialize(x, y, character, swordType, swordSide)
	Fighter.initialize(self, x, y, character, swordType, swordSide)
end


-- GAME superclass for matches
----------------------------------------
function Game:initialize(lobbiests)
	self.world = wind.newWorld(0, 0, true)
	self.world:addCollisionClass('Fighter')
	self.world:addCollisionClass('Shield')
	self.world:addCollisionClass('Sword')

	self.remotePlayers = {}
	self.localPlayers = {}
	self.remotePlayersN = 0
	self.localPlayersN = 0

	for k,lobbiest in pairs(lobbiests) do
		if (lobbiest.class.name == "LocalLobbiest") then
			local i = self.localPlayersN + 1
			self.localPlayers[i] = LocalPlayer:new(self, 0 + i * 50, 0 + i * 50,
				KEYMAPS[i], lobbiest.character)
			self.localPlayersN = i
		end
	end

	self.localFighters = self.localPlayers

	self.fighters = self.localFighters

	camera:fade(.2, {0,0,0,0})
	camera:setFollowLerp(0.1)
	camera:setFollowStyle('TOPDOWN')
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

	for i, fighter in pairs(self.fighters) do
		fighter:update(dt)
	end
--	local x, y = player.body:getPosition()
--	camera:follow(x, y)
end


function Game:draw()
	self.world:draw()
	for i, fighter in pairs(self.fighters) do
		fighter:draw()
	end
end


function Game:keypressed(key)
	local dir = self.localFighters[1].directionals

	-- if a player presses the left key, then holds the right key, they should
	-- go right until they let go, then they should go left.
	if (key == "=" and camera.scale < 10) then
		camera.scale = camera.scale + .5
	elseif (key == "-" and camera.scale > .5) then
		camera.scale = camera.scale - .5

	elseif (key == "escape") then
		pause_load()
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

		love.graphics.draw(lobbiest.sprite, rowX, rowY, 0, 1, 1)
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
			rowX + 500, rowY, 0, self.scale)

		if (lobbiest.class.name == "LocalLobbiest") then
			local keymap = lobbiest.keymap
			local text = keymap["accel"] .. " " .. keymap["left"] .. " "
				.. keymap["flip"] .. " " .. keymap["right"]

			love.graphics.draw(love.graphics.newText(self.ttf, text),
				rowX + 300, rowY + 5, 0, self.scale * (2/3))
		end
	end

	love.graphics.draw(love.graphics.newText(self.ttf, "SPACE: Add player"),
		10, 460, 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "LEFT: Edit name"),
		10, 500, 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "RIGHT: Change sprite"),
		10, 520, 0, self.scale)
	love.graphics.draw(love.graphics.newText(self.ttf, "ACCEL: Change sword"),
		10, 540, 0, self.scale)
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
	else
		for i,lobbiest in pairs(self.localLobbiests) do
			lobbiest:keypressed(key)
		end
	end
end


function Lobby:keyreleased(key)
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


-- LOCAL LOBBY
----------------------------------------
LocalLobby = class("LocalLobby", Lobby)

function LocalLobby:initialize()
	Lobby.initialize(self)
end


function LocalLobby:keypressed(key)
	if (key == "return" and self:lobbiestsN() > 1) then
		game_load(self:lobbiests())
	else
		Lobby.keypressed(self, key)
	end
end


-- LOBBIEST	proposed fighter
----------------------------------------
Lobbiest = class("Lobbiest")

function Lobbiest:initialize(lobby, name)
	self.lobby = lobby
	self.name = name or NAMES[math.random(1, table.maxn(NAMES))]
	self.character = math.random(1, table.maxn(CHARACTERS))
	self.sprite = love.graphics.newImage("art/sprites/"
		.. CHARACTERS[self.character]["file"])
	self.swordType = "normal"
end


-- LOCAL LOBBIEST
----------------------------------------
LocalLobbiest = class("LocalLobbiest", Lobbiest)

function LocalLobbiest:initialize(lobby, name, keymap)
	Lobbiest.initialize(self, lobby, name)
	self.keymap = keymap or KEYMAPS[math.random(1, table.maxn(KEYMAPS))]
end


function LocalLobbiest:keypressed(key, playerNo)
	if (key == self.keymap["accel"]) then
		if (self.swordType == "normal")		then self.swordType = "knife"
		elseif (self.swordType == "knife")	then self.swordType = "normal"
		end

	elseif (key == self.keymap["left"]) then
		local textBox = TextBox:new(20, 400, 3, 10, self.name, "Name: ",
			function (text)
				self.name = text
				self.lobby:install()
			end)

		textBox:install(false, drawFunction, nil, false)

	elseif (key == self.keymap["right"]) then
		if (self.character == table.maxn(CHARACTERS)) then
			self.character = 1
		else
			self.character = self.character + 1
		end
		self.sprite = love.graphics.newImage("art/sprites/"
			.. CHARACTERS[self.character]["file"])
	end
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
	self.text = initialText
	self.label = label
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
	print(key)
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


-- UTIL
--------------------------------------------------------------------------------
function split(inputString, seperator)
        local newString = {}
        for stringBit in string.gmatch(inputString, "([^"..seperator.."]+)") do
                table.insert(newString, stringBit)
        end
        return newString
end


-- Install the important 'hook' functions (draw, update, keypressed/released)
-- If any of the 'old' functions passed are not nil, then both the new and
-- old will be added into the new corresponding hook function
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


-- MISC DATA
--------------------------------------------------------------------------------
-- CHARACTERS
------------------------------------------
CHARACTERS = {}
CHARACTERS[1] = {["file"] = "jellyfish-lion.png", ["name"] = "Lion Jellyfish", ["desc"] = "hey, hey. you know whats shocking?", ["author"] = "rapidpunches", ["license"] = "CC-BY-SA 4.0"}
CHARACTERS[2] = {["file"] = "jellyfish-n.png", "Jellyfish N", "(electricity)", "rapidpunches", "CC-BY-SA 4.0"}
CHARACTERS[3] = {["file"] = "shark-unicorn.png", "Shark-Unicorn", "A masterpiece", "My little bro", "CC-BY-SA 4.0"}

-- DEFAULT NAMES
------------------------------------------
NAMES = {"Ignucius", "Penguin", "Tux", "Puffy", "Doktoro", "Espero", "<3", "</3"}

-- LOCAL KEYMAPS
------------------------------------------
KEYMAPS = {}
KEYMAPS[1] = {["accel"] = "up", ["left"] = "left", ["right"] = "right", ["flip"] = "down"}
KEYMAPS[2] = {["accel"] = "w", ["left"] = "a", ["right"] = "d", ["flip"] = "s"}
KEYMAPS[3] = {["accel"] = "i", ["left"] = "j", ["right"] = "l", ["flip"] = "k"}
KEYMAPS[4] = {["accel"] = "kp8", ["left"] = "kp4", ["right"] = "kp6", ["flip"] = "kp5"}
