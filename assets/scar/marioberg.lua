--[[ 

EXAMPLE GAME MODE SCRIPT

This script demonstrates how to use an assortment of SCAR (Scripting at Relic) functions to create a Game Mode for Age of Empires IV. 
We demonstrate how to setup a simple win condition that awards victory to the first player who constructs 5 houses and covers an assortment of topics like building/unit spawning, event tracking, and much more.

Search for the following topic titles (e.g. OPTIONS, RULES, etc.) in this script to see examples of their usage. 

- OPTIONS allow you to add buttons to the Skirmish/Custom lobby when your Game Mode is selected and trigger functions based on what the host has selected. The buttons are added in the Options section of the Win Condition .rdo file and their functionality is driven by this script.
- RULES allow you to call script functions after a delay, on an interval, or whenever a game event (e.g. a unit is killed) occurs.
- OBJECTIVES communicate what the players' goals are and how they are progressing towards them using a UI element at the top left of their screen.
- ENTITIES are the objects you see in-game, like player constructed buildings, Sacred Sites, Stone Deposits, and Trees. Type "Entity_" in this script to view a list of functions you can use to manipulate these objects.
- SQUADS are in-game units. Type "Squad_" in this script to view a list of functions you can use to manipulate these objects.
- ENTITY GROUPS and SQUAD GROUPS (aka EGROUPS/SGROUPS) are bundles of Entities/Squads. It sometimes makes sense to add a number of objects to a group so you can manipulate them together (e.g. you may want to add a group of Spearmen to an SGROUP so you can command them all to attack a location).
- UPGRADES unlock functionality for a player, a unit, or a building.
- BLUEPRINTS are the instructions needed to create an Entity, Squad, or Upgrade. For example, a blueprint exists for each Civilization Villager. If you want to spawn a Mongol Villager, you will need to reference the Mongol Villager Blueprint. Type "BP_" in this script to view a list of Blueprint functions.
- EVENT CUES are messages that appear in the queue at the bottom-right of the player's screen. Some event cues occur automatically, like when an upgrade completes. You can configure your own event cues to communicate important game mode events to the player.

To play and test this Game Mode:

1. From the editor toolbar, select File > Save All to save any changes you have made to this mod.
2. From the editor toolbar, select Build > Build Mod.
3. Launch Age of Empires IV.
4. In the game client, navigate to Single Player > Skirmish > Create Game (alternatively, you can navigate to Multiplayer > Custom > Create Game).
5. In the Game Setup tab of the lobby, select the Edit button.
6. Select your Game Mode* and Start Game.

*Your Game Mode will have a red wrench icon next to it. This means that it is a local mod and you cannot launch with other players in the lobby. If you would like to play this Game Mode with other players, you will either need to:
1. Share your mod file with another player and have them place it in the following directory: YourDriveHere:\Users\YourNameHere\Documents\My Games\Cardinal\mods\extension\local 
2. Publish your Mod from the Mods > My Mods screen. This will publish your Game Mode to all Age of Empires IV players! When a host selects your Game Mode, it will automatically be downloaded for other players in the lobby.


Additional documentation and function references can be found online.

]]

-----------------------------------------------------------------------
-- Imported Scripts

-- When you import a .scar file it will be initialized alongside your Game Mode .scar script. 
-- You can also call functions from imported scripts directly. For example, cardinal.scar has a function called Player_SetCurrentAge() that allows you to set the age of a given player. To use this function, you first have to import cardinal.scar as is demonstrated below.
-- To examine the below scripts, right-click on the import() function and select "Open Document"
-----------------------------------------------------------------------

-- Import Utility Scripts
import("cardinal.scar")							-- Contains sfx references, UI templates, and Civ/Age helper functions
import("ScarUtil.scar")							-- Contains game helper functions

-- Import Gameplay Systems
import("gameplay/score.scar")					-- Tracks player score
import("gameplay/diplomacy.scar")				-- Manages Tribute

