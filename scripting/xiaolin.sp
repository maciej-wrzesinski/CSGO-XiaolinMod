#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <xiaolin>

#pragma semicolon					1
#pragma newdecls					required

#define WALK_SPEED					1.35
#define WALK_GRAVITY				1.0
#define JUMP_SPEED					1.6
#define JUMP_GRAVITY				0.45

#define DASH_FORCE					2000.0
#define DASH_DURATION				0.05
#define DASH_VELOCITY_AFTER			0.1
#define DASH_STAMINA				-15.37

#define RENENERATE_RATE_STAMINA		3.61
#define RENENERATE_RATE_CHI			0.2

#define MEDITATION_STAMINA_LOSS		-8.2
#define MEDITATION_CHI_GAIN			2.0

#define CHI_ORBS_ON_DEATH			4
#define CHI_ORBS_TICK_RATE			0.25
#define CHI_ORBS_SPEED				100.0
#define CHI_ORBS_DISTANCE_FLY		400.0

#define PLAYER_ARTIFACT_COOLDOWN	0.5
#define PLAYER_SPAWN_HEALTH			200

public Plugin myinfo = 
{
	name = "Xiaolin",
	author = "Maciej Vasto_Lorde Wrzesiński",
	description = "Mod that imitates phisics and features from Xiaolin Showdown TV show",
	version = "1.0",
	url = "https://go-code.pl/"
};

char g_cTips[][] = {
	"<font size='21'>Podczas skoku mozesz wykonywac <b>Zrywy</b> naciskajac klawisz SPACJA + W, S, A, D",
	"<font size='21'>Gdy naciskasz klawisz CTRL zaczynasz <b>medytowac</b> odnawiajac Energie Chi",
	"<font size='21'>Zolte swiatla na mapie to Shen Gong Wu",
	"<font size='21'>Wykonujac akrobacje w powietrzu tracisz <b>Wytrzymalosc</b>",
	"<font size='21'>Aby uzyc Shen Gong Wu, nacisnij klawisz E",
	"<font size='21'>Uwazaj! Trzymajac Shen Gong Wu powoli je tracisz!"
};

Handle g_hHUD;
Handle g_hHUDv2;
Handle g_hHUDv3;

Handle g_hOnArtifactPickup;
Handle g_hOnArtifactDropout;
Handle g_hOnArtifactUse;

//Player 
int g_iPlayerCurrentArtifact[MAX_PLAYERS+1];
bool g_bPlayerIsUsingArtifact[MAX_PLAYERS+1];
float g_fPlayerArtifactTimeCD[MAX_PLAYERS+1];
bool g_bPlayerJustTouchedTheGround[MAX_PLAYERS+1];
bool g_bPlayerJustJumped[MAX_PLAYERS+1];
bool g_bPlayerNowDashing[MAX_PLAYERS+1];
int g_iPlayerLastButtons[MAX_PLAYERS+1];
bool g_bPlayerDoUpdateOnThink[MAX_PLAYERS+1];
bool g_bPlayerInMeditation[MAX_PLAYERS+1];
int g_iPlayerEntityMeditation[MAX_PLAYERS+1];
bool g_bBlockArtifactUse[MAX_PLAYERS+1];
bool g_bBlockDashUse[MAX_PLAYERS+1];

//Bars
float g_fPlayerStaminaPercent[MAX_PLAYERS+1];
float g_fPlayerChiEnergyPercent[MAX_PLAYERS+1];
float g_fPlayerArtifactPercent[MAX_PLAYERS+1];
char g_cPredefinedBar[21][] = 
{
	"          ",
	"▄         ",
	"█         ",
	"█▄        ",
	"██        ",
	"██▄       ",
	"███       ",
	"███▄      ",
	"████      ",
	"████▄     ",
	"█████     ",
	"█████▄    ",
	"██████    ",
	"██████▄   ",
	"███████   ",
	"███████▄  ",
	"████████  ",
	"████████▄ ",
	"█████████ ",
	"█████████▄",
	"██████████"
};

#define ARTIFACTS_FILE				"addons/sourcemod/configs/shengongwu/"
#define MAX_ARTIFACT_SPAWNS			254
float g_fEntityArtifactsOrigins[MAX_ARTIFACT_SPAWNS][3];
int g_iActualNumberOfArtifactOrigins;
int g_iEntityArtifactIndexes[MAX_ARTIFACT_SPAWNS];

//dwnld
char g_cSoundJumpTable[] = "sound/xiaolin/jump1.mp3";
char g_cSoundJump[] = "cs-plugin.com/xiaolin/jump1.mp3";
char g_cSoundArtifactRetrivedTable[] = "sound/xiaolin/shengongwu1.mp3";
char g_cSoundArtifactRetrived[] = "cs-plugin.com/xiaolin/shengongwu1.mp3";
char g_cSoundArtifactLostTable[] = "sound/xiaolin/shengongwu2.mp3";
char g_cSoundArtifactLost[] = "cs-plugin.com/xiaolin/shengongwu2.mp3";

#define PLAYER_STAMINA_SOUND_AMOUNT		25.0
#define PLAYER_STAMINA_SOUND_DELAY		0.8
float g_fStaminaBreathTime[MAX_PLAYERS+1];
char g_cSoundStaminaLowTable[6][] = 
{
	"sound/xiaolin/breath1.mp3",
	"sound/xiaolin/breath2.mp3",
	"sound/xiaolin/breath3.mp3",
	"sound/xiaolin/breath4.mp3",
	"sound/xiaolin/breath5.mp3",
	"sound/xiaolin/breath6.mp3"
};

char g_cSoundStaminaLow[6][] = 
{
	"cs-plugin.com/xiaolin/breath1.mp3",
	"cs-plugin.com/xiaolin/breath2.mp3",
	"cs-plugin.com/xiaolin/breath3.mp3",
	"cs-plugin.com/xiaolin/breath4.mp3",
	"cs-plugin.com/xiaolin/breath5.mp3",
	"cs-plugin.com/xiaolin/breath6.mp3"
};

char g_cModelArtifact[5][] = 
{
	"models/player/custom_player/kuristaja/invisible_box/box.mdl",
	"models/player/custom_player/kuristaja/invisible_box/box.dx90.vtx",
	"models/player/custom_player/kuristaja/invisible_box/box.phy",
	"models/player/custom_player/kuristaja/invisible_box/box.vvd",
	"materials/models/player/kuristaja/invisible/invisible.vmt"
};

char g_cSpriteGlow[] = "materials/sprites/blueflare1.vmt";
char g_cSpriteLaser[] = "materials/sprites/laserbeam.vmt";

//artefaktowe
#define MAX_ARTIFACTS_TYPES		50
int g_iArtifactCount = 0;
char g_cArtifactNames[MAX_ARTIFACTS_TYPES][ARTIFACT_NAME_LENG];
char g_cArtifactDesc[MAX_ARTIFACTS_TYPES][ARTIFACT_DESC_LENG];
float g_fArtifactDecay[MAX_ARTIFACTS_TYPES];
int g_iArtifactTypeOfChiUsage[MAX_ARTIFACTS_TYPES];
float g_fArtifactChiUsage[MAX_ARTIFACTS_TYPES];

