Handle g_hTimerArtifacts;

int g_iVotesCount[2];
int g_iWinningGameMode;
char g_cGameModesNames[2][] = 
{
	"Deathmatch",					//każdy na każdego, randomowo spawnujące się SGW
	"Team Deathmatch (od 4 graczy)"				//2 drużyny, randomowo spawnujące się SGW
	//"Small Teams Deathmatch"		//3 osobowe drużyny, randomowo spawnujące się SGW
	//"King of the Shen Gong Wu",	//każdy na każdego, tylko jedno SGW losowe, kto je ma ten otrzymuje punkty
	//"The One Shen Gong Wu",		//każdy na każdego, tylko jedno SGW które ma każdy
};

#define MAX_COLORS		12 // przy 32 graczach nie da się więcej mieć 3 osobowych drużyn
int g_iClientColors[MAX_PLAYERS+1];
/*char g_cColorsNames[MAX_COLORS] = 
{
	"None",
	"Red",
	"Blue",
	"Green",
	"Yellow",
	"Cyan",
	"Pink",
	"Orange",
	"Dark Green",
	"Dark Blue",
	"Dark Red",
	"Gray"
	
};*/
int g_iColorsRGB[MAX_COLORS][3] = 
{
	{255, 255, 255},
	{255, 0, 0},
	{0, 0, 255},
	{0, 255, 0},
	{255, 255, 0},
	{0, 255, 255},
	{255, 0, 255},
	{255, 125, 0},
	{0, 75, 0},
	{0, 0, 75},
	{75, 0, 0},
	{255, 255, 255}
};
//bool g_bIsSmallTeamsOn = false;

stock void OnPluginStartGameModes()
{
	HookEvent("round_start", RoundStart);
}

stock void OnClientPutInServerGameModes(int client)
{
	
}

stock void OnClientDisconnectGameModes(int client)
{
	
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	MakeVoteOnGameMode();
	if (IsValidHandle(g_hTimerArtifacts))
		KillTimer(g_hTimerArtifacts);
}

stock void MakeVoteOnGameMode()
{
	ServerCommand("mp_pause_match");
	
	g_iVotesCount[0] = 0;
	g_iVotesCount[1] = 0;
	
	int iClientsVotersID[MAX_PLAYERS];
	int iClientsVoters = 0;
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		if (IsThisAPlayer(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientSourceTV(i))
		{
			iClientsVotersID[iClientsVoters] = i;
			++iClientsVoters;
		}
	}
	
	Handle hMenu = CreateMenu(ShowVotingMenuHandle);
	SetMenuTitle(hMenu, "Jaki ma być tryb w tej rundzie?");
	
	AddMenuItem(hMenu, g_cGameModesNames[0], g_cGameModesNames[0]);
	
	if(GetClientCount(true) < 4)
		AddMenuItem(hMenu, g_cGameModesNames[1], g_cGameModesNames[1], ITEMDRAW_DISABLED);
	else
		AddMenuItem(hMenu, g_cGameModesNames[1], g_cGameModesNames[1]);
	
	/*if(GetClientCount(true) < 6)
		AddMenuItem(hMenu, g_cGameModesNames[2], g_cGameModesNames[2], ITEMDRAW_DISABLED);
	else
		AddMenuItem(hMenu, g_cGameModesNames[2], g_cGameModesNames[2]);*/
	
	SetMenuExitButton(hMenu, false);
	SetMenuExitBackButton(hMenu, false);
	
	for(int i = 0; i < iClientsVoters; i++)
		DisplayMenu(hMenu, iClientsVotersID[i], MENU_TIME_FOREVER);
	CreateTimer(7.0, EndTheVote);
}

public int ShowVotingMenuHandle(Handle hMenu, MenuAction action, int client, int choose)
{
	if (action == MenuAction_End)
	{
		if (IsValidHandle(hMenu)) CloseHandle(hMenu);
	}
	else if (action == MenuAction_Select)
	{
		++g_iVotesCount[choose];
	}
} 