-- Import Win Conditions
import("winconditions/annihilation.scar")		-- Support for eliminating a player when they can no longer fight or produce units
import("winconditions/elimination.scar")		-- Support for player quitting or dropping (through pause menu or disconnection)
import("winconditions/surrender.scar")			-- Support for player surrender (through pause menu)

-- Import UI Support
import("gameplay/chi/current_dynasty_ui.scar")	-- Displays Chinese Dynasty UI
import("gameplay/event_cues.scar")
import("gameplay/currentageui.scar")

--Import Marioberg scripts
import("mariobergFunctions/gamefunctions.scar")






-----------------------------------------------------------------------
-- Data
-----------------------------------------------------------------------

-- Global data table that can be referenced in script functions (e.g. _mod.module = "Mod")
_mod = {
	module = "Mod",
	objective_title = "$6384a68ad823457e8be819a57b0c9a3f:11",
	objective_requirement = 5,
	options = {},
	icons = {
		objective = "icons\\races\\common\\victory_conditions\\victory_condition_conquest",
	},
}

-- Register the win condition (Some functions can be prepended with "Mod_" to be called automatically as part of the scripting framework)
Core_RegisterModule(_mod.module)

-----------------------------------------------------------------------
-- Scripting framework 
-----------------------------------------------------------------------

-- Called during load as part of the game setup sequence
function Mod_OnGameSetup()
	
	-- The following if statement checks which OPTIONS the host of the match selected.
	-- The UI buttons visible to the host via the game lobby are added in the Options section of the Win Condition .rdo file and their functionality is driven by the code below.
	-- In this example, the host can choose to give every play 200 resources per minute or 500 resources per minute
	
	-- Get the host-selected Options configured in the mod's .rdo file
	Setup_GetWinConditionOptions(_mod.options)
	
	-- Check if there is the economy_section data is available.
	-- economy_section matches the name of the OptionsSectionUIDescriptor Key configured in your Game Mode Win Condition .rdo file.
	if _mod.options.economy_section then
		
		-- If host set the resource amount to 200
		if _mod.options.economy_section.resource_amount.enum_value == _mod.options.economy_section.resource_amount.enum_items.resource_200 then
			
			-- Here we are adding the resource amount selected by the host to the global _mod table that was configured above. It will then be easy for us to reference later in the Mod_GiveResources() function
			_mod.resource_amount = 200
			
			-- You can use the print() function to print a string to the console
			-- You can open the console in a match by holding Ctrl+Alt+~
			-- This is useful for testing which parts of your script are running
			print("OPTION SELECTED: 200 Resources per minute")
			
		-- If host sets Economy to Fast
		elseif _mod.options.economy_section.resource_amount.enum_value == _mod.options.economy_section.resource_amount.enum_items.resource_500 then
			
			-- Store the resource amount selected by the host so it can be referenced elsewhere in the script
			_mod.resource_amount = 500
			
			-- Print the selected option to the console for debugging
			print("OPTION SELECTED: 500 Resources per minute")
			
		end
	end
end

-- Called before initialization, preceding other module OnInit functions
function Mod_PreInit()
	
	-- Enables the Tribute UI by calling the TributeEnabled function in diplomacy.scar, which was imported at the top of this script
	-- Remove this or set to false if you do not want players to have access to resource trading via the Tribute panel
	Core_CallDelegateFunctions("TributeEnabled", true)
	
end

