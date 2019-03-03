#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//dodać dźwięki do wystrzału i eksplozji https://www.youtube.com/watch?v=E_wOcRBmntc&index=26&list=PLxLtpoeGaRwMepPPTsBHD-uYt30txtU4b
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Eye of Dashi",
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

char g_cSoundArtifactUseTable[] = "sound/cs-plugin.com/xiaolin/eyeofdashi.mp3";
char g_cSoundArtifactUse[] = "cs-plugin.com/xiaolin/eyeofdashi.mp3";
char g_cSoundArtifactHitTable[] = "sound/cs-plugin.com/xiaolin/eyeofdashi2.mp3";
char g_cSoundArtifactHit[] = "cs-plugin.com/xiaolin/eyeofdashi2.mp3";

char g_cModelArtifact[5][] = 
{
	"models/player/custom_player/kuristaja/invisible_box/box.mdl",
	"models/player/custom_player/kuristaja/invisible_box/box.dx90.vtx",
	"models/player/custom_player/kuristaja/invisible_box/box.phy",
	"models/player/custom_player/kuristaja/invisible_box/box.vvd",
	"materials/models/player/kuristaja/invisible/invisible.vmt"
};

char g_cSpriteSpark[] = "sprites/physbeam.vmt";
char g_cSpriteGlow[] = "materials/sprites/blueflare1.vmt";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_EyeOfDashi");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_EyeOfDashi");
}

public void OnMapStart()
{
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	for (int i = 0; i < 5; i++)
	{
		AddFileToDownloadsTable(g_cModelArtifact[i]);
		PrecacheModel(g_cModelArtifact[i]);
	}
	
	PrecacheModel(g_cSpriteSpark); 
	PrecacheModel(g_cSpriteGlow);
	
	AddFileToDownloadsTable(g_cSoundArtifactUseTable);
	PrecacheSound(g_cSoundArtifactUse);
	
	AddFileToDownloadsTable(g_cSoundArtifactHitTable);
	PrecacheSound(g_cSoundArtifactHit);
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
	ShootBolt(client);
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse, client);
}

