#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//dodać dźwięki do lecenia i eksplozji
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Tangle Web Comb",
	author = "Vasto_Lorde",
	description = "Shen Gong Wu for Xiaolin",
	version = "1.0",
	url = "http://cs-plugin.com/"
};

char g_cArtifactName[ARTIFACT_NAME_LENG];
char g_cArtifactDesc[ARTIFACT_DESC_LENG];
float g_fArtifactDecay = 0.86;
float g_fArtifactChiUsage = 12.0;

int g_iArtifactIndex;
bool g_bArtifactOwner[MAX_PLAYERS+1];

Handle g_hPlayerTimer[MAX_PLAYERS+1];

char g_cModelArtifact[5][] = 
{
	"models/player/custom_player/kuristaja/invisible_box/box.mdl",
	"models/player/custom_player/kuristaja/invisible_box/box.dx90.vtx",
	"models/player/custom_player/kuristaja/invisible_box/box.phy",
	"models/player/custom_player/kuristaja/invisible_box/box.vvd",
	"materials/models/player/kuristaja/invisible/invisible.vmt"
};

char g_cSpriteGlow[] = "materials/sprites/blueflare1.vmt";
int g_iSpriteGlow;

char g_cSoundArtifactUseTable[] = "sound/cs-plugin.com/xiaolin/tanglewebcomb.mp3";
char g_cSoundArtifactUse[] = "cs-plugin.com/xiaolin/tanglewebcomb.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_TangleWebComb");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_TangleWebComb");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	for (int i = 0; i < 5; i++)
	{
		AddFileToDownloadsTable(g_cModelArtifact[i]);
		PrecacheModel(g_cModelArtifact[i]);
	}
	
	g_iSpriteGlow = PrecacheModel(g_cSpriteGlow);
	
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
	ShootSpiderWeb(client);
}

