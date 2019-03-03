#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//Dorobić dźwięki uderzenia rikoszetu
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Three Ton Tunic",
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

char g_cSprite[] = "materials/sprites/blueflare1.vmt";
int g_iSprite;

bool g_bOnOff = false;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_ThreeTonTunic");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_ThreeTonTunic");
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
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		Xiaolin_SetPlayerBonusSpeed(client, -0.9);
		Xiaolin_SetPlayerBonusGravity(client, 1.0);
		Xiaolin_UpdatePlayerStats(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		Xiaolin_SetPlayerBonusSpeed(client, 0.9);
		Xiaolin_SetPlayerBonusGravity(client, -1.0);
		Xiaolin_UpdatePlayerStats(client);
		g_bArtifactWorking[client] = false;
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bArtifactWorking[client])
	{
		damage *= 0.2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnPreThink(int client)
{
	if (IsPlayerAlive(client) && g_bArtifactWorking[client])
	{
		if (g_bOnOff)
		{
			float fPlayerOrigin[3];
			GetClientAbsOrigin(client, fPlayerOrigin);
			fPlayerOrigin[2] += 50.0;
			TE_SetupBeamRingPoint(fPlayerOrigin, 25.0, 25.1, g_iSprite, g_iSprite, 0, 15, 0.1, 14.0, 0.0, {255, 255, 0, 175}, 1, 0);
			TE_SendToAllInRange(fPlayerOrigin, RangeType_Visibility, 0.0);
		}
		g_bOnOff = !g_bOnOff;
	}
}
