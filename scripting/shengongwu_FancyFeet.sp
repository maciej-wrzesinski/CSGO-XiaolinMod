#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//Nie wiem jakie dźwięki, w czasie biegania?
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Fancy Feet",
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
//int g_iPlayerTrailEntity[MAX_PLAYERS+1];

char g_cSprite[] = "materials/sprites/laserbeam.vmt";
int g_iSprite;

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_FancyFeet");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_FancyFeet");
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
		Xiaolin_SetPlayerBonusSpeed(client, 2.5);
		Xiaolin_UpdatePlayerStats(client);
		StartFancyFeet(client);
		g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "%t %s!", "SGW_TurnOff", g_cArtifactName);
		Xiaolin_SetPlayerBonusSpeed(client, -2.5);
		Xiaolin_UpdatePlayerStats(client);
		StopFancyFeet(client);
		g_bArtifactWorking[client] = false;
	}
}

public void StartFancyFeet(int client)
{
	GetClientAbsOrigin(client, g_fLastPlayerOrigin[client]);
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeFootSteps, client);
	
	/*int iEntitySpriteTrail = CreateEntitySafe("env_spritetrail");
	if (iEntitySpriteTrail != -1 && IsValidEntity(iEntitySpriteTrail))
	{
		DispatchKeyValue(iEntitySpriteTrail, "spritename", g_cSprite);
		DispatchKeyValue(iEntitySpriteTrail, "classname", "SpriteTrail");
		DispatchKeyValue(iEntitySpriteTrail, "startwidth", "5.0");
		DispatchKeyValue(iEntitySpriteTrail, "endwidth", "5.1");
		DispatchKeyValue(iEntitySpriteTrail, "rendermode", "3");
		DispatchKeyValue(iEntitySpriteTrail, "RenderAmt", "175"); 
		DispatchKeyValue(iEntitySpriteTrail, "rendercolor", "255 255 255");
		DispatchSpawn(iEntitySpriteTrail);
		SetVariantString("!activator");
		AcceptEntityInput(iEntitySpriteTrail, "SetParent", client);
		
		g_iPlayerTrailEntity[client] = iEntitySpriteTrail;
	}*/
}

public Action MakeFootSteps(Handle hTimer, int client)
{
	float fTempPlayerOrigin[3];
	GetClientAbsOrigin(client, fTempPlayerOrigin);
	
	float fLife = 3.5;
	int iFadeLenght = 3;
	float fWidth = 3.0;
	
	fTempPlayerOrigin[2] += 5.0;
	g_fLastPlayerOrigin[client][2] += 5.0;
	
	TE_SetupBeamPoints(fTempPlayerOrigin, g_fLastPlayerOrigin[client], g_iSprite, g_iSprite, 0, 15, fLife, fWidth, fWidth+0.1, iFadeLenght, 0.0, {255, 255, 255, 175}, 1);
	TE_SendToAllInRange(fTempPlayerOrigin, RangeType_Visibility, 0.0);
	
	GetClientAbsOrigin(client, g_fLastPlayerOrigin[client]);
	g_hPlayerTimer[client] = CreateTimer(0.01, MakeFootSteps, client);
}

public void StopFancyFeet(int client)
{
	if (IsValidHandle(g_hPlayerTimer[client]))
		KillTimer(g_hPlayerTimer[client]);
	//if (IsValidEntity(g_iPlayerTrailEntity[client]))
	//	RemoveEdict(g_iPlayerTrailEntity[client]);
}

