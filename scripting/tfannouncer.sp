#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colorlib>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Flash Announcer",
    author = "Ilusion9",
    description = "Players will be announced when teammates flashes them.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

int g_ThrowerId;
int g_ThrowerTeam;

ConVar g_Cvar_TeamFlashAnnounce;
ConVar g_Cvar_TeamFlashAnnounceAdmins;
ConVar g_Cvar_TeamFlashMinTime;

public void OnPluginStart()
{
	LoadTranslations("tfannouncer.phrases");
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	g_Cvar_TeamFlashAnnounce = CreateConVar("sm_tfannounce", "1", "Determine whether players should be notified when teammates flashes them or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_TeamFlashAnnounceAdmins = CreateConVar("sm_tfannounce_print_to_admins", "1", "Determine whether admins should be notified when players are flashed by teammates or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_TeamFlashMinTime = CreateConVar("sm_tfannounce_mintime", "1.5", "Minimum flash duration for announcements.", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig(true, "tfannouncer");
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
	if (!g_Cvar_TeamFlashAnnounce.BoolValue && !g_Cvar_TeamFlashAnnounceAdmins.BoolValue)
	{
		return;
	}
	
	if (g_ThrowerTeam == CS_TEAM_NONE)
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
	
	float flashDuration = GetClientFlashDuration(client);
	if (flashDuration < g_Cvar_TeamFlashMinTime.FloatValue)
	{
		return;
	}
	
	int thrower = GetClientOfUserId(g_ThrowerId);
	if (!thrower)
	{
		CPrintToChat(client, "[SM] %t", "Flashed by Disconnected Teammate");
		return;
	}
	
	char clientName[MAX_NAME_LENGTH], throwerName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(thrower, throwerName, sizeof(throwerName));
	
	if (g_Cvar_TeamFlashAnnounce.BoolValue)
	{
		CPrintToChat(client, "[SM] %t", "Flashed by Teammate", throwerName);
		CPrintToChat(thrower, "[SM] %t", "Flashed a Teammate", clientName);
	}
	
	if (g_Cvar_TeamFlashAnnounceAdmins.BoolValue)
	{
		SendToChatAdmins(client, "[SM] %t", "Player Flashed by Teammate", clientName, throwerName);
	}
}

void SendToChatAdmins(int client, const char[] format, any ...)
{
	char buffer[192];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && CheckCommandAccess(i, "sm_tfannounce_admins", ADMFLAG_GENERIC))
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
