
-- Finally found how to call functions
--working address (0x020244EC in hex; 33703148 in decimal)

--read8,16,32 is 1,2,4 bytes respectfully
-- readRange; not sure what the returned value is

--Unfortunately, readrange returns garbled text as the result so impossible to read
--readRange(address,length)
-- b = emu:readRange(w_a,600)
-- type is typeof in any other lang
-- console:log("Testing readRange :" .. b)

-- .. for string concat
-- console log only prints strings so have to change to string

--All values found in the excel file; use it as a reference

--maybe we can get away with working with just decimal values instead (use decimal values for hex addresses?) THIS :D
--alt: keep addresses in decimal and iterate but when calling read, convert to hex (if possible)
--found how to print hex values (as strings) use string.format() "%x" for printing hex values!
-- print(string.format("%x", 0x2f));
-- arrays work like normal no issues found (yet)
-- array length found with # ex: #party_data
-- have to use table.unpack() to create a shallow copy of arrays
--We know all addresses that have values...lets do this

function get_data()

    --Party pokemon data, starting at index 1, each nested array is one of the 6 party members starting from position 1
    party_data = {}

    --[==[
    All known address locations for needed info will be stored in the following arrays (named from the list of poke_data except [14]). Each index correlates to the party pokemon index
    ]==]
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
    -- need to know how many bytes each location holds so we store it here (only first 13 needed)
    address_bytes = {4,4,10,48,4,1,1,2,2,2,2,2,2}

    --start address retrieval
    --[==[
    pokemon data template, in order it will contain: 
    [1] = Personality Value         (4 bytes)
    [2] = Trainer ID                (4 bytes)
    [3] = Nickname                  (10 bytes)
    [4] = Data (Encrypted)          (48 bytes)
    [5] = Status Condition          (4 bytes)
    [6] = Level                     (1 byte)
    [7] = Current HP                (1 byte)
    [8] = Total HP                  (2 bytes)
    [9] = Attack                    (2 bytes)
    [10] = Defence                  (2 bytes)
    [11] = Speed                    (2 bytes)
    [12] = Sp. Attack               (2 bytes)
    [13] = SP. Defence              (2 bytes)
    [14] = Data Order of encrypted data
    ]==]
    for i=1,6 do 
        --testing successful! continue.... >:D
        poke_data = {}
        for j=1,13 do
            data_str = ""
            cur_bytes = address_bytes[j]
            while cur_bytes >= 1 do
                --console:log("total bytes " .. tostring(address_bytes[j]) .. "current bytes: " .. tostring(cur_bytes))
                --console:log("current address " .. tostring(address_locations[i][j]))
                --console:log("i: " .. tostring(i) .. "j: " .. tostring(j))
                address = address_locations[j][i]
                cur_address = address + (address_bytes[j] - cur_bytes)
                if cur_bytes == 1 then
                    data_str = data_str .. (string.format("%x",emu:read8(cur_address)))
                    cur_bytes = cur_bytes - 1
                elseif cur_bytes == 2 then
                    data_str = data_str .. (string.format("%x",emu:read16(cur_address)))
                    cur_bytes = cur_bytes - 2
                else
                    data_str = data_str .. (string.format("%x",emu:read32(cur_address)))
                    cur_bytes = cur_bytes - 4
                end
            end

            if j == 3 then --nickname
                poke_data[j] = hexToString(data_str) .. "_"
            elseif j == 4 then
                data_values = decryptData(data_str,poke_data[1],poke_data[2])
                --[[for now keep as is but in the future we will add a section for each 12 byte section and have it be
                    [4] = Growth
                    [5] = Attacks
                    [6] = EVs & Conditions
                    [7] = Miscellaneous
                    [8] = ... All values after encypted data (we will now add these 4 sections and remove the encrypted data section since it provides no info for the user)
                    may add more sections since each section above has several subsections
                ]]
                poke_data[j] = data_values["G"] .. data_values["A"] .. data_values["E"] .. data_values["M"] .. "_"
                --poke_data[j] = data_str .. "_"
            else
                poke_data[j] = data_str .. "_"
            end
        end
        poke_data[#poke_data + 1] = "eol"
        party_data[i] = {table.unpack(poke_data)}
    end

    --aight now we can print data to a file (should be possible *gulp*)

    file = io.open("test.txt","w")

    if file then
        for index,pokemon in ipairs(party_data) do
            for internal_index,data in ipairs(pokemon) do
                file:write(data)
            end
            file:write("\n")
        end
        file:close()
        console:log("Successfully wrote all data to file.")
    else
        console:log("Error when saving data to a file...")
    end
end

--[[
    found the 'ascii' table for poke characters here:
    https://bulbapedia.bulbagarden.net/wiki/Character_encoding_(Generation_III)#Western
    probably just make a simple array that corresponds with the hex value (0-F nested array) (every byte is a character)
--]]
function hexToString(str)
    --the ascii table for pokemon emerald
    hex_dictionary = {
        ["0"] = {["0"] = " ", ["1"] = "À", ["2"] = "Á",["3"] = "Â",["4"] = "Ç",["5"] = "È",["6"] = "É",["7"] = "Ê",["8"] = "Ë",["9"] = "Ì",["a"] = "",["b"] = "Î",["c"] = "Ï",["d"] = "Ò",["e"] = "Ó",["f"] = "Ô"},
        ["1"] = {["0"] = "Œ", ["1"] = "Ù", ["2"] = "Ú",["3"] = "Û",["4"] = "Ñ",["5"] = "ß",["6"] = "à",["7"] = "á",["8"] = "",["9"] = "ç",["a"] = "è",["b"] = "é",["c"] = "ê",["d"] = "ë",["e"] = "ì",["f"] = ""},
        ["2"] = {["0"] = "î", ["1"] = "ï", ["2"] = "ò",["3"] = "ó",["4"] = "ô",["5"] = "œ",["6"] = "ù",["7"] = "ú",["8"] = "û",["9"] = "ñ",["a"] = "º",["b"] = "ª",["c"] = "ᵉʳ",["d"] = "&",["e"] = "+",["f"] = ""},
        ["3"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "Lv",["5"] = "=",["6"] = ";",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["4"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["5"] = {["0"] = "▯", ["1"] = "¿", ["2"] = "¡",["3"] = "PK",["4"] = "MN",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "Í",["b"] = "%",["c"] = "(",["d"] = ")",["e"] = "",["f"] = ""},
        ["6"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "â",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = "í"},
        ["7"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "↑",["a"] = "↓",["b"] = "←",["c"] = "→",["d"] = "*",["e"] = "*",["f"] = "*"},
        ["8"] = {["0"] = "*", ["1"] = "*", ["2"] = "*",["3"] = "*",["4"] = "ᵉ",["5"] = "<",["6"] = ">",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["9"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["a"] = {["0"] = "ʳᵉ", ["1"] = "0", ["2"] = "1",["3"] = "2",["4"] = "3",["5"] = "4",["6"] = "5",["7"] = "6",["8"] = "7",["9"] = "8",["a"] = "9",["b"] = "!",["c"] = "?",["d"] = ".",["e"] = "-",["f"] = "'"},
        ["b"] = {["0"] = "‥", ["1"] = "\"", ["2"] = "\"",["3"] = "'",["4"] = "'",["5"] = "♂",["6"] = "♀",["7"] = "$",["8"] = ",",["9"] = "",["a"] = "/",["b"] = "A",["c"] = "B",["d"] = "C",["e"] = "D",["f"] = "E"},
        ["c"] = {["0"] = "F", ["1"] = "G", ["2"] = "H",["3"] = "I",["4"] = "J",["5"] = "K",["6"] = "L",["7"] = "M",["8"] = "N",["9"] = "O",["a"] = "P",["b"] = "Q",["c"] = "R",["d"] = "S",["e"] = "T",["f"] = "U"},
        ["d"] = {["0"] = "V", ["1"] = "W", ["2"] = "X",["3"] = "Y",["4"] = "Z",["5"] = "a",["6"] = "b",["7"] = "c",["8"] = "d",["9"] = "e",["a"] = "f",["b"] = "g",["c"] = "h",["d"] = "i",["e"] = "j",["f"] = "k"},
        ["e"] = {["0"] = "l", ["1"] = "m", ["2"] = "n",["3"] = "o",["4"] = "p",["5"] = "q",["6"] = "r",["7"] = "s",["8"] = "t",["9"] = "u",["a"] = "v",["b"] = "w",["c"] = "x",["d"] = "y",["e"] = "z",["f"] = "►"},
        ["f"] = {["0"] = ":", ["1"] = "Ä", ["2"] = "Ö",["3"] = "Ü",["4"] = "ä",["5"] = "ö",["6"] = "ü",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""}
    }

    --for now we'll assume the var str is a string of hex values with an even length 
    -- Maybe we can reverse only characters when grabbing the data instead of way after (add if j == 3 reverse data)
    cur_str = str
    return_str = ""
    while #cur_str >= 2 do
        index_i = string.sub(cur_str,1,1)
        index_j = string.sub(cur_str,2,2)
        --accidentally wrote the indexes in the wrong order...whoops lol
        return_str = return_str .. hex_dictionary[index_j][index_i]

        if #cur_str == 2 then
            cur_str = ""
        else
            cur_str = string.sub(cur_str,3)
        end
    end

    return return_str
end

--[[
    need to handle the 48 bytes of encrypted data located in each poke in [4]
    each 12 byte block corresponds with the data for each section
    the data_order array will contain the correct order depending on the trainer id and personality value of the individual poke
--]]
function decryptData(enc_data,pers_val,t_id)
    --TODO: after switching to original values, we arent getting the correct amount of data back after decrypting (should be 48 bytes)
    --first get the specific order by doing personality value mod 24 (gonna have to do mod 24 +1 since array is index base 1 not 0)
    data_order = {"GAEM","AGEM","EGAM","MGAE","GAME","AGME","EGMA","MGEA","GEAM","AEGM","EAGM","MAGE","GEMA","AEMG","EAMG","MAEG","GMAE","AMGE","EMGA","MEGA","GMEA","AMEG","EMAG","MEAG"}
    return_dict = {["G"] = "", ["A"] = "", ["E"] = "", ["M"] = ""}
    
    --need the values as numbs rather than hex
    personality = tonumber(string.sub(pers_val,1,-2), 16)
    trainer_id = tonumber(string.sub(t_id,1,-2), 16)
    
    order_id = (personality % 24) + 1

    encryption_key = personality ~ trainer_id

    --decrypt the data by first xor the personality value and trainer id: personality ~ trainerid;
    -- then we have to xor the above value with the data 4 bytes at a time
    -- also need to sort it into a dictionary that will be returned
    current_order = data_order[order_id]
    for i=1,4 do
        section_start = ((i-1) * 12 * 2) + 1
        section_end = i * 12 * 2
        section_data = string.sub(enc_data,section_start,section_end)
        decrypted_section = ""
        for j=1,3 do
            str_start = ((j-1) * 4 * 2) + 1
            str_end = j * 4 * 2
            --some issue here, its not getting each section of 4
            decrypted_four = string.sub(section_data,str_start,str_end)
            decrypted_four = tonumber(decrypted_four,16)

            decrypted_four = decrypted_four ~ encryption_key

            decrypted_section = decrypted_section .. string.format("%x",decrypted_four)
        end
        section_id = string.sub(current_order,i,i)
        return_dict[section_id] = decrypted_section
    end

    return return_dict
end

-- TODO: Gonna have to redo most code to work with the reversed hex values that are given
-- also many poke dont correlate to the correct data; only some are correct for encrypted data (first two bytes should be the pokedex num)


--callbacks can probably allow me to call get_data every frame (how cpu intensive though?)
callbacks:add("frame",get_data)