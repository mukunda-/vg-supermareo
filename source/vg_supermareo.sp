/******************************************************************************
 * Super Mareo Bruhs
 * Copyright (C) 2014 Mukunda Johnson
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 ******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <videogames>

#pragma semicolon 1

// 1.0.1
//   vg 1.0.4 update

//----------------------------------------------------------------------------------------------------------------------
public Plugin:myinfo = {
	name = "Videogames -> Super Mareo",
	author = "mukunda",
	description = "super mareo bruhs",
	version = "1.0.1",
	url = "www.mukunda.com"
};

#define SCORE_COIN   75
#define SCORE_GOOBY  150
#define SCORE_TIME	 18


#define BGMODEL "models/videogames/supermareo/gfx_tiles.mdl"
#define SPRITEMODEL "models/videogames/supermareo/gfx_sprites.mdl"
#define CARTMODEL "models/videogames/supermareo/cartridge.mdl"
#define FONTMODEL "models/videogames/supermareo/gfx_font.mdl"

#define BOXHIT_VEL_THRESHOLD 400

new game_state;
enum {
	GAMESTATE_TITLE,
	GAMESTATE_PLAYERSELECT,
	GAMESTATE_INTERMISSION,
	GAMESTATE_GAMEINIT,
	GAMESTATE_INGAME,
	GAMESTATE_GAMEOVER
	
};

// ingame text offsets
// 0 = speechbox (layer2)
// 1 = speechlines (layer3)
// 2 = score ui (layer3)

new mapwidth;

new Handle:mobs = INVALID_HANDLE;
#define MOBBLOCKSIZE 4 // type,x,y,???

new Handle:entity_list;
#define ENTDATASIZE 8

new exitstage_timer;
new igscore_timer;
new igscore_oldscore;
new igscore_time;
new igscore_blink;

new player_pos[2][2];
new player_sprite[2];
new player_direction[2];
new player_accel[2];

new input_override;
new input_override_position;

new player_jumptime[2];

new player_vel[2][2];
new bool:player_grounded[2];

new player_animation_start[2];
new player_animation_len[2];
new player_animation_frame[2];
new player_animation_speed[2];

new player_footstep_frame[2];

new player_dead[2];

new Float:camera;

new blink_animation_last;
new blink_animation_time;
new blink_animation_update;

new bool:ingame_highscore;
//new bool:ingame_besttime;

//new player_alive[2];

new kill_bounce_bonus[2];

new Float:music_fade;
new ingame_music_id;

enum {
	TILE_MAREO = 45,
	TILE_LUEGI = 46,
	TILE_GOOBY = 44,
	TILE_COIN = 33,
	TILE_PRINCESS = 47,
	TILE_ENDMARK =43,
	TILE_CASTLE=7
};

enum {
	GOOBY_FLAGS=4,
	GOOBY_DEAD=5,
	GOOBY_ANIMATION=6,
	GOOBY_VELY=7,
	GOOBY_FLAG_DIR=1,
	GOOBY_FLAG_
};

// sprite list
enum {
	SPR_IDLE=0,
	SPR_WALK=2,
	SPR_AIR=8,
	SPR_BIGIDLE=10,
	SPR_BIGWALK=12,
	SPR_BIGAIR=18,
	SPR_GROW=20,
	SPR_BIGSWIM=22,
	SPR_DEATH=32,
	SPR_LUEGI=34,
	SPR_PRINCESS=68,
	SPR_GOOBY=70
};

enum {
	MOB_GOOBY,
	MOB_COIN,
	MOB_PRINCESS,
	MOB_ENDMARK
};

new const String:solid_map[] =
	" xxxxxxxxx      xxxx         x  x               ";

new const String:soundlist[][] = {
	"*videogames/supermareo/boxhit.mp3",
	"*videogames/supermareo/boxhit2.mp3",
	"*videogames/supermareo/footstep1.mp3",
	"*videogames/supermareo/footstep2.mp3",
	"*videogames/supermareo/footstep3.mp3",
	"*videogames/supermareo/gooby.mp3",
	"*videogames/supermareo/jump1.mp3",
	"*videogames/supermareo/jump2.mp3",
	"*videogames/supermareo/land.mp3",
	"ui/beep07.wav",
	"*videogames/supermareo/smb_powerup.mp3",
	"*videogames/supermareo/smb_stage_clear.mp3",
	"*videogames/supermareo/smb_coin.mp3",
	"*videogames/supermareo/ssh_smb_theme.mp3",
	"*videogames/supermareo/score.mp3", //"*videogames/supermareo/smb_coin.mp3"
	"buttons/button11.wav",
	"*videogames/supermareo/highscore.mp3",
	"*videogames/supermareo/nomnomnom.mp3",
	"*videogames/supermareo/death.mp3",
	"*videogames/supermareo/ssh_top.mp3",
	"*videogames/supermareo/squeak2.mp3"
};

enum {
	SOUND_BOXHIT1,
	SOUND_BOXHIT2,
	SOUND_FOOTSTEP1,
	SOUND_FOOTSTEP2,
	SOUND_FOOTSTEP3,
	SOUND_GOOBY,
	SOUND_JUMP1,
	SOUND_JUMP2,
	SOUND_LAND,
	SOUND_SPEECH,
	SOUND_POWERUP,
	SOUND_STAGECLEAR,
	SOUND_COIN,
	SOUND_THEME,
	SOUND_SCORECOUNTER,
	SOUND_LOWSCORE,
	SOUND_HIGHSCORE,
	SOUND_NOMNOM,
	SOUND_DEATH,
	SOUND_INGAME_MUSIC,
	SOUND_SQUEAK
};

new speechlines_mareo[] = {
	0,3,
	3,3,
	6,4,
	10,3,
	13,3

};

new speechlines_luegi[] = {
	21,4,
	25,5
};

new speechlines_double[] = {
	16,5

};

new const String:speechlines[][] = {
	"Princess: Oh, Mareo!",	// 0		// MAREO SINGLE
	"I need you now more",	// 1
	"than ever!!",	// 2

	"Princess: Mareo! I",	//3		// MAREO SINGLE
	"have a PIE waiting",	// 4
	"for you upstairs!",	// 5
	
	"Mareo: Princess, do you",	//6		// MAREO SINGLE
	"have any more leaky",
	"PIPES in your bedroom",
	"that need to be fixed?",

	"Mareo: Hi, I'm the new",	//10		// MAREO SINGLE
	"milkman. Do you want it in",//11
	"the front or the back...?",		//12

	"Princess: If I said I want",	// MAREO //13
	"your body now, would you",
	"hold it against me?",

	"Princess: Mareo! Luegi!",			// DOUBLE //16
	"I want you both inside of",
	"my CASTLE.",
	"\x01Luegi: It's only gay if",
	"the balls touch!",

	"Princess: Luegi, where's",			// LUEGI SINGLE //21
	"Mareo? Oh well, I have a",
	"PIE upstairs that",
	"I need help eating.",

	"Luegi: Princess, I'm sorry",		//LUEGI SINGLE //25
	"to tell you this but",
	"Mareo passed away.",
	"Let's go upstairs and",
	"TALK about it."

};

// offsets for font characters
// <x offset> (subtracted from pen), <y offset> (added to line), <width> (offset to next character space)
new const font_offsets[96*3] = { 
	0,0,4, 2,0,3, 1,0,6, 0,0,8,  0,0,8, 0,0,8, 0,0,7, 1,0,3,  3,0,3, 3,0,3, 1,0,6, 0,0,7,  2,0,3, 1,0,6, 1,0,3, 0,0,7,
	0,0,8, 0,0,5, 0,0,7, 0,0,7,  0,0,8, 0,0,7, 0,0,7, 0,0,7,  0,0,7, 0,0,7, 2,0,3, 2,0,3,  0,0,7, 0,0,7, 0,0,7, 0,0,7,
	0,0,8, 0,0,7, 0,0,7, 0,0,7,  0,0,7, 0,0,7, 0,0,7, 0,0,7,  0,0,7, 0,0,5, 0,0,7, 0,0,8,  0,0,7, 0,0,8, 0,0,8, 0,0,7,
	0,0,7, 0,0,7, 0,0,7, 0,0,7,  0,0,7, 0,0,7, 0,0,7, 0,0,8,  0,0,8, 0,0,7, 0,0,8, 2,0,4,  0,0,8, 3,0,4, 0,0,8, 0,0,8,
	1,0,5, 1,0,6, 1,0,6, 1,0,6,  1,0,6, 1,0,6, 1,0,7, 1,0,6,  1,0,6, 3,0,3, 2,0,4, 1,0,6,  3,0,3, 1,0,7, 1,0,6, 1,0,6,
	1,0,7, 1,0,7, 1,0,6, 1,0,6,  1,0,7, 1,0,6, 1,0,7, 1,0,7,  1,0,6, 1,0,6, 1,0,6, 1,0,5,  2,0,3, 3,0,5, 0,0,8, 0,0,0
};

new speech_active;
new speech_index;		// current string index
new speech_length;		// number of lines to be printed
new speech_read;		// read position in current string
new speech_cell;		// index of [text] cell to use for next character
new speech_pen;			// horizontal position for next character (IN PIXELS FROM LEFT MARGIN) (0-??)
new speech_line;		// line that we're writing to (0-2)

new speech_timer;		// timer between printing characters
new speech_wait;		// waiting for keypress to change page

new bool:speech_cursor_blink;

new ingame_state;
enum {
	IGS_PLAYING,
	IGS_LEVELEND,
	IGS_SPEECH,
	IGS_GROWTH,
	IGS_EXITSTAGE,
	IGS_SCORE,
	IGS_DEATH
};

new player_growth[2];
new player_growth_frame[2];
new player_big[2];
new player_hide[2];

new castle_point;

new timer_active;

// titlescreen vars/////////
new ts_press_e_timer;
new bool:ts_press_e_on;
new ts_timeout;
new ts_page;
new ts_page_counter;
new bool:ts_page_scrolling;
new ts_page_scrollpos;
new ts_music_id;

new ts_intro;

new ps_cursor;
new ps_selection;
//new ts_princess;

new im_state;

new gi_state;

new death_timer;

new const ts_page_sequence[] = { 0,1,2,1 };
new const ts_page_scroll[] = {0,304,640};

#define TOPSCORE_ENTRIES 3
new String:topscore_names[TOPSCORE_ENTRIES][128];
new topscore_score[TOPSCORE_ENTRIES];
new String:besttime_names[TOPSCORE_ENTRIES][128];
new besttime_time[TOPSCORE_ENTRIES];

new String:topscore_filepath[128];



new current_score;
new actual_score_result;
new bool:score_dirty;
new current_time;

//new gameover_timer;

new const String:downloads[][] = {
	"materials/videogames/supermareo/cart_supermareo.vmt",
	"materials/videogames/supermareo/cart_supermareo.vtf",
	"materials/videogames/supermareo/gfx_font.vmt",
	"materials/videogames/supermareo/gfx_font.vtf",
	"materials/videogames/supermareo/gfx_tiles.vmt",
	"materials/videogames/supermareo/gfx_tiles.vtf",
	"materials/videogames/supermareo/gfx_sprites.vmt",
	"materials/videogames/supermareo/gfx_sprites.vtf",

	"models/videogames/supermareo/cartridge.dx90.vtx",
	"models/videogames/supermareo/cartridge.mdl",
	"models/videogames/supermareo/cartridge.phy",
	"models/videogames/supermareo/cartridge.vvd",
	"models/videogames/supermareo/gfx_font.dx90.vtx",
	"models/videogames/supermareo/gfx_font.mdl",
	"models/videogames/supermareo/gfx_font.vvd",
	"models/videogames/supermareo/gfx_sprites.dx90.vtx",
	"models/videogames/supermareo/gfx_sprites.mdl",
	"models/videogames/supermareo/gfx_sprites.vvd",
	"models/videogames/supermareo/gfx_tiles.dx90.vtx",
	"models/videogames/supermareo/gfx_tiles.mdl",
	"models/videogames/supermareo/gfx_tiles.vvd",

	"sound/videogames/supermareo/boxhit.mp3",
	"sound/videogames/supermareo/boxhit2.mp3",
	"sound/videogames/supermareo/death.mp3",
	"sound/videogames/supermareo/footstep1.mp3",
	"sound/videogames/supermareo/footstep2.mp3",
	"sound/videogames/supermareo/footstep3.mp3",
	"sound/videogames/supermareo/gooby.mp3",
	"sound/videogames/supermareo/highscore.mp3",
	"sound/videogames/supermareo/jump1.mp3",
	"sound/videogames/supermareo/jump2.mp3",
	"sound/videogames/supermareo/land.mp3",
	"sound/videogames/supermareo/nomnomnom.mp3",
	"sound/videogames/supermareo/score.mp3",
	"sound/videogames/supermareo/smb_coin.mp3",
	"sound/videogames/supermareo/smb_powerup.mp3",
	"sound/videogames/supermareo/smb_stage_clear.mp3",
	"sound/videogames/supermareo/squeak2.mp3",
	"sound/videogames/supermareo/ssh_smb_theme.mp3",
	"sound/videogames/supermareo/ssh_top.mp3"
};

public OnAllPluginsLoaded() {
	VG_Register( "supermareo", "Super Mareo Bruhs" );
}

//----------------------------------------------------------------------------------------------------------------------
public OnPluginStart() {
	entity_list = CreateArray(ENTDATASIZE);
	BuildPath( Path_SM, topscore_filepath, sizeof(topscore_filepath), "data/videogames/supermareo/%s", "top.txt" );
	LoadTopScores();
}

//----------------------------------------------------------------------------------------------------------------------
public OnMapStart() {
	PrecacheModel( CARTMODEL );
	PrecacheModel( BGMODEL );
	PrecacheModel( SPRITEMODEL );
	PrecacheModel( FONTMODEL );

	for( new i = 0; i < sizeof( soundlist ); i++ ) {
		PrecacheSound( soundlist[i] );
	}
	
	for( new i =0 ; i < sizeof(downloads); i++ ) {
		AddFileToDownloadsTable( downloads[i] );
	}

}

//----------------------------------------------------------------------------------------------------------------------
public VG_OnEntry() {
	
	VG_SetBackdrop( 0, 0, 0 );
	VG_BG_SetModel( BGMODEL );
	VG_SetFramerate( 60.0 );

	StartTitlescreen();

}

RegisterScore( time, score ) {

	//ingame_besttime = false;
	ingame_highscore = false;
	// max name length = 142-8

	// adjust score with time
	new timebonus = ((10800 - time) * SCORE_TIME)/16;
	if(timebonus < 0 ) timebonus = 0;
	score += timebonus;

	if( !player_dead[0] && !player_dead[1] ) {
		score = score + 2000;
	}
	actual_score_result = score;

	new highscore=-1, besttime=-1;

	for( new i = 0; i < TOPSCORE_ENTRIES; i++ ) {
		if( time < besttime_time[i] ) {
			//ingame_besttime = true;
			besttime = i;
			break;
		}
	}

	for( new i = 0; i < TOPSCORE_ENTRIES; i++ ) {
		if( score > topscore_score[i] ) {
			ingame_highscore = true;
			highscore = i;
			break;
		}
	}

	if( highscore == -1 && besttime == -1 ) return;

	new game_clients[2];
	game_clients[0] = VG_GetGameClient(1);
	game_clients[1] = VG_GetGameClient(2);
	
	new String:name[64];
	// build name
	if( ps_selection == 1 ) {
		// 2 player
		decl String:name1[64],String:name2[64];
		if( game_clients[0] && game_clients[1] ) {
			Format( name1, sizeof(name1), "%N", game_clients[0] );
			Format( name2, sizeof(name2), "%N", game_clients[1] );
			new pixels_remaining = (142-8)/2;
			new write = 0;
			for( new i = 0; name1[i] && pixels_remaining > 0; i++ ) {
				if( write >= sizeof(name)-1 ) break;
				new c = name1[i];
				if( c < 32 || c >= 127 ) continue;
				
				name[write++] = name1[i];
				c -= 32;
				pixels_remaining -= font_offsets[c*3+2];
			}
			name[write++] = '+';
			StrCat(name,sizeof(name),name2);

		} else if( game_clients[0] ) {
			Format( name, sizeof(name), "%N", game_clients[0] );
		} else if( game_clients[1] ) {
			Format( name, sizeof(name), "%N", game_clients[1] );
		} else {
			/// ?????
			name = "UNKNOWN!!";
		}
	} else {
		// 1 player
		if( game_clients[0] ) {
			Format( name, sizeof(name), "%N", game_clients[0] );
		} else {
			name = "UNKNOWN!!";
		}
	}

	ReplaceString( name, sizeof(name), "\r", "" );
	ReplaceString( name, sizeof(name), "\n", "" );
	TrimString(name);

	if( highscore != -1 ) {
		for( new i = TOPSCORE_ENTRIES-1; i > highscore; i-- ) {
			strcopy( topscore_names[i], sizeof(topscore_names[]), topscore_names[i-1] );
			topscore_score[i] = topscore_score[i-1];
		}
		strcopy( topscore_names[highscore], sizeof(topscore_names[]), name );
		topscore_score[highscore] = score;
	}

	if( besttime != -1 ) {
		for( new i = TOPSCORE_ENTRIES-1; i > besttime; i-- ) {
			strcopy( besttime_names[i], sizeof(besttime_names[]), besttime_names[i-1] );
			besttime_time[i] = besttime_time[i-1];
		}
		strcopy( besttime_names[besttime], sizeof(besttime_names[]), name );
		besttime_time[besttime] = time;
	}

	SaveTopScores();
}

LoadTopScores() {

	new Handle:file = OpenFile( topscore_filepath, "r" );
	for( new i = 0; i < 3; i++ ) {
		ReadFileLine( file, topscore_names[i], sizeof(topscore_names[]) );
		TrimString( topscore_names[i] );
		decl String:score[32];
		ReadFileLine( file, score, sizeof(score) );
		TrimString( score );
		topscore_score[i] = StringToInt( score );
	}

	for( new i = 0; i < 3; i++ ) {
		ReadFileLine( file, besttime_names[i], sizeof(besttime_names[]) );
		TrimString( besttime_names[i] );

		decl String:time[32];
		ReadFileLine( file, time, sizeof(time) );
		TrimString( time );
		besttime_time[i] = StringToInt( time );
	}

	CloseHandle(file);
}

//----------------------------------------------------------------------------------------------------------------------
SaveTopScores() {
	new Handle:file = OpenFile( topscore_filepath, "w" );
	for( new i = 0; i < 3; i++ ) {
		WriteFileLine( file, topscore_names[i], sizeof(topscore_names[]) );

		decl String:score[32];
		Format( score, sizeof(score), "%d", topscore_score[i] );

		WriteFileLine( file, score, sizeof(score) ); 
	}

	for( new i = 0; i < 3; i++ ) {
		WriteFileLine( file, besttime_names[i], sizeof(besttime_names[]) );

		decl String:time[32];
		Format( time, sizeof(time), "%d", besttime_time[i] );
		
		WriteFileLine( file, time, sizeof(time) );
	}
	CloseHandle(file);
}

new text_next;

//----------------------------------------------------------------------------------------------------------------------
Text_AddString( offset, const String:text[], x, y , bool:monospace=false, maxpixels=9000) {
	new start = text_next;
	new length = 0;

	new pen = 0;
	for( new i = 0; text[i]; i++ ) {
		new frame = text[i] - 32;
		
		
		if( frame < 0 || frame >= 95 ) continue;
		if( monospace ) {
			if( frame == 0 ) { pen += 8; continue; }
			if( pen+8 >= maxpixels ) break;
			VG_Text_SetPosition( text_next, x+pen, y );
			pen += 8;
		} else {
			if( frame == 0 ) { pen += 3; continue; }
			if( pen+font_offsets[frame*3+2] >= maxpixels ) break;
			VG_Text_SetPosition( text_next, x + pen - font_offsets[frame*3], y + font_offsets[frame*3+1] );
			pen += font_offsets[frame*3+2];
		}
		VG_Text_SetFrame( text_next, frame );
		text_next++;
		length++;
	}
	if( length ) {
		VG_Text_SetOffsetBatch( start, length, offset );
		VG_Text_SetOnBatch( start,length,true );
	}
}

StartGameover() {
	game_state = GAMESTATE_GAMEOVER;
	VG_Sprites_DeleteAll();
	VG_BG_SetScreenRefresh();
	VG_SetUpdateTime(5);
	VG_BG_LoadFile( "title.tmx.out",-1 );
	for( new i = 0; i < 3; i++ ) 
		VG_Text_SetOffsetParam( i, 0, 0, 0 );
	VG_BG_SetScroll( 110*16 );
	//gameover_timer = 0;
	VG_Sleep( 180 );
}

StartIntermission() {
	game_state = GAMESTATE_INTERMISSION;
	VG_Text_SetOnBatch( 0, VG_TEXT_COUNT, false );
	
	VG_BG_SetScroll( 57*16 );
	VG_Text_SetOffsetParam( 0, 0, 0, 0 );
	
	text_next =0;
	Text_AddString( 0, topscore_names[0], 32, 112, false, 150-8 );
	Text_AddString( 0, besttime_names[0], 32,138,false,150-8 );

	decl String:text[16];
	Format( text,sizeof(text), "%03d", besttime_time[0]/60 );
	Text_AddString( 0, text, 182,138,true );
	Format( text, sizeof(text), "%02d", besttime_time[0]%60 );
	Text_AddString( 0, text, 209,138,true );
	Text_AddString( 0,":",206,137 ); // dat colon

	Format( text, sizeof(text), "%05d", topscore_score[0] );
	Text_AddString( 0, text, 185,112,true );

	
	VG_Text_SetOnBatch( 0, text_next, true );

	im_state = 0;

	new chan = VG_Audio_GetChannelFromSoundID( ts_music_id );
	if( chan != 0 ) VG_Audio_StopChannel( chan );

	VG_Sleep(30 );
}

StartPlayerSelect() {
	game_state = GAMESTATE_PLAYERSELECT;
	VG_Text_SetOnBatch( 0, VG_TEXT_COUNT, false );
	VG_BG_SetScroll( 75*16 );

	text_next = 0;
	
	Text_AddString( 0, "1 PLAYER", 128-32, 80-4-12,true );
	Text_AddString( 0, "2 PLAYER", 128-32, 80-4+12,true );
	VG_Text_SetOnBatch( 0, 14, true );

	VG_Text_SetOffsetParam( 0, 0, 0, 3 );

	ps_cursor = VG_Sprites_Create( SPRITEMODEL );
	VG_Sprites_SetTexture( ps_cursor, SPR_IDLE );
	VG_Sprites_SetPosition( ps_cursor, 75*16+64,64-16-6 );

	ps_selection=0;
}

StartIngame() {

	exitstage_timer = 0;
	death_timer = 0;

	VG_Text_SetOnBatch( 0, VG_TEXT_COUNT, false );
	game_state = GAMESTATE_GAMEINIT;
	for( new i = 0; i < 2; i++ ) {
		player_accel[i] = 0;
		player_direction[i] = 0;
		player_sprite[i] = 0;
		
		player_jumptime[i] = 0;
		player_vel[0][i] = 0;
		player_vel[1][i] = 0;
		player_grounded[i] = true;
		player_footstep_frame[i] = 0;
		//player_alive[i] = 1;

		player_growth[i] = 0;
		player_growth_frame[i] = 0;
		player_big[i] = 0;
		player_hide[i] = 0;

		player_dead[i] = 0;
	}

	timer_active = 0;
	current_time = 0;
	current_score = 0;
	score_dirty = false;


	input_override = 0;
	camera = 0.0;
	ingame_state =0;

	speech_active = 0;

	ClearArray( entity_list );

	VG_BG_SetScreenRefresh();

	StartMap( "level1.tmx.out" );
	VG_SetBlanking( false );

	VG_BG_SetScroll(388*16);

	// create player sprites
	player_sprite[0] = VG_Sprites_Create( SPRITEMODEL );
	player_sprite[1] = VG_Sprites_Create( SPRITEMODEL );
	VG_Sprites_SetPosition( player_sprite[0], player_pos[0][0]>>8, (player_pos[0][1]>>8) - 16 );

	if( ps_selection == 0 ) {
		player_dead[1] = 666;
		VG_Sprites_SetPosition( player_sprite[0], player_pos[0][0]>>8, (player_pos[0][1]>>8) - 16 );
	} else {
		VG_Sprites_SetPosition( player_sprite[1], player_pos[1][0]>>8, (player_pos[1][1]>>8) - 16 );
	}
	VG_Sprites_SetTexture( player_sprite[0], SPR_IDLE );
	VG_Sprites_SetTexture( player_sprite[1], SPR_LUEGI );

	SetupSpeech();
	SetupScoreUI();

	gi_state = 0;

	ingame_music_id = VG_Audio_Play( soundlist[SOUND_INGAME_MUSIC], 99, _, _, 130.5);
	music_fade = 1.0;
}

//----------------------------------------------------------------------------------------------------------------------
StartTitlescreen() {
	VG_Audio_Panic();
	ts_press_e_timer = 0;
	ts_press_e_on = false;
	ts_timeout = 0;
	ts_page = 0;
	ts_page_counter = 0;
	ts_page_scrolling = false;
	ts_page_scrollpos = 0;

	game_state = GAMESTATE_TITLE;

	text_next = 0;
	VG_Text_SetModelBatch(0,100,FONTMODEL);
	VG_Text_SetSizeBatch(0,100,1);
	VG_Text_SetOffsetParam( 0, 0, 0, 0 );
	VG_Text_SetOffsetParam( 1, 0, 0, 0 );
	VG_Text_SetColorBatch(0,100,0x80808080);

	VG_Text_SetOnBatch(0,VG_TEXT_COUNT,false);

	Text_AddString( 0, "PRESS E", 12*8+8,14*8 );

	// highscore
	for( new i = 0; i < 3; i++ ) {
		Text_AddString( 1, topscore_names[i], 40, 56+i*24, false, 128 );
		decl String:score[32];
		Format( score, sizeof(score), "%05d", topscore_score[i] );
		Text_AddString( 1, score, 32+128+16, 56+i*24, true );
	}

	
	VG_BG_SetScreenRefresh();
	mapwidth = VG_BG_LoadFile( "title.tmx.out", -1 );
	
	
	VG_SetBlanking( true );

	VG_BG_SetScroll( 57*16 );
	ts_intro = 180;
	VG_SetUpdateTime(99);
	VG_Sleep(100);

	// mareo and princess
//	ts_mareo = VG_Sprites_Create( SPRITEMODEL );
//	VG_Sprites_SetTexture( ts_mareo, SPR_IDLE );
//	VG_Sprites_SetPosition( ts_mareo, 32,128-16 );
	
//	ts_princess = VG_Sprites_Create( SPRITEMODEL );
//	VG_Sprites_SetTexture( ts_princess, SPR_PRINCESS );
//	VG_Sprites_SetPosition( ts_princess, 224, 128-16 );
}

//----------------------------------------------------------------------------------------------------------------------
SetAnimation( player, start, len, speed, bool:forcereset=false ) {
	if( player_animation_start[player] != start || forcereset ) {
		player_animation_frame[player] = 0;
		player_animation_start[player] = start;
		player_animation_len[player] = len;
	}
	player_animation_speed[player] = speed;
}

//----------------------------------------------------------------------------------------------------------------------
ScanMobs() {
	if( mobs != INVALID_HANDLE ) CloseHandle(mobs);
	mobs = CreateStack(MOBBLOCKSIZE);
	VG_BG_ProcessTilemap( 0, mapwidth-1, ScanMobsFunc );
	
	// reverse data
	new Handle:mobs2 = CreateStack(MOBBLOCKSIZE);
	decl buffer[MOBBLOCKSIZE];
	while( !IsStackEmpty(mobs) ) {
		PopStackArray( mobs, buffer );
		PushStackArray(mobs2, buffer);
	}
	CloseHandle(mobs);
	mobs = mobs2;

}

//----------------------------------------------------------------------------------------------------------------------
public ScanMobsFunc( x, y, tile ) {
	if( tile == TILE_MAREO ) {
		// spawn mario
		player_pos[0][0] = x<<12;
		player_pos[0][1] = y<<12;
		return 0;
	} else if( tile == TILE_LUEGI ) {
		// spawn luigi
		player_pos[1][0] = x<<12;
		player_pos[1][1] = y<<12;
		return 0;
	} else if( tile == TILE_GOOBY ) {
		decl data[4];
		data[0] = x;
		data[1] = y;
		data[2] = MOB_GOOBY;
		PushStackArray( mobs, data );
		// queue goomber
		return 0;
	} else if( tile == TILE_PRINCESS ) {
		decl data[4];
		data[0] = x;
		data[1] = y;
		data[2] = MOB_PRINCESS;
		PushStackArray( mobs, data );
		return 0;
	} else if( tile == TILE_COIN ) {
		decl data[4];
		data[0] = x;
		data[1] = y;
		data[2] = MOB_COIN;
		PushStackArray( mobs, data );
		return 0;
	//} else if( tile == TILE_ENDMARK ) {
	//	
	//	decl data[4];
	//	data[0] = x;
	//	data[1] = y;
	//	data[2] = MOB_ENDMARK;
	//	PushStackArray( mobs, data );
	//	return 0;
	} else if( tile == TILE_CASTLE ) {
		castle_point = x;
		return TILE_CASTLE;
	}
	return tile;
}

//----------------------------------------------------------------------------------------------------------------------
StartMap( const String:map[] ) {
	
	mapwidth = VG_BG_LoadFile( map, -1 );
	ScanMobs();
	input_override = 0;
}

#define TEXT_SPEECHBOX		0
#define TEXT_SPEECHLINES	40
#define TEXT_SCORE			106
#define TEXT_SCORE_SCORELABEL (TEXT_SCORE+0)
#define TEXT_SCORE_TIMELABEL (TEXT_SCORE+4)
#define TEXT_SCORE_SCOREVAL (TEXT_SCORE+7)
#define TEXT_SCORE_TIME (TEXT_SCORE+12)

//----------------------------------------------------------------------------------------------------------------------
SetupScoreUI() {
	
	VG_Text_SetModelBatch( TEXT_SCORE, 18, FONTMODEL );
	VG_Text_SetOffsetBatch( TEXT_SCORE, 18, 2 );
	VG_Text_SetOnBatch( TEXT_SCORE, 18, true );
	VG_Text_SetSizeBatch( TEXT_SCORE, 18, 1 );
	VG_Text_SetColorBatch( TEXT_SCORE, 18, 0x80808080 );

	VG_Text_SetPositionGrid( TEXT_SCORE_SCORELABEL, 4, 8, 16, 4, 16,16 );
	VG_Text_SetPositionGrid( TEXT_SCORE_TIMELABEL, 3, 140, 16, 4, 16,16 );

	for( new i = 0; i < 4; i++ ) {
		VG_Text_SetFrame( TEXT_SCORE_SCORELABEL + i, 128+i );
	}
	
	for( new i = 0; i < 3; i++ ) {
		VG_Text_SetFrame( TEXT_SCORE_TIMELABEL + i, 132+i );
	}

	for( new i = 0; i < 5; i++ ) {
		VG_Text_SetPosition( TEXT_SCORE_SCOREVAL+i, 71+i*10,14 );
		VG_Text_SetFrame( TEXT_SCORE_SCOREVAL +i, 112 );
	}

	for( new i = 0; i < 3; i++ ) {
		VG_Text_SetPosition( TEXT_SCORE_TIME+i, 192+i*10, 14 );
		VG_Text_SetFrame( TEXT_SCORE_TIME+i, 112 );
	}

	VG_Text_SetPosition( TEXT_SCORE_TIME+5, 223,17 );
	VG_Text_SetFrame( TEXT_SCORE_TIME+5, 122 );

	for( new i = 0; i < 2; i++ ) {
		VG_Text_SetPosition( TEXT_SCORE_TIME+3+i, 229+i*10,14 );
		VG_Text_SetFrame( TEXT_SCORE_TIME+3+i, 112 );
	}

	VG_Text_SetOffsetParam( 2, 0,0, 0 ); // hide score ui
}

//----------------------------------------------------------------------------------------------------------------------
#define SPEECHBOX_LEFT		3
#define SPEECHBOX_TOP		2
#define SPEECHBOX_WIDTH 10
#define SPEECHBOX_HEIGHT 4
#define SPEECHBOX_CELLS (SPEECHBOX_WIDTH*SPEECHBOX_HEIGHT)

// create text lines
#define SPEECHLINE_COLS 22
#define SPEECHLINE_ROWS 3
#define SPEECHLINE_CELLS (SPEECHLINE_COLS*SPEECHLINE_ROWS)

//----------------------------------------------------------------------------------------------------------------------
SetupSpeech() {

	VG_Text_SetModelBatch( 0, SPEECHBOX_CELLS, FONTMODEL );
	VG_Text_SetColorBatch( 0, SPEECHBOX_CELLS, 0x80808080 );
	VG_Text_SetSizeBatch( 0, SPEECHBOX_CELLS, 1 );
	VG_Text_SetPositionGrid( 0, SPEECHBOX_CELLS, SPEECHBOX_LEFT*16, SPEECHBOX_TOP*16, SPEECHBOX_WIDTH, 16, 16 );
	VG_Text_SetOffsetBatch( 0, SPEECHBOX_CELLS, 0 );
	VG_Text_SetOffsetParam( 0, 0,0 , 0 );

	// center
	for( new x = 1; x < SPEECHBOX_WIDTH-1; x++ ) {
		for( new y = 1; y < SPEECHBOX_HEIGHT; y++ ) {
			VG_Text_SetFrame( x + y * SPEECHBOX_WIDTH, 104 );
		}
	}
	// left/right
	for( new y = 1; y < SPEECHBOX_HEIGHT-1; y++ ) {
		VG_Text_SetFrame( 0 + y * SPEECHBOX_WIDTH, 101 );
		VG_Text_SetFrame( (SPEECHBOX_WIDTH-1) + y * SPEECHBOX_WIDTH, 100 );
	}
	// top/bottom
	for( new x = 1; x < SPEECHBOX_WIDTH-1; x++ ) {
		VG_Text_SetFrame( x, 102 );
		VG_Text_SetFrame( x + (SPEECHBOX_HEIGHT-1)*SPEECHBOX_WIDTH, 103 );
	}

	VG_Text_SetFrame( 0, 96 );
	VG_Text_SetFrame( SPEECHBOX_WIDTH-1, 97 );
	VG_Text_SetFrame( (SPEECHBOX_HEIGHT-1)*SPEECHBOX_WIDTH, 98 );
	VG_Text_SetFrame( SPEECHBOX_WIDTH-1+(SPEECHBOX_HEIGHT-1)*SPEECHBOX_WIDTH, 99 );

	VG_Text_SetOnBatch( 0, SPEECHBOX_CELLS, true );


	VG_Text_SetModelBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, FONTMODEL );
	VG_Text_SetSizeBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, 1 );
	VG_Text_SetColorBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, 0x80808080 );
	//VG_Text_SetPositionGrid( SPEECHBOX_CELLS, SPEECHLINE_CELLS, SPEECHBOX_LEFT*16+16, SPEECHBOX_TOP*16+16, (SPEECHBOX_WIDTH-2)*2, 8, 12 );
	VG_Text_SetOffsetBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, 1 );
	VG_Text_SetOffsetParam( 1, 0,0 , 3 );
	VG_Text_SetFrameBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, 'a'-32 );

}
/*
//----------------------------------------------------------------------------------------------------------------------
ShowSpeechlines() {
	
}*/

