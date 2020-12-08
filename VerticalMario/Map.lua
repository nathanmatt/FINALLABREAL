--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Util'
Flag = Class{}
Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- flag pole
FLAG_POLE_TOP = 8
FLAG_POLE_MIDDLE = 12
FLAG_POLE_BOTTOM = 16

-- flag parts
FLAG_POINTY_UP = 13
FLAG_POINTY_DOWN = 14
FLAG_WRAPPED = 15

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 120

-- constructor for our map object
function Map:init()

    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)
    self.music = love.audio.newSource('sounds/8-bit Detective.wav', 'static')

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 100
    self.mapHeight = 40
    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 15

    -- associate player with map
    self.player = Player(self)

    -- camera offsets
    self.camX = 0
    self.camY = -3

    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- begin generating the terrain using vertical scan lines
    local x = 1
    for x = 1, self.mapWidth, 1 do
        -- changed to if statement
        -- 2% chance to generate a cloud
        -- make sure we're 7 tiles from edge at least
        if x < self.mapWidth - 9 then
            if math.random(20) == 1 then
                
                -- choose a random vertical spot above where blocks/pipes generate
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
                --10% chance to gen. mushroom/pipe
            if math.random(10) == 1 then
                
                self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
                self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)
    
                -- creates column of tiles going to bottom of map
                for y = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end

            -- 3% chance to generate bush, being sure to generate away from edge
            elseif math.random(33) == 1 and x < self.mapWidth - 3 then
                local bushLevel = self.mapHeight / 2 - 1
    
                -- place bush component and then column of bricks
                self:setTile(x, bushLevel, BUSH_LEFT)
                for y = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end
                x = x + 1
    
                self:setTile(x, bushLevel, BUSH_RIGHT)
                for y = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end
                x = x + 1
    
            -- chance to not generate anything, creating a gap
            elseif math.random(10) ~= 1 then
                
                -- creates column of tiles going to bottom of map
                for y = self.mapHeight / 2 , self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end
                -- 3rd row of tiles
                if math.random(3) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 8, TILE_BRICK)
                end
                if math.random(3) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 8, TILE_BRICK)
                end
                -- 2nd row of tiles
                if math.random(2) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 5, TILE_BRICK)
                end
                -- chance to create a block for Mario to hit
                if math.random(12) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
                end
                -- 2nd row of jump blocks
                if math.random(7) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 11, JUMP_BLOCK)
                end
                --4th row of tiles
                if math.random(3) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 12, TILE_BRICK)
                end
                -- 3rd row of jump blocks
                if math.random(6) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 16, JUMP_BLOCK)
                end
            else
                -- increment X so we skip two scanlines, creating a 2-tile gap
                x = x + 2
            end
        end

        
            --pyramid generation
        if x == self.mapWidth - 9 then
            for j = 1, 4, 1 do   --tile, length, increase
                self:setTile(x, self.mapHeight / 2  - j, TILE_BRICK)

                -- creates column of tiles going to bottom of map
                for y = self.mapHeight / 2 - (j - 1), self.mapHeight / 2 - 1 do
                    self:setTile(x,y,TILE_BRICK)
                end
                x = x + 1

                -- ensure nothing is generated between pyramid and flag
                for y = 0, self.mapHeight / 2 - 1 do
                    self:setTile(x, y, TILE_EMPTY)
                end

                for x = self.mapWidth - 9, self.mapWidth do
                    for y = self.mapHeight / 2, self.mapHeight do
                        self:setTile(x, y, TILE_BRICK)
                    end
                end
            end
        end
        
        if x == self.mapWidth - 2 then
            self:setTile(x, self.mapHeight / 2 - 5, FLAG_POLE_TOP)
            self:setTile(x, self.mapHeight / 2 - 4, FLAG_POLE_MIDDLE)
            self:setTile(x, self.mapHeight / 2 - 3, FLAG_POLE_MIDDLE)
            self:setTile(x, self.mapHeight / 2 - 2, FLAG_POLE_MIDDLE)
            self:setTile(x, self.mapHeight / 2 - 1, FLAG_POLE_BOTTOM)
        end

        if x == self.mapWidth - 1 then
            self:setTile(x, self.mapHeight / 2 - 5, FLAG_POINTY_UP)
        end
    end

    -- start the background music
    self.music:setLooping(true)
    self.music:play()
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT,
        MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- return whether a given tile is collidable
function Map:hitsFlag(tile)
    -- define our collidable tiles
    local collidables = {
        FLAG_POLE_BOTTOM, FLAG_POLE_MIDDLE, 
        FLAG_POLE_TOP
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            love.graphics.print( "VICTORY!!!", self.mapWidthPixels - 60, self.mapHeightPixels / 2 - 60)
            return true
        end
    end
    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)
    
    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))
    --follows mario's Y coordinate too to add vertical play
    self.camY = math.max(0, math.min(self.player.y - VIRTUAL_HEIGHT / 2 - 2,
        math.min(self.mapHeightPixels - VIRTUAL_HEIGHT, self.player.y)))

end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- renders our map to the screen, to be called by main's render
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()
end
