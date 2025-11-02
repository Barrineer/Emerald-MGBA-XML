# Emerald-MGBA-XML
A simple script for mgba that gets specific data from mgba's memory and prints that data to a file called poke_data.xml
This script constantly updates the xml file (currently runs every frame but I would like to change this)
I mainly created this for use with some sort of UI (for my use case I will be using excel) so this is just the data portion of the whole script for now.

Current operational script to use: src/testModules.lua

TODO:
1. split the code into modules instead of all in one file UNLESS a single file has faster load times.
2. possibly add a config file for changing things such as the game being run (Emerald,FireRed,Ruby,Sapphire) or the name of the output file for example
3. Add data addresses for getting the data for other games than just Emerald
4. Figure out where ability data is stored (mainly important for when a randomizer is used and the abilities for poke are shuffled)
5. Add a standalone customizable UI (for now using excel for quickly visualizing the data)
