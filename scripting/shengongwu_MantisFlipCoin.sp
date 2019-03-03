#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Mantis Flip Coin",
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

char g_cSprite[] = "materials/sprites/laserbeam.vmt";
int g_iSprite;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_MantisFlipCoin");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_MantisFlipCoin");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);
	
	g_iSprite = PrecacheModel(g_cSprite); 
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
		Xiaolin_SetPlayerBonusSpeed(client, 1.0);
		Xiaolin_SetPlayerBonusGravity(client, -0.15);
		Xiaolin_UpdatePlayerStats(client);
		StartBeams(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		Xiaolin_SetPlayerBonusSpeed(client, -1.0);
		Xiaolin_SetPlayerBonusGravity(client, 0.15);
		Xiaolin_UpdatePlayerStats(client);
		StopBeams(client);
		g_bArtifactWorking[client] = false;
	}
}

public void StartBeams(int client)
{
	g_hPlayerTimer[client] = CreateTimer(0.05, MakeBeams, client);
}

public Action MakeBeams(Handle hTimer, int client)
{
	float fTempPlayerOrigin[3];
	GetClientAbsOrigin(client, fTempPlayerOrigin);
	
	float fLife = 0.3;
	float fWidth = 1.0;
	int iSpeed = 5;
	
	fTempPlayerOrigin[2] += 10.0;
	
	TE_SetupBeamRingPoint(fTempPlayerOrigin, 80.0, 1.0, g_iSprite, g_iSprite, 0, 15, fLife, fWidth, 0.0, {121, 71, 0, 255}, iSpeed, 0);
	TE_SendToAllInRange(fTempPlayerOrigin, RangeType_Visibility, 0.0);
	
	g_hPlayerTimer[client] = CreateTimer(0.05, MakeBeams, client);
}

public void StopBeams(int client)
{
	if (IsValidHandle(g_hPlayerTimer[client]))
		KillTimer(g_hPlayerTimer[client]);
}


