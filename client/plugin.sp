#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

public Plugin myinfo = {
	name = "Basic Team Manager",
	author = "github.com/BeepFelix",
	description = "Allows for very basic team managment using 1 simple file called \"team_setup.txt\" in the main \"sourcemod\" directory. Supports coaching and forced names for players",
	version = "1.0"
};

ConVar g_hForceAssignTeams = null;

public void OnPluginStart()
{
	RegAdminCmd("sm_force", Command_Force, ADMFLAG_KICK, "Forcefully load \"team_setup.txt\" and assign players to teams");

	AddCommandListener(Listener_Jointeam, "jointeam");
	AddCommandListener(Listener_Coach, "coach");

	HookEvent("player_connect_full", Event_PlayerConnectFull);

	g_hForceAssignTeams = FindConVar("mp_force_assign_teams");

	g_hForceAssignTeams.AddChangeHook(OnConVarChange);
}

#include "./functions/commands/force.sp"

#include "./functions/forwards/OnMapStart.sp"
#include "./functions/forwards/OnMapEnd.sp"

#include "./functions/listeners/OnConVarChange.sp"
#include "./functions/listeners/jointeam.sp"
#include "./functions/listeners/coach.sp"

#include "./functions/events/PlayerConnectFull.sp"

#include "./functions/functions.sp"
