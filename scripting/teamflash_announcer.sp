#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <intmap>
#include <colorlib_sample>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Flash Announcer",
    author = "Ilusion9",
    description = "Players and admins can be informed when players are flashed by their teammates.",
    version = "1.1",
    url = "https://github.com/Ilusion9/"
};

#define CHAT_MESSAGE_PREFIX	"{lime}[TeamFlash]{default} "
enum struct ThrowerInfo
{
	int userId;
	int Team;
}

ThrowerInfo g_Thrower;
IntMap g_FlashbangsTeam;

ConVar g_Cvar_InformPlayers;
ConVar g_Cvar_InformAdmins;
ConVar g_Cvar_InformMinTime;

public void OnPluginStart()
{
	LoadTranslations("teamflash_announcer.phrases");
	g_FlashbangsTeam = new IntMap();

	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	g_Cvar_InformPlayers = CreateConVar("sm_teamflash_inform_players", "1", "Inform players when teammates flashes them?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_InformAdmins = CreateConVar("sm_teamflash_inform_admins", "1", "Inform admins when players are flashed by their teammates?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_InformMinTime = CreateConVar("sm_teamflash_inform_mintime", "1.5", "Minimum flash duration for announcements.", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig(true, "teamflash_announcer");
}

public void OnMapStart()
{
	g_FlashbangsTeam.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "flashbang_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_OnFlashbangProjectileSpawn_Post);
	}
}

public void SDK_OnFlashbangProjectileSpawn_Post(int entity)
{
	RequestFrame(Frame_FlashbangProjectileSpawn, EntIndexToEntRef(entity));
}

public void Frame_FlashbangProjectileSpawn(any data)
{
	int entity = EntRefToEntIndex(view_as<int>(data));
	if (entity == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");	
	if (thrower < 1 || thrower > MaxClients || !IsClientInGame(thrower))
	{
		return;
	}
	
	g_FlashbangsTeam.SetValue(entity, GetClientTeam(thrower));
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	g_Thrower.userId = event.GetInt("userid");
	int entity = event.GetInt("entityid");
	
	if (!g_FlashbangsTeam.GetValue(entity, g_Thrower.Team))
	{
		g_Thrower.Team = CS_TEAM_NONE;
	}
	
	g_FlashbangsTeam.Remove(entity);
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Cvar_InformPlayers.BoolValue && !g_Cvar_InformAdmins.BoolValue)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	if (g_Thrower.userId == userId)
	{
		return;
	}
	
	int client = GetClientOfUserId(userId);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != g_Thrower.Team)
	{ 
		return;
	}
	
	float flashDuration = GetClientFlashDuration(client);
	if (flashDuration < g_Cvar_InformMinTime.FloatValue)
	{
		return;
	}
	
	flashDuration = flashDuration < 0.1 ? 0.1 : flashDuration;
	int thrower = GetClientOfUserId(g_Thrower.userId);
	
	if (!thrower)
	{
		if (CheckCommandAccess(client, "TeamFlashAnnouncer", 0, true))
		{
			CPrintToChat(client, "%s%t", CHAT_MESSAGE_PREFIX, "Flashed by Disconnected Teammate", flashDuration);
		}
		
		return;
	}
	
	char clientName[MAX_NAME_LENGTH], throwerName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(thrower, throwerName, sizeof(throwerName));

	if (g_Cvar_InformPlayers.BoolValue)
	{
		if (CheckCommandAccess(client, "TeamFlashAnnouncer", 0, true))
		{
			CPrintToChat(client, "%s%t", CHAT_MESSAGE_PREFIX, "Flashed by Teammate", throwerName, flashDuration);
		}
		
		if (CheckCommandAccess(thrower, "TeamFlashAnnouncer", 0, true))
		{
			CPrintToChat(thrower, "%s%t", CHAT_MESSAGE_PREFIX, "Flashed a Teammate", clientName, flashDuration);
		}
	}
	
	if (g_Cvar_InformAdmins.BoolValue)
	{
		SendToChatAdmins(client, "%s%t", CHAT_MESSAGE_PREFIX, "Player Flashed by Teammate", clientName, throwerName, flashDuration);
	}
}

void SendToChatAdmins(int client, const char[] format, any ...)
{
	char buffer[192];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && CheckCommandAccess(i, "TeamFlashAnnouncerAdmin", ADMFLAG_GENERIC))
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