public Action EndTheVote(Handle hTimer)
{
	int iMostVotes = -1;
	g_iWinningGameMode = -1;
	for (int i = 0; i < 2; i++)
	{
		if (g_iVotesCount[i] > iMostVotes)
		{
			iMostVotes = g_iVotesCount[i];
			g_iWinningGameMode = i;
		}
	}
	
	switch(g_iWinningGameMode)
	{
		case 0:
		{
			InitDeathMatch(180.0);
		}
		case 1:
		{
			InitTeamDeathMatch(180.0);
		}
		case 2:
		{
			InitSmallTeamDeathMatch(180.0);
		}
	}
	PrintToChatAll("Trybem w tej rundzie będzie %s!", g_cGameModesNames[g_iWinningGameMode]);
}

stock void InitDeathMatch(float time)
{
	SetCvar("mp_teammates_are_enemies", "1"); 		// turn on deathmatch
	SetCvar("mp_solid_teammates", "1");				//they have to be solid cuz they are enemies
	SetCvar("mp_ignore_round_win_conditions", "1");	//dont care
	SetCvar("mp_autoteambalance", "0");				//we dont care about team balance here
	SetCvar("mp_join_grace_time", "9999999999");	//everybody can join this match
	SetCvar("mp_respawn_on_death_ct", "1");			//respawns
	SetCvar("mp_respawn_on_death_t", "1");			//everybody
	SetCvar("mp_randomspawn", "1");					//random spawns? chyba tak
	SetCvar("mp_randomspawn_dist", "1");			//random spawns? chyba tak
	SetCvar("mp_randomspawn_los", "1");				//random spawns? chyba tak
	SetCvar("mp_respawn_immunitytime", "2");		//immunity
	ServerCommand("mp_unpause_match");
	
	g_hTimerArtifacts = CreateTimer(0.1, SpawnSomeArtifacts, 30.0);
	
	SetMatchEnd(time);
}

stock void InitTeamDeathMatch(float time)
{
	SetCvar("mp_teammates_are_enemies", "0"); 		//turn off deathmatch
	SetCvar("mp_solid_teammates", "0");				//lul
	SetCvar("mp_ignore_round_win_conditions", "0");	//
	SetCvar("mp_autoteambalance", "0");				//we dont care about team balance here
	SetCvar("mp_join_grace_time", "9999999999");	//everybody can join this match
	SetCvar("mp_respawn_on_death_ct", "1");			//respawns
	SetCvar("mp_respawn_on_death_t", "1");			//everybody
	SetCvar("mp_randomspawn", "1");					//random spawns? chyba tak
	SetCvar("mp_randomspawn_dist", "1");			//random spawns? chyba tak
	SetCvar("mp_randomspawn_los", "1");				//random spawns? chyba tak
	SetCvar("mp_respawn_immunitytime", "2");		//immunity
	ServerCommand("mp_unpause_match");
	
	g_hTimerArtifacts = CreateTimer(0.1, SpawnSomeArtifacts, 30.0);
	
	SetMatchEnd(time);
}

stock void SetMatchEnd(float time)
{
	CreateTimer(time, EndMatch);
}

public Action EndMatch(Handle hTimer)
{
	PrintToChatAll("Runda %s się skończyła!", g_cGameModesNames[g_iWinningGameMode]);
	CreateTimer(5.0, MakeAnotherRound);
	ServerCommand("mp_pause_match");
}

