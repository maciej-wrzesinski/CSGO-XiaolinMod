#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//Dziek latania LUB dzwiek wchodzenia/wychodzenia
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Serpent's Tail",
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

float g_fLastPlayerOrigin[MAX_PLAYERS+1][3];
Handle g_hPlayerTimer[MAX_PLAYERS+1];

char g_cSprite[] = "materials/sprites/laserbeam.vmt";
int g_iSprite;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_SerpentTail");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_SerpentTail");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);
	
	g_iSprite = PrecacheModel(g_cSprite); 
}

public void OnConfigsExecuted()
{
	SetCvar("sv_disable_immunity_alpha", "1");
	SetCvar("sv_noclipspeed", "1");
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
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		StartGhost(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		SetEntityMoveType(client, MOVETYPE_WALK);
		StopGhost(client);
		g_bArtifactWorking[client] = false;
		if (IsPlayerStuck(client))
		{
			SDKHooks_TakeDamage(client, 0, 0, 9999.0);
			PrintToChat(client, "Byles w scianie! Uwazaj, to zabija!");
		}
	}
}

public void StartGhost(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 255, 255, 255, 100); 
	GetClientAbsOrigin(client, g_fLastPlayerOrigin[client]);
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeGhost, client);
}

public Action MakeGhost(Handle hTimer, int client)
{
	float fTempPlayerOrigin[3];
	GetClientAbsOrigin(client, fTempPlayerOrigin);
	
	float fLife = 3.5;
	int iFadeLenght = 3;
	float fWidth = 6.0;
	
	fTempPlayerOrigin[2] += 35.0;
	g_fLastPlayerOrigin[client][2] += 35.0;
	
	TE_SetupBeamPoints(fTempPlayerOrigin, g_fLastPlayerOrigin[client], g_iSprite, g_iSprite, 0, 15, fLife, fWidth, fWidth+0.1, iFadeLenght, 0.0, {50, 50, 50, 255}, 1);
	TE_SendToAllInRange(fTempPlayerOrigin, RangeType_Visibility, 0.0);
	
	GetClientAbsOrigin(client, g_fLastPlayerOrigin[client]);
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeGhost, client);
}

public void StopGhost(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 255, 255, 255, 255); 
	if (IsValidHandle(g_hPlayerTimer[client]))
		KillTimer(g_hPlayerTimer[client]);
}

//Thank you https://forums.alliedmods.net/showthread.php?t=193255
stock bool IsPlayerStuck(int client)
{
	float fTempPlayerMin[3];
	float fTempPlayerMax[3];
	float fTempPlayerOrigin[3];
	GetClientMins(client, fTempPlayerMin);
	GetClientMaxs(client, fTempPlayerMax);
	GetClientAbsOrigin(client, fTempPlayerOrigin);
	TR_TraceHullFilter(fTempPlayerOrigin, fTempPlayerOrigin, fTempPlayerMin, fTempPlayerMax, MASK_PLAYERSOLID, TraceEntityFilterPlayer, client);
	return TR_DidHit();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
  return (entity < 1 || entity > MaxClients);
}
