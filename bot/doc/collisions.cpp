
tpoint.x = obj.entities[i].xp;
tpoint.y = obj.entities[i].yp;

////////////////////////////////////////

if (tpoint.x < 0)
{
    tpoint.x += 320;
    drawRect = sprites_rect;
    drawRect.x += tpoint.x;
    drawRect.y += tpoint.y;
    BlitSurfaceColoured(flipsprites[obj.entities[i].drawframe],NULL, backBuffer, &drawRect, ct);
}
if (tpoint.x > 300)
{
    tpoint.x -= 320;
    drawRect = sprites_rect;
    drawRect.x += tpoint.x;
    drawRect.y += tpoint.y;
    BlitSurfaceColoured(flipsprites[obj.entities[i].drawframe],NULL, backBuffer, &drawRect, ct);
}
