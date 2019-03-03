#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//dzwiek latania lub on/off
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Longi Kite",
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

Handle g_hPlayerTimer[MAX_PLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_LongiKite");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_LongiKite");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);
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
		ActivateFlying(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		DeactivateFlying(client);
		g_bArtifactWorking[client] = false;
	}
}

stock void ActivateFlying(int client)
{
	SetEntityMoveType(client, MOVETYPE_FLY);
	
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeSparks, client);
}

public Action MakeSparks(Handle hTimer, int client)
{
	if (IsPlayerAlive(client) && g_bArtifactWorking[client])
	{
		float fPlayerOrigin[3];
		GetClientAbsOrigin(client, fPlayerOrigin);
		fPlayerOrigin[2] += 50.0;
		
		TE_SetupEnergySplash(fPlayerOrigin, fPlayerOrigin, false);
		TE_SendToAllInRange(fPlayerOrigin, RangeType_Visibility, 0.0);
		
		g_hPlayerTimer[client] = CreateTimer(0.01, MakeSparks, client);
	}
}

stock void DeactivateFlying(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	if (IsValidHandle(g_hPlayerTimer[client]))
		KillTimer(g_hPlayerTimer[client]);
}

