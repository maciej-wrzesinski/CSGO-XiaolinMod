#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Denshi Bunny",
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

char g_cSpriteSpark[] = "sprites/physbeam.vmt";

Handle g_hPlayerTimer[MAX_PLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_DenshiBunny");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_DenshiBunny");
}

public void OnMapStart()
{
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_CONSTANT_USE, g_fArtifactChiUsage);
	PrecacheModel(g_cSpriteSpark); 
}

public void OnConfigsExecuted()
{
	SetCvar("sv_disable_immunity_alpha", "1");
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
		ActivateElectricity(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		DeactivateElectricity(client);
		g_bArtifactWorking[client] = false;
	}
}

stock void ActivateElectricity(int client)
{
	StripPlayerWeaponsAll(client);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 0, 0, 0, 0);
	
	Xiaolin_BlockDashUse(client);
	Xiaolin_SetPlayerBonusSpeed(client, 0.5);
	Xiaolin_SetPlayerBonusGravity(client, 0.5);
	Xiaolin_UpdatePlayerStats(client);
	
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeItElectricity, client);
}

stock void DeactivateElectricity(int client)
{
	GivePlayerStandardWeapons(client);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	Xiaolin_UnblockDashUse(client);
	Xiaolin_SetPlayerBonusSpeed(client, -0.5);
	Xiaolin_SetPlayerBonusGravity(client, -0.5);
	Xiaolin_UpdatePlayerStats(client);
	
	if (IsValidHandle(g_hPlayerTimer[client]))
		KillTimer(g_hPlayerTimer[client]);
}

public Action MakeItElectricity(Handle hTimer, int client)
{
	if (IsPlayerAlive(client) && g_bArtifactWorking[client])
	{
		float fPlayerOrigin[3];
		GetClientAbsOrigin(client, fPlayerOrigin);
		fPlayerOrigin[2] += 50.0;
		MakeSparks(fPlayerOrigin);
		
		DealDamageAroundOrigin(client, 1.0, 120.0);
		g_hPlayerTimer[client] = CreateTimer(0.01, MakeItElectricity, client);
	}
}

stock void MakeSparks(float origin[3])
{
	int iEntityElectric = CreateEntitySafe("point_tesla");
	if (iEntityElectric != -1 && IsValidEntity(iEntityElectric))
	{
		DispatchKeyValue(iEntityElectric, "m_flRadius", "120.0");
		DispatchKeyValue(iEntityElectric, "m_SoundName", "DoSpark");
		DispatchKeyValue(iEntityElectric, "beamcount_min", "10");
		DispatchKeyValue(iEntityElectric, "beamcount_max", "20");
		DispatchKeyValue(iEntityElectric, "texture", g_cSpriteSpark);
		DispatchKeyValue(iEntityElectric, "m_Color", "255 255 255");
		DispatchKeyValue(iEntityElectric, "thick_min", "10.0");  
		DispatchKeyValue(iEntityElectric, "thick_max", "15.0"); 
		DispatchKeyValue(iEntityElectric, "lifetime_min", "0.1");
		DispatchKeyValue(iEntityElectric, "lifetime_max", "0.2"); 
		DispatchKeyValue(iEntityElectric, "interval_min", "0.1"); 
		DispatchKeyValue(iEntityElectric, "interval_max", "0.2"); 
		DispatchSpawn(iEntityElectric);
		TeleportEntity(iEntityElectric, origin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEntityElectric, "TurnOn"); 
		AcceptEntityInput(iEntityElectric, "DoSpark");
		CreateTimer(0.1, KillSpark, iEntityElectric);
	}
}

public Action KillSpark(Handle hTimer, int entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		RemoveEdict(entity);
	}
}