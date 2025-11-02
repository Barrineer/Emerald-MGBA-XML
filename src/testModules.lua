--Decided to do this without modules; Memory is preserved so files loaded usin require() are cached, difficult to debug and takes up more memory.
-- maybe after testing we can have the classes in their own files

-----------------------------------------------------------------------------------

--[[
    Start PokeData Class Definition
--]]
PokeData = {}

function PokeData:new(address)

    local t = {}
    setmetatable(t,self)
    self.__index = self

    --[[
        Define variables needed
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

    Gonna need variables for all the predefined addresses (or just the first value and the offsets needed)
    Also the decrypted values
    --]]
    location = {
    ["PersonalityValue"] = {0,4},
    ["Tid"] = {4,4},
    ["Nickname"] = {8,10},
    ["EncryptedData"] = {32,48},
    ["StatusCondition"] = {80,4},
    ["Level"] = {84,1},
    ["HPCurrent"] = {86,2},
    ["HPMax"] = {88,2},
    ["Attack"] = {90,2},
    ["Defence"] = {92,2},
    ["Speed"] = {94,2},
    ["SpecialAttack"] = {96,2},
    ["SpecialDefence"] = {98,2}}

    for i,v in pairs(location) do
        t[i] = fetchData(address,v[2],v[1])
    end

    --add nickname conversion here
    nickname = toPokeAscii(t["Nickname"])
    t["Nickname"] = nickname

    --add decrypt code here
    decryptedData = decryptData(t["EncryptedData"],t["PersonalityValue"],t["Tid"])

    sectionData = getSectionData(decryptedData)

    --normalize data from fetchdata call
    t["StatusCondition"] = tostring(tonumber(t["StatusCondition"],16))
    t["Level"] = tostring(tonumber(t["Level"],16))
    t["HPCurrent"] = tostring(tonumber(t["HPCurrent"],16))
    t["HPMax"] = tostring(tonumber(t["HPMax"],16))
    t["Attack"] = tostring(tonumber(t["Attack"],16))
    t["Defence"] = tostring(tonumber(t["Defence"],16))
    t["Speed"] = tostring(tonumber(t["Speed"],16))
    t["SpecialAttack"] = tostring(tonumber(t["SpecialAttack"],16))
    t["SpecialDefence"] = tostring(tonumber(t["SpecialDefence"],16))

    --we could remove encrypted data since we dont actually need it anymore
    t["EncryptedData"] = nil

    for j,w in pairs(sectionData) do
        t[j] = w
    end

    return t

end

function PokeData.tostring(data)
    returnStr = "{\n"

    --currently, all data is printed in random order

    for i,v in pairs(data) do
        returnStr = returnStr .. i .. ": " .. v .. "\n"
    end

    return returnStr .. "}\n"
end

function PokeData.print(str)
    console:log(PokeData.tostring(str))
end

--[[
    End PokeData Class Definition
--]]

-----------------------------------------------------------------------------------

--[[
    Start EmeraldData Class Definition
--]]
EmeraldData = {}

function EmeraldData:new()

    local t = {}
    setmetatable(t,self)
    self.__index = self

    start_addresses = {0x020244EC,0x02024550,0x020245B4,0x02024618,0x0202467C,0x020246E0}

    --NICE TO HAVE could add a fetch for getting total # of party poke using the address (4 byte long right before any poke save data) instead of always fetching all 6 poke data

    for i,v in ipairs(start_addresses) do
        pokeIndex = "p" .. i
        t[pokeIndex] = PokeData:new(start_addresses[i])
    end

    return t

end

function EmeraldData.tostring(data)
    --we can keep the regular pokedata tostring but here it must be ready to print for an xml file
    --we'll remove any pokedata tostring calls here.
    returnStr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"

    --We'll organize all data in alphabetical order to normalize the order of the data
    order = {}
    p1 = data["p1"]

    --get all keys
    for key,value in pairs(p1) do
        table.insert(order,key)
    end

    table.sort(order)

    returnStr = returnStr .. "<party>\n"

    for i=1,6 do
        returnStr = returnStr .. "\t<pokemon number=\"" .. i .. "\">\n"
        for j=1,#order do
            element = order[j]
            returnStr = returnStr .. "\t\t<" .. element .. ">"

            returnStr = returnStr .. data["p"..i][element]

            returnStr = returnStr .. "</" .. element .. ">\n"
        end
        returnStr = returnStr .. "\t</pokemon>\n"
    end

    returnStr = returnStr .. "</party>"

    --[[ old code
    for i=1,6 do
        returnStr = returnStr .. "Pokemon " .. i .. ": " .. PokeData.tostring(data["p"..i]) .. "\n"
    end
    --]]
    return returnStr
end

function EmeraldData.print(str)
    --we can change this to be a print to file function instead of console log for our purposes
    printToFile(EmeraldData.tostring(str))
end

