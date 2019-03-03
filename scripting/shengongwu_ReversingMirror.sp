#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Reversing Mirror",
	author = "Vasto_Lorde",
	description = "Shen Gong Wu for Xiaolin",
	version = "1.0",
	url = "http://cs-plugin.com/"
};

char g_cArtifactName[ARTIFACT_NAME_LENG];
char g_cArtifactDesc[ARTIFACT_DESC_LENG];
float g_fArtifactDecay = 0.86;
float g_fArtifactChiUsage = 2.22;

int g_iArtifactIndex;
bool g_bArtifactOwner[MAX_PLAYERS+1];
bool g_bArtifactWorking[MAX_PLAYERS+1];

char g_cSprite[] = "materials/sprites/white.vmt";

int g_iEntitySprite[MAX_PLAYERS+1] = 0;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_ReversingMirror");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_ReversingMirror");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);
	
	PrecacheModel(g_cSprite);
}

public void Xiaolin_OnShenGongWuPick(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	PrintToChat(client, "%t %s! (%s)", "SGW_Get", g_cArtifactName, g_cArtifactDesc);
	g_bArtifactOwner[client] = true;
	g_bArtifactWorking[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void Xiaolin_OnShenGongWuDrop(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	if (g_bArtifactWorking[client])//jeśli używa i traci to przed straceniem trzeba wyłączyć działanie
		Xiaolin_OnShenGongWuUse(client, artifact_index);
	
	PrintToChat(client, "%t %s!", "SGW_Drop", g_cArtifactName);
	g_bArtifactOwner[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
}

public void Xiaolin_OnShenGongWuUse(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	if (!g_bArtifactWorking[client])
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOn", g_cArtifactName);
		TurnOnSprite(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		TurnOffSprite(client);
		g_bArtifactWorking[client] = false;
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker) && IsClientInGame(client) && IsPlayerAlive(client) && g_bArtifactWorking[client])
	{
		SDKHooks_TakeDamage(attacker, client, client, damage*0.3);
		damage *= 0.7;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock void TurnOnSprite(int client)
{
	char cColors[] = "255 255 255";
	char cScale[] = "0.8";
	float fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	char cTempNameOfEntity[64];
	Format(cTempNameOfEntity, 63, "ReversingMirror%i", client);
	char cPlayerTargetName[64];
	Format(cPlayerTargetName, 63, "ReversingMirrorPlayer%i", client);
	
	int iEntityMainMeditation = CreateEntitySafe("func_rotating");
	
	if (iEntityMainMeditation != -1 && IsValidEntity(iEntityMainMeditation))
	{
		DispatchKeyValueVector(iEntityMainMeditation, "origin", fPlayerOrigin);
		DispatchKeyValue(iEntityMainMeditation, "targetname", cTempNameOfEntity);
		DispatchKeyValue(iEntityMainMeditation, "renderfx", "0");
		DispatchKeyValue(iEntityMainMeditation, "rendermode", "0");
		DispatchKeyValue(iEntityMainMeditation, "renderamt", "255");
		DispatchKeyValue(iEntityMainMeditation, "rendercolor", "255 255 255"); 
		DispatchKeyValue(iEntityMainMeditation, "maxspeed", "400");
		DispatchKeyValue(iEntityMainMeditation, "friction", "20");
		DispatchKeyValue(iEntityMainMeditation, "dmg", "0");
		DispatchKeyValue(iEntityMainMeditation, "solid", "0");
		DispatchKeyValue(iEntityMainMeditation, "spawnflags", "64");
		DispatchSpawn(iEntityMainMeditation);
		DispatchKeyValue(client, "targetname", cPlayerTargetName);
		SetVariantString(cPlayerTargetName);
		AcceptEntityInput(iEntityMainMeditation, "SetParent");
		
		int iEntitySpriteMeditation = CreateEntitySafe("env_sprite");
		if (iEntitySpriteMeditation != -1 && IsValidEntity(iEntitySpriteMeditation))
		{
			fPlayerOrigin[0] += 20.0; 
			fPlayerOrigin[2] += 50.0;
			DispatchKeyValue(iEntitySpriteMeditation, "model", g_cSprite);
			DispatchKeyValue(iEntitySpriteMeditation, "classname", "FistOfTebigong");
			DispatchKeyValue(iEntitySpriteMeditation, "spawnflags", "1");
			DispatchKeyValue(iEntitySpriteMeditation, "scale", cScale);
			DispatchKeyValue(iEntitySpriteMeditation, "rendermode", "3");
			DispatchKeyValue(iEntitySpriteMeditation, "RenderAmt", "255"); 
			DispatchKeyValue(iEntitySpriteMeditation, "rendercolor", cColors);
			DispatchKeyValueVector(iEntitySpriteMeditation, "Origin", fPlayerOrigin);
			DispatchSpawn(iEntitySpriteMeditation);
			SetVariantString(cTempNameOfEntity);
			AcceptEntityInput(iEntitySpriteMeditation, "SetParent");
			AcceptEntityInput(iEntitySpriteMeditation, "ShowSprite");
		}
		AcceptEntityInput(iEntityMainMeditation, "Start");
	}
	
	g_iEntitySprite[client] = iEntityMainMeditation;
}

stock void TurnOffSprite(int client)
{
	if (IsValidEntity(g_iEntitySprite[client]))
		RemoveEdict(g_iEntitySprite[client]);
}