stock void ShootBolt(int client)
{
	float fPlayerOrigin[3];
	GetClientEyePosition(client, fPlayerOrigin);
	float fPlayerAngles[3];
	GetClientEyeAngles(client, fPlayerAngles);
	float fWantedOrigin[3];
	fWantedOrigin[0] = (fPlayerOrigin[0]+(100*((Cosine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fWantedOrigin[1] = (fPlayerOrigin[1]+(100*((Sine(DegToRad(fPlayerAngles[1]))) * (Cosine(DegToRad(fPlayerAngles[0]))))));
	fPlayerAngles[0] -= (2*fPlayerAngles[0]);
	fWantedOrigin[2] = (fPlayerOrigin[2]+(100*(Sine(DegToRad(fPlayerAngles[0])))));
	
	
	int iEntityMainBolt = CreateEntitySafe("generic_actor");
	if (iEntityMainBolt != -1 && IsValidEntity(iEntityMainBolt))
	{
		DispatchKeyValue(iEntityMainBolt, "model", g_cModelArtifact[0]);
		DispatchKeyValue(iEntityMainBolt, "classname", "ElectricBolt");
		DispatchKeyValue(iEntityMainBolt, "solid", "0");
		DispatchKeyValue(iEntityMainBolt, "spawnflags", "4");
		DispatchKeyValueVector(iEntityMainBolt, "Origin", fWantedOrigin);
		DispatchSpawn(iEntityMainBolt);
		
		int iEntitySpriteBolt = CreateEntitySafe("env_sprite");
		if (iEntitySpriteBolt != -1 && IsValidEntity(iEntitySpriteBolt))
		{
			DispatchKeyValue(iEntitySpriteBolt, "model", g_cSpriteGlow);
			DispatchKeyValue(iEntitySpriteBolt, "classname", "ElectricBolt"); //ambient_sparks, ambient_sparks_core,  env_sparks_a, env_sparks_b, nuke_sparks, baggage_sparks1
			DispatchKeyValue(iEntitySpriteBolt, "spawnflags", "1");
			DispatchKeyValue(iEntitySpriteBolt, "scale", "0.3");
			DispatchKeyValue(iEntitySpriteBolt, "rendermode", "3");
			DispatchKeyValue(iEntitySpriteBolt, "RenderAmt", "255"); 
			DispatchKeyValue(iEntitySpriteBolt, "rendercolor", "255 255 255");
			DispatchKeyValueVector(iEntitySpriteBolt, "Origin", fWantedOrigin);
			DispatchSpawn(iEntitySpriteBolt);
			SetVariantString("!activator");
			AcceptEntityInput(iEntitySpriteBolt, "SetParent", iEntityMainBolt);
		}
		
		//ambient_sparks_core - małe, co jakiś czas
		//baggage_sparks1_core - małe, częściej
		//nuke_sparks1_core - małe, częściej
		char cTempParticles[3][] = 
		{
			"ambient_sparks_core",
			"baggage_sparks1_core",
			"nuke_sparks1_core"
		};
		for (int i = 0; i <= 20; i++)
		{
			if (!IsValidEntity(iEntityMainBolt))
				break;
			int iEntityInfoParticleBolt = CreateEntitySafe("info_particle_system");
			if (iEntityInfoParticleBolt != -1 && IsValidEntity(iEntityInfoParticleBolt))
			{
				DispatchKeyValue(iEntityInfoParticleBolt, "effect_name", cTempParticles[GetRandomInt(0, 2)]);
				DispatchKeyValue(iEntityInfoParticleBolt, "name", "ElectricBolt"); 
				DispatchKeyValueVector(iEntityInfoParticleBolt, "Origin", fWantedOrigin);
				DispatchSpawn(iEntityInfoParticleBolt);
				SetVariantString("!activator");
				AcceptEntityInput(iEntityInfoParticleBolt, "SetParent", iEntityMainBolt);
				CreateTimer(0.05 * i, StartParticle, iEntityInfoParticleBolt);
			}
		}
		
		SDKHook(iEntityMainBolt, SDKHook_StartTouch, OnStartTouchBolt);
		SetEntityMoveType(iEntityMainBolt, MOVETYPE_FLY);
		
		GetClientEyeAngles(client, fPlayerAngles);
		float fEntityVelocity[3];
		GetAngleVectors(fPlayerAngles, fEntityVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fEntityVelocity, 1000.0); 
		TeleportEntity(iEntityMainBolt, NULL_VECTOR, fPlayerAngles, fEntityVelocity);
		//SDKHooks_TakeDamage(iEntityMainBolt, 0, 0, 10.0); // hitbox fix????
	}
}

public Action StartParticle(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	AcceptEntityInput(entity, "start");
	ActivateEntity(entity);
}

public void OnStartTouchBolt(int entity, int client)
{ 
	if (!IsValidEntity(entity))
		return;
	
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactHit, entity);
	
	if (IsThisAPlayer(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SDKHooks_TakeDamage(client, entity, entity, 30.0);
		ShookPlayer(client);
	}
	
	float fTempOrigin[3];
	float fTempOriginDest[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fTempOrigin);
	
	TE_SetupSparks(fTempOrigin, fTempOriginDest, 500, 100);
	TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	TE_SetupSparks(fTempOrigin, fTempOriginDest, 250, 50);
	TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	TE_SetupMetalSparks(fTempOrigin, fTempOriginDest);
	TE_SendToAllInRange(fTempOrigin, RangeType_Visibility, 0.0);
	
	MakeSparks(fTempOrigin);
	
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchBolt);
	RemoveEdict(entity);
}

stock void MakeSparks(float origin[3])
{
	int iEntityElectric = CreateEntitySafe("point_tesla");
	if (iEntityElectric != -1 && IsValidEntity(iEntityElectric))
	{
		DispatchKeyValue(iEntityElectric, "m_flRadius", "30.0");
		DispatchKeyValue(iEntityElectric, "m_SoundName", "DoSpark");
		DispatchKeyValue(iEntityElectric, "beamcount_min", "40");
		DispatchKeyValue(iEntityElectric, "beamcount_max", "50");
		DispatchKeyValue(iEntityElectric, "texture", g_cSpriteSpark);
		DispatchKeyValue(iEntityElectric, "m_Color", "255 255 255");
		DispatchKeyValue(iEntityElectric, "rendercolor", "255 255 255");
		DispatchKeyValue(iEntityElectric, "thick_min", "10.0");  
		DispatchKeyValue(iEntityElectric, "thick_max", "15.0"); 
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

stock void ShookPlayer(int client)
{
	for (int i=1; i <= 10; i++)
		CreateTimer(0.1 * i, MakeThemMove, client);
}

public Action MakeThemMove(Handle hTimer, int client)
{
	if (!IsPlayerAlive(client))
		return;
	float fTempPlayerVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fTempPlayerVelocity);
	
	fTempPlayerVelocity[0] *= 0.3;
	fTempPlayerVelocity[1] *= 0.3;
	fTempPlayerVelocity[2] *= 0.3;
	fTempPlayerVelocity[0] += GetRandomInt(50, 100) * (GetRandomInt(0, 1) ? 1.0 : -1.0);
	fTempPlayerVelocity[1] += GetRandomInt(50, 100) * (GetRandomInt(0, 1) ? 1.0 : -1.0);
	fTempPlayerVelocity[2] += GetRandomInt(50, 100) * -1.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fTempPlayerVelocity);
}