//----------------------------------------------------------------------------------------------------------------------
ShowSpeechbox() {
	VG_Text_SetOffsetParam( 0, 0,0 , 2 );
	VG_Text_SetOffsetParam( 1, 0,0 , 3 );
}

//----------------------------------------------------------------------------------------------------------------------
HideSpeechbox() {
	VG_Text_SetOffsetParam( 0, 0,0 , 0 );
	VG_Text_SetOffsetParam( 1, 0,0 , 0 );
}

//----------------------------------------------------------------------------------------------------------------------
EraseSpeechText() {
	VG_Text_SetFrameBatch( SPEECHBOX_CELLS, SPEECHLINE_CELLS, 0 );
	speech_cell = 0;
}

//----------------------------------------------------------------------------------------------------------------------
StartSpeech( index, length ) {
	EraseSpeechText();
	ShowSpeechbox();
	speech_active = true;
	speech_index = index;
	speech_length = length;
	speech_read = 0;
	speech_cell = 0;
	speech_pen = 0;
	speech_line = 0;
	speech_timer = 0;
	speech_wait = 0;
}
/*
//----------------------------------------------------------------------------------------------------------------------
SpeechNewLine() {
	speech_line++;
	speech_pen = 0;
}*/

//----------------------------------------------------------------------------------------------------------------------
bool:SpeechOutputChar() {
	
	new character = speechlines[speech_index][speech_read];
	if( character == 0 ) {
		speech_read = 0;
		speech_index++;
		speech_length--;
		return true;
	}
	if( character == 1 ) {
		ingame_state = IGS_GROWTH;
		player_growth[0] = 0;
		player_growth[1] = -30;
		speech_read++;
		return SpeechOutputChar();
	}
	speech_read++;
	if( character < 32 || character >= 128 ) return false;
	character -= 32;

	if( character == 0 ) {
		speech_pen += 3;
		return SpeechOutputChar();
	}
	
	VG_Audio_Play( soundlist[SOUND_SPEECH], _, 140, 0.5 );
	if( character != 0 ) VG_Text_SetPosition( SPEECHBOX_CELLS+speech_cell, SPEECHBOX_LEFT*16+16+speech_pen - font_offsets[character*3], SPEECHBOX_TOP*16+16+speech_line*12 + font_offsets[character*3+1] );
	speech_pen += font_offsets[(character)*3+2];
	VG_Text_SetFrame( SPEECHBOX_CELLS+speech_cell, character );
	VG_Text_SetOn( SPEECHBOX_CELLS+speech_cell, true );
	speech_cell++;
	return false;
}