-- Called on match initialization before handing control to the player
function Mod_OnInit()
	
	-- Store the local player so we can reference them later
	localPlayer = Core_GetPlayersTableEntry(Game_GetLocalPlayer())
	
	-- CALLING FUNCTIONS: The following calls the Mod_FindTownCenter() and Mod_SpawnBuilding() functions directly and immediately.
	Mod_FindTownCenter()
	Mod_SpawnBuilding()
	-- ONE SHOT RULES: The following rule runs the Mod_SpawnUnits() function after a 5 second delay. If you want to call a function without a delay, you can change the 5 to a 0 or simply call the function directly by typing Mod_SetupObjective()
	Rule_AddOneShot(Mod_SpawnUnits, 5)
	-- INTERVAL RULES: The following rule runs the Mod_GiveResources() function every 60 seconds. This is useful for functions that need to query a game state or perform an action every so often (e.g. give players resources or spawning waves of enemies)
	Rule_AddInterval(Mod_GiveResources, 60)
	-- GLOBAL EVENT RULES: The following rule runs the Mod_OnConstructionComplete() function whenever a building is constructed. Type "GE_" in this script to see a list of global events.
	Rule_AddGlobalEvent(Mod_OnConstructionComplete, GE_ConstructionComplete)
	
	-- This is a for loop that does something for each player in the match.
	-- PLAYERS is a table that contains all of the players in the match.
	-- If there are two players it will run twice, if there are eight players it will run eight times, etc.
	for i, player in pairs(PLAYERS) do
		
		-- Set player starting Ages to Imperial
		-- Ages are mapped to: Dark Age = 1, Feudal Age = 2, Castle Age = 3, Imperial Age = 4
		Player_SetCurrentAge(player.id, 4)
		
		-- Set player starting resources
		-- RT stands for Resource Type
		Player_SetResource(player.id, RT_Food, 1000)		
		Player_SetResource(player.id, RT_Wood, 50)
		Player_SetResource(player.id, RT_Gold, 0)
		Player_SetResource(player.id, RT_Stone, 0)
		
		-- Set starting population cap to 50
		Player_SetMaxPopulation(player.id, CT_Personnel, 50)
		
	end
	
	Core_CallDelegateFunctions("DiplomacyEnabled", false)
	Core_CallDelegateFunctions("TributeEnabled", true)
end

-- Called after initialization is done when game is fading up from black
function Mod_Start()
	
	-- Setup the player's objective UI by calling the below function directly
	Mod_SetupObjective()
	
end

-- Called when Core_SetPlayerDefeated() is invoked. Signals that a player has been eliminated from play due to defeat.
function Mod_OnPlayerDefeated(player, reason)
	
	
	
end

-- When a victory condition is met, a module must call Core_OnGameOver() in order to invoke this delegate and notify all modules that the match is about to end. Generally used for clean up (removal of rules, objectives, and UI elements specific to the module).
function Mod_OnGameOver()
	
	-- It is good practice to remove any Rules that were configured so they do not continue to run after the match has concluded
	Rule_RemoveGlobalEvent(Mod_OnConstructionComplete)

end

-----------------------------------------------------------------------
-- Mod Functions
-----------------------------------------------------------------------

-- This function creates the objective UI that appears in the top-left corner of each player's screen
function Mod_SetupObjective()
	
	-- Check if an objective has not been created yet
	if _mod.objective == nil then 
		
		-- Create and store objective in the global table created at the start of this script
		_mod.objective = Obj_Create(localPlayer.id, _mod.objective_title, Loc_Empty(), _mod.icons.objective, "ConquestObjectiveTemplate", localPlayer.raceName, OT_Primary, 0, "conquestObj")		
		
		-- Sets the objective's state to incomplete
		Obj_SetState(_mod.objective, OS_Incomplete)
		-- Sets the objective to visible so players can see it
		Obj_SetVisible(_mod.objective, true)
		-- Sets the progress element of the objective to visible so players can see it
		Obj_SetProgressVisible(_mod.objective, true)		
		-- Sets the objective progress type to a counter
		Obj_SetCounterType(_mod.objective, COUNTER_CountUpTo)
		-- Set the starting objective progress to 1 because we spawn a House for the player in Mod_SpawnBuilding()
		Obj_SetCounterCount(_mod.objective, 1)
		-- Set the maximum objective progress
		Obj_SetCounterMax(_mod.objective, _mod.objective_requirement)
		-- Set the objective progress bar percentage value
		Obj_SetProgress(_mod.objective, 1 / _mod.objective_requirement)
	end
