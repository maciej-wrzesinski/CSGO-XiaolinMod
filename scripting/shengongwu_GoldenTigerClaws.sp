#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

public Plugin myinfo = 
{
	name = "Shen Gong Wu - Golden Tiger Claws",
	author = "Vasto_Lorde",
	description = "Shen Gong Wu for Xiaolin",
	version = "1.0",
	url = "http://cs-plugin.com/"
};

char g_cArtifactName[ARTIFACT_NAME_LENG];
char g_cArtifactDesc[ARTIFACT_DESC_LENG];
float g_fArtifactDecay = 0.86;
float g_fArtifactChiUsage = 7.22;

int g_iArtifactIndex;
bool g_bArtifactOwner[MAX_PLAYERS+1];

float g_fPlayerTeleportOrigin[MAX_PLAYERS+1][3];
float g_fPlayerTeleportAngle[MAX_PLAYERS+1][3];
int g_iPlayerMode[MAX_PLAYERS+1] = 0;

char g_cSprite[] = "sprites/smoke.vmt";
int g_iSprite;

int g_iMaxSprites = 3;
int g_iMaxHeight = 60;
float g_fScale = 10.0;
int g_iFrameRate = 20;

char g_cSoundArtifactUse1Table[] = "sound/cs-plugin.com/xiaolin/goldentigerclaws1.mp3";
char g_cSoundArtifactUse1[] = "cs-plugin.com/xiaolin/goldentigerclaws1.mp3";
char g_cSoundArtifactUse2Table[] = "sound/cs-plugin.com/xiaolin/goldentigerclaws2.mp3";
char g_cSoundArtifactUse2[] = "cs-plugin.com/xiaolin/goldentigerclaws2.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_GoldenTigerClaws");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_GoldenTigerClaws");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	g_iSprite = PrecacheModel(g_cSprite); 
	
	AddFileToDownloadsTable(g_cSoundArtifactUse1Table);
	PrecacheSound(g_cSoundArtifactUse1);
	
	AddFileToDownloadsTable(g_cSoundArtifactUse2Table);
	PrecacheSound(g_cSoundArtifactUse2);
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
	g_iPlayerMode[client] = 2;
}

public void Xiaolin_OnShenGongWuDrop(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	g_iPlayerMode[client] = 0;
	
	PrintToChat(client, "%t %s!", "SGW_Drop", g_cArtifactName);
	g_bArtifactOwner[client] = false;
}

public void Xiaolin_OnShenGongWuUse(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	if (g_iPlayerMode[client] != 0)
	{
		if (g_iPlayerMode[client] == 2)
		{
			PrintToChat(client, "%t", "Chat_GoldenTigerClawsUsage1");
			SetTeleportSpot(client);
			g_iPlayerMode[client] = 1;
		}
		else if(g_iPlayerMode[client] == 1)
		{
			PrintToChat(client, "%t", "Chat_GoldenTigerClawsUsage2");
			TeleportToSpot(client);
			g_iPlayerMode[client] = 2;
			if (IsPlayerStuck(client))
			{
				SDKHooks_TakeDamage(client, artifact_index, artifact_index, 9999.0);
				PrintToChat(client, "%t", "Chat_GoldenTigerClawsError");
			}
		}
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_Drop", g_cArtifactName);
	}
}

stock void SetTeleportSpot(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse1, client);
	
	GetClientAbsOrigin(client, g_fPlayerTeleportOrigin[client]);
	GetClientAbsAngles(client, g_fPlayerTeleportAngle[client]);
}

stock void TeleportToSpot(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse2, client);
	
	StripPlayerWeaponsAll(client);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 0, 0, 0, 0);
	
	float fTempPlayerActualOrigin[3];
	GetClientAbsOrigin(client, fTempPlayerActualOrigin);
	
	for (int i = 0; i < g_iMaxSprites; i++)
	{
		fTempPlayerActualOrigin[2] += g_iMaxHeight/g_iMaxSprites;
		
		TE_SetupSmoke(fTempPlayerActualOrigin, g_iSprite, g_fScale, g_iFrameRate);
		TE_SendToAllInRange(fTempPlayerActualOrigin, RangeType_Visibility, 0.0);
	}
	CreateTimer(0.2, TeleportTimer, client);
}

public Action TeleportTimer(Handle hTimer, int client)
{
	GivePlayerStandardWeapons(client);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	TeleportEntity(client, g_fPlayerTeleportOrigin[client], g_fPlayerTeleportAngle[client], NULL_VECTOR);
	
	for (int i = 0; i < g_iMaxSprites; i++)
	{
		g_fPlayerTeleportOrigin[client][2] += g_iMaxHeight/g_iMaxSprites;
		
		TE_SetupSmoke(g_fPlayerTeleportOrigin[client], g_iSprite, g_fScale, g_iFrameRate);
		TE_SendToAllInRange(g_fPlayerTeleportOrigin[client], RangeType_Visibility, 0.0);
	}
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