//----------------------------------------------------------------------------------------------------------------------
SpeechBlinkCursor() {
	speech_cursor_blink = !speech_cursor_blink;
	VG_Text_SetOn( SPEECHBOX_CELLS+speech_cell, speech_cursor_blink );
}

PlaceSpeechCursor() {
	new character = 95;
	VG_Text_SetPosition( SPEECHBOX_CELLS+speech_cell, SPEECHBOX_LEFT*16+16+speech_pen - font_offsets[character*3], SPEECHBOX_TOP*16+16+speech_line*12 + font_offsets[character*3+1] );
	VG_Text_SetFrame( SPEECHBOX_CELLS+speech_cell, character );
	VG_Text_SetOn( SPEECHBOX_CELLS+speech_cell, true );
	speech_cursor_blink = false;
}
/*
RemoveSpeechCursor() {
	VG_Text_SetOn( SPEECHBOX_CELLS+speech_cell, false );
}*/

//----------------------------------------------------------------------------------------------------------------------
UpdateSpeech() {
	if( speech_active ) {

		if( !speech_wait ) {
			speech_timer += 50;
			if( speech_timer >= 256 ) {
				speech_timer -= 256;

				// print char
				if( SpeechOutputChar() ) {
					if( speech_line < 2 && speech_length ) {
						speech_line++;
						speech_pen = 0;
					} else {
						if( speech_length ) {
							speech_wait = 1;
							speech_timer =0;
							PlaceSpeechCursor();
						} else {
							speech_wait = 2;
						}
						
						
					}
					
//					if( speech_length ) {
	//					speech_line++;
		//				speech_pen = 0;
			//		} else {
//
	//				}
				}
			}
		} else {


			if( speech_wait == 1 ) {
				speech_timer += 10;
				if( speech_timer >= 256 ) {
					speech_timer -= 256;
					SpeechBlinkCursor();
				}
			} else {
				
			}
			if( VG_Joypad_Clicks( 1, VG_INPUT_JUMP_INDEX, false ) || VG_Joypad_Clicks( 2, VG_INPUT_JUMP_INDEX ) )  {

				if( speech_wait == 1 ) {
					speech_wait = 0;
					EraseSpeechText();
					speech_cell = 0;
					speech_line = 0;
					speech_pen = 0;
				} else {
					HideSpeechbox();
					speech_active = false;
				}
			}
		}
		
	}
}


