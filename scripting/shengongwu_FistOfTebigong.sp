#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Fist of Tebigong",
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
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_FistOfTebigong");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_FistOfTebigong");
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
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		TurnOnSprite(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		TurnOffSprite(client);
		g_bArtifactWorking[client] = false;
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker) && g_bArtifactWorking[attacker] && IsClientInGame(client))
	{
		float fTempNewVelocity[3];
		float fTempNewAngle[3];
		fTempNewVelocity[0] = 0.0;
		fTempNewVelocity[1] = 0.0;
		fTempNewVelocity[2] = 0.0;
		fTempNewAngle[0] = GetRandomInt(50, 200)+0.0;
		fTempNewAngle[1] = GetRandomInt(50, 200)+0.0;
		fTempNewAngle[2] = GetRandomInt(50, 200)+0.0;
		
		TeleportEntity(client, fTempNewVelocity, fTempNewAngle, NULL_VECTOR);
	}
	return Plugin_Continue;
}

stock void TurnOnSprite(int client)
{
	char cColors[] = "255 238 54";
	char cScale[] = "0.4";
	float fHeight = 60.0;
	float fWidth = 13.0;
	
	int iEntityEnvSprite = CreateEntitySafe("env_sprite");
	if (iEntityEnvSprite != -1 && IsValidEntity(iEntityEnvSprite))
	{
		float fTempPlayerOrigin[3];
		GetClientAbsOrigin(client, fTempPlayerOrigin);
		float fTempPlayerAngle[3];
		GetClientAbsAngles(client, fTempPlayerAngle);
		
		float fOriginRightUp[3];
		fOriginRightUp[0] = fTempPlayerOrigin[0] + Cosine(DegToRad( fTempPlayerAngle[1] - 90.0 )) * fWidth + Cosine(DegToRad( fTempPlayerAngle[1] )) * fWidth;
		fOriginRightUp[1] = fTempPlayerOrigin[1] + Sine(DegToRad( fTempPlayerAngle[1] - 90.0 )) * fWidth + Sine(DegToRad( fTempPlayerAngle[1] )) * fWidth; 
		fOriginRightUp[2] = fTempPlayerOrigin[2] + fHeight;
		
		DispatchKeyValue(iEntityEnvSprite, "model", g_cSprite);
		DispatchKeyValue(iEntityEnvSprite, "classname", "FistOfTebigong");
		DispatchKeyValue(iEntityEnvSprite, "spawnflags", "1");
		DispatchKeyValue(iEntityEnvSprite, "scale", cScale);
		DispatchKeyValue(iEntityEnvSprite, "rendermode", "3");
		DispatchKeyValue(iEntityEnvSprite, "RenderAmt", "255"); 
		DispatchKeyValue(iEntityEnvSprite, "rendercolor", cColors);
		DispatchKeyValueVector(iEntityEnvSprite, "Origin", fOriginRightUp);
		DispatchSpawn(iEntityEnvSprite);
		SetVariantString("!activator");
		AcceptEntityInput(iEntityEnvSprite, "SetParent", client);
	}
	
	g_iEntitySprite[client] = iEntityEnvSprite;
}

stock void TurnOffSprite(int client)
{
	if (IsValidEntity(g_iEntitySprite[client]))
		RemoveEdict(g_iEntitySprite[client]);
}

