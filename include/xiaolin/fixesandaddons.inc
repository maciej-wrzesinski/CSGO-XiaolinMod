#define MAX_BLOCKED_DECALS			46
int g_iTotalTempEntitiesSpawned = 0;
int g_iTotalTempEntityLimit = 2000;
char g_cBlockedTempDecals[MAX_BLOCKED_DECALS][] = 
{
	"PlayerAnimEvent",
	"RadioIcon",
	"Bomb Plant",
	"Shotgun Shot",
	"FoundryHelpers",
	"Dust",
	"GaussExplosion",
	"Armor Ricochet",
	"Metal Sparks",
	"BeamEntPoint",
	"BeamEnts",
	"BeamFollow",
	"BeamLaser",
	"BeamPoints",
	"BeamRing",
	"BeamRingPoint",
	"BeamSpline",
	"Blood Sprite",
	"Blood Stream",
	"breakmodel",
	"BSP Decal",
	"Bubbles",
	"Bubble Trail",
	"Client Projectile",
	"Entity Decal",
	"Dynamic Light",
	"EffectDispatch",
	"Energy Splash",
	"Explosion",
	"Fizz",
	"Footprint Decal",
	"Surface Shatter",
	"GlowSprite",
	"Impact",
	"KillPlayerAttachments",
	"Large Funnel",
	"MuzzleFlash",
	"physicsprop",
	"Player Decal",
	"Projected Decal",
	"Show Line",
	"Smoke",
	"Sparks",
	"Sprite",
	"Sprite Spray",
	"World Decal"
};

#define MAX_BLOCKED_EVENTS			13
char g_cBlockedEvents[MAX_BLOCKED_EVENTS][] = 
{
	"round_mvp",			// Blokuje info o mvp
	"ammo_pickup",		// Blokuje dawanie amunicji
	"player_radio",		// Blokuje radio
	"bomb_pickup",		// Blokuje podnoszenie bomby
	"bomb_dropped",		// Blokuje puszczanie bomby
	"player_given_c4",	// Blokuje dawanie bomby
	"buymenu_open",		// Blokuje otwieranie menu broni
	"buymenu_close",		// Blokuje zamykanie
	"item_purchase",		// Blokuje kupno broni
	"enter_buyzone",		// Blokuje wejście w kupno broni
	"enter_bombzone",		// Blokuje wejście w strefę bomby
	"enter_rescue_zone",	// Blokuje wejście w strefę ratowania
	"item_pickup"		// Blokuje bronie?
};

#define MAX_BLOCKED_ENTITES			11
char g_cBlockedEntities[MAX_BLOCKED_ENTITES][] = 
{
	"env_hudhint",//hinty z reklamą
	"point_spotlight",//światło
	"spotlight_end",//światło
	"trigger_gravity",//grawitacja
	"func_buyzone",//strefa kupna
	"beam",//światło
	"env_sprite", // sprite
	"prop_physics", //niepotrzebne obiekty
	"info_particle_system", //efekty
	"env_wind", //dzwiek wiatru?
	"ambient_generic" //dzwieki
};

#define MAX_BLOCKED_SOUNDS			5
char g_cBlockedSounds[MAX_BLOCKED_SOUNDS][] = 
{
	"player/damage",//upadek
	"items/pickup_weapon_02.wav",//podniesienie noza
	"radio",//wszystkie radia
	"player/footsteps/new/suit",//chodzenie dziwne
	"buttons"//dźwięk menu wybrania do zamienienia?
};
//do zamienienia
/*
buttons/button14.wav
buttons/combine_button7.wav
*/

stock void OnPluginStartFixes()
{
	for (int i = 0; i < MAX_BLOCKED_DECALS; i++)
	{
		AddTempEntHook(g_cBlockedTempDecals[i], OnTempEntitySpawn);
	}
	
	for (int i = 0; i < MAX_BLOCKED_EVENTS; i++)
	{
		HookEvent(g_cBlockedEvents[i], eventBlock, EventHookMode_Pre);
	}
	
	HookUserMessage(GetUserMessageId("TextMsg"), eventTextMsg, true);
	HookEvent("round_start", eventRoundStart);
	AddNormalSoundHook(SoundHook);
	
	//RegAdminCmd("sm_test", ListEntities, ADMFLAG_ROOT);
}