//----------------------------------------------------------------------------------------------------------------------
SolidTest( x, y ) {
	new tile = VG_BG_GetTile( x>>4, y>>4 );
	if( tile < 0 ) return 'x';
	return solid_map[tile] == 'x';
	
}

//----------------------------------------------------------------------------------------------------------------------
Abs( x ) {
	return x < 0 ? -x : x;
}

AddScore( amount ) {
	current_score += amount;
	score_dirty = true;
}

OnFrame_GameInit() {
	if( gi_state == 0 ) {
		gi_state = 1;
		VG_SetUpdateTime( 3 );
		VG_BG_SetScreenRefresh();
		VG_BG_SetScroll(0);
		VG_Text_SetOffsetParam( 2, 0,0, 3 ); // show score ui
		VG_Sleep( 60 );
	} else {
		VG_SetUpdateTime( 900 );
		game_state = GAMESTATE_INGAME;
	}
}

OnFrame_PlayerSelect() {
	if( VG_Joypad_Clicks( 1, VG_INPUT_DOWN_INDEX ) || VG_Joypad_Clicks( 1, VG_INPUT_UP_INDEX ) || VG_Joypad_Clicks( 1, VG_INPUT_F_INDEX ) ) {
		ps_selection = 1-ps_selection;
		VG_Audio_Play( soundlist[SOUND_SCORECOUNTER],1,_,0.5 );
		VG_Sprites_SetPosition( ps_cursor, 75*16+64,64-16-6 +ps_selection*24 );
		

	}

	if( VG_Joypad_Clicks( 1, VG_INPUT_E_INDEX ) || VG_Joypad_Clicks( 1, VG_INPUT_JUMP_INDEX ) ) {
		
		VG_Audio_Play( soundlist[SOUND_COIN] );
		StartIntermission();
	}
}

