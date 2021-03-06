#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4downtown>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define MAXSPAWNS               8

new     bool:   g_bReadyUpAvailable     = false;
new     bool:   g_bIsRoundLive	        = false;
new		Handle:	g_hOnOff;


new const String: g_csSIClassName[][] =
{
    "",
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank"
};


public Plugin:myinfo = 
{
    name = "Special Infected Class Announce",
    author = "Tabun",
    description = "Report what SI classes are up when the round starts.",
    version = "0.9.2",
    url = "none"
}

public OnAllPluginsLoaded()
{
	g_bIsRoundLive = false;
	g_bReadyUpAvailable = LibraryExists("readyup");
	g_hOnOff = CreateConVar("l4d_announceSI_on", "1", "Display SI class for player when using commands", FCVAR_PLUGIN);
	RegConsoleCmd("sm_spawns", PrintSpawns);
	HookEvent("round_end", Event_RoundEnd);
}
public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}
public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}

public OnRoundIsLive()
{
	if (GetConVarBool(g_hOnOff)) {
	    // announce SI classes up now
	    for (new i = 1; i <= MaxClients; i++)
	    	if (IS_SURVIVOR_ALIVE(i))
	    		AnnounceSIClasses(i);
	    g_bIsRoundLive = true;
	}
}

public Action:Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	g_bIsRoundLive = false;
}

public Action:PrintSpawns(client, args) {
	if (!IsClientInGame(client) || !(1 <= client <= MaxClients)) {return;}
	if (g_bIsRoundLive) {
		PrintToChat(client, "\x01Special infected: \x05Your mom\x01, \x05Your dad\x01.");
		return;
	}
	if (!GetConVarBool(g_hOnOff)) return;
	AnnounceSIClasses(client);
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client )
{   
    // if no readyup, use this as the starting event
    if (!g_bReadyUpAvailable) {
    	for (new i = 1; i <= MaxClients; i++)
    		if(IS_SURVIVOR_ALIVE(i))
        		AnnounceSIClasses(i);
        g_bIsRoundLive = true;
    }
}

stock AnnounceSIClasses(any:client)
{
    // get currently active SI classes
    new iSpawns;
    new iSpawnClass[MAXSPAWNS+1];
    
    for (new i = 1; i <= MaxClients && iSpawns < MAXSPAWNS; i++) {
        if (!IS_INFECTED_ALIVE(i)) { continue; }

        iSpawnClass[iSpawns] = GetEntProp(i, Prop_Send, "m_zombieClass");
        iSpawns++;
    }
	
		    // print classes, according to amount of spawns found
		    switch (iSpawns) {
		        case 4: {
		            CPrintToChat(client,
		                    "Special Infected: {olive}%s{default}, {olive}%s{default}, {olive}%s{default}, {olive}%s{default}.",
		                    g_csSIClassName[iSpawnClass[0]],
		                    g_csSIClassName[iSpawnClass[1]],
		                    g_csSIClassName[iSpawnClass[2]],
		                    g_csSIClassName[iSpawnClass[3]]
		                );
		        }
		        case 3: {
		            CPrintToChat(client,
		                    "Special Infected: {olive}%s{default}, {olive}%s{default}, {olive}%s{default}.",
		                    g_csSIClassName[iSpawnClass[0]],
		                    g_csSIClassName[iSpawnClass[1]],
		                    g_csSIClassName[iSpawnClass[2]]
		                );
		        }
		        case 2: {
		            CPrintToChat(client,
		                    "Special Infected: {olive}%s{default}, {olive}%s{default}.",
		                    g_csSIClassName[iSpawnClass[0]],
		                    g_csSIClassName[iSpawnClass[1]]
		                );
		        }
		        case 1: {
		            CPrintToChat(client,
		                    "Special Infected: {olive}%s{default}.",
		                    g_csSIClassName[iSpawnClass[0]]
		                );
		        }
		        default: {
		      		CPrintToChat(client, "There are no special infected.");
		      	}
		    }
}