--[[
    End EmeraldData Class Definition
--]]

-----------------------------------------------------------------------------------

--[[
    Start Helper functions
--]]

-- Gets the value of the given address based on the number of bytes given. If an offset is given, it will increment the address by that many bytes.
-- If the numBytes is greater than 4, it will continue to get the data in chunks. Returns the data in a hex string.
function fetchData(address,numBytes,offset)
    returnVal = ""

    if offset ~= nil and offset > 0 then
        address = address + offset
    end

    curBytes = numBytes
    prevBytes = 0
    while curBytes >= 1 do
        address = address + prevBytes
        if numBytes == 1 then
            returnVal = returnVal .. string.format("%08x",emu:read8(address))
            prevBytes = 1
            curBytes = curBytes - 1
        elseif numBytes == 2 then
            returnVal = returnVal .. string.format("%08x",emu:read16(address))
            prevBytes = 2
            curBytes = curBytes - 2
        else
            returnVal = returnVal .. string.format("%08x",emu:read32(address))
            prevBytes = 4
            curBytes = curBytes - 4
        end
    end

    return returnVal

end

-- Translates the hex value to a readable string of characters
function toPokeAscii(hex)
    --removed extra chars
    hex_dictionary = {
        ["0"] = {["0"] = " ", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["1"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "",["e"] = "",["f"] = ""},
        ["2"] = {["0"] = "", ["1"] = "", ["2"] = "",["3"] = "",["4"] = "",["5"] = "",["6"] = "",["7"] = "",["8"] = "",["9"] = "",["a"] = "",["b"] = "",["c"] = "",["d"] = "&",["e"] = "+",["f"] = ""},
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
    --reverse every 4 bytes
    --only need 10 bytes...remove extras
    correct_order = string.reverse(string.sub(hex,1,8)) .. string.reverse(string.sub(hex,9,16)) .. string.reverse(string.sub(hex,21,24))
    return_str = ""

    while #correct_order >= 2 do
        index_i = string.sub(correct_order,1,1)
        index_j = string.sub(correct_order,2,2)
        --accidentally wrote the indexes in the wrong order...whoops lol
        return_str = return_str .. hex_dictionary[index_j][index_i]

        if #correct_order == 2 then
            correct_order = ""
        else
            correct_order = string.sub(correct_order,3)
        end
    end

    return return_str
end

-- Returns the decrypted data given by using the personality value (p) and the trainer id (t)
function decryptData(hex,p,t)
    data_order = {"GAEM","GAME","GEAM","GEMA","GMAE","GMEA","AGEM","AGME","AEGM","AEMG","AMGE","AMEG","EGAM","EGMA","EAGM","EAMG","EMGA","EMAG","MGAE","MGEA","MAGE","MAEG","MEGA","MEAG"}
    return_dict = {["G"] = "", ["A"] = "", ["E"] = "", ["M"] = ""}
    result = {}

    encryption_key = tonumber(p,16) ~ tonumber(t,16)
    order_id = (tonumber(p,16) % 24) + 1
    --TODO change all address calls since we already have the hex value
    for i=1,12 do
        section = ""
        start_index = ((i-1) * 8) + 1
        end_index = i * 8
        cur_4 = string.sub(hex,start_index,end_index)
        result[i] = tonumber(cur_4,16) ~ encryption_key

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
    return return_dict
end

--Assumes the hex is given as a string; Returns the hex value as a binary value
function convertHexBinary(hex)
    hex_binary_dict = {
        ['0'] = "0000", ['1'] = "0001", ['2'] = "0010", ['3'] = "0011",
        ['4'] = "0100", ['5'] = "0101", ['6'] = "0110", ['7'] = "0111",
        ['8'] = "1000", ['9'] = "1001", ['A'] = "1010", ['B'] = "1011",
        ['C'] = "1100", ['D'] = "1101", ['E'] = "1110", ['F'] = "1111",
        ['a'] = "1010", ['b'] = "1011", ['c'] = "1100", ['d'] = "1101",
        ['e'] = "1110", ['f'] = "1111"}

    result_binary = ""

    for b=1,#hex do
        result_binary = result_binary .. hex_binary_dict[string.sub(hex,b,b)]
    end

    return result_binary
end

--Gets the needed section data from the unencrypted data
function getSectionData(data)
    --add each subsection here
    --[[

        Subsection Analysis
        Example data for pokemon 6 [Lotad]:
        [G] = 000001270000006000004600
        [A] = 002d0136000000000000240d
        [E] = 000000000000000000000000
        [M] = 2184110023caf4ca00000000

        FYI: the way mgba grabs the hex values is a bit weird so these values may be in the incorrect order as stated in the wiki.
        Lets create our own table:

        Growth : 00 00 01 27 00 00 00 60 00 00 46 00
        [Item Held][2] = 0000 ; Must be the first 2 bytes; Lotad has no item currently.
        [Species][2] = 0127 ; Wiki says it is the first value shown so 01 27 MUST be the correct value.
        [Experience][4] = 00 00 00 60 ; Middle 4 bytes
        [Unused][2] = 00 00 ; the unused bytes seem to be the two before friendship
        [Friendship][1] = 46 ; Every poke has a friendship value so this must be it
        [PP bonuses][1] = 00 ; Must be the very last byte on the right side

        Attacks : 002d 0021 0000 00bd 00 06 28 21
        Moves correspond with the list here :https://bulbapedia.bulbagarden.net/wiki/List_of_moves
        HAVE FUN HARDCODING THIS LIST AHAHAHHAHAHAHAHAHAH :(
        [Move 2][2] : 002d [45] - Growl
        [Move 1][2] : 0021 [33] - Tackle
        [Move 4][2] : 0000
        [Move 3][2] : 00bd [189] - Mud-Slap
        [PP4][1] : 00
        [PP3][1] : 06 [6]
        [PP2][1] : 28 [40]
        [PP1][1] : 21 [33]

        We'll look at our starter, Mudkip since it is the only poke that has defeated anything.
        Example data for pokemon 1 [Mudkip]:
        [G] = 0000011b000000f600005300
        [A] = 002d0021000000bd00062821
        [E] = 030002020000010100000000
        [M] = 218510000ee8ce6300000000

        EVs & Condition : 03 00 02 02 00 00 01 01 00 00 00 00
        After testing, the order is:
        [Speed][1] : Byte 1
        [Defence][1] : Byte 2
        [Attack][1] : Byte 3
        [HP][1] : Byte 4
        [][1]
        [][1]
        [Sp Defence][1] : Byte 7
        [Sp Attack][1] : Byte 8
        [][1]
        [][1]
        [][1]
        [][1]

        For misc, we'll have to look at the individual bits for the correct info 
        Miscellaneous : 21 84 11 00 23 ca f4 ca 00 00 00 00
        [Origins Info][2] : First 2 bytes; gonna ignore this since not much necessary info here
        [Met Location][1] : 11 , see wiki; 0x11 is route 102 so correct
        [Pokerus][1] : 00 , no pokerus on lotad
        [IV, Egg, Ability][4] : Middle 4 bytes 23 ca f4 ca ; This is where you'll have to check the bits; every 5 bits corresponds to a stat
        [Ribbons, Obedience][4] Last 4 bytes; gonna ignore since ribbons dont matter and obedience is only for fateful encounters (Mew, Deoxys)

        Analysis on IVs, Egg, Ability: Is given as a full 4 byte value so it should be in the correct order
        Using mudkip's data : 0ee8ce63 = 01110111010001100111001100011 in bits (binary)
        script binary correction: 0 0 00111 01110 10001 10011 10011 00011
        Use function convertHexBinary(hex) to convert from hex to binary
        Assuming the order is correct and we don't have to move any bytes around the order is:
        [Ability][1 bit] : 0
        [Egg][1 bit] : 0
        [Sp Defence][5 bits] : 00111 = 7 oof
        [Sp Attack][5 bits] : 01110 = 14
        [Speed][5 bits] : 10001 = 17
        [Defence][5 bits] : 10011 = 19
        [Attack][5 bits] : 10011 = 19
        [HP][5 bits] : 00011 = 3 yikes
    --]]

    returnArr = {}
    growth = data["G"]
    attacks = data["A"]
    ev = data["E"]
    misc = data["M"]
    misc_IV = convertHexBinary(string.sub(data["M"],9,16))

    --Growth
    returnArr["Item_Held"] = getItem(tonumber(string.sub(growth,1,4),16))
    returnArr["Species"] = getName(tonumber(string.sub(growth,5,8),16))
    returnArr["Experience"] = tostring(tonumber(string.sub(growth,9,16),16))
    returnArr["Friendship"] = tostring(tonumber(string.sub(growth,21,22),16))
    returnArr["PP_Bonuses"] = tostring(tonumber(string.sub(growth,23,24),16))

    --Attacks
    -- 354 Total moves up to Gen 3
    --TODO add list of moves to reference (getMove function)
    returnArr["Move_1"] = getMove(tonumber(string.sub(attacks,5,8),16))
    returnArr["Move_2"] = getMove(tonumber(string.sub(attacks,1,4),16))
    returnArr["Move_3"] = getMove(tonumber(string.sub(attacks,13,16),16))
    returnArr["Move_4"] = getMove(tonumber(string.sub(attacks,9,12),16))
    returnArr["PP_1"] = tostring(tonumber(string.sub(attacks,23,24),16))
    returnArr["PP_2"] = tostring(tonumber(string.sub(attacks,21,22),16))
    returnArr["PP_3"] = tostring(tonumber(string.sub(attacks,19,20),16))
    returnArr["PP_4"] = tostring(tonumber(string.sub(attacks,17,18),16))

    --EVs & Condition
    returnArr["Speed_EV"] = tostring(tonumber(string.sub(ev,1,2),16))
    returnArr["Defence_EV"] = tostring(tonumber(string.sub(ev,3,4),16))
    returnArr["Attack_EV"] = tostring(tonumber(string.sub(ev,5,6),16))
    returnArr["HP_EV"] = tostring(tonumber(string.sub(ev,7,8),16))
    returnArr["Sp_Defence_EV"] = tostring(tonumber(string.sub(ev,13,14),16))
    returnArr["Sp_Attack_EV"] = tostring(tonumber(string.sub(ev,15,16),16))

    --Miscellaneous
    returnArr["Met_Location"] = getLocation(tonumber(string.sub(misc,5,6),16)+1)
    returnArr["Ability"] = tostring(tonumber(string.sub(misc_IV,1,2),2))
    returnArr["Sp_Defence_IV"] = tostring(tonumber(string.sub(misc_IV,3,7),2))
    returnArr["Sp_Attack_IV"] = tostring(tonumber(string.sub(misc_IV,8,12),2))
    returnArr["Speed_IV"] = tostring(tonumber(string.sub(misc_IV,13,17),2))
    returnArr["Defence_IV"] = tostring(tonumber(string.sub(misc_IV,18,22),2))
    returnArr["Attack_IV"] = tostring(tonumber(string.sub(misc_IV,23,27),2))
    returnArr["HP_IV"] = tostring(tonumber(string.sub(misc_IV,28,32),2))

    return returnArr

end

--returns the specified move based on the index given
function getMove(move_id)

    if move_id == 0 or move_id == false or move_id == nil then
        return "None"
    end

    poke_move_dict = {"Pound","Karate Chop","Double Slap","Comet Punch","Mega Punch","Pay Day","Fire Punch","Ice Punch","Thunder Punch","Scratch","Vise Grip","Guillotine","Razor Wind","Swords Dance","Cut","Gust","Wing Attack","Whirlwind","Fly","Bind","Slam","Vine Whip","Stomp","Double Kick","Mega Kick","Jump Kick","Rolling Kick","Sand Attack","Headbutt","Horn Attack","Fury Attack","Horn Drill","Tackle","Body Slam","Wrap","Take Down","Thrash","Double-Edge","Tail Whip","Poison Sting","Twineedle","Pin Missile","Leer","Bite","Growl","Roar","Sing","Supersonic","Sonic Boom","Disable","Acid","Ember","Flamethrower","Mist","Water Gun",
        "Hydro Pump","Surf","Ice Beam","Blizzard","Psybeam","Bubble Beam","Aurora Beam","Hyper Beam","Peck","Drill Peck","Submission","Low Kick","Counter","Seismic Toss","Strength","Absorb","Mega Drain","Leech Seed","Growth","Razor Leaf","Solar Beam","Poison Powder","Stun Spore","Sleep Powder","Petal Dance","String Shot","Dragon Rage","Fire Spin","Thunder Shock","Thunderbolt","Thunder Wave","Thunder","Rock Throw","Earthquake","Fissure","Dig","Toxic","Confusion","Psychic","Hypnosis","Meditate","Agility","Quick Attack","Rage","Teleport","Night Shade","Mimic","Screech","Double Team","Recover","Harden","Minimize",
        "Smokescreen","Confuse Ray","Withdraw","Defense Curl","Barrier","Light Screen","Haze","Reflect","Focus Energy","Bide","Metronome","Mirror Move","Self-Destruct","Egg Bomb","Lick","Smog","Sludge","Bone Club","Fire Blast","Waterfall","Clamp","Swift","Skull Bash","Spike Cannon","Constrict","Amnesia","Kinesis","Soft-Boiled","High Jump Kick","Glare","Dream Eater","Poison Gas","Barrage","Leech Life","Lovely Kiss","Sky Attack","Transform","Bubble","Dizzy Punch","Spore","Flash","Psywave","Splash","Acid Armor","Crabhammer","Explosion","Fury Swipes","Bonemerang","Rest","Rock Slide","Hyper Fang","Sharpen","Conversion",
        "Tri Attack","Super Fang","Slash","Substitute","Struggle","Sketch","Triple Kick","Thief","Spider Web","Mind Reader","Nightmare","Flame Wheel","Snore","Curse","Flail","Conversion Normal","Aeroblast","Cotton Spore","Reversal","Spite","Powder Snow","Protect","Mach Punch","Scary Face","Feint Attack","Sweet Kiss","Belly Drum","Sludge Bomb","Mud-Slap","Octazooka","Spikes","Zap Cannon","Foresight","Destiny Bond","Perish Song","Icy Wind","Detect","Bone Rush","Lock-On","Outrage","Sandstorm","Giga Drain","Endure","Charm","Rollout","False Swipe","Swagger","Milk Drink","Spark","Fury Cutter","Steel Wing","Mean Look",
        "Attract","Sleep Talk","Heal Bell","Return","Present","Frustration","Safeguard","Pain Split","Sacred Fire","Magnitude","Dynamic Punch","Megahorn","Dragon Breath","Baton Pass","Encore","Pursuit","Rapid Spin","Sweet Scent","Iron Tail","Metal Claw","Vital Throw","Morning Sun","Synthesis","Moonlight","Hidden Power","Cross Chop","Twister","Rain Dance","Sunny Day","Crunch","Mirror Coat","Psych Up","Extreme Speed","Ancient Power","Shadow Ball","Future Sight","Rock Smash","Whirlpool","Beat Up","Fake Out","Uproar","Stockpile","Spit Up","Swallow","Heat Wave","Hail","Torment","Flatter","Will-O-Wisp","Memento","Facade",
        "Focus Punch","Smelling Salts","Follow Me","Nature Power","Charge","Taunt","Helping Hand","Trick","Role Play","Wish","Assist","Ingrain","Superpower","Magic Coat","Recycle","Revenge","Brick Break","Yawn","Knock Off","Endeavor","Eruption","Skill Swap","Imprison","Refresh","Grudge","Snatch","Secret Power","Dive","Arm Thrust","Camouflage","Tail Glow","Luster Purge","Mist Ball","Feather Dance","Teeter Dance","Blaze Kick","Mud Sport","Ice Ball","Needle Arm","Slack Off","Hyper Voice","Poison Fang","Crush Claw","Blast Burn","Hydro Cannon","Meteor Mash","Astonish","Weather Ball","Aromatherapy","Fake Tears","Air Cutter",
        "Overheat","Odor Sleuth","Rock Tomb","Silver Wind","Metal Sound","Grass Whistle","Tickle","Cosmic Power","Water Spout","Signal Beam","Shadow Punch","Extrasensory","Sky Uppercut","Sand Tomb","Sheer Cold","Muddy Water","Bullet Seed","Aerial Ace","Icicle Spear","Iron Defense","Block","Howl","Dragon Claw","Frenzy Plant","Bulk Up","Bounce","Mud Shot","Poison Tail","Covet","Volt Tackle","Magical Leaf","Water Sport","Calm Mind","Leaf Blade","Dragon Dance","Rock Blast","Shock Wave","Water Pulse","Doom Desire","Psycho Boost",}
    
    return poke_move_dict[move_id]
end

function getName(pokedex_id)
    if pokedex_id == 0 or pokedex_id == false or pokedex_id == nil then
        return "None"
    end
    poke_dict = {"?","Bulbasaur","Ivysaur","Venusaur","Charmander","Charmeleon","Charizard","Squirtle","Wartortle","Blastoise","Caterpie","Metapod","Butterfree","Weedle","Kakuna","Beedrill","Pidgey","Pidgeotto","Pidgeot","Rattata","Raticate","Spearow","Fearow","Ekans","Arbok","Pikachu","Raichu","Sandshrew","Sandslash","Nidoran♀","Nidorina","Nidoqueen","Nidoran♂","Nidorino","Nidoking","Clefairy","Clefable","Vulpix","Ninetales","Jigglypuff","Wigglytuff","Zubat","Golbat","Oddish","Gloom","Vileplume","Paras","Parasect","Venonat","Venomoth","Diglett","Dugtrio","Meowth","Persian","Psyduck","Golduck","Mankey","Primeape","Growlithe","Arcanine","Poliwag","Poliwhirl","Poliwrath","Abra","Kadabra","Alakazam","Machop","Machoke","Machamp","Bellsprout","Weepinbell","Victreebel","Tentacool","Tentacruel","Geodude","Graveler","Golem","Ponyta","Rapidash","Slowpoke",
        "Slowbro","Magnemite","Magneton","Farfetch'd","Doduo","Dodrio","Seel","Dewgong","Grimer","Muk","Shellder","Cloyster","Gastly","Haunter","Gengar","Onix","Drowzee","Hypno","Krabby","Kingler","Voltorb","Electrode","Exeggcute","Exeggutor","Cubone","Marowak","Hitmonlee","Hitmonchan","Lickitung","Koffing","Weezing","Rhyhorn","Rhydon","Chansey","Tangela","Kangaskhan","Horsea","Seadra","Goldeen","Seaking","Staryu","Starmie","Mr. Mime","Scyther","Jynx","Electabuzz","Magmar","Pinsir","Tauros","Magikarp","Gyarados","Lapras","Ditto","Eevee","Vaporeon","Jolteon","Flareon","Porygon","Omanyte","Omastar","Kabuto","Kabutops","Aerodactyl","Snorlax","Articuno","Zapdos","Moltres","Dratini","Dragonair","Dragonite","Mewtwo","Mew","Chikorita","Bayleef","Meganium","Cyndaquil","Quilava","Typhlosion","Totodile","Croconaw","Feraligatr","Sentret","Furret",
        "Hoothoot","Noctowl","Ledyba","Ledian","Spinarak","Ariados","Crobat","Chinchou","Lanturn","Pichu","Cleffa","Igglybuff","Togepi","Togetic","Natu","Xatu","Mareep","Flaaffy","Ampharos","Bellossom","Marill","Azumarill","Sudowoodo","Politoed","Hoppip","Skiploom","Jumpluff","Aipom","Sunkern","Sunflora","Yanma","Wooper","Quagsire","Espeon","Umbreon","Murkrow","Slowking","Misdreavus","Unown","Wobbuffet","Girafarig","Pineco","Forretress","Dunsparce","Gligar","Steelix","Snubbull","Granbull","Qwilfish","Scizor","Shuckle","Heracross","Sneasel","Teddiursa","Ursaring","Slugma","Magcargo","Swinub","Piloswine","Corsola","Remoraid","Octillery","Delibird","Mantine","Skarmory","Houndour","Houndoom","Kingdra","Phanpy","Donphan","Porygon2","Stantler","Smeargle","Tyrogue","Hitmontop","Smoochum","Elekid","Magby","Miltank","Blissey","Raikou","Entei",
        "Suicune","Larvitar","Pupitar","Tyranitar","Lugia","Ho-Oh","Celebi","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","?","Treecko","Grovyle","Sceptile","Torchic","Combusken","Blaziken","Mudkip","Marshtomp","Swampert","Poochyena","Mightyena","Zigzagoon","Linoone","Wurmple","Silcoon","Beautifly","Cascoon","Dustox","Lotad","Lombre","Ludicolo","Seedot","Nuzleaf","Shiftry","Nincada","Ninjask","Shedinja","Taillow","Swellow","Shroomish","Breloom","Spinda","Wingull","Pelipper","Surskit","Masquerain","Wailmer","Wailord","Skitty","Delcatty","Kecleon","Baltoy","Claydol","Nosepass","Torkoal","Sableye","Barboach","Whiscash","Luvdisc","Corphish","Crawdaunt","Feebas","Milotic","Carvanha","Sharpedo","Trapinch","Vibrava","Flygon","Makuhita","Hariyama","Electrike","Manectric","Numel","Camerupt","Spheal","Sealeo","Walrein","Cacnea","Cacturne","Snorunt","Glalie","Lunatone","Solrock","Azurill","Spoink",
        "Grumpig","Plusle","Minun","Mawile","Meditite","Medicham","Swablu","Altaria","Wynaut","Duskull","Dusclops","Roselia","Slakoth","Vigoroth","Slaking","Gulpin","Swalot","Tropius","Whismur","Loudred","Exploud","Clamperl","Huntail","Gorebyss","Absol","Shuppet","Banette","Seviper","Zangoose","Relicanth","Aron","Lairon","Aggron","Castform","Volbeat","Illumise","Lileep","Cradily","Anorith","Armaldo","Ralts","Kirlia","Gardevoir","Bagon","Shelgon","Salamence","Beldum","Metang","Metagross","Regirock","Regice","Registeel","Kyogre","Groudon","Rayquaza","Latias","Latios","Jirachi","Deoxys","Chimecho","Pokemon Egg","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown","Unown",}
    return poke_dict[pokedex_id]
end

function getLocation(location_id)
    if location_id == 0 or location_id == false or location_id == nil then
        return "None"
    end
    poke_location_dict = {"Littleroot Town","Oldale Town","Dewford Town","Lavaridge Town","Fallarbor Town","Verdanturf Town","Pacifidlog Town","Petalburg City","Slateport City","Mauville City","Rustboro City","Fortree City","Lilycove City","Mossdeep City","Sootopolis City","Ever Grande City","Route 101","Route 102","Route 103","Route 104","Route 105","Route 106","Route 107","Route 108","Route 109","Route 110","Route 111","Route 112","Route 113","Route 114","Route 115","Route 116","Route 117","Route 118","Route 119","Route 120","Route 121","Route 122",
        "Route 123","Route 124","Route 125","Route 126","Route 127","Route 128","Route 129","Route 130","Route 131","Route 132","Route 133","Route 134","Underwater (Route 124)","Underwater (Route 126)","Underwater (Route 127)","Underwater (Route 128)","Underwater (Sootopolis City)","Granite Cave","Mt. Chimney","Safari Zone","Battle TowerRS/Battle FrontierE","Petalburg Woods","Rusturf Tunnel","Abandoned Ship","New Mauville","Meteor Falls","Meteor Falls (unused)","Mt. Pyre","Hideout* (Magma HideoutR/Aqua HideoutS)","Shoal Cave","Seafloor Cavern",
        "Underwater (Seafloor Cavern)","Victory Road","Mirage Island","Cave of Origin","Southern Island","Fiery Path","Fiery Path (unused)","Jagged Pass","Jagged Pass (unused)","Sealed Chamber","Underwater (Route 134)","Scorched Slab","Island Cave","Desert Ruins","Ancient Tomb","Inside of Truck","Sky Pillar","Secret Base","Ferry","Pallet Town","Viridian City","Pewter City","Cerulean City","Lavender Town","Vermilion City","Celadon City","Fuchsia City","Cinnabar Island","Indigo Plateau","Saffron City","Route 4 (Pokémon Center)",
        "Route 10 (Pokémon Center)","Route 1","Route 2","Route 3","Route 4","Route 5","Route 6","Route 7","Route 8","Route 9","Route 10","Route 11","Route 12","Route 13","Route 14","Route 15","Route 16","Route 17","Route 18","Route 19","Route 20","Route 21","Route 22","Route 23","Route 24","Route 25","Viridian Forest","Mt. Moon","S.S. Anne","Underground Path (Routes 5-6)","Underground Path (Routes 7-8)","Diglett's Cave","Victory Road","Rocket Hideout","Silph Co.","Pokémon Mansion","Safari Zone","Pokémon League","Rock Tunnel",
        "Seafoam Islands","Pokémon Tower","Cerulean Cave","Power Plant","One Island","Two Island","Three Island","Four Island","Five Island","Seven Island","Six Island","Kindle Road","Treasure Beach","Cape Brink","Bond Bridge","Three Isle Port","Sevii Isle 6","Sevii Isle 7","Sevii Isle 8","Sevii Isle 9","Resort Gorgeous","Water Labyrinth","Five Isle Meadow","Memorial Pillar","Outcast Island","Green Path","Water Path","Ruin Valley","Trainer Tower (exterior)","Canyon Entrance","Sevault Canyon","Tanoby Ruins","Sevii Isle 22","Sevii Isle 23",
        "Sevii Isle 24","Navel Rock","Mt. Ember","Berry Forest","Icefall Cave","Rocket Warehouse","Trainer Tower","Dotted Hole","Lost Cave","Pattern Bush","Altering Cave","Tanoby Chambers","Three Isle Path","Tanoby Key","Birth Island","Monean Chamber","Liptoo Chamber","Weepth Chamber","Dilford Chamber","Scufib Chamber","Rixy Chamber","Viapois Chamber","Ember Spa","Celadon Dept.FRLG","Aqua Hideout","Magma Hideout","Mirage Tower","Birth Island","Faraway Island","Artisan Cave","Marine Cave","Underwater (Marine Cave)","Terra Cave",
        "Underwater (Route 105)","Underwater (Route 125)","Underwater (Route 129)","Desert Underpass","Altering Cave","Navel Rock","Trainer Hill","(gift egg)","(in-game trade)","(fateful encounter)",}

    return poke_location_dict[location_id]

end

function getItem(item_id)

    if item_id == 0 or item_id == false or item_id == nil then
        return "None"
    end

    poke_item_dict = {"None","Master Ball","Ultra Ball","Great Ball","Poké Ball","Safari Ball","Net Ball","Dive Ball","Nest Ball","Repeat Ball","Timer Ball","Luxury Ball","Premier Ball","Potion","Antidote","Burn Heal","Ice Heal","Awakening","Paralyze Heal","Full Restore","Max Potion","Hyper Potion","Super Potion","Full Heal","Revive","Max Revive","Fresh Water","Soda Pop","Lemonade","Moomoo Milk","Energy Powder","Energy Root","Heal Powder","Revival Herb","Ether","Max Ether","Elixir","Max Elixir","Lava Cookie","Blue Flute","Yellow Flute","Red Flute","Black Flute","White Flute","Berry Juice","Sacred Ash","Shoal Salt","Shoal Shell","Red Shard","Blue Shard","Yellow Shard","Green Shard","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","HP Up","Protein","Iron","Carbos","Calcium","Rare Candy","PP Up","Zinc","PP Max","unknown","Guard Spec.","Dire Hit","X Attack","X Defense","X Speed","X Accuracy","X Sp. Atk","Poké Doll","Fluffy Tail","unknown","Super Repel","Max Repel","Escape Rope","Repel",
        "unknown","unknown","unknown","unknown","unknown","unknown","Sun Stone","Moon Stone","Fire Stone","Thunder Stone","Water Stone","Leaf Stone","unknown","unknown","unknown","unknown","Tiny Mushroom","Big Mushroom","unknown","Pearl","Big Pearl","Stardust","Star Piece","Nugget","Heart Scale","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","Orange Mail","Harbor Mail","Glitter Mail","Mech Mail","Wood Mail","Wave Mail","Bead Mail","Shadow Mail","Tropic Mail","Dream Mail","Fab Mail","Retro Mail","Cheri Berry","Chesto Berry","Pecha Berry","Rawst Berry","Aspear Berry","Leppa Berry","Oran Berry","Persim Berry","Lum Berry","Sitrus Berry","Figy Berry","Wiki Berry","Mago Berry","Aguav Berry","Iapapa Berry","Razz Berry","Bluk Berry","Nanab Berry","Wepear Berry","Pinap Berry","Pomeg Berry","Kelpsy Berry","Qualot Berry","Hondew Berry","Grepa Berry","Tamato Berry","Cornn Berry","Magost Berry","Rabuta Berry","Nomel Berry","Spelon Berry","Pamtre Berry","Watmel Berry","Durin Berry","Belue Berry",
        "Liechi Berry","Ganlon Berry","Salac Berry","Petaya Berry","Apicot Berry","Lansat Berry","Starf Berry","Enigma Berry","unknown","unknown","unknown","Bright Powder","White Herb","Macho Brace","Exp. Share","Quick Claw","Soothe Bell","Mental Herb","Choice Band","King's Rock","SilverPowder","Amulet Coin","Cleanse Tag","Soul Dew","Deep Sea Tooth","Deep Sea Scale","Smoke Ball","Everstone","Focus Band","Lucky Egg","Scope Lens","Metal Coat","Leftovers","Dragon Scale","Light Ball","Soft Sand","Hard Stone","Miracle Seed","Black Glasses","Black Belt","Magnet","Mystic Water","Sharp Beak","Poison Barb","Never-Melt Ice","Spell Tag","Twisted Spoon","Charcoal","Dragon Fang","Silk Scarf","Up-Grade","Shell Bell","Sea Incense","Lax Incense","Lucky Punch","Metal Powder","Thick Club","Stick","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown","unknown",
        "unknown","unknown","unknown","Red Scarf","Blue Scarf","Pink Scarf","Green Scarf","Yellow Scarf","Mach Bike","Coin Case","Itemfinder","Old Rod","Good Rod","Super Rod","S.S. Ticket","Contest Pass","unknown","Wailmer Pail","Devon Parts","Soot Sack","Basement Key","Acro Bike","Pokeblock Case","Letter","Eon Ticket","Red Orb","Blue Orb","Scanner","Go-Goggles","Meteorite","Key to Room 1","Key to Room 2","Key to Room 4","Key to Room 6","Storage Key","Root Fossil","Claw Fossil","Devon Scope","TM01","TM02","TM03","TM04","TM05","TM06","TM07","TM08","TM09","TM10","TM11","TM12","TM13","TM14","TM15","TM16","TM17","TM18","TM19","TM20","TM21","TM22","TM23","TM24","TM25","TM26","TM27","TM28","TM29","TM30","TM31","TM32","TM33","TM34","TM35","TM36","TM37","TM38","TM39","TM40","TM41","TM42","TM43","TM44","TM45","TM46","TM47","TM48","TM49","TM50","HM01","HM02","HM03","HM04","HM05","HM06","HM07","HM08","unknown","unknown","Parcel","Poke Flute","Secret Key","Bike Voucher","Gold Teeth","Old Amber","Card Key","Lift Key","Helix Fossil","Dome Fossil",
        "Silph Scope","Bicycle","Town Map","Vs. Seeker","Fame Checker","TM Case","Berry Pouch","Teachy TV","Tri-Pass","Rainbow Pass","Tea","MysticTicket","AuroraTicket","Powder Jar","Ruby","Sapphire","Magma Emblem","Old Sea Map",}

    return poke_item_dict[item_id]

end

function printToFile(str)
    file = io.open("poke_data.xml","w")

    if file then
        file:write(str)
        file:close()
        console:log("Successfully wrote all data to file.")
    else
        console:log("Error when saving data to a file...")
    end
end

--[[
    End Helper functions
--]]

-----------------------------------------------------------------------------------

--[[
    Main Code
--]]

function main()
    --add check for what frame we're on so we don't call this every frame

    --change seconds to decrease frequency
    seconds = 1
    frame = emu:currentFrame() % (60 * seconds)

    if frame == 0 then
        --this is where we would change the class called based on what game it is.
        pokemain = EmeraldData:new()
        EmeraldData.print(pokemain)
    end
    
end

--Testing callback
callbacks:add("frame",main)

--DONE change tostring to print data in json OR xml syntax for ease of use
--DONE handle encrypted data the same way as test.lua and add values to PokeData
--DONE implement toPokeAscii
--DONE get pokemon name from pokedex number obtained from encrypted data
--DONE add lookup for routes using link: https://bulbapedia.bulbagarden.net/wiki/List_of_locations_by_index_number_in_Generation_III

--DONE get held item data 
--NICE TO HAVE could get ability info for each poke but may need more research since there isn't a ability list or reference currently available for it
--TODO print EmeraldData into a xml file

--TODO add callback and look into alternatives to calling this code every frame.
