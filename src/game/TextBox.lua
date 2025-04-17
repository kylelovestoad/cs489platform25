local Class = require "libs.hump.class"

local TextBox = Class{}

function TextBox:init(text,font,x,y,limit,align)
    self.text = text
    self.font = font
    self.x = x
    self.y = y
    self.limit = limit
    self.align = align
end

function TextBox:draw()
    love.graphics.printf(
        self.text,
        self.font,
        self.x,
        self.y,
        self.limit,
        self.align
    )
end

return TextBox