end

-- This function finds the starting Town Center for all players in the match, reveals it to all other players, and increases its production speed
function Mod_FindTownCenter()
	
	-- This is a for loop that does something for each player in the match.
	-- PLAYERS is a table that contains all of the players in the match.
	-- If there are two players it will run twice, if there are eight players it will run eight times, etc.
	for i, player in pairs(PLAYERS) do
		
		-- Get the player's entities and place them into an ENTITY GROUP
		local eg_player_entities = Player_GetEntities(player.id)
		-- Filter out everything in the ENTITY GROUP except for the Town Center
		EGroup_Filter(eg_player_entities, "town_center", FILTER_KEEP)
		-- Get the Town Center ENTITY by getting the first entry in the ENTITY GROUP we just filtered
		local entity =  EGroup_GetEntityAt(eg_player_entities, 1)
		-- Get the Town Center's ENTITY ID
		-- Some functions require the ENTITY ID to perform an action on the ENTITY
		local entity_id = Entity_GetID(entity) 
		-- Get the Town Center's position
		local position = Entity_GetPosition(entity)
		
		-- Store the player's Town Center information so it can be referenced later
		player.town_center = {
			entity = entity,
			entity_id = entity_id,
			position = position,
		}
			
		-- Reveal Town Center locations for the first 30 seconds of the match
		FOW_RevealArea(player.town_center.position, 40, 30)
		
		-- Increase the production speed of the player's Town Center
		Modifier_ApplyToEntity(Modifier_Create(MAT_Entity, "production_speed_modifier", MUT_Multiplication, false, 20, nil), player.town_center.entity, 0.0)
		
	end
end

-- This function spawns a group of Spearmen next each player's Town Center
function Mod_SpawnUnits()
	
	-- This is a for loop that does something for each player in the match.
	-- PLAYERS is a table that contains all of the players in the match.
	-- If there are two players it will run twice, if there are eight players it will run eight times, etc.
	for i, player in pairs(PLAYERS) do
		
		-- Get player's Civilization name
		local player_civ = Player_GetRaceName(player.id)
		
		-- Create a local variable for the Spearman BLUEPRINT (BP) we are going to find below
		-- The local variable needs to be established before the below IF statement so it can be referenced outside of it within the function
		local sbp_spearman
		
		-- This checks which Civilization the player is using and gets the appropriate BLUEPRINTS for the Spearmen unit
		-- BLUEPRINTS are the instructions needed to create a SQUAD, ENTITY, or UPGRADE
		if player_civ == "english" then
			
			-- Get the Age 4 English Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_eng")
			
		elseif player_civ == "chinese" then
			
			-- Get the Age 4 Chinese Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_chi")
			
		elseif player_civ == "french" then
			
			-- Get the Age 4 French Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_fre")
			
		elseif player_civ == "hre" then
			
			-- Get the Age 4 HRE Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_hre")
			
		elseif player_civ == "mongol" then
			
			-- Get the Age 4 Mongol Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_mon")
			
		elseif player_civ == "rus" then
			
			-- Get the Age 4 Rus Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_rus")
			
		elseif player_civ == "sultanate" then
			
			-- Get the Age 4 Delhi Sultanate Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_sul")
			
		elseif player_civ == "abbasid" then
			
			-- Get the Age 4 Abbasid Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_abb")
			
		elseif player_civ == "malian" then
			
			-- Get the Age 4 malian Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_mal")
			
		elseif player_civ == "ottoman" then
			
			-- Get the Age 4 ottoman Spearman Blueprint
			sbp_spearman = BP_GetSquadBlueprint("unit_spearman_4_ott")
			
		end
		
		-- Get a position offset from the player's Town Center
		local spawn_position = Util_GetOffsetPosition(player.town_center.position, 20, 10)
		
		-- Create a unique sgroup name for this player's spearmen units
		local sgroup_name = "sg_player_spearmen_" .. tostring(player.id)
		-- Create a SQUAD GROUP (SGROUP) that will act as a container for the spawned SQUADS
		-- SGROUPS are useful for controlling all of the spawned units at once via scripted commands.
		local sg_player_spearmen = SGroup_CreateIfNotFound(sgroup_name)
		
		-- This function spawns 16 Spearmen of the player's Civilization near their starting Town Center
		-- You can hover over the function to view the parameters it requires. From left to right:
		-- player = The player that the spawned units will belong to.
		-- sgroup = The SQUAD GROUP (SG) that the units will be spawned into.
		-- units = A table of data that contains the SQUAD BLUEPRINT (SBP) and the number of SQUADS (aka units) to spawn.
		-- spawn = The location the units will be spawned at.
		UnitEntry_DeploySquads(player.id, sg_player_spearmen, {{sbp = sbp_spearman, numSquads = 16 }}, spawn_position)
		
		-- Get a position offset from the Town Center position
		local move_position = Util_GetOffsetPosition(player.town_center.position, 20, 20)
		-- Command the SGROUP to enter into a formation
		Cmd_Ability(sg_player_spearmen, BP_GetAbilityBlueprint("core_formation_line"))
		-- Command the SGROUP to Move to that position
		Cmd_FormationMove(sg_player_spearmen, move_position, false)
		
	end
