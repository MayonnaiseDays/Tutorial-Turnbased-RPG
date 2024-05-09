/// @description Insert description here
// You can write your code in this editor

battleState();

if (cursor.active)
{
	with (cursor)
	{
		//input
		var _keyUp = keyboard_check_pressed(vk_up);
		var _keyDown = keyboard_check_pressed(vk_down);
		var _keyLeft = keyboard_check_pressed(vk_left);
		var _keyRight = keyboard_check_pressed(vk_right);
		var _keyToggle = false;
		var _keyConfirm = false;
		var _keyCancel = false;
		
		confirmDelay++;
		if (confirmDelay > 1)// prevent player from immediately going through menus by pressing enter slowly
		{
			_keyConfirm = keyboard_check_pressed(vk_enter);
			_keyCancel = keyboard_check_pressed(vk_escape);
			_keyToggle = keyboard_check_pressed(vk_shift);
		}
		var _moveH = _keyRight - _keyLeft;
		var _moveV = _keyDown - _keyUp;
		
		if (_moveH == -1)
			targetSide = oBattle.partyUnits;
		if (_moveH == 1)
			targetSide = oBattle.enemyUnits;
			
		//verify target list
		if (targetSide == oBattle.enemyUnits)
		{
			targetSide = array_filter(targetSide, function(_element, _index)
			{
				return _element.hp > 0;
			});
		}
		
		//move between targets
		if (targetAll == false)//single target
		{
			if (_moveV == 1)
				targetIndex++;
			if (_moveV == -1)
				targetIndex--;
				
			//wrap
			var _targets = array_length(targetSide);
			if (targetIndex < 0)
				targetIndex = _targets - 1;
			if (targetIndex > (_targets - 1))
				targetIndex = 0;
			
			//identify target 
			activeTarget = targetSide[targetIndex];
			
			//tiggle all mode
			if (activeAction.targetAll == MODE.VARIES) && (_keyToggle) // swithc to all mode
			{
				targetAll = true;
			}
		}
		else // target all
		{
			activeTarget = targetSide;
			if (activeAction.targetAll == MODE.VARIES) && (_keyToggle) // go to single mode
			{
				targetAll = false;
			}
		}
		
		//confirm action
		if (_keyConfirm)
		{
			with (oBattle)
				BeginAction(cursor.activeUser, cursor.activeAction, cursor.activeTarget);
			with (oMenu)
				instance_destroy();
			active = false;
			confirmDelay = 0;
		}
		
		//cancel and return to maenu
		if (_keyCancel) && (!_keyConfirm)//prevent both confirm and return happening at once(although unlikely)
		{
			with (oMenu) 
				active = true;
			active = false;
			confirmDelay = 0;
		}
	}
}

