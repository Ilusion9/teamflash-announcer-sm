#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colorlib>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Flash Announcer",
    author = "Ilusion9",
    description = "Players and admins can be informed about flashes made by teammates.",
    version = "1.1",
    url = "https://github.com/Ilusion9/"
};

int g_ThrowerId;
int g_ThrowerTeam;

ConVar g_Cvar_InformPlayers;
ConVar g_Cvar_InformAdmins;
ConVar g_Cvar_InformMinTime;

public void OnPluginStart()
{
	LoadTranslations("teamflash_announcer.phrases");
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	g_Cvar_InformPlayers = CreateConVar("sm_teamflash_inform_players", "1", "Inform players when teammates flashes them?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_InformAdmins = CreateConVar("sm_teamflash_inform_admins", "1", "Inform admins when players are flashed by teammates?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_InformMinTime = CreateConVar("sm_teamflash_inform_mintime", "1.5", "Minimum flash duration for announcements.", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig(true, "teamflash_announcer");
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	g_ThrowerTeam = CS_TEAM_NONE;
	g_ThrowerId = event.GetInt("userid");
	
	int client = GetClientOfUserId(g_ThrowerId);
	if (!client || !IsClientInGame(client))
	{
		g_ThrowerTeam = CS_TEAM_NONE;
		return;
	}
	
	g_ThrowerTeam = GetClientTeam(client);
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Cvar_InformPlayers.BoolValue && !g_Cvar_InformAdmins.BoolValue || g_ThrowerTeam == CS_TEAM_NONE)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	if (g_ThrowerId == userId)
	{
		return;
	}
	
	int client = GetClientOfUserId(userId);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != g_ThrowerTeam)
	{
		return;
	}
	
	int thrower = GetClientOfUserId(g_ThrowerId);
	if (!thrower)
	{
		return;
	}
	
	float flashDuration = GetClientFlashDuration(client);
	if (flashDuration < g_Cvar_InformMinTime.FloatValue)
	{
		return;
	}
	
	char clientName[MAX_NAME_LENGTH], throwerName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(thrower, throwerName, sizeof(throwerName));
	
	if (g_Cvar_InformPlayers.BoolValue)
	{
		CPrintToChat(client, "[SM] %t", "Flashed by Teammate", throwerName);
		CPrintToChat(thrower, "[SM] %t", "Flashed a Teammate", clientName);
	}
	
	if (g_Cvar_InformAdmins.BoolValue)
	{
		SendToChatAdmins(client, "[SM] %t", "Player Flashed by Teammate", clientName, throwerName);
	}
}

void SendToChatAdmins(int client, const char[] format, any ...)
{
	char buffer[192];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && CheckCommandAccess(i, "sm_teamflash_admins", ADMFLAG_GENERIC))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			CPrintToChat(i, buffer);
		}
	}
}

float GetClientFlashDuration(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
}
