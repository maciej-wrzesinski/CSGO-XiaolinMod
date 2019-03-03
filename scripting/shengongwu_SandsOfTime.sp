#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//dżwięk na włączenie
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Sands of time",
	author = "Vasto_Lorde",
	description = "Shen Gong Wu for Xiaolin",
	version = "1.0",
	url = "http://cs-plugin.com/"
};

char g_cArtifactName[ARTIFACT_NAME_LENG];
char g_cArtifactDesc[ARTIFACT_DESC_LENG];
float g_fArtifactDecay = 0.86;
float g_fArtifactChiUsage = 99.0;

int g_iArtifactIndex;
bool g_bArtifactOwner[MAX_PLAYERS+1];

char g_cSpriteLaser[] = "materials/sprites/laserbeam.vmt";
char g_iSpriteLaser;

char g_cSoundArtifactUseTable[] = "sound/cs-plugin.com/xiaolin/sandsoftime.mp3";
char g_cSoundArtifactUse[] = "cs-plugin.com/xiaolin/sandsoftime.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_SandsOfTime");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_SandsOfTime");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	g_iSpriteLaser = PrecacheModel(g_cSpriteLaser);
	
	AddFileToDownloadsTable(g_cSoundArtifactUseTable);
	PrecacheSound(g_cSoundArtifactUse);
}

public void Xiaolin_OnShenGongWuPick(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	PrintToChat(client, "%t %s! (%s)", "SGW_Get", g_cArtifactName, g_cArtifactDesc);
	g_bArtifactOwner[client] = true;
}

public void Xiaolin_OnShenGongWuDrop(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	PrintToChat(client, "%t %s!", "SGW_Drop", g_cArtifactName);
	g_bArtifactOwner[client] = false;
}

public void Xiaolin_OnShenGongWuUse(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	PrintToChat(client, "%t %s!", "SGW_Use", g_cArtifactName);
	SlowTime(client);
}

stock void SlowTime(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse, client);
	
	float fTempOrigin[3];
	GetClientAbsOrigin(client, fTempOrigin);
	int iTempBeamColor[4] = {255, 255, 255, 255};
	TE_SetupBeamRingPoint(fTempOrigin, 10.0, 9999.9, g_iSpriteLaser, g_iSpriteLaser, 0, 10, 2.0, 9999.9, 0.0, iTempBeamColor, 10, FBEAM_SHADEOUT);
	TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	
	MakeAnHourGlass(fTempOrigin);
	
	for (int i = 1; i < MAX_PLAYERS; i++)
	{
		if (i != client && IsClientInGame(i))
		{
			Xiaolin_SetPlayerBonusSpeed(i, -3.0);
			Xiaolin_UpdatePlayerStats(i);
			Xiaolin_BlockShenGongWuUse(i);
		}
	}
	CreateTimer(4.0, NormalTime, client);
}

public Action NormalTime(Handle hTimer, int client)
{
	for (int i = 1; i < MAX_PLAYERS; i++)
	{
		if (i != client && IsClientInGame(i))
		{
			Xiaolin_SetPlayerBonusSpeed(i, 3.0);
			Xiaolin_UpdatePlayerStats(i);
			Xiaolin_UnblockShenGongWuUse(i);
		}
	}
}

stock void MakeAnHourGlass(float origin[3])
{
	float fWidth = 60.0;
	for (int i = 0; i < 100; i++)
	{
		if (i > 20 && i < 50)
		{
			fWidth -= 2.0;
		}
		else if(i > 50 && i < 80)
		{
			fWidth += 2.0;
		}
		
		TE_SetupBeamRingPoint(origin, fWidth, fWidth+0.1, g_iSpriteLaser, g_iSpriteLaser, 0, 10, 10.0, 2.0, 0.0, {255, 255, 255, 255}, 10, 0);
		TE_SendToAllInRange(origin, RangeType_Visibility, 0.0);
		
		origin[2] += 1.0;
	}
}

