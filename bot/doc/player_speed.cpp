
if (game.press_left)
{
	game.tapleft++;
}
else
{
	if (game.tapleft <= 4 && game.tapleft > 0)
	{
		if (obj.entities[ie].vx < 0.0f)
		{
			obj.entities[ie].vx = 0.0f;
		}
	}
	game.tapleft = 0;
}
if (game.press_right)
{
	game.tapright++;
}
else
{
	if (game.tapright <= 4 && game.tapright > 0)
	{
		if (obj.entities[ie].vx > 0.0f)
		{
			obj.entities[ie].vx = 0.0f;
		}
	}
	game.tapright = 0;
}


if(game.press_left)
{
	//obj.entities[i].vx = -4;
	obj.entities[ie].ax = -3;
	obj.entities[ie].dir = 0;
}
else if (game.press_right)
{
	//obj.entities[i].vx = 4;
	obj.entities[ie].ax = 3;
	obj.entities[ie].dir = 1;
}

/////////////////////////////////

void entityclass::applyfriction( int t, float xrate, float yrate )
{
    if (entities[t].vx > 0.00f) entities[t].vx -= xrate;
    if (entities[t].vx < 0.00f) entities[t].vx += xrate;
    if (entities[t].vy > 0.00f) entities[t].vy -= yrate;
    if (entities[t].vy < 0.00f) entities[t].vy += yrate;
    if (entities[t].vy > 10.00f) entities[t].vy = 10.0f;
    if (entities[t].vy < -10.00f) entities[t].vy = -10.0f;
    if (entities[t].vx > 6.00f) entities[t].vx = 6.0f;
    if (entities[t].vx < -6.00f) entities[t].vx = -6.0f;

    if (std::abs(entities[t].vx) < xrate) entities[t].vx = 0.0f;
    if (std::abs(entities[t].vy) < yrate) entities[t].vy = 0.0f;
}

/////////////////////////////////

entities[t].vx = entities[t].vx + entities[t].ax;
entities[t].vy = entities[t].vy + entities[t].ay;
entities[t].ax = 0;

if(game.gravitycontrol==0)
{
	entities[t].ay = 3;
}
else
{
	entities[t].ay = -3;
}

applyfriction(t, game.inertia, 0.25f); // NOTE: inertia = 1.1f;

entities[t].newxp = entities[t].xp + entities[t].vx; // NOTE: int conversion
entities[t].newyp = entities[t].yp + entities[t].vy; // NOTE: int conversion

/////////////// COLLISIONS ARE CHECKED HERE //////////////////

if (obj.entities[i].xp <= -10)
{
    obj.entities[i].xp += 320;
}
else
{
    if (obj.entities[i].xp > 310)
    {
        obj.entities[i].xp -= 320;
    }
}