//natywne
float g_fPlayerBonusSpeed[MAX_PLAYERS+1];
float g_fPlayerBonusGravity[MAX_PLAYERS+1];
float g_fPlayerBonusDash[MAX_PLAYERS+1];
float g_fPlayerBonusStamina[MAX_PLAYERS+1];

//translatey
char g_cTranslateStamina[32];
char g_cTranslateChi[32];
char g_cTranslateShenGongWu[32];

#if defined ADDONS_AND_FIXES
	#include "include/xiaolin/fixesandaddons.inc"
#endif
#if defined GAME_MODES
	#include "include/xiaolin/gamemodes.inc"
#endif

public void OnPluginStart()
{
	RegAdminCmd("sm_adminmenu", AdminMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_am", AdminMenu, ADMFLAG_ROOT);
	
	RegAdminCmd("sm_drop", CmdDropArtifact, 0);
	
	HookEvent("player_death", eventDeath, EventHookMode_Post);
	
	g_hOnArtifactPickup = CreateGlobalForward("Xiaolin_OnShenGongWuPick", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnArtifactDropout = CreateGlobalForward("Xiaolin_OnShenGongWuDrop", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnArtifactUse = CreateGlobalForward("Xiaolin_OnShenGongWuUse", ET_Ignore, Param_Cell, Param_Cell);
	g_hHUD = CreateHudSynchronizer();
	g_hHUDv2 = CreateHudSynchronizer();
	g_hHUDv3 = CreateHudSynchronizer();
	CreateTimer(GAME_TICK_RATE, TimerGameTick, _, TIMER_REPEAT);
	CreateTimer(40.0, TimerShowTips, _, TIMER_REPEAT);
	
	LoadTranslations("xiaolin.phrases");
	
	Format(g_cTranslateStamina, 31, "%t", "Name_Stamina");
	Format(g_cTranslateChi, 31, "%t", "Name_Chi");
	Format(g_cTranslateShenGongWu, 31, "%t", "Name_ShenGongWu");
	
#if defined ADDONS_AND_FIXES
	OnPluginStartFixes();
#endif
#if defined GAME_MODES
	OnPluginStartGameModes();
#endif
}

public void OnConfigsExecuted()
{
	LoadArtifactsOrigins();
	SetCvar("sv_disable_show_team_select_menu", "1");	//nie pokazuje wyboru drużyn na początku
	SetCvar("mp_force_assign_teams", "1");				//wymusza by gościu był w teamie
	SetCvar("mp_force_pick_time", "0");					//i to któtko
	SetCvar("mp_freezetime", "1");						//potrzebne bo pausa się nie odpali
	SetCvar("mp_limitteams", "0");						//
	SetCvar("mp_buytime", "1");							//
	SetCvar("mp_teamname_1", "Xiaolin Adepts");			//
	SetCvar("mp_teamname_2", "Xiaolin Adepts");			//
	SetCvar("mp_warmuptime", "0");						//
	SetCvar("sv_timebetweenducks", "0");				//we like autoduck
	SetCvar("weapon_auto_cleanup_time", "1");			//auto delete weapons on ground
	SetCvar("mp_give_player_c4", "0");					//no c4
	
	SetCvar("sv_alltalk", "1"); 
	SetCvar("sv_deadtalk", "1"); 
	SetCvar("sv_full_alltalk", "1"); 
	SetCvar("sv_talk_enemy_dead", "1"); 
	SetCvar("sv_talk_enemy_living", "1"); 
	
	SetCvar("sv_enablebunnyhopping", "1"); 
	SetCvar("sv_staminamax", "0");
	SetCvar("sv_airaccelerate", "2000");
	SetCvar("sv_staminajumpcost", "0");
	SetCvar("sv_staminalandcost", "0");
	SetCvar("mp_ignore_round_win_conditions", "0");
}

public void OnMapStart()
{
	AddFileToDownloadsTable(g_cSoundJumpTable);
	PrecacheSound(g_cSoundJump);
	
	AddFileToDownloadsTable(g_cSoundArtifactRetrivedTable);
	PrecacheSound(g_cSoundArtifactRetrived);
	
	AddFileToDownloadsTable(g_cSoundArtifactLostTable);
	PrecacheSound(g_cSoundArtifactLost);
	
	for (int i = 0; i < sizeof(g_cSoundStaminaLow); i++)
	{
		AddFileToDownloadsTable(g_cSoundStaminaLowTable[i]);
		PrecacheSound(g_cSoundStaminaLow[i]);
	}
	
	for (int i = 0; i < sizeof(g_cModelArtifact); i++)
	{
		AddFileToDownloadsTable(g_cModelArtifact[i]);
		PrecacheModel(g_cModelArtifact[i]);
	}
	
	PrecacheModel(g_cSpriteGlow);
	PrecacheModel(g_cSpriteLaser);
}

public void OnMapEnd()
{
	//if (IsValidHandle(g_hHUD)) CloseHandle(g_hHUD);
	//if (IsValidHandle(g_hHUDv2)) CloseHandle(g_hHUDv2);
	g_iArtifactCount = 0;
}

public void OnPluginEnd()
{
	if (IsValidHandle(g_hHUD)) CloseHandle(g_hHUD);
	if (IsValidHandle(g_hHUDv2)) CloseHandle(g_hHUDv2);
	if (IsValidHandle(g_hHUDv3)) CloseHandle(g_hHUDv3);
	if (IsValidHandle(g_hOnArtifactPickup)) CloseHandle(g_hOnArtifactPickup);
	if (IsValidHandle(g_hOnArtifactDropout)) CloseHandle(g_hOnArtifactDropout);
	if (IsValidHandle(g_hOnArtifactUse)) CloseHandle(g_hOnArtifactUse);
	g_iArtifactCount = 0;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_iArtifactCount = 0;
	
	CreateNative("Xiaolin_RegisterShenGongWu", Native_RegisterShenGongWu);
	CreateNative("Xiaolin_ForceShenGongWuDrop", Native_ForceShenGongWuDrop);
	
	CreateNative("Xiaolin_SetPlayerBonusSpeed", Native_SetPlayerBonusSpeed);
	CreateNative("Xiaolin_SetPlayerBonusGravity", Native_SetPlayerBonusGravity);
	CreateNative("Xiaolin_SetPlayerBonusDash", Native_SetPlayerBonusDash);
	CreateNative("Xiaolin_SetPlayerBonusStamina", Native_SetPlayerBonusStamina);
	
	CreateNative("Xiaolin_UsePlayerChiEnergy", Native_UsePlayerChiEnergy);
	
	CreateNative("Xiaolin_UpdatePlayerStats", Native_UpdatePlayerStats);
	
	CreateNative("Xiaolin_BlockShenGongWuUse", Native_BlockShenGongWuUse);
	CreateNative("Xiaolin_UnblockShenGongWuUse", Native_UnblockShenGongWuUse);
	CreateNative("Xiaolin_BlockDashUse", Native_BlockDashUse);
	CreateNative("Xiaolin_UnblockDashUse", Native_UnblockDashUse);
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	ResetPlayerVars(client);
	
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SpawnPost, SpawnPost);
	
#if defined ADDONS_AND_FIXES
	OnClientPutInServerFixes(client);
#endif
}

public void OnClientDisconnect(int client)
{
	ResetPlayerVars(client);
	
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_SpawnPost, SpawnPost);
	
#if defined ADDONS_AND_FIXES
	OnClientDisconnectFixes(client);
#endif
}

public Action SpawnPost(int client)
{
	UpdatePlayerStats(client); //cuz after spawn he does not have speed
	
	g_fPlayerStaminaPercent[client] = 100.0;
	g_fPlayerChiEnergyPercent[client] = 100.0;
	
	CreateTimer(0.5, AnotherSpawn_Timer, client);
	
	PlayerArtifactDrop(client);
}

public Action AnotherSpawn_Timer(Handle hTimer, int client)
{
	if (IsThisAPlayer(client) && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityHealth(client, PLAYER_SPAWN_HEALTH);
		StripPlayerWeaponsAll(client);
		GivePlayerStandardWeapons(client);
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action OnPreThink(int client)
{
	if (IsPlayerAlive(client))
	{
		int iClientButtons = GetClientButtons(client);
		int iClientFlags = GetEntityFlags(client);
		if (iClientFlags & FL_ONGROUND)
		{
			if (g_bPlayerJustTouchedTheGround[client] || g_bPlayerDoUpdateOnThink[client])
			{
				g_bPlayerJustTouchedTheGround[client] = false;
				g_bPlayerJustJumped[client] = true;
				g_bPlayerDoUpdateOnThink[client] = false;
				SetPlayerSpeed(client, NEVER_END, WALK_SPEED, REPLACE_PROPERTY);
				SetPlayerGravity(client, NEVER_END, WALK_GRAVITY, REPLACE_PROPERTY);
			}
		}
		else
		{
			if ((g_bPlayerJustJumped[client] || g_bPlayerDoUpdateOnThink[client]))
			{
				g_bPlayerJustTouchedTheGround[client] = true;
				g_bPlayerJustJumped[client] = false;
				g_bPlayerDoUpdateOnThink[client] = false;
				EmitSoundToAllAliveWithinDistance(g_cSoundJump, client);
				SetPlayerSpeed(client, NEVER_END, JUMP_SPEED, REPLACE_PROPERTY);
				SetPlayerGravity(client, NEVER_END, JUMP_GRAVITY, REPLACE_PROPERTY);
				UpdatePlayerPercentStamina(client, DASH_STAMINA/2.0);
			}
			else//w else bo nie chcemy by od razu po skoku się zrobił
			{
				if (iClientButtons & IN_JUMP && !(g_iPlayerLastButtons[client] & IN_JUMP) && !g_bPlayerNowDashing[client] && !g_bBlockDashUse[client])
					if (iClientButtons & IN_FORWARD)
						PlayerStartDash(client, ANGLE_FORWARD, DASH_FORCE, DASH_DURATION);
					else if (iClientButtons & IN_BACK)
						PlayerStartDash(client, ANGLE_BACK, DASH_FORCE, DASH_DURATION);
					else if (iClientButtons & IN_MOVELEFT)
						PlayerStartDash(client, ANGLE_LEFT, DASH_FORCE, DASH_DURATION);
					else if (iClientButtons & IN_MOVERIGHT)
						PlayerStartDash(client, ANGLE_RIGHT, DASH_FORCE, DASH_DURATION);
					else
						PlayerStartDash(client, ANGLE_UP, DASH_FORCE, DASH_DURATION);
			}
		}
		
		if (iClientButtons & IN_USE && !(g_iPlayerLastButtons[client] & IN_USE))
		{
			if (g_iPlayerCurrentArtifact[client] && !g_bPlayerInMeditation[client] && !g_bBlockArtifactUse[client] && GetGameTime() > g_fPlayerArtifactTimeCD[client] + PLAYER_ARTIFACT_COOLDOWN)
			{
				g_fPlayerArtifactTimeCD[client] = GetGameTime();
				
				if (!g_bPlayerIsUsingArtifact[client] && g_fPlayerChiEnergyPercent[client] + g_fArtifactChiUsage[g_iPlayerCurrentArtifact[client]] <= 0 ) // chce wlaczyc nie ma many
				{
					g_bPlayerIsUsingArtifact[client] = false; // czyli nic nie robi
				}
				else if (!g_bPlayerIsUsingArtifact[client])// chce uzyc i ma mane
				{
					UpdatePlayerPercentChi(client, g_fArtifactChiUsage[g_iPlayerCurrentArtifact[client]]);
					Forward_OnArtifactUse(client);
					
					if (g_iArtifactTypeOfChiUsage[g_iPlayerCurrentArtifact[client]])//jeśli cały czas używa
						g_bPlayerIsUsingArtifact[client] = true;
				}
				else // wylacza
				{
					Forward_OnArtifactUse(client);
					g_bPlayerIsUsingArtifact[client] = false;
				}
			}
		}
		
		if (iClientFlags & FL_ONGROUND && iClientButtons & IN_DUCK && !(g_iPlayerLastButtons[client] & IN_DUCK) && g_fPlayerStaminaPercent[client] + MEDITATION_STAMINA_LOSS > 0 && g_fPlayerChiEnergyPercent[client] < 100.0)
		{
			if (!g_bPlayerInMeditation[client])
			{
				PlayerStartMeditation(client);
			}
			else
			{
				PlayerStopMeditation(client);
			}
		}
		
		if ((g_bPlayerInMeditation[client] && g_fPlayerStaminaPercent[client] < 1.0) || (g_bPlayerInMeditation[client] && g_fPlayerChiEnergyPercent[client] > 99.0))
		{
			PlayerStopMeditation(client);
		}
		
		g_iPlayerLastButtons[client] = iClientButtons;
	}
	return Plugin_Continue;
}

public void OnStartTouchArtifact(int entity, int client)
{ 
	if (!IsThisAPlayer(client) || !IsPlayerAlive(client))
	{
		//float fVelocity[3];
		//fVelocity[2] = 300.0;
		//TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVelocity);
		return;
	}
	
	PlayerArtifactPickup(client, GetRandomInt(1, g_iArtifactCount));
	
	DeleteSingleExistingArtifact(entity);
}

public int OnStartTouchChi(int entity, int client)
{ 
	if (!IsThisAPlayer(client) || !IsPlayerAlive(client) || !IsValidEntity(entity))
		return;
	
	char cTempEntityName[16];
	GetEdictClassname(entity, cTempEntityName, 15);
	DeleteSingleExistingChi(entity);
	ReplaceString(cTempEntityName, 15, "Chi", "", true);
	
	UpdatePlayerPercentChi(client, StringToInt(cTempEntityName)+0.0);
}

public Action TimerGameTick(Handle hTimer)
{
	for (int client = 1; client <= MAX_PLAYERS; ++client)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
#if defined CHEATS
			UpdatePlayerPercentStamina(client, 100.0);
			UpdatePlayerPercentChi(client, 100.0);
			UpdatePlayerPercentArtifact(client, 100.0);
#endif
		
			//Stamina regen
			UpdatePlayerPercentStamina(client, RENENERATE_RATE_STAMINA*g_fPlayerBonusStamina[client]);
			//Chi regen
			UpdatePlayerPercentChi(client, RENENERATE_RATE_CHI);
			
			//Stamina sound
			if (g_fPlayerStaminaPercent[client] < PLAYER_STAMINA_SOUND_AMOUNT && GetGameTime() > g_fStaminaBreathTime[client] + PLAYER_STAMINA_SOUND_DELAY)
			{
				g_fStaminaBreathTime[client] = GetGameTime();
				EmitSoundToClient(client, g_cSoundStaminaLow[GetRandomInt(0, sizeof(g_cSoundStaminaLow)-1)]);
			}
			//ArtifactDuration
			if (g_iPlayerCurrentArtifact[client])
				UpdatePlayerPercentArtifact(client, g_fArtifactDecay[g_iPlayerCurrentArtifact[client]]);
			
			//Artifact Chi usage
			if (g_bPlayerIsUsingArtifact[client])
				UpdatePlayerPercentChi(client, g_fArtifactChiUsage[g_iPlayerCurrentArtifact[client]]);
			
			//block usage cuz Chi
			if (g_bPlayerIsUsingArtifact[client] && g_fPlayerChiEnergyPercent[client] + g_fArtifactChiUsage[g_iPlayerCurrentArtifact[client]] <= 0)
			{
				g_bPlayerIsUsingArtifact[client] = false;
				Forward_OnArtifactUse(client);
			}
			
			if (g_bPlayerInMeditation[client])
			{
				UpdatePlayerPercentChi(client, MEDITATION_CHI_GAIN);
				UpdatePlayerPercentStamina(client, MEDITATION_STAMINA_LOSS);
			}
			
			//HUD
			char cTempFormatText[256];
			int iTempArrayNumber = RoundFloat(g_fPlayerStaminaPercent[client]/5.0);
			Format(cTempFormatText, 255, "%s: %s %.2f%", g_cTranslateStamina, g_cPredefinedBar[iTempArrayNumber], g_fPlayerStaminaPercent[client]);
			SetHudTextParams(0.4, 0.1, GAME_TICK_RATE+0.02, 47, 105, 64, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHUD, cTempFormatText);
			
			//HUD2
			iTempArrayNumber = RoundFloat(g_fPlayerChiEnergyPercent[client]/5.0);
			Format(cTempFormatText, 255, "\n\n%s: %s %.2f%", g_cTranslateChi, g_cPredefinedBar[iTempArrayNumber], g_fPlayerChiEnergyPercent[client]);
			SetHudTextParams(0.4, 0.1, GAME_TICK_RATE+0.02, 37, 60, 176, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHUDv2, cTempFormatText);
			
			//HUD3
			if (g_iPlayerCurrentArtifact[client])
			{
				iTempArrayNumber = RoundFloat(g_fPlayerArtifactPercent[client]/5.0);
				Format(cTempFormatText, 255, "\n\n\n\n%s: %s %.2f%", g_cTranslateShenGongWu, g_cPredefinedBar[iTempArrayNumber], g_fPlayerArtifactPercent[client]);
				SetHudTextParams(0.4, 0.1, GAME_TICK_RATE+0.02, 253, 250, 117, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, g_hHUDv3, cTempFormatText);
			}
		}
	}
}

public Action TimerShowTips(Handle timer)
{
	for(int i = 1; i <= MAX_PLAYERS; i++)
		
		if(IsThisAPlayer(i) && IsClientInGame(i))
			
			PrintHintText(i, g_cTips[GetRandomInt(0, sizeof(g_cTips)-1)]);
}

public Action CmdDropArtifact(int client, int args)
{
	PlayerArtifactDrop(client);
}

public Action SpawnChi(int client, int args)
{
	SpawnChiOrbs(client);
}

public Action eventDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SpawnChiOrbs(client);
	PlayerArtifactDrop(client);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Menus
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action AdminMenu(int client, int args)
{
	char temptext[64];
	Handle hMenu = CreateMenu(AdminMenuHandle);
	Format(temptext, 63, "%t", "Name_AdminMenu");
	SetMenuTitle(hMenu, temptext);
	
	Format(temptext, 63, "%t", "Name_AdminMenu_SetSGW");
	AddMenuItem(hMenu, temptext, temptext);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int AdminMenuHandle(Handle hMenu, MenuAction action, int client, int choose)
{
	if (action == MenuAction_End)
	{
		if (IsValidHandle(hMenu)) CloseHandle(hMenu);
	}
	else if (action == MenuAction_Select)
	{
		if (IsValidHandle(hMenu)) CloseHandle(hMenu);
		switch (choose)
		{
			case 0:
			{
				AdminArtifactsMenu(client);
			}
		}
	}
}

public Action AdminArtifactsMenu(int client)
{
	char temptext[64];
	Handle hMenu = CreateMenu(AdminArtifactsHandle);
	Format(temptext, 63, "%t", "Name_AdminMenuSGW");
	SetMenuTitle(hMenu, temptext);
	
	Format(temptext, 63, "%t", "Name_AdminMenuSGW_NewPlace");
	AddMenuItem(hMenu, temptext, temptext);
	Format(temptext, 63, "%t", "Name_AdminMenuSGW_Spawn");
	AddMenuItem(hMenu, temptext, temptext);
	Format(temptext, 63, "%t", "Name_AdminMenuSGW_Reload");
	AddMenuItem(hMenu, temptext, temptext);
	Format(temptext, 63, "%t", "Name_AdminMenuSGW_DeleteFromMap");
	AddMenuItem(hMenu, temptext, temptext);
	Format(temptext, 63, "%t", "Name_AdminMenuSGW_DeleteFromFile");
	AddMenuItem(hMenu, temptext, temptext);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int AdminArtifactsHandle(Handle hMenu, MenuAction action, int client, int choose)
{
	if (action == MenuAction_End)
	{
		if (IsValidHandle(hMenu)) CloseHandle(hMenu);
		AdminMenu(client, 0);
	}
	else if (action == MenuAction_Cancel)
	{
		AdminMenu(client, 0);
	}
	else if (action == MenuAction_Select)
	{
		if (IsValidHandle(hMenu)) CloseHandle(hMenu);
		switch (choose)
		{
			case 0:
			{
				SaveNewArtifact(client);
				AdminArtifactsMenu(client);
			}
			case 1:
			{
				SpawnArtifacts(-1);
				AdminArtifactsMenu(client);
				PrintToChat(client, "%t", "Chat_SpawnedSGW");
			}
			case 2:
			{
				LoadArtifactsOrigins();
				AdminArtifactsMenu(client);
				PrintToChat(client, "%t", "Chat_ReloadSGW");
			}
			case 3:
			{
				DeleteExistingArtifacts();
				AdminArtifactsMenu(client);
				PrintToChat(client, "%t", "Chat_DeleteMapSGW");
			}
			case 4:
			{
				DeleteArtifactsFile(client);
				AdminArtifactsMenu(client);
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Forwards
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock void Forward_OnArtifactUse(int client)
{
	Call_StartForward(g_hOnArtifactUse);
	Call_PushCell(client);
	Call_PushCell(g_iPlayerCurrentArtifact[client]);
	Call_Finish();
}

stock void Forward_OnArtifactDropout(int client)
{
	Call_StartForward(g_hOnArtifactDropout);
	Call_PushCell(client);
	Call_PushCell(g_iPlayerCurrentArtifact[client]);
	Call_Finish();
}

stock void Forward_OnArtifactPickup(int client, int artifact_index)
{
	Call_StartForward(g_hOnArtifactPickup);
	Call_PushCell(client);
	Call_PushCell(artifact_index);
	Call_Finish();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Natives
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public int Native_RegisterShenGongWu(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 5)
	{
		LogError("Native_RegisterShenGongWu param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	if (g_iArtifactCount >= MAX_ARTIFACTS_TYPES)
	{
		LogError("Native_RegisterShenGongWu Shen Gong Wu count is higher than MAX_ARTIFACTS_TYPES (%d)!", MAX_ARTIFACTS_TYPES);
		return -1;
	}
	
	if (g_iArtifactCount > 0 && g_fArtifactDecay[0] != -987364.0) //zabezpieczenie, by się resetowały co mapę
	{
		g_iArtifactCount = 0;
	}
	
	g_fArtifactDecay[0] = -987364.0;
	
	++g_iArtifactCount;
	
	char cTempName[ARTIFACT_NAME_LENG];
	GetNativeString(1, cTempName, sizeof(cTempName));
	char cTempDesc[ARTIFACT_DESC_LENG];
	GetNativeString(2, cTempDesc, sizeof(cTempDesc));
	
	
	strcopy(g_cArtifactNames[g_iArtifactCount], ARTIFACT_NAME_LENG-1, cTempName);
	strcopy(g_cArtifactDesc[g_iArtifactCount], ARTIFACT_DESC_LENG-1, cTempDesc);
	g_fArtifactDecay[g_iArtifactCount] = view_as<float>(GetNativeCell(3))*-1.0;
	g_iArtifactTypeOfChiUsage[g_iArtifactCount] = GetNativeCell(4);
	g_fArtifactChiUsage[g_iArtifactCount] = view_as<float>(GetNativeCell(5))*-1.0;
	
	LogError("Shen Gong Wu: '%s'(%d) loaded successfully with %i params", cTempName, g_iArtifactCount, iParamsNum);
	
	return g_iArtifactCount;
}

public int Native_ForceShenGongWuDrop(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_ForceShenGongWuDrop param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		PlayerArtifactDrop(client);
	
	return 1;
}

public int Native_SetPlayerBonusSpeed(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 2)
	{
		LogError("Native_SetPlayerBonusSpeed param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	
	if (IsClientInGame(client))
		g_fPlayerBonusSpeed[client] += amount;
	
	return 1;
}

public int Native_SetPlayerBonusGravity(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 2)
	{
		LogError("Native_SetPlayerBonusGravity param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	
	if (IsClientInGame(client))
		g_fPlayerBonusGravity[client] += amount;
	
	return 1;
}

public int Native_SetPlayerBonusDash(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 2)
	{
		LogError("Native_SetPlayerBonusDash param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	
	if (IsClientInGame(client))
		g_fPlayerBonusDash[client] += amount;
	
	return 1;
}

public int Native_SetPlayerBonusStamina(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 2)
	{
		LogError("Native_SetPlayerBonusStamina param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	
	if (IsClientInGame(client))
		g_fPlayerBonusStamina[client] += amount;
	
	return 1;
}

public int Native_UsePlayerChiEnergy(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 2)
	{
		LogError("Native_UsePlayerChiEnergy param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	
	if (IsClientInGame(client))
		UpdatePlayerPercentChi(client, amount);
	
	return 1;
}

public int Native_UpdatePlayerStats(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_UpdatePlayerStats param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		UpdatePlayerStats(client);
	
	return 1;
}

public int Native_BlockShenGongWuUse(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_BlockShenGongWuUse param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		g_bBlockArtifactUse[client] = true;
	
	return 1;
}

public int Native_UnblockShenGongWuUse(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_UnblockShenGongWuUse param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		g_bBlockArtifactUse[client] = false;
	
	return 1;
}

public int Native_BlockDashUse(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_BlockDashUse param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		g_bBlockDashUse[client] = true;
	
	return 1;
}

public int Native_UnblockDashUse(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_UnblockDashUse param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		g_bBlockDashUse[client] = false;
	
	return 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Stocks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock void ResetPlayerVars(int client)
{
	g_bPlayerJustTouchedTheGround[client] = true;
	g_bPlayerJustJumped[client] = false;
	g_fPlayerArtifactTimeCD[client] = 0.0;
	g_bPlayerDoUpdateOnThink[client] = false;
	g_iPlayerCurrentArtifact[client] = 0;
	g_bPlayerIsUsingArtifact[client] = false;
	g_bPlayerInMeditation[client] = false;
	g_bBlockArtifactUse[client] = false;
	g_bBlockDashUse[client] = false;
	
	g_fPlayerBonusSpeed[client] = 0.0;
	g_fPlayerBonusGravity[client] = 0.0;
	g_fPlayerBonusDash[client] = 0.0;
	g_fPlayerBonusStamina[client] = 1.0;
	
	g_fPlayerStaminaPercent[client] = 100.0;
	g_fPlayerChiEnergyPercent[client] = 100.0;
}

stock void PlayerStartMeditation(int client)
{
	float fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	char fTempNameOfEntity[64];
	Format(fTempNameOfEntity, 63, "Meditation%i", client);
	
	int iEntityMainMeditation = CreateEntitySafe("func_rotating");
	
	if (iEntityMainMeditation != -1 && IsValidEntity(iEntityMainMeditation))
	{
		DispatchKeyValueVector(iEntityMainMeditation, "origin", fPlayerOrigin);
		DispatchKeyValue(iEntityMainMeditation, "targetname", fTempNameOfEntity);
		DispatchKeyValue(iEntityMainMeditation, "renderfx", "0");
		DispatchKeyValue(iEntityMainMeditation, "rendermode", "0");
		DispatchKeyValue(iEntityMainMeditation, "renderamt", "255");
		DispatchKeyValue(iEntityMainMeditation, "rendercolor", "255 255 255"); 
		DispatchKeyValue(iEntityMainMeditation, "maxspeed", "400");
		DispatchKeyValue(iEntityMainMeditation, "friction", "20");
		DispatchKeyValue(iEntityMainMeditation, "dmg", "0");
		DispatchKeyValue(iEntityMainMeditation, "solid", "0");
		DispatchKeyValue(iEntityMainMeditation, "spawnflags", "64");
		DispatchSpawn(iEntityMainMeditation);
		
		fPlayerOrigin[0] += 26.0; 
		
		int iTempMaxSprites = 6;
		int iTempMaxHeight = 80;
		
		for (int i = 0; i < iTempMaxSprites; i++)
		{
			if (!IsValidEntity(iEntityMainMeditation))
				break;
			fPlayerOrigin[2] += iTempMaxHeight/iTempMaxSprites;
			int iEntitySpriteMeditation = CreateEntitySafe("env_spritetrail");
			if (iEntitySpriteMeditation != -1 && IsValidEntity(iEntitySpriteMeditation))
			{
				DispatchKeyValueVector(iEntitySpriteMeditation, "origin", fPlayerOrigin);
				DispatchKeyValue(iEntitySpriteMeditation, "lifetime", "1");
				DispatchKeyValue(iEntitySpriteMeditation, "startwidth", "0.5");
				DispatchKeyValue(iEntitySpriteMeditation, "endwidth", "0.5");
				DispatchKeyValue(iEntitySpriteMeditation, "spritename", "materials/sprites/laserbeam.vmt");
				DispatchKeyValue(iEntitySpriteMeditation, "rendermode", "1");
				DispatchKeyValue(iEntitySpriteMeditation, "rendercolor", "60 176 255");
				DispatchKeyValue(iEntitySpriteMeditation, "renderamt", "255");
				DispatchSpawn(iEntitySpriteMeditation);
				SetVariantString(fTempNameOfEntity);
				AcceptEntityInput(iEntitySpriteMeditation, "SetParent");
				AcceptEntityInput(iEntitySpriteMeditation, "ShowSprite");
			}
		}
		AcceptEntityInput(iEntityMainMeditation, "Start");
	}
	
	g_iPlayerEntityMeditation[client] = iEntityMainMeditation;
	
	PrintToChat(client, "%t", "Chat_MeditateStart");
	g_bPlayerInMeditation[client] = true;
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	if (g_bPlayerIsUsingArtifact[client])
	{
		Forward_OnArtifactUse(client);
		g_bPlayerIsUsingArtifact[client] = false;
	}
}

stock void PlayerStopMeditation(int client)
{
	if (IsValidEntity(g_iPlayerEntityMeditation[client]))
	{
		RemoveEdict(g_iPlayerEntityMeditation[client]);
	}
	PrintToChat(client, "%t", "Chat_MeditateStop");
	g_bPlayerInMeditation[client] = false;
	SetEntityMoveType(client, MOVETYPE_WALK);
}

stock void SpawnChiOrbs(int client)
{
	float fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	
	for (int i = 0; i < CHI_ORBS_ON_DEATH; i++)
	{
		float fTempChiOrigin[3];
		fTempChiOrigin[0] = fPlayerOrigin[0] + GetRandomInt(20, 70) * (GetRandomInt(0,1) ? 1.0 : -1.0);
		fTempChiOrigin[1] = fPlayerOrigin[1] + GetRandomInt(20, 70) * (GetRandomInt(0,1) ? 1.0 : -1.0);
		fTempChiOrigin[2] = fPlayerOrigin[2] + GetRandomInt(10, 50);
		int iEntityChiMain = CreateEntitySafe("generic_actor");
		if (iEntityChiMain != -1 && IsValidEntity(iEntityChiMain))
		{
			DispatchKeyValue(iEntityChiMain, "model", g_cModelArtifact[0]);
			char cTeampChiName[64];
			Format(cTeampChiName, 63, "Chi%i", RoundFloat((g_fPlayerChiEnergyPercent[client]*0.75 + 25.0)/CHI_ORBS_ON_DEATH));
			//DispatchKeyValue(iEntityChiMain, "targetname", cTeampChiName);
			DispatchKeyValue(iEntityChiMain, "classname", cTeampChiName);
			DispatchKeyValue(iEntityChiMain, "hull_name", "TINY_HULL");
			DispatchKeyValue(iEntityChiMain, "spawnflags", "4");
			DispatchKeyValueVector(iEntityChiMain, "Origin", fTempChiOrigin);
			DispatchSpawn(iEntityChiMain);
			SDKHook(iEntityChiMain, SDKHook_StartTouch, OnStartTouchChi);
			
			for (int j = 0; j < 2; j++)
			{
				int iEntityChiSprite = CreateEntitySafe("env_sprite");
				if (iEntityChiSprite != -1 && IsValidEntity(iEntityChiSprite))
				{
					DispatchKeyValue(iEntityChiSprite, "model", g_cSpriteGlow);
					//DispatchKeyValue(iEntityChiSprite, "targetname", "Chi");
					DispatchKeyValue(iEntityChiSprite, "classname", "Chi");
					DispatchKeyValue(iEntityChiSprite, "spawnflags", "1");
					DispatchKeyValue(iEntityChiSprite, "scale", "0.2");
					DispatchKeyValue(iEntityChiSprite, "rendermode", "3");
					DispatchKeyValue(iEntityChiSprite, "RenderAmt", "255"); 
					DispatchKeyValue(iEntityChiSprite, "rendercolor", "60 176 255");
					DispatchKeyValueVector(iEntityChiSprite, "Origin", fTempChiOrigin);
					DispatchSpawn(iEntityChiSprite);
					SetVariantString("!activator");
					AcceptEntityInput(iEntityChiSprite, "SetParent", iEntityChiMain);
				}
			}
			SetEntityMoveType(iEntityChiMain, MOVETYPE_FLY);
			float fVelocity[3];
			fVelocity[2] = -10.0;
			TeleportEntity(iEntityChiMain, NULL_VECTOR, NULL_VECTOR, fVelocity);
			CreateTimer(CHI_ORBS_TICK_RATE+1.0, ChiMove_Timer, iEntityChiMain);
			SDKHooks_TakeDamage(iEntityChiMain, 0, 0, 10.0); // hitbox fix????
			
		}
	}
}

public Action ChiMove_Timer(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	float fNearestDistance = 9999999.0;
	int iNearestPlayer = 0;
	for (int i = 1; i < MAX_PLAYERS; i++)
	{
		if (!IsThisAPlayer(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		float fTempDistance = GetEntitesDistance(entity, i);
		
		if (fTempDistance < fNearestDistance)
		{
			fNearestDistance = fTempDistance;
			iNearestPlayer = i;
		}
	}
	
	if (fNearestDistance < CHI_ORBS_DISTANCE_FLY && IsThisAPlayer(iNearestPlayer))
	{
		float fOriginEntity[3], fOriginPlayer[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOriginEntity);
		GetEntPropVector(iNearestPlayer, Prop_Send, "m_vecOrigin", fOriginPlayer);
		fOriginPlayer[2] += 60.0;
		
		float fVelocity[3];
		SubtractVectors(fOriginPlayer, fOriginEntity, fVelocity);
		NormalizeVector(fVelocity, fVelocity);
		ScaleVector(fVelocity, CHI_ORBS_SPEED);
		
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	else
	{
		float fVelocity[3];
		fVelocity[2] = -10.0;
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	CreateTimer(CHI_ORBS_TICK_RATE, ChiMove_Timer, entity);
}

stock float GetEntitesDistance(int entity1, int entity2)
{
	float fOrigin1[3], fOrigin2[3];
	GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", fOrigin1);
	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", fOrigin2);
	
	return GetVectorDistance(fOrigin1, fOrigin2);
}

stock void PlayerArtifactDrop(int client)
{
	if (g_iPlayerCurrentArtifact[client])
	{
		if (g_bPlayerIsUsingArtifact[client])
		{
			Forward_OnArtifactUse(client);
			g_bPlayerIsUsingArtifact[client] = false;
		}
		
		Forward_OnArtifactDropout(client);
		
		EmitSoundToClient(client, g_cSoundArtifactLost);
		
		g_iPlayerCurrentArtifact[client] = 0;
	}
}

stock void PlayerArtifactPickup(int client, int artifact_index)
{
	PlayerArtifactDrop(client);
	
	Handle data = CreateDataPack();
	WritePackCell(data, client);
	WritePackCell(data, artifact_index);
	
	CreateTimer(0.4, PlayerArtifactPickup_Timer, data); // bugfix cuz forwards didn't catch up (XD Increased to 0.4 cuz server lags XD)
}

public Action PlayerArtifactPickup_Timer(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int artifact_index = ReadPackCell(data);
	CloseHandle(data);
	
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		EmitSoundToClient(client, g_cSoundArtifactRetrived);
		
		g_iPlayerCurrentArtifact[client] = artifact_index;
		UpdatePlayerPercentArtifact(client, 100.0);
		
		Forward_OnArtifactPickup(client, artifact_index);
	}
}

stock void UpdatePlayerStats(int client)
{
	g_bPlayerDoUpdateOnThink[client] = true;
	//SetPlayerSpeed(client, NEVER_END, GetPlayerSpeed(client)+g_fPlayerBonusSpeed[client], REPLACE_PROPERTY);
	//SetPlayerGravity(client, NEVER_END, GetPlayerGravity(client)+g_fPlayerBonusGravity[client], REPLACE_PROPERTY);
}

stock void DeleteExistingArtifacts()
{
	for (int i = 0; i < g_iActualNumberOfArtifactOrigins; i++)
	{
		DeleteSingleExistingArtifact(g_iEntityArtifactIndexes[i]);
		g_iEntityArtifactIndexes[i] = -1;
	}
}

stock void DeleteSingleExistingArtifact(int entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchArtifact);
		RemoveEdict(entity);
	}
}

stock void DeleteSingleExistingChi(int entity)
{
	if (entity > MAX_PLAYERS && IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchChi);
		RemoveEdict(entity);
	}
}

stock void DeleteArtifactsFile(int client)
{
	char cCurrentMap[64];
	char cFilePath[128];
	GetCurrentMap(cCurrentMap, 63);
	
	Format(cFilePath, 127, "%s%s.ini", ARTIFACTS_FILE, cCurrentMap);
	
	if (FileExists(cFilePath))
	{
		DeleteFile(cFilePath);
		PrintToChat(client, "%t", "Chat_DeleteFileSGW");
	}
	else
		PrintToChat(client, "%t %s.", "Chat_DeleteErrorSGW", cFilePath);
}

stock void SaveNewArtifact(int client)
{
	char cCurrentMap[64];
	char cFilePath[128];
	GetCurrentMap(cCurrentMap, 63);
	
	Format(cFilePath, 127, "%s%s.ini", ARTIFACTS_FILE, cCurrentMap);
	
	float fPlayerOrigin[3];
	char cTempReadLine[128];
	GetClientAbsOrigin(client, fPlayerOrigin);
	
	Format(cTempReadLine, 127, "%f %f %f", fPlayerOrigin[0], fPlayerOrigin[1], fPlayerOrigin[2]);
	
	Handle hFile = OpenFile(cFilePath, "a+");
	WriteFileLine(hFile, "%s", cTempReadLine);
	CloseHandle(hFile);
	
	PrintToChat(client, "%t", "Chat_NewSGW");
}

stock void SpawnArtifacts(int amount = -1)
{
	if (amount == -1)
		for (int i = 0; i < g_iActualNumberOfArtifactOrigins; i++){
			SpawnAnArtifact(i);
		}
	else
	{
		int chosen = 0;
		for (int i = 0; i < amount; i++){
			chosen = chosen == GetRandomInt(0, g_iActualNumberOfArtifactOrigins-1) ? GetRandomInt(1, g_iActualNumberOfArtifactOrigins-2) : GetRandomInt(0, g_iActualNumberOfArtifactOrigins-1);
			SpawnAnArtifact(chosen);
		}
	}
}

stock void SpawnAnArtifact(int artifact_id)
{
	int iEntityArtifactMain = CreateEntitySafe("generic_actor");
	if (iEntityArtifactMain != -1 && IsValidEntity(iEntityArtifactMain))
	{
		DispatchKeyValue(iEntityArtifactMain, "model", g_cModelArtifact[0]);
		//DispatchKeyValue(iEntityArtifactMain, "targetname", "Artifact");
		DispatchKeyValue(iEntityArtifactMain, "classname", "Artifact");
		DispatchKeyValue(iEntityArtifactMain, "hull_name", "TINY_HULL");
		DispatchKeyValue(iEntityArtifactMain, "solid", "2");
		DispatchKeyValue(iEntityArtifactMain, "scale", "0.1");
		DispatchKeyValue(iEntityArtifactMain, "spawnflags", "4");
		DispatchKeyValueVector(iEntityArtifactMain, "Origin", g_fEntityArtifactsOrigins[artifact_id]);
		DispatchSpawn(iEntityArtifactMain);
		SDKHook(iEntityArtifactMain, SDKHook_StartTouch, OnStartTouchArtifact);
		g_iEntityArtifactIndexes[artifact_id] = iEntityArtifactMain;
		
		for (int j = 0; j < 2; j++)
		{
			int iEntityArtifactSprite = CreateEntitySafe("env_sprite");
			if (iEntityArtifactSprite != -1 && IsValidEntity(iEntityArtifactSprite))
			{
				DispatchKeyValue(iEntityArtifactSprite, "model", g_cSpriteGlow);
				//DispatchKeyValue(iEntityArtifactSprite, "targetname", "Artifact");
				DispatchKeyValue(iEntityArtifactSprite, "classname", "ArtifactSprite");
				DispatchKeyValue(iEntityArtifactSprite, "spawnflags", "1");
				DispatchKeyValue(iEntityArtifactSprite, "scale", "0.5");
				DispatchKeyValue(iEntityArtifactSprite, "rendermode", "3");
				DispatchKeyValue(iEntityArtifactSprite, "RenderAmt", "255"); 
				DispatchKeyValue(iEntityArtifactSprite, "rendercolor", "253 250 117");
				DispatchKeyValueVector(iEntityArtifactSprite, "Origin", g_fEntityArtifactsOrigins[artifact_id]);
				DispatchSpawn(iEntityArtifactSprite);
				SetVariantString("!activator");
				AcceptEntityInput(iEntityArtifactSprite, "SetParent", iEntityArtifactMain);
			}
		}
		
		SetEntityMoveType(iEntityArtifactMain, MOVETYPE_FLY);
		float fVelocity[3];
		fVelocity[2] = 100.0;
		TeleportEntity(iEntityArtifactMain, NULL_VECTOR, NULL_VECTOR, fVelocity);
		CreateTimer(2.0, ArtifactMoveDown_Timer, iEntityArtifactMain);
	}
}

public Action ArtifactMoveDown_Timer(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	float fEntityVelocity[3];
	fEntityVelocity[2] = -100.0;
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fEntityVelocity);
	
	CreateTimer(2.0, ArtifactMoveUp_Timer, entity);
}

public Action ArtifactMoveUp_Timer(Handle hTimer, int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	float fEntityVelocity[3];
	fEntityVelocity[2] = 100.0;
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fEntityVelocity);
	
	CreateTimer(2.0, ArtifactMoveDown_Timer, entity);
}

stock void LoadArtifactsOrigins()
{
	char cCurrentMap[64];
	char cFilePath[128];
	char cTempReadLine[128];
	GetCurrentMap(cCurrentMap, 63);
	
	Format(cFilePath, 127, "%s%s.ini", ARTIFACTS_FILE, cCurrentMap);
	
	if (!FileExists(cFilePath))
	{
		Handle hFile = OpenFile(cFilePath, "w");
		CloseHandle(hFile);
	}
	
	g_iActualNumberOfArtifactOrigins = 0;
	if (FileSize(cFilePath) > 0)
	{
		Handle hFile = OpenFile(cFilePath, "a+");
		
		int i = 0;
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, cTempReadLine, 127) && i < MAX_ARTIFACT_SPAWNS)
		{
			if (!StrEqual(cTempReadLine, ""))
			{
				char cTempOrigins[3][16];
				ExplodeString(cTempReadLine, " ", cTempOrigins, 3, 15);
				for (int j = 0; j < 3; ++j)
					g_fEntityArtifactsOrigins[i][j] = StringToFloat(cTempOrigins[j]);
			}
			++i;
		}
		g_iActualNumberOfArtifactOrigins = i;
		CloseHandle(hFile);
	}
}

stock void PlayerStartDash(int client, float angle, float force, float duration)
{
	if (g_fPlayerStaminaPercent[client] < DASH_STAMINA*-1.0)
		return;
	if (duration+g_fPlayerBonusDash[client] < 0.0)
		return;
	if (g_bPlayerNowDashing[client])
		return;
	
	UpdatePlayerPercentStamina(client, DASH_STAMINA);
	g_bPlayerNowDashing[client] = true;
	EmitSoundToClient(client, g_cSoundJump);
	float playerNewVelocity[3], playerRightVelocity[3], playerUpVelocity[3], playerOldVelocity[3];
	float playerEyeAngles[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerOldVelocity);
	GetClientEyeAngles(client, playerEyeAngles);
	if (angle != ANGLE_UP)
		playerEyeAngles[1] += angle;
	else
		playerEyeAngles[0] = -90.0; // -90 to góra this should be set because then it will always be 90 degrees up
	
	if (angle == ANGLE_BACK)//fix jeśli patrzy na dół to na górę przestawia
		playerEyeAngles[0] *= -1.0;
	if (angle == ANGLE_LEFT || angle == ANGLE_RIGHT) // fix jeśli idziemy lewo/prawo to nie ma prawa nas przenosić w górę/dół
		playerEyeAngles[0] = 0.0;
	if (angle == ANGLE_UP)
	{ // fix jeśli chcemy w górę to żeby nie na boki
		playerEyeAngles[1] = 0.0;
		playerEyeAngles[2] = 0.0;
	}
	GetAngleVectors(playerEyeAngles, playerNewVelocity, playerRightVelocity, playerUpVelocity);//uzyskuje vel z ang
	NormalizeVector(playerNewVelocity, playerNewVelocity);//normalizacja
	ScaleVector(playerNewVelocity, force);//skalowanie
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, playerNewVelocity);
	
	Handle data = CreateDataPack();
	WritePackCell(data, client);
	ScaleVector(playerNewVelocity, DASH_VELOCITY_AFTER);//skalowanie odwrotne
	WritePackFloat(data, playerNewVelocity[0]);
	WritePackFloat(data, playerNewVelocity[1]);
	WritePackFloat(data, playerNewVelocity[2]);
	
	CreateTimer(duration+g_fPlayerBonusDash[client], PlayerStopDash, data);
}

public Action PlayerStopDash(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	float vel0 = ReadPackFloat(data);
	float vel1 = ReadPackFloat(data);
	float vel2 = ReadPackFloat(data);
	CloseHandle(data);
	
	if (IsClientInGame(client))
	{
		float resetVelocity[3];
		resetVelocity[0] = vel0;
		resetVelocity[1] = vel1;
		resetVelocity[2] = vel2;
		
		g_bPlayerNowDashing[client] = false;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, resetVelocity);
	}
}

stock float GetPlayerSpeed(int client)
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

stock void SetPlayerSpeed(int client, float time, float speed, bool set)
{
	float nowspeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	float setspeed;
	
	speed += g_fPlayerBonusSpeed[client]; //bonus
	
	if (set)
		setspeed = speed<=0.0 ? 0.001 : speed;
	else
		setspeed = nowspeed+speed<=0.0 ? 0.001 : nowspeed+speed;
	
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", setspeed);
	
	if (time > 0.0)
	{
		Handle data = CreateDataPack();
		WritePackCell(data, client);
		WritePackFloat(data, speed);
		
		CreateTimer(time, DeactivateSpeed, data);
	}
}

public Action DeactivateSpeed(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	float speed = ReadPackFloat(data);
	CloseHandle(data);
	
	float nowspeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", nowspeed-speed);
}

stock float GetPlayerGravity(int client)
{
	return GetEntityGravity(client);
}

stock void SetPlayerGravity(int client, float time, float gravity, bool set)
{
	float nowgravity = GetEntityGravity(client);
	float setgravity;
	
	gravity += g_fPlayerBonusGravity[client]; //bonus
	
	if (set)
		setgravity = gravity<=0.0 ? 0.001 : gravity;
	else
		setgravity = nowgravity+gravity<=0.0 ? 0.001 : nowgravity+gravity;
	
	SetEntityGravity(client, setgravity);
	
	if (time > 0.0)
	{
		Handle data = CreateDataPack();
		WritePackCell(data, client);
		WritePackFloat(data, gravity);
		
		CreateTimer(time, DeactivateGravity, data);
	}
}

public Action DeactivateGravity(Handle hTimer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	float gravity = ReadPackFloat(data);
	CloseHandle(data);
	
	float nowgravity = GetEntityGravity(client);
	SetEntityGravity(client, nowgravity-gravity);
}

stock void UpdatePlayerPercentStamina(int client, float amount)
{
	if (amount > 0)
		g_fPlayerStaminaPercent[client] = g_fPlayerStaminaPercent[client]+amount > 100.0 ? 100.0 : g_fPlayerStaminaPercent[client]+amount;
	else
		g_fPlayerStaminaPercent[client] = g_fPlayerStaminaPercent[client]+amount < 0.1 ? 0.1 : g_fPlayerStaminaPercent[client]+amount; //cant be 0 cuz 0/x = infinity
}

stock void UpdatePlayerPercentArtifact(int client, float amount)
{
	if (amount > 0)
		g_fPlayerArtifactPercent[client] = g_fPlayerArtifactPercent[client]+amount > 100.0 ? 100.0 : g_fPlayerArtifactPercent[client]+amount;
	else
		g_fPlayerArtifactPercent[client] = g_fPlayerArtifactPercent[client]+amount < 0.1 ? 0.1 : g_fPlayerArtifactPercent[client]+amount; //cant be 0 cuz 0/x = infinity
	
	if (g_fPlayerArtifactPercent[client] <= 0.1)
		PlayerArtifactDrop(client);
}

stock void UpdatePlayerPercentChi(int client, float amount)
{
	if (amount > 0)
		g_fPlayerChiEnergyPercent[client] = g_fPlayerChiEnergyPercent[client]+amount > 100.0 ? 100.0 : g_fPlayerChiEnergyPercent[client]+amount;
	else
		g_fPlayerChiEnergyPercent[client] = g_fPlayerChiEnergyPercent[client]+amount < 0.1 ? 0.1 : g_fPlayerChiEnergyPercent[client]+amount; //cant be 0 cuz 0/x = infinity
}