OnFrame_Gameover() {
	StartTitlescreen();
}

OnFrame_Intermission() {
	if( im_state == 0 ) {
		VG_Text_SetOffsetParam( 0, 0, 0, 3 );
		VG_BG_SetScroll( 92*16 );

		// mario/luigi
		if( ps_selection == 0 ) {
			//1 player
			new sprite = VG_Sprites_Create( SPRITEMODEL );
			VG_Sprites_SetPosition( sprite, 92*16+128-8, 64-16 );
			VG_Sprites_SetTexture( sprite, SPR_IDLE );

		} else {
			// 2 player
			new sprite = VG_Sprites_Create( SPRITEMODEL );
			VG_Sprites_SetPosition(sprite, 92*16+110,64-16);
			VG_Sprites_SetTexture( sprite, SPR_IDLE );

			sprite = VG_Sprites_Create( SPRITEMODEL );
			VG_Sprites_SetPosition( sprite, 92*16+130,64-16 );
			VG_Sprites_SetTexture( sprite, SPR_LUEGI );
		}

		im_state = 1;
		VG_Sleep( 60*4 );
	} else if( im_state == 1 ) {
		VG_Text_SetOffsetParam( 0, 0, 0, 0 );
		VG_BG_SetScroll( 57*16 );
		VG_Sprites_DeleteAll();
		VG_Sleep(30 );
		im_state = 2;
	} else if( im_state == 2 ) {
		StartIngame();
		im_state = 3;
		VG_SetUpdateTime(900);
		VG_Sleep(60);
	}
}

UpdatePlayerDead(i) {
	if( player_dead[i] < 666 ) {
		player_dead[i]++;
		if( player_dead[i] == 30 ) {
			player_vel[i][1] = -4 * 256;
			VG_Audio_Play( soundlist[SOUND_DEATH], 50 );
		} else if( player_dead[i] > 30 ) {
			player_vel[i][1] += 44;
			player_vel[i][1] *= 250;
			player_vel[i][1] >>= 8;
			player_pos[i][1] += player_vel[i][1];
			if( player_pos[i][1] > (160-16)*256 ) {
				player_dead[i] = 666;
				
				VG_Sprites_SetPosition( player_sprite[i], -900, 0 );
			} else {
				VG_Sprites_SetPosition( player_sprite[i], player_pos[i][0]>>8, (player_pos[i][1]>>8)-16 );
			}
		}
	
		new animation_offset = 0;
		if( i == 1 ) animation_offset += SPR_LUEGI;
		
		VG_Sprites_SetTexture( player_sprite[i], SPR_DEATH + animation_offset );
	}
	
	
}