end

-- This function spawns a building next to each player's Town Center
function Mod_SpawnBuilding()
	
	-- This is a for loop that does something for each player in the match.
	-- PLAYERS is a table that contains all of the players in the match.
	-- If there are two players it will run twice, if there are eight players it will run eight times, etc.
	for i, player in pairs(PLAYERS) do
		
		-- Get player's Civilization name
		local player_civ = Player_GetRaceName(player.id)
		
		-- Create a local variable for the Spearman BLUEPRINT (BP) we are going to find below
		-- The local variable needs to be established before the below IF statement so it can be referenced outside of it within the function
		local ebp_building
		
		-- This checks which Civilization the player is using and gets the appropriate BLUEPRINTS for the House building
		-- BLUEPRINTS are the instructions needed to create a SQUAD, ENTITY, or UPGRADE
		if player_civ == "english" then
			
			-- Get the English House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_eng")
			
		elseif player_civ == "chinese" then
			
			-- Get the Chinese House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_chi")
			
		elseif player_civ == "french" then
			
			-- Get the French House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_fre")
			
		elseif player_civ == "hre" then
			
			-- Get the HRE House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_hre")
			
		elseif player_civ == "mongol" then
			
			-- Get the Mongol Ger Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_mon")
			
		elseif player_civ == "rus" then
			
			-- Get the Rus House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_rus")
			
		elseif player_civ == "sultanate" then
			
			-- Get the Delhi Sultanate House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_sul")
			
		elseif player_civ == "abbasid" then
			
			-- Get the Abbasid House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_control_abb")
			
		elseif player_civ == "malian" then
			
			-- Get the malian House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_mal")
			
		elseif player_civ == "ottoman" then
			
			-- Get the ottoman House Blueprint
			ebp_building = BP_GetEntityBlueprint("building_house_ott")
			
		end
		
		-- Get a position offset from the player's Town Center
		local spawn_position = Util_GetOffsetPosition(player.town_center.position, 10, 20)
		
		-- Create a new ENTITY using the ENTITY BLUEPRINT (EBP) we found above at the location we calculated above
		local entity = Entity_Create(ebp_building, player.id, spawn_position, false)
		-- Spawn the ENTITY
		Entity_Spawn(entity)
		-- Construct the ENTITY immediately
		Entity_ForceConstruct(entity)
		-- Snap the ENTITY to the construction grid
		Entity_SnapToGridAndGround(entity, false)	
		
	end
end

