#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//dodać dźwięk zmieniania się w obie strony
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Lotus Twister",
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

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_LotusTwister");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_LotusTwister");
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
		StartLotus(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		StopLotus(client);
		g_bArtifactWorking[client] = false;
	}
}

stock void StartLotus(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.9);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 37, 202, 64, 255); 
}

stock void StopLotus(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 255, 255, 255, 255); 
}
public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsClientInGame(client) && g_bArtifactWorking[client] && GetRandomInt(0, 1))
	{
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
