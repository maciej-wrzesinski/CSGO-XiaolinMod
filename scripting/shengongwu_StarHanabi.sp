#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required
//UWAGA POTRZEBNE JESZCZE DŹWIĘK LOTU KULI I WYSTRZAŁU
public Plugin myinfo = 
{
	name = "Shen Gong Wu - Star Hanabi",
	author = "Vasto_Lorde",
	description = "Shen Gong Wu for Xiaolin",
	version = "1.0",
	url = "http://cs-plugin.com/"
};

char g_cArtifactName[ARTIFACT_NAME_LENG];
char g_cArtifactDesc[ARTIFACT_DESC_LENG];
float g_fArtifactDecay = 0.86;
float g_fArtifactChiUsage = 9.5;

int g_iArtifactIndex;
bool g_bArtifactOwner[MAX_PLAYERS+1];
bool g_bArtifactWorking[MAX_PLAYERS+1];

char g_cModelArtifact[5][] = 
{
	"models/player/custom_player/kuristaja/invisible_box/box.mdl",
	"models/player/custom_player/kuristaja/invisible_box/box.dx90.vtx",
	"models/player/custom_player/kuristaja/invisible_box/box.phy",
	"models/player/custom_player/kuristaja/invisible_box/box.vvd",
	"materials/models/player/kuristaja/invisible/invisible.vmt"
};

char g_cSpriteGlow[] = "materials/sprites/blueflare1.vmt";

char g_cSoundArtifactUse1Table[] = "sound/cs-plugin.com/xiaolin/starhanabi1.mp3";
char g_cSoundArtifactUse1[] = "cs-plugin.com/xiaolin/starhanabi1.mp3";
char g_cSoundArtifactUse2Table[] = "sound/cs-plugin.com/xiaolin/starhanabi2.mp3";
char g_cSoundArtifactUse2[] = "cs-plugin.com/xiaolin/starhanabi2.mp3";

public void OnPluginStart()
{
	LoadTranslations("xiaolin_shengongwu.phrases");
	
	Format(g_cArtifactName, ARTIFACT_NAME_LENG - 1, "%t", "Name_StarHanabi");
	Format(g_cArtifactDesc, ARTIFACT_DESC_LENG - 1, "%t", "Desc_StarHanabi");
}

public void OnMapStart()
{ 
	g_iArtifactIndex = Xiaolin_RegisterShenGongWu(g_cArtifactName, g_cArtifactDesc, g_fArtifactDecay, ARTIFACT_ON_TIME_USE, g_fArtifactChiUsage);
	
	for (int i = 0; i < 5; i++)
	{
		AddFileToDownloadsTable(g_cModelArtifact[i]);
		PrecacheModel(g_cModelArtifact[i]);
	}
	
	PrecacheModel(g_cSpriteGlow);
	
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
	g_bArtifactWorking[client] = false;
}

public void Xiaolin_OnShenGongWuDrop(int client, int artifact_index)
{
	if (artifact_index != g_iArtifactIndex)
		return;
	
	if (!g_bArtifactOwner[client])
		return;
	
	//if (g_bArtifactWorking[client])//NIE TRZEBA WYŁĄCZAĆ BO PRZECIEŻ TO ON TIME USE
	//	Xiaolin_OnShenGongWuUse(client, artifact_index);
	
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
		PrintToChat(client, "%t %s!", "SGW_Use", g_cArtifactName);
		ShootFireball(client);
		//g_bArtifactWorking[client] = true;
	}
	else
	{
		PrintToChat(client, "Poczekaj az uzyjesz %s!", g_cArtifactName);
		//g_bArtifactWorking[client] = false;
	}
}

