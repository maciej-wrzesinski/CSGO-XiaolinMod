#if defined _xiaolin_included
 #endinput
#endif
#define _xiaolin_included

//Do not modify these

#define MAX_PLAYERS					64
#define ARTIFACT_NAME_LENG			64
#define ARTIFACT_DESC_LENG			128

#define ARTIFACT_ON_TIME_USE		0
#define ARTIFACT_CONSTANT_USE		1

#define DMG_FALL					(1 << 5)

#define REPLACE_PROPERTY			true
#define ADD_PROPERTY				false
#define NEVER_END					0.0

#define ANGLE_FORWARD				0.0
#define ANGLE_BACK					180.0
#define ANGLE_RIGHT					270.0
#define ANGLE_LEFT					90.0
#define ANGLE_UP					-1.0

#define GAME_TICK_RATE				0.5

//#define CHEATS					//EVERYONE HAS INFINITE STATS (BARS)
//#define ADDONS_AND_FIXES		//.inc THAT FIXES SOME STUFF
//#define GAME_MODES				//.nc THAT ADDS GAMEMODES

//Stocks

stock int CreateEntitySafe(char[] name)
{
	if (IsThereTooMuchEntities())
		return -1;
	
	return CreateEntityByName(name);
}

stock bool IsThereTooMuchEntities()
{
	if (GetEntityCount() >= GetMaxEntities() - MAX_PLAYERS - 10)//10 for safety
	{
		return true;
	}
	return false;
}

stock bool IsThisAPlayer(int entity)
{
	return (entity >0 && entity <= MAX_PLAYERS);
}

stock void SetCvar(char[] cvarstring, char[] value)
{
	Handle hCvar = FindConVar(cvarstring);
	SetConVarString(hCvar, value, true);
	CloseHandle(hCvar);
}

stock void StripPlayerWeaponsAll(int client)
{
	if (IsThisAPlayer(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int iTempWeapon = -1;
		for (int j = 0; j < 7; j++)
			if ((iTempWeapon = GetPlayerWeaponSlot(client, j)) != -1)
			{
				if (IsValidEntity(iTempWeapon))
					RemovePlayerItem(client, iTempWeapon);
			}
	}
}

stock void GivePlayerStandardWeapons(int client)
{
	GivePlayerItem(client, "weapon_knife");
}

stock void DealDamageAroundOrigin(int client, float damage, float distance, int attacker = 0, bool self = false)
{
	float fMainPlayerOrigin[3];
	GetClientAbsOrigin(client, fMainPlayerOrigin);
	
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		if(client == i && self == false)
			continue;
		
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			float fPlayerOrigin[3];
			GetClientAbsOrigin(i, fPlayerOrigin);
			
			if (GetVectorDistance(fMainPlayerOrigin, fPlayerOrigin) < distance)
			{
				SDKHooks_TakeDamage(i, attacker, attacker, damage);
			}
		}
	}
}

stock void EmitSoundToAllAliveWithinDistance(const char[] sample, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL, int speakerentity = -1, const float dir[3] = NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	float MAX_VOLUME = 0.8;
	if (volume > MAX_VOLUME)
		volume = MAX_VOLUME;
	
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			float origin[3];
			
			if (entity != SOUND_FROM_PLAYER)
			{
				float tempplayerorigin[3];
				GetClientAbsOrigin(i, tempplayerorigin);
				
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin); //z tego origin będzie się wydobywał dźwięk
				volume = volume * GetDistGainFromSoundLevel(level, GetVectorDistance(origin, tempplayerorigin)); //obliczamy jaką głośnośc usłyszy gracz na podstawie dystansu między nim a entity
				volume = volume * 5 > MAX_VOLUME ? MAX_VOLUME : volume * 5;
				
			}
			else
			{
				GetClientAbsOrigin(i, origin); //jeśli nie wyznaczymy entity z którego ma się wydobywać dźwięk to ma się wydobyć od gracza
			}
			
			EmitSoundToClient(i, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
		}
	}
}

//Natives

// Registeres Shen Gong Wu
// @param1: Name of the Shen Gong Wu
// @param2: Description of the Shen Gong Wu
// @param3: Amount of Shen Gong Wu % that is gone on one game tick
// @param4: Type of Shen Gong Wu usage. ARTIFACT_ON_TIME_USE for one time usage, ARTIFACT_CONSTANT_USE when Shen Gong Wu effect continues in time
// @param5: Amount of Chi taken away when Shen Gong Wu is being used
// @return: Index of the Shen Gong Wu
native int Xiaolin_RegisterShenGongWu(char[] name, char[] description, float decay, int usage_type, float chi_usage);

// Forces a player to drop his Shen Gong Wu (+ automaticly turns its effects off)
// @param1: Client ID
native int Xiaolin_ForceShenGongWuDrop(int client);

// Adds bonus speed
// @param1: Client ID
// @param2: Bonus speed amount
native int Xiaolin_SetPlayerBonusSpeed(int client, float speed);

// Adds bonus gravity
// @param1: Client ID
// @param2: Bonus gravity amount
native int Xiaolin_SetPlayerBonusGravity(int client, float gravity);

// Adds bonus dash time
// @param1: Client ID
// @param2: Bonus dash time amount
native int Xiaolin_SetPlayerBonusDash(int client, float dash);

// Adds bonus stamina loss in %
// @param1: Client ID
// @param2: Bonus stamina loss amount
native int Xiaolin_SetPlayerBonusStamina(int client, float stamina);

// Adds chi energy to player
// @param1: Client ID
// @param2: Amount of Chi Energy (can be less than 0)
native int Xiaolin_UsePlayerChiEnergy(int client, float chi_energy);

// Updates player speed and gravity so he does not have to wait for plugin functions to trigger
// @param1: Client ID
native int Xiaolin_UpdatePlayerStats(int client);

// Block player ability to use his current Shen Gong Wu
// @param1: Client ID
native int Xiaolin_BlockShenGongWuUse(int client);

// Unlock player ability to use his current Shen Gong Wu
// @param1: Client ID
native int Xiaolin_UnblockShenGongWuUse(int client);

// Block player ability to use Dash
// @param1: Client ID
native int Xiaolin_BlockDashUse(int client);

// Unlock player ability to use Dash
// @param1: Client ID
native int Xiaolin_UnblockDashUse(int client);

#if defined GAME_MODES

// Resets a players team color
// @param1: Client ID
native int Xiaolin_ResetPlayerColor(int client);

#endif


//Forwards

// Called when client picks up a Shen Gong Wu
// @param1: Client ID
// @param2: Shen Gong Wu index
forward void Xiaolin_OnShenGongWuPick(int client, int shen_gong_wu_index);

// Called when client drops out a Shen Gong Wu
// @param1: Client ID
// @param2: Shen Gong Wu index
forward void Xiaolin_OnShenGongWuDrop(int client, int shen_gong_wu_index);

// Called when client uses a Shen Gong Wu
// @param1: Client ID
// @param2: Shen Gong Wu index
forward void Xiaolin_OnShenGongWuUse(int client, int shen_gong_wu_index);
