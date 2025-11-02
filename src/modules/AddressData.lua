--[[

Module for storing data for specific address values

--]]

local AddressData = {}
AddressData.__index = AddressData

function AddressData.new()

    local newAddressData = setmetatable({},AddressData)

    newAddressData.address = "Hi"

    return newAddressData

end

function AddressData:testPrint()
    console:log(self.address)
end

return AddressData