UpdatePlayer( i ) {

	new audio_pitch_offset = i == 0 ? 0 : 40;
	if( player_dead[i] ) {
		UpdatePlayerDead(i);
		return;
	}
	new keys = VG_Joypad_Read( i+1 );
		
	if( input_override ) {

		
		new pos2 = i == 1 ? (input_override_position - 18*256):input_override_position;
		if( ingame_state == IGS_EXITSTAGE ) pos2 = input_override_position; // cancel that if theyre entering the door!!
		keys = 0;
		new diff = player_pos[i][0] - pos2;
		if( diff > 4*256 ) {
			keys = VG_INPUT_LEFT;
		} else if( diff < -4*256 ) {
			keys = VG_INPUT_RIGHT;
		} else if( Abs(diff)<256 ) {
			if( ingame_state == IGS_LEVELEND ) {
				ingame_state = IGS_SPEECH;

				new spindex;
				new splength;
				// 
				if( player_dead[1] || ps_selection == 0 ) { // luegi dead or not there
					new random = GetRandomInt( 0, (sizeof(speechlines_mareo)/2) -1 );
					spindex = speechlines_mareo[random*2];
					splength = speechlines_mareo[random*2+1];
				} else if( !player_dead[0] && !player_dead[1] ) { // both alive
					new random = GetRandomInt( 0, (sizeof(speechlines_double)/2) -1 );
					spindex = speechlines_double[random*2];
					splength = speechlines_double[random*2+1];
				} else { // mareo dead
					new random = GetRandomInt( 0, (sizeof(speechlines_luegi)/2) -1 );
					spindex = speechlines_luegi[random*2];
					splength = speechlines_luegi[random*2+1];
				}

				StartSpeech( spindex,splength );

			} else if( ingame_state == IGS_EXITSTAGE ) {
				player_hide[i] = true;
			}
			player_pos[i][0] = pos2;//input_override_position;
			player_direction[i] = 0;
		}
	}
	
	if( keys & VG_INPUT_RIGHT ) {
		if( keys & VG_INPUT_SHIFT ) player_accel[i] += 200;
		player_vel[i][0] += 40;
			
		player_direction[i] = 0;
		timer_active = true;
		
	} else if( keys & VG_INPUT_LEFT ) {
		if( keys & VG_INPUT_SHIFT ) player_accel[i] -= 200;
		player_vel[i][0] -= 40;
		player_direction[i] = 1;
	}
	player_vel[i][0] += player_accel[i]>>8;

	// clamp and decay
	if( player_accel[i] < -256*45 ) player_accel[i] = -256*45;
	if( player_accel[i] > 256*45 ) player_accel[i] = 256*45;
	if( (keys & VG_INPUT_RIGHT) || (keys & VG_INPUT_LEFT ) ) {
		player_accel[i] *= 250;
	} else {
		player_accel[i] *= 230;
	}
	player_accel[i] >>= 8;
	if( Abs(player_accel[i]) < 50 ) player_accel[i] = 0;
		
	
	if( keys & VG_INPUT_JUMP ) {
		if( player_grounded[i] ) {
			if( VG_Joypad_Clicks( i+1, VG_INPUT_JUMP_INDEX ) ) {
				VG_Audio_Play( soundlist[GetRandomInt(SOUND_JUMP1,SOUND_JUMP2)], _, GetRandomInt( 95, 110 ) + audio_pitch_offset );
				player_vel[i][1] = -3 * 256;
				player_grounded[i] = false;
				player_jumptime[i] = 15;
			}
		} else {
			if( player_jumptime[i] > 0 ) {
				if( player_vel[i][1] < 0 ) {
					player_vel[i][1] -= 20;
					player_vel[i][1] *= 270;	
					player_vel[i][1] >>= 8;
				}
			}
		}
	}
	player_jumptime[i]--;


	if( !player_grounded[i] ) {
		player_vel[i][1] += 44;
		player_vel[i][1] *= 250;
		player_vel[i][1] >>= 8;
	}
	player_vel[i][0] *= 225;
	player_vel[i][0] >>= 8;
	if( Abs(player_vel[i][0]) < 10 ) player_vel[i][0] = 0;
	

	player_pos[i][0] += player_vel[i][0];
	if( ingame_state != IGS_EXITSTAGE ) {
		if( player_vel[i][0] < 0 ) {
			if( SolidTest( player_pos[i][0]>>8, player_pos[i][1]>>8 ) ||
				SolidTest( player_pos[i][0]>>8, (player_pos[i][1]>>8) + 15 ) ) {
				player_accel[i] = 0;
				player_vel[i][0] = 0;
				player_pos[i][0] = ((player_pos[i][0] >> 12)+1) << 12;
			}

			if( input_override == 0 && ingame_state == IGS_PLAYING ) {
				if( (player_pos[i][0]>>8) < RoundToFloor(camera) ) {
					player_pos[i][0] = RoundToFloor(camera)<<8;
					player_vel[i][0] = 0;
					player_accel[i] = 0;
				}
			}
		
		} else if( player_vel[i][0] > 0 ) {
			if( SolidTest( (player_pos[i][0]>>8)+16, (player_pos[i][1]>>8) ) ||
				SolidTest( (player_pos[i][0]>>8)+16, (player_pos[i][1]>>8) + 15 ) ) {
				player_accel[i] = 0;
				player_vel[i][0] = 0;
				player_pos[i][0] = ((player_pos[i][0] >> 12)) << 12;
			}
			
			if( input_override == 0 && ingame_state == IGS_PLAYING ) {
				if( player_pos[i][0] >= (RoundToFloor(camera)+256-16)*256 ) {
					player_pos[i][0] = (RoundToFloor(camera)+256-16)*256;
					player_vel[i][0] = 0;
					player_accel[i] = 0;
				}
			}
		}
	}
	
	
	player_pos[i][1] += player_vel[i][1];
	if( player_grounded[i] ) {
		if( !SolidTest( (player_pos[i][0]>>8), (player_pos[i][1]>>8)+16 ) &&
			!SolidTest( (player_pos[i][0]>>8)+15, (player_pos[i][1]>>8)+16 ) ) {
			player_grounded[i] = false;
		}
	} else {
		if( player_vel[i][1] > 0 ) {
			if( SolidTest( (player_pos[i][0]>>8), (player_pos[i][1]>>8)+16 ) ||
				SolidTest( (player_pos[i][0]>>8)+15, (player_pos[i][1]>>8)+16 ) ) {
				VG_Audio_Play( soundlist[SOUND_LAND], _, GetRandomInt( 95, 110 ) + audio_pitch_offset );

				player_grounded[i] = true;
				kill_bounce_bonus[i] = 0;
				player_vel[i][1] = 0;
				player_pos[i][1] = ((player_pos[i][1]>>12))<<12;

				if( player_pos[i][1] >= (160-16)*256 ) {
					player_dead[i] = 29;
					
				}
			}

		} else if( player_vel[i][1] < 0 ) {
			if( SolidTest( (player_pos[i][0]>>8)+8, (player_pos[i][1]>>8) ) ) {
				if( player_vel[i][1] <= BOXHIT_VEL_THRESHOLD )
					VG_Audio_Play( soundlist[GetRandomInt(SOUND_BOXHIT1,SOUND_BOXHIT2)], _, GetRandomInt( 95, 110 ) + audio_pitch_offset );
				player_vel[i][1] = 0;
				player_pos[i][1] = ((player_pos[i][1]>>12)+1)<<12;
			} else if( SolidTest( (player_pos[i][0]>>8)+15, (player_pos[i][1]>>8) ) ) {
				if( player_vel[i][0] > 0 ) {
					player_vel[i][0] = 0;
				}
				player_pos[i][0] = ((player_pos[i][0]>>12))<<12;
			} else if( SolidTest( (player_pos[i][0]>>8), (player_pos[i][1]>>8) ) ) {
				if( player_vel[i][0] < 0 ) {
					player_vel[i][0] = 0;
				}
				player_pos[i][0] = ((player_pos[i][0]>>12)+1)<<12;
			}
		}
	}

	if( player_grounded[i] ) {
			
		if( Abs(player_vel[i][0]) < 40 ) {
			SetAnimation( i, SPR_IDLE, 1, 0 );
		} else {
			SetAnimation( i, SPR_WALK, 3, (40 * Abs(player_vel[i][0]))>>8 );
		}
	} else {
			
			
		SetAnimation( i, SPR_AIR, 1, 0 );
			
	}
		
	if( !player_hide[i] ) {
		VG_Sprites_SetPosition( player_sprite[i], player_pos[i][0]>>8, (player_pos[i][1]>>8)-16 );
	} else {
		VG_Sprites_SetPosition( player_sprite[i], -900, 0 );
	}

	new animation_offset = 0;
	if( player_direction[i] ) animation_offset += 1;
	if( i == 1 ) animation_offset += SPR_LUEGI;
	if( player_big[i] ) animation_offset += SPR_BIGIDLE;
		
	if( !player_growth[i] ) {
		VG_Sprites_SetTexture( player_sprite[i], player_animation_start[i] + (player_animation_frame[i]>>8)*2 + animation_offset );
	} else {

		VG_Sprites_SetTexture( player_sprite[i], player_growth_frame[i] +animation_offset  );
	}

		
	player_animation_frame[i] += player_animation_speed[i];
	if( player_animation_frame[i] >= (player_animation_len[i]<<8) ) {
		player_animation_frame[i] -= (player_animation_len[i]<<8);
	}

	if( !player_footstep_frame[i] ) {
		if( player_animation_start[i] == SPR_WALK ) {
			if( (player_animation_frame[i] >>8) == 1 ) {
				player_footstep_frame[i] = true;
				// playsound
			}
		}
	} else {
		if( player_animation_start[i] == SPR_WALK ) {
			if( (player_animation_frame[i] >>8) != 1 ) {
				player_footstep_frame[i] = false;
					
				new pitchoff = player_big[i] ? -20 : 0;
				VG_Audio_Play( soundlist[GetRandomInt(SOUND_FOOTSTEP1,SOUND_FOOTSTEP3)], _, GetRandomInt( 95, 110 )+pitchoff + audio_pitch_offset );
				// playsound
			}
		} else {
			player_footstep_frame[i] = false;
		}
	}

	// test for collision with objects
	// +4,+12 = collision borders
	// +8 = jump landing attack
	{
		new size = GetArraySize( entity_list );

		new bool:points[6]; // topleft,topright,bottomleft,bottomright,down


		for( new ent = 0; ent < size; ent++ ) {
			decl data[ENTDATASIZE];
			new bool:delete_entry = false;
			GetArrayArray( entity_list, ent, data );

			points[0] = ((player_pos[i][0]+(5<<8))  >= data[1]) && ((player_pos[i][0]+(5<<8))  < (data[1]+(16<<8))) && ((player_pos[i][1]+(0<<8)) >= data[2]) && ((player_pos[i][1]+(0<<8)) < (data[2]+(16<<8)));
			points[1] = ((player_pos[i][0]+(11<<8)) >= data[1]) && ((player_pos[i][0]+(11<<8)) < (data[1]+(16<<8))) && ((player_pos[i][1]+(0<<8)) >= data[2]) && ((player_pos[i][1]+(0<<8)) < (data[2]+(16<<8)));
			points[2] = ((player_pos[i][0]+(5<<8)) >= data[1])  && ((player_pos[i][0]+(5<<8)) < (data[1]+(16<<8))) && ((player_pos[i][1]+(15<<8)) >= data[2]) && ((player_pos[i][1]+(15<<8)) < (data[2]+(16<<8)));
			points[3] = ((player_pos[i][0]+(11<<8)) >= data[1]) && ((player_pos[i][0]+(11<<8)) < (data[1]+(16<<8))) && ((player_pos[i][1]+(15<<8)) >= data[2]) && ((player_pos[i][1]+(15<<8)) < (data[2]+(16<<8)));
			points[4] = ((player_pos[i][0]+(8<<8)) >= data[1])  && ((player_pos[i][0]+(8<<8)) < (data[1]+(16<<8))) && ((player_pos[i][1]+(15<<8)) >= data[2]) && ((player_pos[i][1]+(15<<8)) < (data[2]+(16<<8)));
			switch( data[0] ) {
				case MOB_COIN:
				{
					if( points[0]||points[1]||points[2]||points[3] ) {
						VG_BG_SetTile( data[1]>>12,data[2]>>12, 0 );
						// play coin sound
						VG_Audio_Play( soundlist[SOUND_COIN] );
						// add score
						AddScore( SCORE_COIN );
							
						delete_entry = true;
					}
				}
				case MOB_GOOBY:
				{
					if( !data[GOOBY_DEAD] ) {
						if( (points[4] || points[3] || points[2]) && !player_grounded[i] && player_vel[i][1] > 0 && ((player_pos[i][1]>>8) <= ((data[2]>>8)-8)) ) {
							data[GOOBY_DEAD] = 30;
							VG_Audio_Play( soundlist[SOUND_GOOBY], _, GetRandomInt( 95, 110 ) );
								
							SetArrayArray( entity_list, ent, data );
							VG_Sprites_SetTexture( data[3], SPR_GOOBY+2 );

							AddScore( SCORE_GOOBY * (kill_bounce_bonus[i]+1) );
							kill_bounce_bonus[i]++;
							player_vel[i][1] = -3 * 256;
							player_grounded[i] = false;
							player_jumptime[i] = 15;
						} else if( points[0]||points[1]||points[2]||points[3] && ((player_pos[i][1]>>8) >= ((data[2]>>8)-9))  ) {
							player_dead[i] = 1;
							VG_Audio_Play( soundlist[SOUND_NOMNOM], 50 );
						//	player_pos[i][0] = 0;
						//	player_pos[i][1] = 0;
						}
					}
				}
			}

			if( delete_entry ) {
				RemoveFromArray( entity_list, ent );
				ent--;
				size--;
			}
		}
	}
}

