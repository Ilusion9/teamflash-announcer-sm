#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <intmap>
#include <sourcecolors>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Flash Announcer",
    author = "Ilusion9",
    description = "Players and admins can be informed when players are flashed by their teammates.",
    version = "1.1",
    url = "https://github.com/Ilusion9/"
};

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
	// Entity's properties can be retrieved after 1 frame
	RequestFrame(Frame_FlashbangProjectileSpawn, EntIndexToEntRef(entity));
}

public void Frame_FlashbangProjectileSpawn(any data)
{
	int reference = view_as<int>(data);
	int entity = EntRefToEntIndex(reference);
	
	if (entity == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	// Get the thrower of this flashbang
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");	
	if (thrower < 1 || thrower > MaxClients || !IsClientInGame(thrower))
	{
		return;
	}
	
	// Set the team of this flashbang
	// Players can change their teams until the flash explodes, so we set the team here
	g_FlashbangsTeam.SetValue(reference, GetClientTeam(thrower));
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	g_Thrower.userId = event.GetInt("userid");
	int entity = event.GetInt("entityid");
	int reference = EntIndexToEntRef(entity);
	
	// Set the team globally and free the memory from the intmap
	if (!g_FlashbangsTeam.GetValue(reference, g_Thrower.Team))
	{
		g_Thrower.Team = CS_TEAM_NONE;
	}
	
	g_FlashbangsTeam.Remove(reference);
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Cvar_InformPlayers.BoolValue && !g_Cvar_InformAdmins.BoolValue)
	{
		return;
	}
	
	// Own flash
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
	
	// Check the minimum flash duration
	float flashDuration = GetClientFlashDuration(client);
	if (flashDuration < g_Cvar_InformMinTime.FloatValue)
	{
		return;
	}
	flashDuration = flashDuration < 0.1 ? 0.1 : flashDuration;
	
	// Check if the thrower has disconnected
	// TO DO: display their name and maybe their steamid
	int thrower = GetClientOfUserId(g_Thrower.userId);
	if (!thrower)
	{
		if (CheckCommandAccess(client, "TeamFlashAnnouncer", 0, true))
		{
			CPrintToChat(client, "%t", "Flashed by Disconnected Teammate", flashDuration);
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
			CPrintToChat(client, "%t", "Flashed by Teammate", throwerName, flashDuration);
		}
		
		if (CheckCommandAccess(thrower, "TeamFlashAnnouncer", 0, true))
		{
			CPrintToChat(thrower, "%t", "Flashed a Teammate", clientName, flashDuration);
		}
	}
	
	if (g_Cvar_InformAdmins.BoolValue)
	{
		SendToChatAdmins(client, "%t", "Player Flashed by Teammate", clientName, throwerName, flashDuration);
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