/*
stock void SetThirdPersonView( int client )
{
	float fHeight = 150.0;
	float fWidth = 30.0;
	
	float fTempPlayerOrigin[3];
	GetClientAbsOrigin(client, fTempPlayerOrigin);
	
	float fTempPlayerAngle[3];
	GetClientEyeAngles(client, fTempPlayerAngle);
	
	float fOriginRightUp[3];
	fOriginRightUp[0] = fTempPlayerOrigin[0] + Cosine(DegToRad( fTempPlayerAngle[1] + 180.0 )) * fWidth;
	fOriginRightUp[1] = fTempPlayerOrigin[1] + Sine(DegToRad( fTempPlayerAngle[1] + 180.0 )) * fWidth; 
	fOriginRightUp[2] = fTempPlayerOrigin[2] + fHeight;
	
	int camera = SpawnEntity( "point_viewcontrol", "player_cam", fOriginRightUp, fTempPlayerAngle );

	char watcher[ 64 ];
	Format( watcher, sizeof( watcher ), "target%i", client);

	DispatchKeyValue( client, "targetname", watcher );
	DispatchKeyValue( camera, "wait", "3600" );
	DispatchSpawn(camera);

	
	SetVariantString("!activator");
	AcceptEntityInput(camera, "SetParent", client);
	AcceptEntityInput( camera, "Enable", client, camera, 0 );
}

stock int SpawnEntity( char[] classname, char[] targetname = "", float origin[ 3 ] = NULL_VECTOR, float angles[ 3 ] = NULL_VECTOR )
{
	int entity = CreateEntityByName( classname );
	DispatchKeyValue( entity, "targetname", targetname );
	DispatchKeyValueVector( entity, "origin", origin );
	DispatchKeyValueVector( entity, "angles", angles );
	DispatchSpawn( entity );

	return entity;
}

public void OnGameFrame()
{
	//for (int i = 1; i <= MaxClients; i++)
	//{
		//if (IsClientInGame(i) && IsPlayerAlive(i))
		//	TeleportEntity(i, NULL_VECTOR, CameraPosition[i], NULL_VECTOR);
	//}
}

public Action ListEntities(int client, int args)
{
	SetThirdPersonView(client);

	float fHeight = 150.0;
	float fWidth = 30.0;
	
	int iEntityArm = CreateEntitySafe("prop_dynamic_override");
	if (iEntityArm != -1 && IsValidEntity(iEntityArm))
	{
		float fTempPlayerOrigin[3];
		GetClientAbsOrigin(client, fTempPlayerOrigin);
		float fTempPlayerAngle[3];
		GetClientEyeAngles(client, fTempPlayerAngle);
		
		float fOriginRightUp[3];
		fOriginRightUp[0] = fTempPlayerOrigin[0] + Cosine(DegToRad( fTempPlayerAngle[1] + 180.0 )) * fWidth;
		fOriginRightUp[1] = fTempPlayerOrigin[1] + Sine(DegToRad( fTempPlayerAngle[1] + 180.0 )) * fWidth; 
		fOriginRightUp[2] = fTempPlayerOrigin[2] + fHeight;
		
		DispatchKeyValue(iEntityArm, "model", "models/inventory_items/boston_pickem_2018_bronze.mdl");
		DispatchKeyValue(iEntityArm, "classname", "Camera");
		DispatchKeyValue(iEntityArm, "spawnflags", "1");
		DispatchKeyValueVector(iEntityArm, "Origin", fOriginRightUp);
		DispatchSpawn(iEntityArm);
		SetVariantString("!activator");
		AcceptEntityInput(iEntityArm, "SetParent", client);
	}
	
	float fTempPlayerAngle[3];
	GetClientEyeAngles(client, fTempPlayerAngle);
	SetEntPropVector(iEntityArm, Prop_Send, "m_angRotation", fTempPlayerAngle);
	
	SetEntityMoveType(iEntityArm, MOVETYPE_FLY);
	
	SetClientViewEntity(client, iEntityArm);
	
}*/

/*public Action SpawnMake3rd(int client)
{
	if (IsThisAPlayer(client) && IsClientInGame(client))
		CreateTimer(0.1*client, Set3rdPerson_Timer, client);
}

public Action Set3rdPerson_Timer(Handle hTimer, int client)
{
	if (IsPlayerAlive(client))
	{
		ServerCommand("sv_allow_thirdperson 1");
		ServerCommand("sv_cheats 1");
		ClientCommand(client, "thirdperson");
		ServerCommand("sv_cheats 0");
		ServerCommand("sv_allow_thirdperson 0");
	}
}*/

stock void OnClientPutInServerFixes(int client)
{
	
	//SDKHook(client, SDKHook_SpawnPost, SpawnMake3rd);
}

stock void OnClientDisconnectFixes(int client)
{
	//SDKUnhook(client, SDKHook_SpawnPost, SpawnMake3rd);
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	for (int j = 0; j < MAX_BLOCKED_SOUNDS; j++)
		if (StrContains(sample, g_cBlockedSounds[j], false) != -1)
			return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action eventRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_iTotalTempEntitiesSpawned = 0;
	for (int i = MAX_PLAYERS; i < GetMaxEntities(); i++)
		if (IsValidEntity(i))
		{
			char cTempClassName[64];
			GetEntityClassname(i, cTempClassName, 63);
			
			for (int j = 0; j < MAX_BLOCKED_ENTITES; j++)
				if (StrContains(cTempClassName, g_cBlockedEntities[j], false) != -1)
				{
					RemoveEdict(i);
				}
				
			if (StrContains(cTempClassName, "weapon", false) != -1 && StrContains(cTempClassName, "knife", false) == -1)
			{
				RemoveEdict(i);
				continue;
			}
		}
}

public Action OnTempEntitySpawn(const char[] te_name, const players[], int numClients, float delay)
{
	if(g_iTotalTempEntitiesSpawned > g_iTotalTempEntityLimit)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action eventBlock(Handle event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	g_iTotalTempEntitiesSpawned += 10;
}

public void OnEntityDestroyed(int entity)
{
	g_iTotalTempEntitiesSpawned -= 10;
}

public Action eventTextMsg(UserMsg msg_id, Handle pb, const players[], int playersNum, bool reliable, bool init){
	char cMsgText[256];
	PbReadString(pb, "params", cMsgText, sizeof(cMsgText), 0);
	
	if(StrContains(cMsgText, "#", false) != -1)
		return Plugin_Handled;
	
	//if(StrContains(cMsgText, "\"sv_", false) != -1)
	//	return Plugin_Handled;
	
	//if(StrContains(cMsgText, "sv_cheats", false) != -1)
	//	return Plugin_Handled;
	
	return Plugin_Continue;
}

