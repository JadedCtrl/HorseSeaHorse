-- pls set tabs to width of 4 spaces
class	= require "lib/middleclass"
wind	= require "lib/windfield"
stalker	= require "lib/STALKER-X"

mainmenu = 0; game = 1; gameover = 2; pause = 3; youwin = 4
startSwordLength = 40; startKnifeLength = 10

world = wind.newWorld(0, 0, true)

-- GAME STATES
--------------------------------------------------------------------------------
-- LOVE
----------------------------------------
function love.load ()
	math.randomseed(os.time())

	love.graphics.setDefaultFilter("nearest", "nearest")
	a_ttf = love.graphics.newFont("art/font/alagard.ttf", nil, "none")
	r_ttf = love.graphics.newFont("art/font/romulus.ttf", nil, "none")

	camera = stalker()

	mainmenu_load()
end


function love.update(dt)
	if(mode == mainmenu) then		mainmenu_update(dt)
	elseif(mode == game) then		game_update(dt)
	elseif(mode == gameover) then	gameover_update(dt)
	elseif(mode == youwin) then		youwin_update(dt)
	elseif(mode == pause) then		pause_update(dt)
	end
	camera:update(dt)
end


function love.draw()
	camera:attach()
	if(mode == mainmenu)		then mainmenu_draw()
	elseif(mode == game)		then game_draw()
	elseif(mode == gameover)	then gameover_draw()
	elseif(mode == youwin)		then youwin_draw()
	elseif(mode == pause)		then pause_draw()
	end
	camera:detach()
	camera:draw()
end


function love.resize()
	camera = stalker()
end


function love.keypressed(key)
	if(mode == mainmenu) then		mainmenu_keypressed(key)
	elseif(mode == game) then		game_keypressed(key)
	elseif(mode == gameover) then	gameover_keypressed(key)
	elseif(mode == youwin) then		youwin_keypressed(key)
	elseif(mode == pause) then		pause_keypressed(key)
	end
end


function love.keyreleased (key)
	if(mode == mainmenu) then		mainmenu_keyreleased(key)
	elseif(mode == game) then		game_keyreleased(key)
	elseif(mode == gameover) then	gameover_keyreleased(key)
	elseif(mode == youwin) then		youwin_keyreleased(key)
	elseif(mode == pause) then		pause_keyreleased(key)
	end
end


-- MENU STATE
----------------------------------------
function mainmenu_load ()
	mode = mainmenu
	selection = 1
	if(bgm) then
		bgm:stop()
	end
--	bgm = love.audio.newSource("art/music/default.mp3", "static")
--	bgm:play()
--	bgm:setLooping(true)
--	bgm:setVolume(1.5)
	frontMenu = nil

	frontMenu_init()

	camera = stalker()
end


function mainmenu_update(dt)
end


function mainmenu_draw ()
	frontMenu:draw()
end


function mainmenu_keypressed(key)
	frontMenu:keypressed(key)
end


function mainmenu_keyreleased(key)
	frontMenu:keyreleased(key)
end


function frontMenu_init()
	frontMenu = Menu:new(100, 100, 30, 50, 3, {
		{love.graphics.newText(a_ttf, "Local"),
			function () 
				local lobbiest1 = LocalLobbiest:new(nil, KEYMAPS[1])
				local lobbiest2 = LocalLobbiest:new(nil, KEYMAPS[2])
				game_load({lobbiest1, lobbiest2})
			end},
		{love.graphics.newText(a_ttf, "Quit"),
			function () love.event.quit(0) end }})
	mapMenu = nil
end


-- PAUSE STATE
----------------------------------------
function pause_load()
	if(bgm) then
		bgm:stop()
	end
	mode = pause
end


function pause_update(dt)
end


function pause_draw ()
	game_draw()
	camera:detach()
	love.graphics.draw(love.graphics.newText(r_ttf,
		"paused\n[enter to continue]\n[escape to exit]"), 200, 200, 0, 3, 3)
	camera:attach()
end


function pause_keypressed(key)
	if (key == "return") then
		if(bgm) then
			bgm:play()
		end
		mode = game
	elseif (key == "escape") then
		mainmenu_load()
	end
end


function pause_keyreleased(key)
end


-- GAMEOVER STATE
----------------------------------------
function gameover_load ()
	mode = gameover
end


function gameover_update(dt)
end


function gameover_draw ()
	game_draw()
	camera:detach()
	love.graphics.draw(love.graphics.newText(r_ttf,
		"nice try!\n[enter to restart]\n[escape to exit]"), 200, 200, 0, 3, 3)
	camera:attach()
end


function gameover_keypressed(key)
	if (key == "return" or key == "space") then
		camera:fade(.2, {0,0,0,1}, function() game_load() end)
	elseif (key == "escape") then
		mainmenu_load()
	end
end


function gameover_keyreleased(key)
end