-- This function generates resources for all players on an interval.
-- It is called every 60 seconds based on the INTERVAL RULES configured in Mod_OnInit()
-- The amount of resources given is determined by the OPTIONS available to the match host in the Skirmish/Custom lobby
function Mod_GiveResources()
	
	-- This is a for loop that does something for each player in the match.
	-- PLAYERS is a table that contains all of the players in the match.
	-- If there are two players it will run twice, if there are eight players it will run eight times, etc.
	for i, player in pairs(PLAYERS) do
		
		-- Add resource amount configured by host for the player that is being looped through
		Player_AddResource(player.id, RT_Food, _mod.resource_amount)
		Player_AddResource(player.id, RT_Wood, _mod.resource_amount)
		Player_AddResource(player.id, RT_Gold, _mod.resource_amount)
		Player_AddResource(player.id, RT_Stone, _mod.resource_amount)
		
		-- This checks if the player being looped through is the local player.
		-- It is useful to check if the player is local in cases where we only want a function to run once for each player.
		-- In the below example, we want to show each player an Event Cue once.
		if player.isLocal then
			
			-- The following function displays an EVENT CUE to the player
			-- First we create a string that contains the resource value selected by the host
			-- NOTE: The following string is not localized. To localize a string, you must:
			-- 1. Open the .locdb file in the Asset Explorer.
			-- 2. Enter your text in a new row and note the row number. For this example, we would enter " of each resource added" without quotations.
			-- 3. In your script, use the format $Guid:RowNumber. Guid = your Game Mode's GUID which can be grabbed by selecting Edit > Copy Mod Guid. RowNumber = the row of your text in the .locdb file
			-- 4. If the below example was localized, it would look something like: local event_cue_text = _mod.resource_amount .. "$1010e7809f07426d99b3468c53794260:12"
			local event_cue_text = Loc_FormatText("$6384a68ad823457e8be819a57b0c9a3f:12", _mod.resource_amount)
			-- Then we create the event cue with the string we created.
			UI_CreateEventCueClickable(-1, 10, -1, 0, event_cue_text, "", "low_priority", "", "sfx_ui_event_queue_low_priority_play", 255, 255, 255, 255, ECV_Queue, nothing)
			
		end
	end
end

-- This function checks if a House was constructed, updates the builder's Objective progress, and ends the match if it was their 5th House built
-- It is called every time any player constructs a building based on the GLOBAL EVENT RULES configured in Mod_OnInit()
-- Global Event functions are provided with a bundle of data that provide "context" for the event. In the following example, the "context" parameter has been added to store this data.
-- The context parameter will be provided with a table of data that contains the player that constructed the building and the building constructed. You can reference this information within the function.
function Mod_OnConstructionComplete(context)

	-- Store the player who constructed the building
	local builder = Core_GetPlayersTableEntry(context.player)
	
	-- Check to see if there was a builder (just in case the building was constructed via script or some other means) and that the builder has not been eliminated yet
	if builder ~= nil and not builder.isEliminated then
		
		-- Check if the builder is the local player
		-- We only want to run the below code for the local player as only their objective UI needs to be updated
		if builder.isLocal then
			
			-- Check if the building constructed was a house
			-- The first parameter contains the pbg (proberty bag group) data provided by the global event that tells us which building was constructed
			-- The second parameter is a Type. All Entities and Squads have a list of Types that help identify them. For example, while each Civilization has a different House entity they all are associated with the Type "house". 
			-- Using the Entity_IsEBPPOfType() function, we can check that the entity constructed was a house easily without first checking what Civilization the player is playing and then checking if they constructed that Civilization's House entity.
			if Entity_IsEBPOfType(context.pbg, "house") then
				
				-- Get the player's current objective progress
				local obj_progress_current = Obj_GetCounterCount(_mod.objective)
				-- Since the player constructed a house, calculate their new progress
				local obj_progress_new = obj_progress_current + 1
				-- Update their objective progress UI
				Obj_SetCounterCount(_mod.objective, obj_progress_new)
				Obj_SetProgress(_mod.objective, obj_progress_new / _mod.objective_requirement)
				
				-- If the player constructed their 5th house, set them as the winner and end the match
				if obj_progress_new == _mod.objective_requirement then
					
					-- Since the match is over, loop through every player
					for i, player in pairs(PLAYERS) do
						
						-- If the player being looked at is Allies with the player who constructed their 5th House, set them as the winner
						-- This is done by checking the Relationship (R) of two players using the Player_ObserveRelationship() function. R_ALLY returns true for any players on the same team (and if a player is checked against themself) while R_ENEMY returns true for players on other teams.
						if Player_ObserveRelationship(player.id, builder.id) == R_ALLY then
							
							-- Set the player as a winner and trigger the "Victory" stinger
							Core_SetPlayerVictorious(player.id, Mod_WinnerPresentation, WR_CONQUEST)
							
						-- Otherwise, set them as defeated
						else
							
							-- Set the player as a loser and trigger the "Defeat" stinger
							Core_SetPlayerDefeated(player.id, Mod_LoserPresentation, WR_CONQUEST)
							
						end
					end
					
				-- If this is not the player's 5th house
				else
					
					-- Play a success sound
					-- Additional sound references can be found in cardinal.scar
					-- To open cardinal.scar, scroll to line 44 of this script, right click on "import" and select "Open Document"
					Sound_Play2D("mus_stinger_campaign_triumph_short")
					
				end
			end
		end
	end