OnFrame_Ingame() {
	if( timer_active && ingame_state == IGS_PLAYING ) {
		current_time++;
	}
	
	for( new i = 0; i < 2; i++ ) {
	
		UpdatePlayer(i);

	}

	if( player_dead[0] && player_dead[1] ) {
		ingame_state = IGS_DEATH;

		
		new chan = VG_Audio_GetChannelFromSoundID( ingame_music_id );
		if( chan ) {
			VG_Audio_StopChannel( chan );
		}
	}

	if( ingame_state == IGS_PLAYING ) {
		new chan = VG_Audio_GetChannelFromSoundID( ingame_music_id );
		if( chan ) {
			if( VG_Audio_GetTimeout( chan ) <= 0.0 ) {
				ingame_music_id = VG_Audio_Play( soundlist[SOUND_INGAME_MUSIC], 99, _, _, 130.5);
			}
		} else {
			ingame_music_id = VG_Audio_Play( soundlist[SOUND_INGAME_MUSIC], 99, _, _, 130.5);
		}
	}

	if(ingame_state == IGS_LEVELEND ) {
		// fade music
		music_fade -= 0.01;
		if( music_fade < 0.0 ) music_fade = 0.0;
		new chan = VG_Audio_GetChannelFromSoundID( ingame_music_id );
		if( chan ) {
			VG_Audio_SetChannelVolume( chan, music_fade );
		}

	} else if( ingame_state == IGS_SPEECH ) {

		new chan = VG_Audio_GetChannelFromSoundID( ingame_music_id );
		if( chan ) {
			VG_Audio_StopChannel( chan );
		}

		if( !speech_active ) {
			ingame_state = IGS_GROWTH;

			player_growth[0] = 0;
			if( !player_dead[0] ) {
				
				player_growth[1] = -30;
			} else {
				player_growth[1] = 0;
			}
		}

	} else if( ingame_state == IGS_GROWTH ) {

		
		for( new i = 0; i < 2; i++ ) {
			if( player_dead[i] ) continue;
			if( player_growth[i] == 0 ) {
				VG_Audio_Play( soundlist[SOUND_POWERUP] );
			}

			if( player_growth[i] < 75 ) {
				new growth_frame;
				if( player_growth[i] < 45 ) {
					growth_frame = (player_growth[i]>>2)%2;
				} else {
					growth_frame = (player_growth[i]>>2)%3;
				}
				if( growth_frame == 0 ) {
					player_growth_frame[i] = SPR_IDLE;
				} else if( growth_frame == 1 ) {
					player_growth_frame[i] = SPR_GROW;
				} else if( growth_frame == 2 ) {
					player_growth_frame[i] = SPR_BIGIDLE;
				}
				
				//player_growth_frame[i] = player_growth[i] % 3;
			} else {
				player_growth_frame[i] = SPR_BIGIDLE;

			}
			player_growth[i]++;
			

		}

		if( player_growth[0] >= 110 || player_growth[1] >= 110 ) {
			player_growth[0] = 0;
			player_growth[1] = 0;
			player_big[0] = 1;
			player_big[1] = 1;
			ingame_state = IGS_EXITSTAGE;
			
			input_override_position = (castle_point)*16*256;
			input_override=true;

			VG_Audio_Play( soundlist[SOUND_STAGECLEAR], 99,_,_,10.0 );
		}
	} else if (ingame_state == IGS_EXITSTAGE ) {
		exitstage_timer++;
		if( exitstage_timer == 6*60 ) {
			ingame_state = IGS_SCORE;
			
			EraseSpeechText();
			igscore_timer = 0;
			igscore_oldscore = current_score;
			igscore_time = current_time;
			HideSpeechbox();
			speech_active = false;
		}
	} else if( ingame_state == IGS_SCORE ) {
		igscore_timer++;
		#define IGSCORE_TALLYTIME 150
		if( igscore_timer < IGSCORE_TALLYTIME ) {
			current_score = (igscore_oldscore * (IGSCORE_TALLYTIME-igscore_timer) + (actual_score_result * igscore_timer) + (IGSCORE_TALLYTIME/2)) / IGSCORE_TALLYTIME;
			score_dirty = true;
			current_time = (igscore_time * (IGSCORE_TALLYTIME-igscore_timer) + (IGSCORE_TALLYTIME/2)) / IGSCORE_TALLYTIME;
			if( igscore_timer&1 )
				VG_Audio_Play( soundlist[SOUND_SCORECOUNTER], 1,120,0.6 );
		} else if( igscore_timer == IGSCORE_TALLYTIME ) {
			
			current_score = actual_score_result;
			score_dirty = true;
			
			
			current_time = 0;
		} else if( igscore_timer == IGSCORE_TALLYTIME + 40 ) { // show highscore label

			if(ingame_highscore ) {
				text_next = TEXT_SPEECHLINES;

				for( new i = 0; i < 11; i++ ) {
					VG_Text_SetOffset( text_next, 1 );
					VG_Text_SetOn( text_next, true );
					VG_Text_SetFrame( text_next, 144+i );
					VG_Text_SetPosition( text_next, 128-165/2 + i*16,48 );
					text_next++;
				}
				//VG_Text_SetFrame
				//Text_AddString( 1, "HIGHSCORE!!", 128-11*4,48,true );
				VG_Text_SetOffsetParam( 1, 0, 0, 3 );
				VG_Audio_Play( soundlist[SOUND_HIGHSCORE], 99 );
				igscore_blink = 1;
			} else {
				text_next = TEXT_SPEECHLINES;
				Text_AddString( 1, "LOWSCORE!!", 128-10*4,48,true );
				Text_AddString( 1, "TRY AGAIN.", 128-10*4,58,true );
				VG_Audio_Play( soundlist[SOUND_LOWSCORE], 99 );
				VG_Text_SetOffsetParam( 1, 0, 0, 3 );
			}
			
		} else if( igscore_timer == IGSCORE_TALLYTIME + 40 + 300 ) { // restart game
			
			StartTitlescreen();
			return;
		}

		if( igscore_timer >= IGSCORE_TALLYTIME + 40 ) {
			if(ingame_highscore) {
				new t = igscore_timer - IGSCORE_TALLYTIME + 40;
				if( t % 20 == 0 ) {
					igscore_blink = !igscore_blink;
					VG_Text_SetOffsetParam( 1, 0, 0, igscore_blink ? 3 : 0 );
				}
			}
		}
	} else if( ingame_state == IGS_DEATH ) {
		death_timer++;
		if( death_timer == 120 ) {
			StartGameover();
			return;
		}
		
	}

	if( !IsStackEmpty( mobs ) ) {
		decl data[4];
		PopStackArray( mobs, data );
		if( RoundToFloor(camera) + VG_SCREEN_WIDTH >= data[0]*16 ) {
			 
			SpawnEntity( data[2], data[0], data[1] );
		} else {
			PushStackArray( mobs, data );
		}
	}

	blink_animation_time += 30;
	if( (blink_animation_time>>8) != blink_animation_last ) {
		if( (blink_animation_time>>8) >= 8 ) blink_animation_time -= 8<<8;
		blink_animation_last = blink_animation_time>>8;
		switch( blink_animation_last ) {
		case 0:
			blink_animation_update = 1;
			
		case 5:
			blink_animation_update = 2;
		case 6:
			blink_animation_update = 3;
		case 7:
			blink_animation_update = 2;
		}
	}

	UpdateSpeech();
	UpdateEntities();
	
	if( ingame_state == IGS_PLAYING ) {
		if( RoundToFloor(camera) > castle_point*16-500 ) {
			
			ingame_state = IGS_LEVELEND;

			RegisterScore( current_time, current_score );
			input_override = 1;
			input_override_position = 999<<12;
		}
	}
	
	if( input_override == 0 ) {

		new Float:desired_camera = camera;
		if( !player_dead[0] && player_dead[1] ) {
			// mareo only
			desired_camera = float(player_pos[0][0]>>8) - 64.0;
			if( desired_camera < 0.0 ) desired_camera = 0.0;
		} else if( player_dead[0] && !player_dead[1] ) {
			// luegi only
			desired_camera = float(player_pos[1][0]>>8) - 64.0;
			if( desired_camera < 0.0 ) desired_camera = 0.0;
		} else if( !player_dead[0] && !player_dead[1] ) {
			// double

			new Float:x1,Float:x2;
			x1 = float(player_pos[0][0]>>8);
			x2 = float(player_pos[1][0]>>8);
			new Float:far,Float:near;
			far = x1 > x2 ? x1 : x2;
			near = x1 > x2 ? x2 : x1;

			new Float:dc = far - 64.0;
			if( dc > near ) {
				// dont move
				desired_camera = near;
			} else {
				desired_camera = dc;
			}

			
		} else {
			// none, this will instantly stop scrolling
		}
	
		camera = camera * 0.9 + desired_camera * 0.1;
	} else if( input_override == 1 ) {

		if( ingame_state == IGS_LEVELEND ) {
			new Float:desired_camera = float(input_override_position>>8) - 64.0;
			if( camera < desired_camera ) camera += 2.0;
		}
	}
	
	VG_BG_SetScroll( RoundToFloor(camera) );

	if( score_dirty ) {
		score_dirty = false;
		decl String:text[8];
		Format( text, sizeof(text), "%05d", current_score );
		for( new i = 0; i < 5; i++ ) {
			VG_Text_SetFrame( TEXT_SCORE_SCOREVAL+i,text[i]-'0'+112 );
		}
	}

	{
		decl String:text[8];
		Format( text, sizeof(text), "%03d%02d", current_time/60, current_time%60 );
		for( new i = 0; i < 5; i++ ) {
			VG_Text_SetFrame( TEXT_SCORE_TIME+i , text[i]-'0'+112 );
		}
	}
}

