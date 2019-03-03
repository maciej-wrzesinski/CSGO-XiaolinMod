#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Mikado Arm",
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

char g_cSpriteGlow[] = "materials/sprites/laserbeam.vmt";

int g_iRightArm[MAX_PLAYERS+1] = 0;
int g_iLeftArm[MAX_PLAYERS+1] = 0;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_MikadoArm");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_MikadoArm");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);

	PrecacheModel(g_cSpriteGlow);
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
		TurnOnTheArms(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		TurnOffTheArms(client);
		g_bArtifactWorking[client] = false;
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker) && g_bArtifactWorking[attacker] && IsClientInGame(client))
	{
		damage *= 1.25;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock void TurnOnTheArms(int client)
{
	char cColors[] = "255 0 0";
	char cScale[] = "0.45";
	float fHeight = 53.0;
	float fWidth = 11.0;
	
	int iEntityArm = CreateEntitySafe("env_sprite");
	if (iEntityArm != -1 && IsValidEntity(iEntityArm))
	{
		float fTempPlayerOrigin[3];
		GetClientAbsOrigin(client, fTempPlayerOrigin);
		float fTempPlayerAngle[3];
		GetClientAbsAngles(client, fTempPlayerAngle);
		
		float fOriginRightUp[3];
		fOriginRightUp[0] = fTempPlayerOrigin[0] + Cosine(DegToRad( fTempPlayerAngle[1] + 90.0 )) * fWidth;
		fOriginRightUp[1] = fTempPlayerOrigin[1] + Sine(DegToRad( fTempPlayerAngle[1] + 90.0 )) * fWidth; 
		fOriginRightUp[2] = fTempPlayerOrigin[2] + fHeight;
		
		DispatchKeyValue(iEntityArm, "model", g_cSpriteGlow);
		DispatchKeyValue(iEntityArm, "classname", "Arm");
		DispatchKeyValue(iEntityArm, "spawnflags", "1");
		DispatchKeyValue(iEntityArm, "scale", cScale);
		DispatchKeyValue(iEntityArm, "rendermode", "3");
		DispatchKeyValue(iEntityArm, "RenderAmt", "255"); 
		DispatchKeyValue(iEntityArm, "rendercolor", cColors);
		DispatchKeyValueVector(iEntityArm, "Origin", fOriginRightUp);
		DispatchSpawn(iEntityArm);
		SetVariantString("!activator");
		AcceptEntityInput(iEntityArm, "SetParent", client);
	}
	
	int iEntityArm3 = CreateEntitySafe("env_sprite");
	if (iEntityArm3 != -1 && IsValidEntity(iEntityArm3))
	{
		float fTempPlayerOrigin[3];
		GetClientAbsOrigin(client, fTempPlayerOrigin);
		float fTempPlayerAngle[3];
		GetClientAbsAngles(client, fTempPlayerAngle);
		
		float fOriginRightUp[3];
		fOriginRightUp[0] = fTempPlayerOrigin[0] + Cosine(DegToRad( fTempPlayerAngle[1] - 90.0 )) * fWidth;
		fOriginRightUp[1] = fTempPlayerOrigin[1] + Sine(DegToRad( fTempPlayerAngle[1] - 90.0 )) * fWidth; 
		fOriginRightUp[2] = fTempPlayerOrigin[2] + fHeight;
		
		DispatchKeyValue(iEntityArm3, "model", g_cSpriteGlow);
		DispatchKeyValue(iEntityArm3, "classname", "Arm");
		DispatchKeyValue(iEntityArm3, "spawnflags", "1");
		DispatchKeyValue(iEntityArm3, "scale", cScale);
		DispatchKeyValue(iEntityArm3, "rendermode", "3");
		DispatchKeyValue(iEntityArm3, "RenderAmt", "255"); 
		DispatchKeyValue(iEntityArm3, "rendercolor", cColors);
		DispatchKeyValueVector(iEntityArm3, "Origin", fOriginRightUp);
		DispatchSpawn(iEntityArm3);
		SetVariantString("!activator");
		AcceptEntityInput(iEntityArm3, "SetParent", client);
	}
	
	g_iRightArm[client] = iEntityArm3;
	g_iLeftArm[client] = iEntityArm;
}

stock void TurnOffTheArms(int client)
{
	if (IsValidEntity(g_iRightArm[client]))
		RemoveEdict(g_iRightArm[client]);
	if (IsValidEntity(g_iLeftArm[client]))
		RemoveEdict(g_iLeftArm[client]);
}

