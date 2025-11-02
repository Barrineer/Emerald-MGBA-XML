--Check the excel file for more info on how memory addresses work. It seems like its possible to make a script here YAY!

--I think the best way to do this is to constantly load specific memory addresses every second and test if this is too much load
-- We want to get the first 600 bytes after 0x020244EC (0x020244EC - 0x020250EC)
--so every 100 bytes (200 hex) (0x020244EC, 0x020246EC, 0x020248EC, 0x02024AEC, 0x02024CEC, 0x02024EEC) is each pokemon in the party
-- the first 4 bytes of each section is the personality data which is NEEDED to figure out where the pokedex num of the party pokemon is.
-- we also need the trainer id to decrypt the data for each pokemon. This is found at 0x000A and is 4 bytes long (need to confirm)

--Before checking any data, need to find the correct section where the data is at.
--each section (14 total sections) is 4 kb long within two save sections (A and B)
-- looks like the trainer id is found at 0x02000020 and again at 0x020000c8 (need to confirm on new save)
-- new save found trainer id at 0x02000552, after getting starter it disappeared. New location at 0x02020000
-- looks like 0x02020000 is a consistent spot to find the trainer id in working memory in mgba
-- todo: test if unecryption works if not, find a way to get all locations of party pokemon data
-- party data starts at 0x020244EC
-- in both files, found pokemon in slot 1 data at 0x0202499e (might have to test a few more times but looks good)
-- incorrect above assumption. that memory address contains the current pokedex num for the currently viewed poke in the summary screen


--Notes on debugging
-- uses assembly
-- read a memory address using r/<size> <address> size is in bytes and can be 1,2,4; address is for example: 0x020244EC
-- watch a memory address using w/<address>
-- watch can be appended with /r (read), /w (write), /c (changes made to the address)
-- watches can be deleted with d <index>
-- listw to show all watches
-- c to continue execution

address_locations = {
    {0x020244EC,0x02024550,0x020245B4,0x02024618,0x0202467C,0x020246E0},
    {0x020244f0,0x02024554,0x020245b8,0x0202461c,0x02024680,0x020246e4},
    {0x020244F4,0x02024558,0x020245BC,0x02024620,0x02024684,0x020246E8},
    {0x0202450C,0x02024570,0x020245D4,0x02024638,0x0202469C,0x02024700},
    {0x0202453C,0x020245A0,0x02024604,0x02024668,0x020246CC,0x02024730},
    {0x02024540,0x020245A4,0x02024608,0x0202466C,0x020246D0,0x02024734},
    {0x02024542,0x020245A6,0x0202460A,0x0202466E,0x020246D2,0x02024736},
    {0x02024544,0x020245A8,0x0202460C,0x02024670,0x020246D4,0x02024738},
    {0x02024546,0x020245AA,0x0202460E,0x02024672,0x020246D6,0x0202473A},
    {0x02024548,0x020245AC,0x02024610,0x02024674,0x020246D8,0x0202473C},
    {0x0202454A,0x020245AE,0x02024612,0x02024676,0x020246DA,0x0202473E},
    {0x0202454C,0x020245B0,0x02024614,0x02024678,0x020246DC,0x02024740},
    {0x0202454E,0x020245B2,0x02024616,0x0202467A,0x020246DE,0x02024742}
}

data_order = {"GAEM","AGEM","EGAM","MGAE","GAME","AGME","EGMA","MGEA","GEAM","AEGM","EAGM","MAGE","GEMA","AEMG","EAMG","MAEG","GMAE","AMGE","EMGA","MEGA","GMEA","AMEG","EMAG","MEAG"}
return_dict = {["G"] = "", ["A"] = "", ["E"] = "", ["M"] = ""}
--[[
[1] = Personality Value         (4 bytes)
[2] = Trainer ID                (4 bytes)
[3] = Nickname                  (10 bytes)
[4] = Data (Encrypted)          (48 bytes)

testing decryption for party pokemon
Pokedex nums 
[Mudkip] = [0x11b]
[Wurmple] = [0x122]
[Pooch] = [11e]
[wingull] = [135]
[zigzag] = [120]
[lotad] = [127]
--]]

pp = 4 --Party member we want to test [1-6]
poke_id = 0
encrypted_address = address_locations[4][pp]
personality_value_address = address_locations[1][pp]
t_id_address = address_locations[2][pp]

personality_value = string.format("%08x",emu:read32(personality_value_address))
t_id = string.format("%08x",emu:read32(t_id_address))
result = {}

encryption_key = tonumber(personality_value,16) ~ tonumber(t_id,16)
order_id = (tonumber(personality_value,16) % 24) + 1

console:log("..........................")
console:log("Checking encrypted data for party pokemon #" .. pp .. "\n------------------------")
console:log("Personality: " .. personality_value .. " ; Address: " .. string.format("%08x",personality_value_address))
console:log("Trainer: " .. t_id .. " ; Address: " .. string.format("%08x",t_id_address))
console:log("Encryption key: " .. encryption_key)

for i=1,12 do
    section = ""
    cur_address = encrypted_address + ((i-1 )*4)
    result[i] = emu:read32(cur_address) ~ encryption_key
    console:log("Address: " .. string.format("%08x",cur_address) .. " ; Value: " .. string.format("%08x",result[i]))

    if i < 4 then
        section = string.sub(data_order[order_id],1,1)
    elseif i >= 4 and i < 7 then
        section = string.sub(data_order[order_id],2,2)
    elseif i >= 7 and i < 10 then
        section = string.sub(data_order[order_id],3,3)
    else
        section = string.sub(data_order[order_id],4,4)
    end

    return_dict[section] = return_dict[section] .. string.format("%08x",result[i])
end

poke_id = string.sub(return_dict["G"],5,8)

console:log("Data for section G: " .. return_dict["G"])
console:log("PokeID: " .. poke_id)

--SO looks like we gotta make our own binary conversion function since none implemented in Lua natively...weird
-- 2 options: make a table with all hex value conversions OR mod 2 everytime and get the result... ew
hex_binary_dict = {
    ['0'] = "0000", ['1'] = "0001", ['2'] = "0010", ['3'] = "0011",
    ['4'] = "0100", ['5'] = "0101", ['6'] = "0110", ['7'] = "0111",
    ['8'] = "1000", ['9'] = "1001", ['A'] = "1010", ['B'] = "1011",
    ['C'] = "1100", ['D'] = "1101", ['E'] = "1110", ['F'] = "1111",
    ['a'] = "1010", ['b'] = "1011", ['c'] = "1100", ['d'] = "1101",
    ['e'] = "1110", ['f'] = "1111"}

hex_test = "0ee8ce63"
result_binary = ""

for b=1,#hex_test do
    result_binary = result_binary .. hex_binary_dict[string.sub(hex_test,b,b)]
end

console:log("Binary conversion test; Hex: " .. hex_test .. " Binary: " .. result_binary)