StartTsScroll( target ) {
	ts_page = target;
	ts_page_scrolling= true; 
	ts_press_e_on = false;
	ts_press_e_timer = 0;
	ts_timeout = 0;
	VG_Text_SetOffsetParam( 0, 0,0, 0 ); // hide PRESS E
	VG_Text_SetOffsetParam( 1, 0,0, 0 ); // hide SCORE
}

OnFrame_Titlescreen() {

	if( ts_intro ){
		if(ts_intro == 180 ) {
			VG_SetBlanking( false );
			VG_Audio_Play( soundlist[SOUND_COIN] );
		}
		ts_intro--;
		if( ts_intro == 60 ) {
			for( new x = 62; x <= 67; x++ ) {
				for( new y = 4; y <= 5; y++ ) {
					VG_BG_SetTile( x,y, 8 );
				}
			}
		} else if( ts_intro == 1 ) {
			
			VG_BG_SetScroll( 0 );
			VG_Sleep(30);
			VG_SetUpdateTime(3);
			
			ts_music_id = VG_Audio_Play( soundlist[SOUND_THEME], 99,_,_,65.0 );

		}
		return;
	}
	VG_SetUpdateTime(900);

	if( !ts_page_scrolling ) {
		
		if( VG_Joypad_Clicks( 1, VG_INPUT_E_INDEX ) ) {
			
			VG_Audio_Play( soundlist[SOUND_COIN] );
			StartPlayerSelect();
			return;
		}

		if( ts_page == 0 ) {
			ts_press_e_timer++;
			if( ts_press_e_timer == 20 ) {
				
				ts_press_e_timer = 0;
				ts_press_e_on = !ts_press_e_on;
				VG_Text_SetOffsetParam( 0, 0,0, ts_press_e_on ? 3 : 0 );
			}
		} else if( ts_page == 1 ) {
			VG_Text_SetOffsetParam( 1, 0, 0, 3 );
		}
		ts_timeout++;
		if( ts_timeout == 300 ) {
			ts_page_counter++;
			if( ts_page_counter == sizeof(ts_page_sequence) ) ts_page_counter=0;
			
			StartTsScroll(ts_page_sequence[ts_page_counter]);
		}
	} else {
		if( ts_page_scrollpos < ts_page_scroll[ts_page] ) {
			ts_page_scrollpos+=4;
		} else if( ts_page_scrollpos > ts_page_scroll[ts_page] ) {
			ts_page_scrollpos-=4;
		} else {
			
			ts_page_scrolling = false;
		}
		VG_BG_SetScroll( ts_page_scrollpos );
		
		
	}

}

//----------------------------------------------------------------------------------------------------------------------
public VG_OnFrame() {
	// todo!

	switch( game_state ) {
	case GAMESTATE_TITLE:
		OnFrame_Titlescreen();
	case GAMESTATE_PLAYERSELECT:
		OnFrame_PlayerSelect();
	case GAMESTATE_GAMEINIT:
		OnFrame_GameInit();
	case GAMESTATE_INGAME:
		OnFrame_Ingame();
	case GAMESTATE_INTERMISSION:
		OnFrame_Intermission();
	case GAMESTATE_GAMEOVER:
		OnFrame_Gameover();

	}
	
	VG_Joypad_Flush();
}

SpawnEntity( type, x, y ) {
	decl data[8];
	data[0] = type;
	data[1] = x<<12;
	data[2] = y<<12;

	switch( type ) {
		case MOB_COIN:
		{
			VG_BG_SetTile( x, y, TILE_COIN );
		}
		case MOB_GOOBY:
		{
			data[3] = VG_Sprites_Create( SPRITEMODEL );
			data[GOOBY_FLAGS] = 0;
			data[GOOBY_DEAD] = 0;
			data[GOOBY_ANIMATION] = 0;
			
			VG_Sprites_SetTexture( data[3], SPR_GOOBY );
		}
		case MOB_PRINCESS:
		{
			data[2] += 16<<8;
			data[3] = VG_Sprites_Create( SPRITEMODEL );
			
			VG_Sprites_SetTexture( data[3], SPR_PRINCESS );
			VG_Sprites_SetPosition( data[3], data[1]>>8,(data[2]>>8)-16 );

			input_override = 1;
			input_override_position = data[1] - (64<<8);
		}
		//case MOB_ENDMARK:
		//{
		//	ingame_state = IGS_LEVELEND;
		//	input_override = 1;
		//	input_override_position = 999<<12;
		//}
	}

	PushArrayArray( entity_list, data );
}

UpdateEntities() {
	new size = GetArraySize( entity_list );

	for( new i =0; i < size; i++ ) {
		new delete_entry;

		decl data[ENTDATASIZE];
		GetArrayArray( entity_list, i, data );
		switch( data[0] ) {
		case MOB_COIN:
			{
				if( blink_animation_update ) {
					VG_BG_SetTile( data[1]>>12, data[2]>>12, TILE_COIN-1+blink_animation_update );
				}
				if( data[1]>>8 < RoundToFloor(camera)-16 ) {
					delete_entry = true;
					VG_BG_SetTile( data[1]>>12, data[2]>>12, 0 );
				}
			}
		case MOB_GOOBY:
			{
				if( data[GOOBY_DEAD] ) {
					data[GOOBY_DEAD]--;
					if( data[GOOBY_DEAD] == 0 ) {
						delete_entry = true;
						VG_Sprites_Delete( data[3] );
					}
				} else {
					new ani1,ani2;
					ani1 = data[GOOBY_ANIMATION] >> 8;
					data[GOOBY_ANIMATION] += 20;
					data[GOOBY_ANIMATION] &= 511;
					ani2 = data[GOOBY_ANIMATION] >> 8;
					if( data[GOOBY_ANIMATION] > 256 ) {
						VG_Sprites_SetTexture( data[3], SPR_GOOBY );
					} else {
						VG_Sprites_SetTexture( data[3], SPR_GOOBY+1 );
					}

					if( ani1 != ani2 && ani1 == 0 ) {
						VG_Audio_Play( soundlist[SOUND_SQUEAK] );
					}

					data[2] += data[GOOBY_VELY];
					if( !SolidTest( (data[1]>>8), (data[2]>>8)+16 ) && !SolidTest( (data[1]>>8)+15,(data[2]>>8)+16 ) ) {
						data[GOOBY_VELY] += 30;
						if( data[GOOBY_VELY] > 800 ) data[GOOBY_VELY] = 800;
						
					} else {
						data[2] = (data[2]>>12)<<12;
						data[GOOBY_VELY] = 0;
						if( data[2] >= (160-16)*256 ) {
							delete_entry = true;
							VG_Sprites_Delete( data[3] );
						}
					}

					if( data[GOOBY_FLAGS] & GOOBY_FLAG_DIR ) {
						data[1] += 400;
						if( SolidTest( (data[1]>>8)+15,(data[2]>>8)+14 ) ) {
							data[1] = (data[1]>>12)<<12;
							data[GOOBY_FLAGS] ^= GOOBY_FLAG_DIR;
						}
					} else {
						data[1] -= 400;
						if( SolidTest( (data[1]>>8),(data[2]>>8)+14 ) ) {
							data[1] = ((data[1]>>12)+1)<<12;
							data[GOOBY_FLAGS] ^= GOOBY_FLAG_DIR;
						}
					}

					if( data[1]>>8 <( RoundToFloor(camera)-16) && (!delete_entry) ) {
						delete_entry = true;
						VG_Sprites_Delete( data[3] );
					}
				}

				if( !delete_entry )
					VG_Sprites_SetPosition( data[3], data[1]>>8, (data[2]>>8)-16 );
					
				
				SetArrayArray( entity_list, i, data );
			}
		case MOB_PRINCESS:
			if( ingame_state == IGS_GROWTH ) {
				VG_Sprites_SetTexture( data[3], SPR_PRINCESS+1 );
				data[1] += 200;
				if( data[1] >= castle_point*16*256 ) {
					VG_Sprites_Delete( data[3] );
					delete_entry = true;
				} else {
					VG_Sprites_SetPosition( data[3], data[1]>>8, (data[2]>>8)-16 );
					SetArrayArray( entity_list, i, data );
					
				}
				
			}
		}
		if( delete_entry ) {
			RemoveFromArray( entity_list, i );
			i--;
			size--;
		}
	}
}
