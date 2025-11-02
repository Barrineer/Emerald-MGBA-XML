--[[

Module for getting specific data from the mgba emulator for pokemon emerald

--]]

local EmeraldData = {}
EmeraldData.__index = EmeraldData

function EmeraldData.new()

    local newEmeraldData = {}
    setmetatable(newEmeraldData,self)

    newEmeraldData.address = "Testies"

    return newEmeraldData

end

function EmeraldData:testPrint()
    console:log(self.address)
end

return EmeraldData