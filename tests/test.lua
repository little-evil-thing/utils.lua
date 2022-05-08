local utils = require("utils")
local Class = utils.Class
local strColorize = require("utils").strColorize

local function construct(self, name)
    print(strColorize("new &mag"..self.type.. " &resappears with name : &yel"..name))
    self.name = name
end

local kitty = {
    say=function(self, something) 
        print(strColorize("<&mag"..self.type.."&res:".."&yel"..self.name.."&res> : &blu"..something))
    end,
    age=16,
    type = "Kitty"
}
local cat = {
    age=19,
    type = "Cat"
}

Kitty = Class:extend(construct, kitty)
Cat = Kitty:extend(construct, cat)

Plume = Cat:new("Plume")
Aslan = Kitty:new("Aslan")

Plume:say("nya!")
Aslan:say("How old are you?")
Plume:say("I'm actually "..Plume.age.." years old. and you?")
Aslan:say("I'm "..Aslan.age.." years old.")
