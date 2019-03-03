#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//ZRÓB JEDEN DŹWIĘK UŻYCIA https://www.youtube.com/watch?v=swmwhcW8PpQ
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Emperor Scorpion",
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

char g_cSoundArtifactUseTable[] = "sound/cs-plugin.com/xiaolin/emperorscorpion.mp3";
char g_cSoundArtifactUse[] = "cs-plugin.com/xiaolin/emperorscorpion.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_EmperorScorpion");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_EmperorScorpion");
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
	MakePlayersDrop(client);
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse);
}

stock void MakePlayersDrop(int client)
{
	
	for (int i = 1; i <= 4; i++)
	{
		Handle data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, i);
		CreateTimer(0.2 * i, CreateBeamRing, data);
	}
	
	for (int i = 1; i < MAX_PLAYERS; i++)
	{
		if (i != client && IsClientInGame(i) && IsPlayerAlive(i))
		{
			PrintToChat(i, "%N %t %s!", client, "Chat_EmperorScorpionEffect", g_cArtifactName);
			Xiaolin_ForceShenGongWuDrop(i);
		}
	}
}

public Action CreateBeamRing(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int i = ReadPackCell(data);
	CloseHandle(data);
	
	if (IsPlayerAlive(client))
	{
		float fTempOrigin[3];
		GetClientAbsOrigin(client, fTempOrigin);
		int iTempBeamColor[4] = {155, 224, 98, 255};
		TE_SetupBeamRingPoint(fTempOrigin, 10.0, 999.9, g_iSpriteLaser, g_iSpriteLaser, 0, 10, 2.0, 999.9, 1.0*i, iTempBeamColor, 10, FBEAM_SHADEOUT);
		TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	}
}
