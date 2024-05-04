var inputH = keyboard_check(vk_right) - keyboard_check(vk_left);
var inputV = keyboard_check(vk_down) - keyboard_check(vk_up);
var inputD = point_direction(0,0, inputH, inputV);
var inputM = point_distance(0,0, inputH, inputV);

if (inputM != 0)
{
	direction = inputD;	
	image_speed = 1;
}
else
{
	image_speed = 0;
	animIndex = 0;
}

FourDirectionAnimate();

x += lengthdir_x(spdWalk * inputM, inputD);
y += lengthdir_y(spdWalk * inputM, inputD);


