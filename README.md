# Pomomon Farm
![Godot](https://img.shields.io/badge/Godot-4.5.1-%23478CBF?logo=godot-engine)
![GDScript](https://img.shields.io/badge/GDScript-%23FFFFFF?logo=godot-engine)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)  
A single-player idle farming game, which can be utilized as a pomodoro timer.

## Description

This repository is simply a Godot project, which was developed solo in a very particular kind of workflow: Agile Software Development, or, SCRUM. The intention is to get familiar with the convention over the course of a few weeks within the context of a university project.

Archived here (the version/commit history is on a closed gitlab community and shall stay there), as described in a User Requirements document that I was given, is a graphically humble game, with motley features that all for their part posed a kind of learning opportunity regarding basic game development. Examples include save states, websocket connections and pathfinding on a 2d grid.

Perhaps development will not end (certainly slow down though) now that this project has from the academic standpoint. There are certain features I would like it to have that simply weren't feasible to squeeze into the given development time frame.

## Features

Here are some features and functions the game has that are noteworthy:
- manual tile set generation and management
    - A* pathfinding
- persistent save state storing via JSON
- configuration without recompilation via a JSON config file
- websocket connection ("wonder event")
- timer system

Potential additions in the future:
- more sound effects
- original graphical assets, to make the game look nicer and more visually cohesive
- alert system in the game screen, for various purposes such as explaining why an action failed
- support for more than 3 seed types at once in config

## Documentation

The code is appropriately commented to communicate what it does or what the approach to something is.  
For further (not-necessarily-technical) information regarding the game, see the Wiki.

The general structure of the project follows Godot conventions, i.e. all scripts are in the subdirectory `scripts/`, all scenes are in `scenes/`.
All other game assets are in `resources/` with no separation of file types because there are considerably few.
The test scripts reside in `test/unit/`, while the `addons/` folder contains files for the gut addon and can be ignored.

#### Important Nodes
The essential node tree summarized.

- **Screen Manager:** Root node of the entire game. Screen-independent management nodes are children of it, as well as the current screen. Switches screens by freeing the current screen child and replacing it with the respective new one.

  - **Game Screen:** This node is responsible for all "overarching" game logic, and those features that require a view of several different subsections of the game screen. E.g. committing an action is done both by looking at UI state and tile grid state. 

    - **Tile Set Manager:** Handles everything to do with the tile grid, including initializing it, moving the Pomomon, changing tile states, providing information of the grid, etc.
	- **UI:** Holds all of the UI containers, acts as an interface to UI elements and handles display logic.

  - **Start Screen:** Provides a visual interface mostly for save state management, and is the gateway to the Game Screen.

  - **Audio Manager:** Responsible for playing audio. All audio assets must be children of this node and played using it as an interface.
  - **Config Loader:** Responsible for parsing the Config file, and saving the contents (or fallback defaults) in static fields for the rest of the game to use.
  - **Save State 1-3:** Responsible for parsing and writing to their respective Save State file, and holding the contents in their fields, for other nodes to reference. Can be thought of as a cache.

#### Save States
Below is the expected structure of a Save State JSON file:
```
{
	"farmState": {
		"rows": (int), "cols": (int),
		"unlockedTiles": [ { "x": (int),"y": (int), "plantedBerryId": (int), "growthStage": (int), "watered": (bool), "withered": (bool) }, ... ] },
	"inventory": {
		"berrySeeds": { "0": (int), "1": (int), "2": (int)},
		"totalBerries": (int) },
	"timers": {
		"focusMinutes": (int), "focusSeconds": (int),
		"breakMinutes": (int), "breakSeconds": (int),
		"longBreakMinutes": (int), "longBreakSeconds": (int) },
	"session": {
		"focusPhasesCompleted": (int), "currentActivePhase": (String) }
} 
```
If `plantedBerryId` is null, there is no plant on this tile. The values of the fields `growthStage`, `watered`, `withered` are thus ignored.

If you are only here to play the game, I recommend _not_ manually editing these files in any way. The parsing is not as robust as it is for the config file which _does_ expect to be edited arbitrarily by the user.

## Installation / Prerequisites

Pomomon Farm is being developed in (pure) Godot; the programming language is exclusively gdscript.

To **work** on this project: 
- clone the repository  
- open the project in the Godot Game Engine (version 4.5.1).  

If you want to use or add unit tests:
- make sure the plugin "gut" (version 9.6.0) by bitwes is enabled in the project settings  

If you want to **play** the game, see the `binaries/` directory in the repository, which contains executables for Windows 11 and for Linux, both 64-Bit.
You may also make a binary yourself via the Godot Engine (having acquired the project as described above), suited to your Operating System, under "Project" -> "Export..." Note that exporting requires you to install export templates, which Godot will notify you of and prompt you to do.

#### Configuring the Game
The game can be played as-is. However, you may edit some game parameters by creating and editing the file `user://config.json`, where `user://` is an absolute OS-dependent path.  
For Windows, replace it with `%APPDATA%\Godot\app_userdata\PomomonFarm`.  
For Linux, replace it with `~/.local/share/godot/app_userdata/PomomonFarm`.  

This file is read on each start of the game application. If it is not found, a hardcoded default configuration is used instead.  
Below are the fields the configuration file can have (in JSON format):
```
{
    "server": {
    	"url":(String)
	},
	"fieldExtension": {
		"baseCost": (int),
		"increase": (float)
	},
	"berries" : [{"id":(int), "name":(String), "growthStages":(int), "harvestYield":(int), "seedCost":(int), "favoredSeasons":[(String)]}, ... ]     
}
```
The `"server"` key holds an entry for the url that is to be queried for the wonder event websocket connection. It is recommended to leave this as default (omit the key).

The `"berries"` array can contain an arbitrary amount of entries, but as of now any ids that aren't 0, 1 or 2 will be ignored. The id of a berry must be unique; it follows that 3 entries is the maximum that makes sense. Note that omitted fields of a berry entry will have fallback values applied to them.

The `"favoredSeasons"` array should be a subset of the set of strings: {"BREEZY", "WARM", "RAINY"}. I.e. one or zero of each.

## Credits / Sources / Tools

- Pomomon Sprite: Lara Schneck
- Plant textures: melonking's "texturetown" (melonking.net)
- Sky Background: sadgrl.online
- Sound effects: bfxr.net

## License
Licensed under the MIT License.
```
Copyright (c) 2025 Daniel Schwenkkrauß

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