stock void ShootSpiderWeb(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse, client);
	
	float fPlayerOrigin[3];
	GetClientEyePosition(client, fPlayerOrigin);
	float fPlayerAngles[3];
	GetClientEyeAngles(client, fPlayerAngles);
	float fWantedOrigin[3];
	fWantedOrigin[0] = (fPlayerOrigin[0]+(100*((Cosine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fWantedOrigin[1] = (fPlayerOrigin[1]+(100*((Sine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fPlayerAngles[0] -= (2*fPlayerAngles[0]);
	fWantedOrigin[2] = (fPlayerOrigin[2]+(100*(Sine(DegToRad(fPlayerAngles[0])))));
	fWantedOrigin[2] -= 10.0;
	
	int iEntityMainSpiderWeb = CreateEntitySafe("generic_actor");
	if (iEntityMainSpiderWeb != -1 && IsValidEntity(iEntityMainSpiderWeb))
	{
		DispatchKeyValue(iEntityMainSpiderWeb, "model", g_cModelArtifact[0]);
		DispatchKeyValue(iEntityMainSpiderWeb, "classname", "Web");
		DispatchKeyValue(iEntityMainSpiderWeb, "solid", "0");
		DispatchKeyValue(iEntityMainSpiderWeb, "spawnflags", "4");
		DispatchKeyValueVector(iEntityMainSpiderWeb, "Origin", fWantedOrigin);
		DispatchSpawn(iEntityMainSpiderWeb);
		
		SDKHook(iEntityMainSpiderWeb, SDKHook_StartTouch, OnStartTouchSpiderWeb);
		SetEntityMoveType(iEntityMainSpiderWeb, MOVETYPE_FLY);
		
		GetClientEyeAngles(client, fPlayerAngles);
		float fEntityVelocity[3];
		GetAngleVectors(fPlayerAngles, fEntityVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fEntityVelocity, 1000.0); 
		TeleportEntity(iEntityMainSpiderWeb, NULL_VECTOR, fPlayerAngles, fEntityVelocity);
		
		CreateTimer(0.01, MakeFlyingSpiderWeb, iEntityMainSpiderWeb);
	}
}

public void OnStartTouchSpiderWeb(int entity, int client)
{ 
	if (!IsValidEntity(entity))
		return;
	
	if (IsThisAPlayer(client) && IsPlayerAlive(client))
	{
		int iEntitySpriteWeb = CreateEntitySafe("env_sprite");
		if (iEntitySpriteWeb != -1 && IsValidEntity(iEntitySpriteWeb))
		{
			float fTempPlayerOrigin[3];
			GetClientAbsOrigin(client, fTempPlayerOrigin);
			
			DispatchKeyValue(iEntitySpriteWeb, "model", g_cSpriteGlow);
			DispatchKeyValue(iEntitySpriteWeb, "classname", "Web");
			DispatchKeyValue(iEntitySpriteWeb, "spawnflags", "1");
			DispatchKeyValue(iEntitySpriteWeb, "scale", "0.3");
			DispatchKeyValue(iEntitySpriteWeb, "rendermode", "3");
			DispatchKeyValue(iEntitySpriteWeb, "RenderAmt", "255"); 
			DispatchKeyValue(iEntitySpriteWeb, "rendercolor", "152 255 152");
			DispatchKeyValueVector(iEntitySpriteWeb, "Origin", fTempPlayerOrigin);
			DispatchSpawn(iEntitySpriteWeb);
			SetVariantString("!activator");
			AcceptEntityInput(iEntitySpriteWeb, "SetParent", client);
		}
		
		Handle data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, iEntitySpriteWeb);
		
		if (IsValidHandle(g_hPlayerTimer[client]))
		{
			KillTimer(g_hPlayerTimer[client]);
		}
		else
		{
			Xiaolin_SetPlayerBonusSpeed(client, -0.5);
			Xiaolin_UpdatePlayerStats(client);
			Xiaolin_BlockDashUse(client);
		}
		g_hPlayerTimer[client] = CreateTimer(3.0, FreePlayerFromWeb_Timer, data);
	}
	
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchSpiderWeb);
	RemoveEdict(entity);
}

public Action FreePlayerFromWeb_Timer(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int entity = ReadPackCell(data);
	CloseHandle(data);
	
	if (IsClientInGame(client))
	{
		Xiaolin_SetPlayerBonusSpeed(client, 0.5);
		Xiaolin_UpdatePlayerStats(client);
		Xiaolin_UnblockDashUse(client);
		
		if (IsValidEntity(entity))
		{
			RemoveEdict(entity);
		}
	}
}

public Action MakeFlyingSpiderWeb(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	MakeBeamsSpriteSpiderWeb(entity);
	
	CreateTimer(0.05, MakeFlyingSpiderWeb, entity);
}

stock void MakeBeamsSpriteSpiderWeb(int entity)
{
	float center[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", center);
	
	float angle[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angle);
	
	int iColors[4] = {152, 255, 152, 255};
	float fLife = 0.1;
	float fHeightAndWidth = 40.0;
	float fDegree = 90.0;
	float fNumberOfHolesInWeb = 2.0; // less = less holes
	
	
	for ( float i = fHeightAndWidth*-1.0; i <= fHeightAndWidth; i += fHeightAndWidth/fNumberOfHolesInWeb)
	{
		float fOriginRightUp[3];
		float fOriginRightDown[3];
		
		
		fOriginRightUp[0] = center[0] + Cosine(DegToRad( angle[1] + fDegree )) * i;
		fOriginRightUp[1] = center[1] + Sine(DegToRad( angle[1] + fDegree )) * i; 
		fOriginRightUp[2] = center[2] + fHeightAndWidth; 
		
		fOriginRightDown[0] = fOriginRightUp[0];
		fOriginRightDown[1] = fOriginRightUp[1];
		fOriginRightDown[2] = center[2] - fHeightAndWidth;
		
		
		TE_SetupBeamPoints(fOriginRightUp, fOriginRightDown, g_iSpriteGlow, 0, 0, 0, fLife, 1.0, 1.0, 10, 0.5, iColors, 0);
		TE_SendToAllInRange(fOriginRightUp, RangeType_Visibility, 0.0);
	}
	
	for ( float i = fHeightAndWidth*-1.0; i <= fHeightAndWidth; i += fHeightAndWidth/fNumberOfHolesInWeb)
	{
		float fOriginRightUp[3];
		float fOriginLeftUp[3];
		
		
		fOriginRightUp[0] = center[0] + Cosine(DegToRad( angle[1] + fDegree )) * fHeightAndWidth;
		fOriginRightUp[1] = center[1] + Sine(DegToRad( angle[1] + fDegree )) * fHeightAndWidth; 
		fOriginRightUp[2] = center[2] - i; 
		
		fOriginLeftUp[0] = center[0] + Cosine(DegToRad( angle[1] - fDegree )) * fHeightAndWidth; 
		fOriginLeftUp[1] = center[1] + Sine(DegToRad( angle[1] - fDegree )) * fHeightAndWidth;
		fOriginLeftUp[2] = center[2] - i; 
		
		
		TE_SetupBeamPoints(fOriginRightUp, fOriginLeftUp, g_iSpriteGlow, 0, 0, 0, fLife, 1.0, 1.0, 10, 0.5, iColors, 0);
		TE_SendToAllInRange(fOriginRightUp, RangeType_Visibility, 0.0);
	}
}