-- GAME STATE
----------------------------------------
function game_load(lobbiests)
	mode = game
	world:destroy()
	world = wind.newWorld(0, 0, true)
	world:addCollisionClass('Fighter')
	world:addCollisionClass('Shield')
	world:addCollisionClass('Sword')

	remotePlayers = {}
	localPlayers = {}
	remotePlayersN = 0
	localPlayersN = 0

	for k,lobbiest in pairs(lobbiests) do
		if (lobbiest.class.name == "LocalLobbiest") then
			local i = localPlayersN + 1
			localPlayers[i] = LocalPlayer:new(0 + i * 50, 0 + i * 50, KEYMAPS[i])
			localPlayersN = i
		end
	end

	localFighters = localPlayers

	fighters = localFighters

	camera:fade(.2, {0,0,0,0})
	camera:setFollowLerp(0.1)
	camera:setFollowStyle('TOPDOWN')
end


function game_update(dt)
	world:update(dt)

	for i, fighter in pairs(fighters) do
		fighter:update(dt)
	end
--	local x, y = player.body:getPosition()
--	camera:follow(x, y)
end


function game_draw ()
	world:draw()
	for i, fighter in pairs(fighters) do
		fighter:draw()
	end
end


function game_keypressed(key)
	local dir = localFighters[1].directionals

	-- if a player presses the left key, then holds the right key, they should
	-- go right until they let go, then they should go left.
	if (key == "=" and camera.scale < 10) then
		camera.scale = camera.scale + .5
	elseif (key == "-" and camera.scale > .5) then
		camera.scale = camera.scale - .5

	elseif (key == "escape") then
		pause_load()
	else
		for i, player in pairs(localPlayers) do
			player:keypressed(key)
		end
	end
end


function game_keyreleased (key)
	for i, player in pairs(localPlayers) do
		player:keyreleased(key)
	end
end


-- CLASSES
--------------------------------------------------------------------------------
-- Fighter		player class
----------------------------------------
Fighter = class('Fighter')

function Fighter:initialize(x, y, character, swordType, swordSide)
	self.swordType = swordType or 'normal'
	self.swordSide = swordSide or 'top'
	self.character = character or "jellyfish-lion.png"

	self.directionals = {}
	self.deadPieces = {}

	self.sprite = love.graphics.newImage("art/sprites/" .. self.character)

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


function Fighter:draw ()
	local x,y = self.body:getWorldPoints(self.body.shape:getPoints())

	love.graphics.draw(self.sprite, x, y, self.body:getAngle(), 1, 1)
end


function Fighter:movement ()
end


function Fighter:initBody(x, y)
	self.body = world:newRectangleCollider(x, y, 16, 16);
	self.body:setCollisionClass('Fighter')
	self.body:setObject(self)
	self.body:setAngularDamping(2)
	self.body:setLinearDamping(.5)
	self.body:setPostSolve(self.makePostSolve())
end


function Fighter:initShield()
	self.shield = world:newRectangleCollider(0, 0, 20, 5);
	self.shield:setCollisionClass('Shield')
	self.shield:setObject(self)
end


function Fighter:initSword()
	self.swordLength = startSwordLength

	if (self.swordType == 'normal') then
		self.sword = world:newRectangleCollider(0, 0, 3, self.swordLength);
	else
		self.sword = world:newRectangleCollider(0, 0, 3, startKnifeLength);
	end
	self.sword:setCollisionClass('Sword')
	self.sword:setObject(self)
	self.sword:setPostSolve(self:makeSwordPostSolve())
end


function Fighter:glueSwordAndShield ()
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

function LocalPlayer:initialize(x, y, keymap, character, swordType, swordSide)
	self.keymap = keymap or KEYMAPS[1]
	Fighter.initialize(self, x, y, character, swordType, swordSide)
end


function LocalPlayer:movement ()
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


function Menu:draw ()
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


-- LOBBY superclass for pre-matches
----------------------------------------
Lobby = class("Lobby")

-- LOBBIEST	proposed fighter
----------------------------------------
Lobbiest = class("Lobbiest")

function Lobbiest:initialize(name)
	self.name = name or NAMES[math.random(1, table.maxn(NAMES))]
	self.character = CHARACTERS[math.random(1, table.maxn(CHARACTERS))]
end


-- LOCALLOBBIEST
----------------------------------------
LocalLobbiest = class("LocalLobbiest", Lobbiest)

function LocalLobbiest:initialize(name, keymap)
	Lobbiest.initialize(self, name)
	self.keymap = keymap or KEYMAPS[math.random(1, table.maxn(KEYMAPS))]
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


-- MISC DATA
--------------------------------------------------------------------------------
-- CHARACTERS
------------------------------------------
CHARACTERS = {}
CHARACTERS["jellyfish-lion.png"] = {"Lion Jellyfish", "hey, hey. you know whats shocking?", "rapidpunches", "CC-BY-SA 4.0"}
CHARACTERS["jellyfish-n.png"] = {"Jellyfish N", "(electricity)", "rapidpunches", "CC-BY-SA 4.0"}

-- DEFAULT NAMES
------------------------------------------
NAMES = {"Ignucius", "Penguin", "Tux", "Puffy", "Doktoro", "Espero", "<3", "</3"}

-- LOCAL KEYMAPS
------------------------------------------
KEYMAPS = {}
KEYMAPS[1] = {["accel"] = "w", ["left"] = "a", ["right"] = "d", ["flip"] = "s"}
KEYMAPS[2] = {["accel"] = "up", ["left"] = "left", ["right"] = "right", ["flip"] = "down"}
