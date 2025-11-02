# Emerald-MGBA-XML
A simple script for mgba that gets specific data from mgba's memory and prints that data to a file called poke_data.xml.
Tested on Windows 11 using mgba version 0.10.5
This script constantly updates the xml file (currently runs every frame but I would like to change this).
I mainly created this for use with some sort of UI (for my use case I will be using excel) so this is just the data portion of the whole script for now.

Current operational script to use: src/testModules.lua
Current output file: poke_data.xml

Instructions:
1. Add the mgba emulator file to this location (so the xml file prints to this same address)
2. Open mgba and load Emerald.
3. Under Tools click Scripting...
4. In the top left of the new scripting window that opens, click File > Load Script
5. Navigate to where this folder is located (Emerald-MGBA-XML) and click src > testModules.lua
6. There should be a console message saying "Successfully wrote all data to file." if successful and poke_data.xml will be updated

TODO:
1. Figure out a more appropriate callback function that doesn't run every in game frame (I would rather have a callback that runs every few seconds instead of every frame if possible)
2. Split the code into modules instead of all in one file UNLESS a single file has faster load times.
3. Add versioning
4. Possibly add a config file for changing things such as the game being run (Emerald,FireRed,Ruby,Sapphire) or the name of the output file for example
5. Add data addresses for getting the data for other games than just Emerald
6. Figure out where ability data is stored (mainly important for when a randomizer is used and the abilities for poke are shuffled)
7. Add a standalone customizable UI (for now using excel for quickly visualizing the data)