end

-- Victory Presentation 
-- This creates the large "Victory" stinger that animates for winning players at the end of a match
function Mod_WinnerPresentation(playerID)
	
	-- If player is local
	if playerID == localPlayer.id then
		
		-- Clear player's selection
		Misc_ClearSelection()
		-- Hide UI
		Taskbar_SetVisibility(false)		
		-- Set Win Condition Objective to complete
		Obj_SetState(_mod.objective, OS_Complete)

		-- Trigger objective complete pop up
		Obj_CreatePopup(_mod.objective, _mod.objective_title)
		-- Play Victory sfx
		Music_PlayStinger(MUS_STING_PRIMARY_OBJ_COMPLETE)
		-- Set objective to invisible
		Obj_SetVisible(_mod.objective, false)
		
		-- Create Victory Stinger
		Rule_AddOneShot(_gameOver_message, 
			GAMEOVER_OBJECTIVE_TIME, { 
			_playerID = playerID, 
			_icon = _mod.icons.objective, 
			_endType = Loc_GetString(11161277), 					-- "VICTORY"  
			_message = Loc_Empty(),
			_sound = "mus_stinger_landmark_objective_complete_success", 
			_videoURI = "stinger_victory" 
		})
	end
end

-- Defeat Presentation
-- This creates the large "Defeat" stinger that animates for losing players at the end of a match
function Mod_LoserPresentation(playerID)
	
	-- If player is local
	if playerID == localPlayer.id then
		
		-- Clear player's selection
		Misc_ClearSelection()
		-- Hide UI
		Taskbar_SetVisibility(false)		
		-- Set Win Condition Objective to failed
		Obj_SetState(_mod.objective, OS_Failed)

		-- Trigger objective complete pop up
		Obj_CreatePopup(_mod.objective, _mod.objective_title)
		-- Play Victory sfx
		Music_PlayStinger(MUS_STING_PRIMARY_OBJ_FAIL)
		-- Set objective to invisible
		Obj_SetVisible(_mod.objective, false)

		-- Create Defeat Stinger
		Rule_AddOneShot(_gameOver_message, 
			GAMEOVER_OBJECTIVE_TIME, {
			_playerID = playerID, 
			_icon = _mod.icons.objective, 
			_endType = Loc_GetString(11045235), 					-- "DEFEAT"  
			_message = Loc_Empty(),
			_sound = "mus_stinger_landmark_objective_complete_fail", 
			_videoURI = "stinger_defeat"})
	end
end