stock void ShootFireball(int client)
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
	
	int iEntityMainFireBall = CreateEntitySafe("generic_actor");
	if (iEntityMainFireBall != -1 && IsValidEntity(iEntityMainFireBall))
	{
		DispatchKeyValue(iEntityMainFireBall, "model", g_cModelArtifact[0]);
		DispatchKeyValue(iEntityMainFireBall, "classname", "FireBall");
		DispatchKeyValue(iEntityMainFireBall, "spawnflags", "4");
		DispatchKeyValueVector(iEntityMainFireBall, "Origin", fWantedOrigin);
		DispatchSpawn(iEntityMainFireBall);
		
		int iEntityEnvSpriteFireBall = CreateEntitySafe("env_sprite");
		if (iEntityEnvSpriteFireBall != -1 && IsValidEntity(iEntityEnvSpriteFireBall))
		{
			DispatchKeyValue(iEntityEnvSpriteFireBall, "model", g_cSpriteGlow);
			DispatchKeyValue(iEntityEnvSpriteFireBall, "classname", "FireBallSprite");
			DispatchKeyValue(iEntityEnvSpriteFireBall, "spawnflags", "1");
			DispatchKeyValue(iEntityEnvSpriteFireBall, "scale", "0.3");
			DispatchKeyValue(iEntityEnvSpriteFireBall, "rendermode", "3");
			DispatchKeyValue(iEntityEnvSpriteFireBall, "RenderAmt", "255"); 
			DispatchKeyValue(iEntityEnvSpriteFireBall, "rendercolor", "255 184 43");
			DispatchKeyValue(iEntityEnvSpriteFireBall, "solid", "0");
			DispatchKeyValueVector(iEntityEnvSpriteFireBall, "Origin", fWantedOrigin);
			DispatchSpawn(iEntityEnvSpriteFireBall);
			SetVariantString("!activator");
			AcceptEntityInput(iEntityEnvSpriteFireBall, "SetParent", iEntityMainFireBall);
		}
		char cTempParticles[2][] = 
		{
			"molotov_fire01",
			"env_fire_medium"
		};
		for (int i = 0; i <= 5; i++)
		{
			if (!IsValidEntity(iEntityMainFireBall))
				break;
			int iEntityInfoParticleFireBall = CreateEntitySafe("info_particle_system");
			if (iEntityInfoParticleFireBall != -1 && IsValidEntity(iEntityInfoParticleFireBall))
			{
				DispatchKeyValue(iEntityInfoParticleFireBall, "effect_name", cTempParticles[GetRandomInt(0, 1)]);
				DispatchKeyValue(iEntityInfoParticleFireBall, "name", "FireBallFire"); 
				DispatchKeyValueVector(iEntityInfoParticleFireBall, "Origin", fWantedOrigin);
				DispatchSpawn(iEntityInfoParticleFireBall);
				SetVariantString("!activator");
				AcceptEntityInput(iEntityInfoParticleFireBall, "SetParent", iEntityMainFireBall);
				CreateTimer(0.05 * i, StartParticle, iEntityInfoParticleFireBall);
			}
		}
		
		SDKHook(iEntityMainFireBall, SDKHook_StartTouch, OnStartTouchFireball);
		SetEntityMoveType(iEntityMainFireBall, MOVETYPE_FLY);
		
		GetClientEyeAngles(client, fPlayerAngles);
		float fEntityVelocity[3];
		GetAngleVectors(fPlayerAngles, fEntityVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fEntityVelocity, 700.0); 
		TeleportEntity(iEntityMainFireBall, NULL_VECTOR, fPlayerAngles, fEntityVelocity);
		
		EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse1, iEntityMainFireBall);
	}
}

public Action StartParticle(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	AcceptEntityInput(entity, "start");
	ActivateEntity(entity);
}

public void OnStartTouchFireball(int entity, int client)
{ 
	if (!IsValidEntity(entity))
		return;
	
	EmitSoundToAllAliveWithinDistance(g_cSoundArtifactUse2, entity);
	
	if (IsThisAPlayer(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SDKHooks_TakeDamage(client, entity, entity, 5.0);
		IgniteEntity(client, 5.0, false);
	}
	
	int iEntityExplosion = CreateEntitySafe("env_explosion");
	if (iEntityExplosion != -1 && IsValidEntity(iEntityExplosion))
	{
		float fTempOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fTempOrigin);
		
		//DispatchKeyValue(iEntityExplosion, "model", g_cModelArtifact);
		DispatchKeyValue(iEntityExplosion, "classname", "FireBallExplosion");
		DispatchKeyValue(iEntityExplosion, "spawnflags", "0x00000001");
		DispatchKeyValueVector(iEntityExplosion, "Origin", fTempOrigin);
		DispatchSpawn(iEntityExplosion);
		AcceptEntityInput(iEntityExplosion, "Explode");
		AcceptEntityInput(iEntityExplosion, "Kill");
	}
	
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchFireball);
	RemoveEdict(entity);
}

