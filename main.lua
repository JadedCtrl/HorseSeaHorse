-- pls set tabs to width of 4 spaces
class	= require "lib/middleclass"
wind	= require "lib/windfield"
stalker	= require "lib/STALKER-X"

mainmenu = 0; game = 1; gameover = 2; pause = 3; youwin = 4

world = wind.newWorld(0, 40, true)

-- GAME STATES
--------------------------------------------------------------------------------
-- LOVE
----------------------------------------
function love.load ()
	math.randomseed(os.time())

	dieParticle = nil
	love.graphics.setDefaultFilter("nearest", "nearest")
	a_ttf = love.graphics.newFont("art/font/alagard.ttf", nil, "none")
	r_ttf = love.graphics.newFont("art/font/romulus.ttf", nil, "none")

	camera = stalker()

	game_load()
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
	map = Map:new("maps/sys/menu.lua")
end


function mainmenu_update(dt)
	if not (mapMenu == nil) then return; end

	world:update(dt)
	player:update(dt)
	map:update(dt)

	-- make player monkey move randomly
	local num = math.random(100)
	local dirs = player.directionals
	if (num == 1) then
		dirs['left'] = 1
		dirs['right'] = 0
	elseif (num == 2) then
		dirs['right'] = 1
		dirs['left'] = 0
	elseif (num == 3) then
		dirs['up'] = 1
	end
end


function mainmenu_draw ()
	if (mapMenu == nil) then
		map:draw()
		player:draw()
		frontMenu:draw()
	else
		mapMenu:draw()
	end
end


function mainmenu_keypressed(key)
	if (mapMenu == nil) then
		frontMenu:keypressed(key)
	else
		mapMenu:keypressed(key)
	end
end


function mainmenu_keyreleased(key)
	if (mapMenu == nil) then
		frontMenu:keyreleased(key)
	else
		mapMenu:keyreleased(key)
	end
end


function frontMenu_init()
	frontMenu = Menu:new(100, 100, 30, 50, 3, {
		{love.graphics.newText(a_ttf, ""),
			function () mapMenu_init() end},
--				camera:fade(.2, {0,0,0,1}, function() mapMenu_init() end)
--				2, {0,0,0,1}, function() mapMenu_init() end)
--			end},
		{love.graphics.newText(a_ttf, "Quit"),
			function () love.event.quit(0) end }})
	mapMenu = nil
end


function mapMenu_init(directory)
	directory = directory or "maps"
	local menuEntries = {[1] = {love.graphics.newText(a_ttf, "../"),
		function () mainmenu_load() end}}
--			if (directory == "maps") then mainmenu_load()

	local indice = 2
	local files = love.filesystem.getDirectoryItems(directory)

	for k,file in pairs(files) do
		file = directory .. "/" .. file
		local filetype = love.filesystem.getInfo(file).type
		local fileSplit = split(file, ".")
		local fileExt = fileSplit[2] or ""
		
		if (filetype == "directory") then
			menuEntries[indice] = {love.graphics.newText(a_ttf, file .. "/"),
					function() mapMenu_init(file) end}
			indice = indice + 1
		elseif (filetype == "file" and fileExt == "lua") then
			menuEntries[indice] = {love.graphics.newText(a_ttf, fileSplit[1]),
					function() game_load(file) end}
			indice = indice + 1
		end
	end

	mapMenu = Menu:new(100, 100, 30, 50, 3, menuEntries)
	frontMenu = nil
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
function game_load(mapfile)
	mode = game
	world:destroy()
	world = wind.newWorld(0, 400, true)
	world:addCollisionClass('Fighter')

--	mapfile = mapfile or map.filepath
--	map = Map:new(mapfile)

	player = Fighter:new(100, 100)
	camera:fade(.2, {0,0,0,0})
	camera:setFollowLerp(0.1)
	camera:setFollowStyle('PLATFORMER')

