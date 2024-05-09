/// @description Insert description here
// You can write your code in this editor

instance_deactivate_all(true);

units = [];
turn = 0;
unitTurnOrder = [];
unitRenderOrder = [];

turnCount = 0;
roundCount = 0;
battleWaitTimeFrames = 30;
battleWaitTimeRemaining = 0;
currentUser = noone;
currentAction = -1;
currentTargets = noone;

//make targetting cursor
cursor = 
{
	activeUser: noone,
	activeTarget: noone,
	activeAction: -1,
	targetSide: -1,
	targetIndex: 0,
	targetAll: false,
	confirmDelay: 0,
	active: false
};


//make enemies
for(var i = 0; i < array_length(enemies); i++)
{
	// draw enemies at set positions(not good for more customization), depth - 10 is just temp solution and not needed by end
	enemyUnits[i] = instance_create_depth(x + 250 + ((i mod 3) * 10) + ((i div 3) * 25), y + 68 + ((i mod 3) * 20), depth - 10, oBattleUnitEnemy, enemies[i]);
	array_push(units, enemyUnits[i]);
}

for(var i = 0; i < array_length(global.party); i++)
{
	// draw enemies at set positions(not good for more customization), depth - 10 is just temp solution and not needed by end
	partyUnits[i] = instance_create_depth(x + 70 + ((i mod 3) * 10) + ((i div 3) * 25), y + 68 + ((i mod 3) * 20), depth - 10, oBattleUnitPC, global.party[i]);
	array_push(units, partyUnits[i]);
}

//shuffle turn order
unitTurnOrder = array_shuffle(units);

//get render order
RefreshRenderOrder = function()
{
	unitRenderOrder = [];
	array_copy(unitRenderOrder, 0, units, 0, array_length(units));
	array_sort(unitRenderOrder, function(_1, _2)
	{
		return _1.y - _2.y;
	});
}
RefreshRenderOrder();


function BattleStateSelectAction()
{
	if (!instance_exists(oMenu))
	{
		// get current unit
		var _unit = unitTurnOrder[turn];
	
		//is the uinit dead or unable to act?
		if (!instance_exists(_unit)) || (_unit.hp <= 0)
		{
			battleState = BattleStateVictoryCheck;
			exit;
		}
	
		//select action to perform
	
		//if unit ios player controlled
		if (_unit.object_index == oBattleUnitPC)
		{
			//compile the aciton menu
			var _menuOptions = [];
			var _subMenus = {};
			
			var _actionList = _unit.actions;
			
			for (var i = 0; i < array_length(_actionList); i++)
			{
				var _action = _actionList[i];
				var _available = true; // this will be mp check
				var _nameAndCount = _action.name; // for items
				if (_action.subMenu == -1)
				{
					array_push(_menuOptions, [_nameAndCount, MenuSelectAction, [_unit, _action], _available]);
				}
				else
				{
					//create or add to submenu
					if (is_undefined(_subMenus[$ _action.subMenu]))
					{
						variable_struct_set(_subMenus, _action.subMenu, [[_nameAndCount, MenuSelectAction, [_unit, _action], _available]]);
					}
					else
					{
						array_push(_subMenus[$ _action.subMenu], [_nameAndCount, MenuSelectAction, [_unit, _action], _available]);
					}
				}
			}
			
			//turn sub menus in to an array
			var _subMenusArray = variable_struct_get_names(_subMenus);
			for (var i = 0; i < array_length(_subMenusArray); i++)
			{
				//sort submenu if needed
				//(here)
			
				//add back option at end of each submenu
				array_push(_subMenus[$ _subMenusArray[i]], ["Back", MenuGoBack, -1, true]);
				//addsubmenu into main menu
				array_push(_menuOptions, [_subMenusArray[i], SubMenu, [_subMenus[$ _subMenusArray[i]]], true]);
			}
			
			
			Menu(x + 10, y + 110, _menuOptions, , 74, 60);
		}
		else
		{
			//if unit ios ai
			var _enemyAction = _unit.AIscript();
			if (_enemyAction != -1)
				BeginAction(_unit.id, _enemyAction[0], _enemyAction[1]);
		}
	}
}

function BeginAction(_user, _action, _targets)
{
		currentUser = _user;
		currentAction = _action;
		currentTargets = _targets;
		if (!is_array(currentTargets))
			currentTargets = [currentTargets];
		battleWaitTimeRemaining = battleWaitTimeFrames;
		with(_user)
		{
			acting = true;
			//play animation if it is defined
			if (!is_undefined(_action[$ "userAnimation"])) && (!is_undefined(_user.sprites[$ _action.userAnimation]))
			{
				sprite_index = sprites[$ _action.userAnimation];
				image_index = 0;
			}
		}
		battleState = BattleStatePerformAction;
}

function BattleStatePerformAction()
{
	//ifanimtion is still palying
	if (currentUser.acting)
	{
		//when it ends perform action effect if it exists
		if (currentUser.image_index >= currentUser.image_number - 1)
		{
			with (currentUser)
			{
				sprite_index = sprites.idle;
				image_index = 0;
				acting = false;
			}
			
			if (variable_struct_exists(currentAction, "effectSprite"))
			{
				if (currentAction.effectOnTarget == MODE.ALWAYS) || ( (currentAction.effectOnTarget == MODE.VARIES) && (array_length(currentTargets) <= 1) )
				{
					for (var i = 0; i < array_length(currentTargets); i++)
					{
						instance_create_depth(currentTargets[i].x, currentTargets[i].y, currentTargets[i].depth - 1, oBattleEffect, {sprite_index : currentAction.effectSprite});
					}
				}
				else // play at 0,0
				{
					var _effectSprite = currentAction.effectSprite;
					if (variable_struct_exists(currentAction, "effectSpriteNoTarget"))
						_effectSprite = currentAction.effectSpriteNoTarget;
					instance_create_depth(x, y, depth - 100, oBattleEffect, {sprite_index : _effectSprite});
				}
			}
			currentAction.func(currentUser, currentTargets);
			show_debug_message("i should have punched!");
		}
	}
	else // wait for delayu then end turn
	{
		if (!instance_exists(oBattleEffect))
		{
			battleWaitTimeRemaining--;
			if (battleWaitTimeRemaining == 0)
			{
				show_debug_message("going to next state now");
				battleState = BattleStateVictoryCheck;
			}
		}
	}
}

function BattleStateVictoryCheck()
{
	battleState = BattleStateTurnProgression;
}

function BattleStateTurnProgression()
{
	turnCount++;
	turn++;
	//loopturns
	if(turn > array_length(unitTurnOrder) - 1)
	{
		turn = 0;
		roundCount++;
	}
	battleState = BattleStateSelectAction;
}


battleState = BattleStateSelectAction;
