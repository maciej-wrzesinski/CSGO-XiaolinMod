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
	name = "Shen Gong Wu - Sphere of Yun",
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

char g_cSoundArtifactUse1Table[] = "sound/cs-plugin.com/xiaolin/sphereofyun1.mp3";
char g_cSoundArtifactUse1[] = "cs-plugin.com/xiaolin/sphereofyun1.mp3";
char g_cSoundArtifactUse2Table[] = "sound/cs-plugin.com/xiaolin/sphereofyun2.mp3";
char g_cSoundArtifactUse2[] = "cs-plugin.com/xiaolin/sphereofyun2.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_SphereOfYun");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_SphereOfYun");
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
	
	AddFileToDownloadsTable(g_cSoundArtifactUse1Table);
	PrecacheSound(g_cSoundArtifactUse1);
	
	AddFileToDownloadsTable(g_cSoundArtifactUse2Table);
	PrecacheSound(g_cSoundArtifactUse2);
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
	ShootSphere(client);
}

stock void ShootSphere(int client)
{
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse1, client);
	
	float fPlayerOrigin[3];
	GetClientEyePosition(client, fPlayerOrigin);
	float fPlayerAngles[3];
	GetClientEyeAngles(client, fPlayerAngles);
	float fWantedOrigin[3];
	fWantedOrigin[0] = (fPlayerOrigin[0]+(100*((Cosine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fWantedOrigin[1] = (fPlayerOrigin[1]+(100*((Sine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fPlayerAngles[0] -= (2*fPlayerAngles[0]);
	fWantedOrigin[2] = (fPlayerOrigin[2]+(100*(Sine(DegToRad(fPlayerAngles[0])))));
	
	
	int iEntityMainSphere = CreateEntitySafe("generic_actor");
	if (iEntityMainSphere != -1 && IsValidEntity(iEntityMainSphere))
	{
		DispatchKeyValue(iEntityMainSphere, "model", g_cModelArtifact[0]);
		DispatchKeyValue(iEntityMainSphere, "classname", "SphereOfYun");
		DispatchKeyValue(iEntityMainSphere, "solid", "0");
		DispatchKeyValue(iEntityMainSphere, "spawnflags", "4");
		DispatchKeyValueVector(iEntityMainSphere, "Origin", fWantedOrigin);
		DispatchSpawn(iEntityMainSphere);
		
		int iEntitySpriteSphere = CreateEntitySafe("env_sprite");
		if (iEntitySpriteSphere != -1 && IsValidEntity(iEntitySpriteSphere))
		{
			DispatchKeyValue(iEntitySpriteSphere, "model", g_cSpriteGlow);
			DispatchKeyValue(iEntitySpriteSphere, "classname", "SphereOfYun");
			DispatchKeyValue(iEntitySpriteSphere, "spawnflags", "1");
			DispatchKeyValue(iEntitySpriteSphere, "scale", "0.2");
			DispatchKeyValue(iEntitySpriteSphere, "rendermode", "3");
			DispatchKeyValue(iEntitySpriteSphere, "RenderAmt", "255"); 
			DispatchKeyValue(iEntitySpriteSphere, "rendercolor", "0 100 255");
			DispatchKeyValueVector(iEntitySpriteSphere, "Origin", fWantedOrigin);
			DispatchSpawn(iEntitySpriteSphere);
			SetVariantString("!activator");
			AcceptEntityInput(iEntitySpriteSphere, "SetParent", iEntityMainSphere);
		}
		
		SDKHook(iEntityMainSphere, SDKHook_StartTouch, OnStartTouchSphere);
		SetEntityMoveType(iEntityMainSphere, MOVETYPE_FLY);
		
		GetClientEyeAngles(client, fPlayerAngles);
		float fEntityVelocity[3];
		GetAngleVectors(fPlayerAngles, fEntityVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fEntityVelocity, 700.0); 
		TeleportEntity(iEntityMainSphere, NULL_VECTOR, fPlayerAngles, fEntityVelocity);
		//SDKHooks_TakeDamage(iEntityMainSphere, 0, 0, 10.0); // hitbox fix????
		
		CreateTimer(0.01, SphereRings, iEntityMainSphere);
	}
}

public Action SphereRings(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	float fTempOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fTempOrigin);
	TE_SetupBeamRingPoint(fTempOrigin, 50.0, 51.0, g_iSpriteGlow, g_iSpriteGlow, 0, 1, 0.1, 1.0, 0.0, {0, 100, 255, 255}, 30, 0);
	TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	
	CreateTimer(0.01, SphereRings, entity);
}

public void OnStartTouchSphere(int entity, int client)
{ 
	if (!IsValidEntity(entity))
		return;
	
	if (IsThisAPlayer(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse2, client);
		Xiaolin_SetPlayerBonusSpeed(client, -10.0);
		Xiaolin_UpdatePlayerStats(client);
		SDKHooks_TakeDamage(client, entity, entity, 10.0);
		
		float fPlayerOrigin[3];
		GetClientAbsOrigin(client, fPlayerOrigin);
		Cage(fPlayerOrigin, 1.7);
		CreateTimer(1.7, UnfreezePlayer, client);
	}
	else
	{
		EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse1, entity);
		float fTempOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fTempOrigin);
		Cage(fTempOrigin, 0.2);
	}
	
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchSphere);
	RemoveEdict(entity);
}

public Action UnfreezePlayer(Handle hTimer, int client)
{
	Xiaolin_SetPlayerBonusSpeed(client, 10.0);
	Xiaolin_UpdatePlayerStats(client);
}

public void Cage(float origin[3], float time)
{
	origin[2] -= 10.0;
	
	for (int i = 1; i < 10; i++)
	{
		TE_SetupBeamRingPoint(origin, 50.0-(i*5), 51.0-(i*5), g_iSpriteGlow, g_iSpriteGlow, 0, 1, time, 2.0, 0.0, {0, 100, 255, 255}, 30, 0);
		TE_SendToAllInRange(origin, RangeType_Visibility, 0.0);
	}
	
	for (int i = 0; i < 100; i++)
	{
		TE_SetupBeamRingPoint(origin, 50.0, 51.0, g_iSpriteGlow, g_iSpriteGlow, 0, 1, time, 2.0, 0.0, {0, 100, 255, 255}, 30, 0);
		TE_SendToAllInRange(origin, RangeType_Visibility, 0.0);
		origin[2] += 1.0;
	}
	
	for (int i = 1; i < 10; i++)
	{
		TE_SetupBeamRingPoint(origin, 50.0-(i*5), 51.0-(i*5), g_iSpriteGlow, g_iSpriteGlow, 0, 1, time, 2.0, 0.0, {0, 100, 255, 255}, 30, 0);
		TE_SendToAllInRange(origin, RangeType_Visibility, 0.0);
	}
}
