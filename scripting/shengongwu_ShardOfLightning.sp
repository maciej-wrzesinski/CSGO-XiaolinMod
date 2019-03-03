#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//jakies dzwieki sa ale moze byc wiecej, 1 przy uzyciu
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Shard of Lightning",
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

char g_cSpriteSpark[] = "sprites/physbeam.vmt";

char g_cSoundArtifactUseTable[] = "sound/cs-plugin.com/xiaolin/shardoflightning.mp3";
char g_cSoundArtifactUse[] = "cs-plugin.com/xiaolin/shardoflightning.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_ShardOfLightning");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_ShardOfLightning");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	PrecacheModel(g_cSpriteSpark);
	
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
	TeleportToWhereYouLook(client);
}

stock bool TeleportToWhereYouLook(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse, client);
	
	float fPlayerAngles[3];
	float fPlayerOrigin[3];
	float fPlayerAbsOrigin[3];
	float fTeleportPosition[3];
	
	GetClientEyePosition(client, fPlayerOrigin);
	GetClientAbsOrigin(client, fPlayerAbsOrigin);
	GetClientEyeAngles(client, fPlayerAngles);
	
	MakeSparks(fPlayerOrigin);
	
	Handle hTrace = TR_TraceRayFilterEx(fPlayerOrigin, fPlayerAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client); 

	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fTeleportPosition, hTrace);
		
		float fNewPositionOrigin[3];
		GetClientEyePosition(client, fNewPositionOrigin);
		float fTempGoodOrigin[3];
		int howmuch = 5;
		while(howmuch--)
		{
			fTempGoodOrigin[0] = fNewPositionOrigin[0];
			fTempGoodOrigin[1] = fNewPositionOrigin[1];
			fTempGoodOrigin[2] = fNewPositionOrigin[2];
			CalculateCloserPoint(fTeleportPosition, fNewPositionOrigin, fNewPositionOrigin);
			
			TeleportEntity(client, fNewPositionOrigin, NULL_VECTOR, NULL_VECTOR);
			
			if (IsPlayerStuck(client))
			{
				TeleportEntity(client, fTempGoodOrigin, NULL_VECTOR, NULL_VECTOR);
				break;
			}
			MakeSparks(fTempGoodOrigin);
			EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse, client);
		}
		
		if (IsPlayerStuck(client)/* || fTempGoodOrigin[2] > 350.0 zabezpieczenie bo jak sie patrzy w tekstury to sie wylatuje poza mape na gorze*/)
		{
			//PrintToChat(client, "Cos poszlo kompletnie nie tak... teleportacja do poczatkowej lokalizacji");
			TeleportEntity(client, fPlayerAbsOrigin, NULL_VECTOR, NULL_VECTOR);
			CloseHandle(hTrace);
			return true;
		}
		
		CloseHandle(hTrace);
		return true;
	}
	
	CloseHandle(hTrace);
	return false;
}

stock void MakeSparks(float origin[3])
{
	int iEntityElectric = CreateEntitySafe("point_tesla");
	if (iEntityElectric != -1 && IsValidEntity(iEntityElectric))
	{
		DispatchKeyValue(iEntityElectric, "m_flRadius", "20.0");
		DispatchKeyValue(iEntityElectric, "m_SoundName", "DoSpark");
		DispatchKeyValue(iEntityElectric, "beamcount_min", "64");
		DispatchKeyValue(iEntityElectric, "beamcount_max", "128");
		DispatchKeyValue(iEntityElectric, "texture", g_cSpriteSpark);
		DispatchKeyValue(iEntityElectric, "m_Color", "255 255 255");
		DispatchKeyValue(iEntityElectric, "thick_min", "1.0");  
		DispatchKeyValue(iEntityElectric, "thick_max", "10.0"); 
		DispatchKeyValue(iEntityElectric, "lifetime_min", "0.1");
		DispatchKeyValue(iEntityElectric, "lifetime_max", "0.5"); 
		DispatchKeyValue(iEntityElectric, "interval_min", "0.1"); 
		DispatchKeyValue(iEntityElectric, "interval_max", "0.5"); 
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

stock void CalculateCloserPoint(float origin1[3], float origin2[3], float origin3[3])
{
	origin3[0] = ((origin1[0] + origin2[0]) / 2);
	origin3[1] = ((origin1[1] + origin2[1]) / 2);
	origin3[2] = ((origin1[2] + origin2[2]) / 2);
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