stock void InitSmallTeamDeathMatch(float time)
{
	SetCvar("mp_teammates_are_enemies", "1"); 		//turn off deathmatch
	SetCvar("mp_solid_teammates", "1");				//lul
	SetCvar("mp_ignore_round_win_conditions", "1");	//
	SetCvar("mp_autoteambalance", "0");				//we dont care about team balance here
	SetCvar("mp_join_grace_time", "9999999999");	//everybody can join this match
	SetCvar("mp_respawn_on_death_ct", "1");			//respawns
	SetCvar("mp_respawn_on_death_t", "1");			//everybody
	SetCvar("mp_randomspawn", "1");					//random spawns? chyba tak
	SetCvar("mp_randomspawn_dist", "1");			//random spawns? chyba tak
	SetCvar("mp_randomspawn_los", "1");				//random spawns? chyba tak
	SetCvar("mp_respawn_immunitytime", "2");		//immunity
	ServerCommand("mp_unpause_match");
	
	//set the spawns of orbs
	//g_bIsSmallTeamsOn = true;
	SmallTeamDeathMatchMakeTeams();
	//stop dealing damage to them
	
	SetSmallTeamDeathMatchEnd(time);
}

stock void SmallTeamDeathMatchMakeTeams()
{
	int iClientCount = 0;
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		if (IsThisAPlayer(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientSourceTV(i))
		{
			++iClientCount;
		}
	}
	int iColorCount = RoundToCeil(iClientCount / 3.0);
	
	int iCurrentColor = 0;
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		if (IsThisAPlayer(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientSourceTV(i))
		{
			g_iClientColors[i] = iCurrentColor;
			iCurrentColor = iCurrentColor + 1 > iColorCount ? 0 : iCurrentColor + 1;
			
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, g_iColorsRGB[g_iClientColors[i]][0], g_iColorsRGB[g_iClientColors[i]][1], g_iColorsRGB[g_iClientColors[i]][2], 255);
		}
	}
}

stock void SetSmallTeamDeathMatchEnd(float time)
{
	CreateTimer(time, EndSmallTeamDeathMatch);
}

public Action EndSmallTeamDeathMatch(Handle hTimer)
{
	//g_bIsSmallTeamsOn = false;
	for (int i = 1; i <= MAX_PLAYERS; i++)
	{
		g_iClientColors[i] = 0;
		SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i, g_iColorsRGB[g_iClientColors[i]][0], g_iColorsRGB[g_iClientColors[i]][1], g_iColorsRGB[g_iClientColors[i]][2], 255);
	}
	PrintToChatAll("Runda %s się skończyła!", g_cGameModesNames[g_iWinningGameMode]);
	CreateTimer(5.0, MakeAnotherRound);
	ServerCommand("mp_pause_match");
}

public Action MakeAnotherRound(Handle hTimer)
{
	RoundEnd();
}

stock void RoundEnd()
{
	SetCvar("mp_teammates_are_enemies", "0"); 		//turn on deathmatch
	SetCvar("mp_ignore_round_win_conditions", "0");	//dont care
	SetCvar("mp_respawn_on_death_ct", "0");			//respawns
	SetCvar("mp_respawn_on_death_t", "0");			//everybody
	SetCvar("mp_randomspawn", "0");					//random spawns? chyba tak
	SetCvar("mp_randomspawn_dist", "0");			//random spawns? chyba tak
	SetCvar("mp_randomspawn_los", "0");				//random spawns? chyba tak
	SetCvar("mp_respawn_immunitytime", "0");		//immunity
	ServerCommand("mp_scrambleteams");
}

public Action SpawnSomeArtifacts(Handle hTimer, float time)
{
	int amount = GetClientCount(true) < 6 ? 2 : GetClientCount(true) / 2;
	PrintToChatAll("Pojawiły się %i nowe Shen Gong Wu!", amount);
	SpawnArtifacts(amount);
	g_hTimerArtifacts = CreateTimer(time, SpawnSomeArtifacts, time);
}

//Native
public int Native_ResetPlayerColor(Handle hPlugin, int iParamsNum)
{
	if (iParamsNum != 1)
	{
		LogError("Native_ResetPlayerColor param count is invalid(%d)!", iParamsNum);
		return -1;
	}
	
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_iColorsRGB[g_iClientColors[client]][0], g_iColorsRGB[g_iClientColors[client]][1], g_iColorsRGB[g_iClientColors[client]][2], 255);
	}
	
	return 1;
}