--	bgm:stop()
--	bgm = love.audio.newSource("art/music/game.ogg", "static")
--	bgm:play()
end


function game_update(dt)
	world:update(dt)
	player:update(dt)
--	map:update(dt)

	local x, y = player.body:getPosition()
	camera:follow(x, y)
end


function game_draw ()
--	map:draw()
	world:draw()
	player:draw()
end


function game_keypressed(key)
	local dir = player.directionals

	-- if a player presses the left key, then holds the right key, they should
	-- go right until they let go, then they should go left.
	if (key == "right" or key == "d") then
		dir['right'] = 1
		if (dir['left'] == 1) then dir['left'] = 2; end
	elseif (key == "left" or key == "a") then
		dir['left'] = 1
		if (dir['right'] == 1) then dir['right'] = 2; end
	elseif (key == "up" or key == "w") then
		dir['up'] = 1
		if (dir['down'] == 1) then dir['down'] = 2; end

	elseif (key == "=" and camera.scale < 10) then
		camera.scale = camera.scale + .5
	elseif (key == "-" and camera.scale > .5) then
		camera.scale = camera.scale - .5

	elseif (key == "escape") then
		pause_load()
	end
end


function game_keyreleased (key)
	local dir = player.directionals
	local dx, dy = player.body:getLinearVelocity()

	if (key == "right" or key == "d") then
		dir['right'] = 0
		player.body:setLinearVelocity(dx - 150, dy)
	elseif (key == "left" or key == "a") then
		dir['left'] = 0
		player.body:setLinearVelocity(dx + 150, dy)
	elseif (key == "up" or key == "w") then
		dir['up'] = 0
	elseif (key == "down") then
		dir['down'] = 0
	end
end



-- CLASSES
--------------------------------------------------------------------------------
-- MONK		player class
----------------------------------------
Fighter = class('Fighter')

function Fighter:initialize(x, y)
	self.directionals = {}

--	self.sprite = love.graphics.newImage("art/sprites/monk-jump.png")
		
	self.body = world:newRectangleCollider(x, y, 16, 16);
	self.body:setCollisionClass('Fighter')
	self.body:setObject(self)
end


function Fighter:update(dt)
	local dir = self.directionals

	if (self.following == true) then self:follow()
	else self:idle()
	end

	self:movement()

	if (dir['left'] == 2 and dir['right'] == 0) then dir['left'] = 1; end
	if (dir['right'] == 2 and dir['left'] == 0) then dir['right'] = 1; end
end


function Fighter:draw ()
--	local x,y = self.body:getWorldPoints(monk.shape:getPoints())

--	love.graphics.draw(self.sprite, x, y, monk.body:getAngle(), 1, 1)
--	end
end


function Fighter:movement ()
	local dx, dy = self.body:getLinearVelocity()
	local dir = self.directionals
	local newVel = 250

	if not (self.onGround == downwall) then
		newVel = newVel - 50
	end

	if (dir['left'] == 1) then
		self.body:setLinearVelocity(-newVel, dy);
	elseif (dir['right'] == 1) then
		self.body:setLinearVelocity(newVel, dy);
	end

	if (dir['up'] == 1 and onGround == downwall) then
		self.body:setLinearVelocity(dx, -newVel);
	elseif (dir['up'] == 1 and onGround == leftwall) then
		self.body:setLinearVelocity(newVel, -newVel - 30);
	elseif (dir['up'] == 1 and onGround == rightwall) then
		self.body:setLinearVelocity(-newVel, -newVel - 30);
	end
end

-- Fighter should jitter when inactive, every once in a while
function Fighter:idle ()
--	if (self.onGround[i] == downwall and math.random(20) == 5) then
--	end
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



function split(inputString, seperator)
        local newString = {}
        for stringBit in string.gmatch(inputString, "([^"..seperator.."]+)") do
                table.insert(newString, stringBit)
        end
        return newString
end
