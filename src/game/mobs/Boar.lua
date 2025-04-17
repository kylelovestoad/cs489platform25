local Class = require "libs.hump.class"
local Anim8 = require "libs.anim8"
local Timer = require "libs.hump.timer"
local Enemy = require "src.game.mobs.Enemy"
local Hbox = require "src.game.Hbox"
local Sounds = require "src.game.Sounds"

-- Idle Animation Resources
local idleSprite = love.graphics.newImage("graphics/mobs/boar/Idle-Sheet.png")
local idleGrid = Anim8.newGrid(48, 32, idleSprite:getWidth(), idleSprite:getHeight())
local idleAnim = Anim8.newAnimation(idleGrid('1-4',1),0.2)
-- Walk Animation Resources
local walkSprite = love.graphics.newImage("graphics/mobs/boar/Walk-Sheet.png")
local walkGrid = Anim8.newGrid(48, 32, walkSprite:getWidth(), walkSprite:getHeight())
local walkAnim = Anim8.newAnimation(walkGrid('1-6',1),0.2)
-- Hit Animation Resources
local hitSprite = love.graphics.newImage("graphics/mobs/boar/Hit-Sheet.png")
local hitGrid = Anim8.newGrid(48, 32, hitSprite:getWidth(), hitSprite:getHeight())
local hitAnim = Anim8.newAnimation(hitGrid('1-4',1),0.2)


local Boar = Class{__includes = Enemy}
function Boar:init(type) Enemy:init() -- superclass const.

    -- local imageData = love.image.newImageData(1, 1)
    -- imageData:setPixel(0, 0, 1, 1, 1, 1) -- white pixel with full alpha

    self.name = "boar"
    self.type = type
    if type == nil then self.type = "brown" end

    self.dir = "l" -- Direction r = right, l = left
    self.state = "idle" -- idle state
    self.animations = {} -- dict of animations (each mob will have its own)
    self.sprites = {} -- dict of sprites (for animations)
    self.hitboxes = {}
    self.hurtboxes = {}

    self.hp = 20
    self.score = 200
    self.damage = 20

    self:setAnimation("idle",idleSprite, idleAnim)
    self:setAnimation("walk",walkSprite, walkAnim)
    self:setAnimation("hit", hitSprite, hitAnim)

    self:setHurtbox("idle",10,10,34,22)
    self:setHurtbox("walk",10,10,34,22)
    self:setHurtbox("hit",6,2,34,30)

    self:setHitbox("idle",10,10,34,22)
    self:setHitbox("walk",10,10,34,22)
    --self:setHurtbox("hit",6,2,34,30)

    local particleImage = love.graphics.newImage("graphics/particles/34.png")
    self.poof = love.graphics.newParticleSystem(particleImage, 50)
    self.poof:setParticleLifetime(0.5, 1)
    self.poof:setLinearAcceleration(-100, -100, 100, 100)
    self.poof:setEmissionRate(30)
    self.poof:setSizes(0.1, 0.05)
    self.poof:setColors(1, 1, 1, 1, 1, 1, 1, 0)

    self.deathParticlesNotPlayed = true

    Timer.every(5,function() self:changeState() end)
end

function Boar:changeState()
    if self.state == "idle" then
            self.state = "walk"
    elseif self.state == "walk" then
        self.state = "idle"
    end
end

function Boar:draw()

    if self.died then 
        love.graphics.draw(self.poof, self.x + 20, self.y + 20)
        return 
    end

    self.animations[self.state]:draw(self.sprites[self.state],
        math.floor(self.x), math.floor(self.y))
    
    if debugFlag then
        local w,h = self:getDimensions()
        love.graphics.rectangle("line",self.x,self.y,w,h) -- sprite
    
        if self:getHurtbox() then
            love.graphics.setColor(0,0,1) -- blue
            self:getHurtbox():draw()
        end
    
        if self:getHitbox() then
            love.graphics.setColor(1,0,0) -- red
            self:getHitbox():draw()
        end
        love.graphics.setColor(1,1,1) 
    end
end


function Boar:update(dt, stage)

    if self.deathParticlesNotPlayed then
        self.poof:update(dt)
    end

    if self.died then return end

    -- Boar should fall even when idle
    if not stage:bottomCollision(self,1,0) then -- not on solid ground
        self.y = self.y + 32*dt -- fall 
    end

    if self.state == "walk" then

        if self.dir == "l" then -- on ground and walking left
            if stage:leftCollision(self,0) then -- collision, change dir
                self:changeDirection()
            else -- no collision, keep walking left
                self.x = self.x-16*dt
            end
        else -- on ground and walking right
            if stage:rightCollision(self,0) then -- collision, change dir
                self:changeDirection()
            else -- no collision, keep walking right
                self.x = self.x+16*dt
            end 
        end -- end if bottom collision & dir 
    end -- end if walking state
    Timer.update(dt) -- attention, Timer.update uses dot, and not :
    self.animations[self.state]:update(dt)
end -- end function
    
function Boar:hit(damage, direction)
    if self.invincible then return end

    self.invincible = true
    self.hp = self.hp - damage
    self.state = "hit"
    Sounds["mob_hurt"]:play()

    if self.hp <= 0 then
        self.deathParticlesNotPlayed = true
        self.died = true
        Timer.after(2, function() self.deathParticlesNotPlayed = false end)
    end

    Timer.after(1, function() self:endHit(direction) end)
    Timer.after(0.9, function() self.invincible = false end)

end

function Boar:endHit(direction)
    if self.dir == direction then
        self:changeDirection()
    end
    self.state = "walk"
end

return Boar