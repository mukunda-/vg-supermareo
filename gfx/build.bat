 

rem set gamedir to compile.
REM SET GAMEDIR=C:\Steam\steamapps\common\Counter-Strike Global Offensive\csgo
SET VGNAME=supermareo

mkdir produce
mkdir gfx_font
mkdir gfx_tiles
mkdir gfx_sprites
del produce\* /Q
del gfx_font\* /Q
del gfx_tiles\* /Q
del gfx_sprites\* /Q

 
convert font2.png -crop 16x16 -transparent #00FF00 gfx_font/tile_%%03d.png
call process gfx_font 16 16
convert tiles.png -crop 16x16 -transparent #00FF00 gfx_tiles/tile_%%03d.png
call process gfx_tiles 16 16
convert sprites.png -crop 16x32 -transparent #00FF00 gfx_sprites/tile_%%03d.png
call process gfx_sprites 16 32 

