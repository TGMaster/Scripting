/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include "left4downtown"
#include <colors>
 
#define TEAM_INFECTED                   3
#define TAUNT_HIGH_THRESHOLD            0.4
#define TAUNT_MID_THRESHOLD             0.2
#define TAUNT_LOW_THRESHOLD             0.04

enum SIClasses
{
        SMOKER_CLASS=1,
        BOOMER_CLASS,
        HUNTER_CLASS,
        SPITTER_CLASS,
        JOCKEY_CLASS,
        CHARGER_CLASS,
        WITCH_CLASS,
        TANK_CLASS,
        NOTINFECTED_CLASS
}
 
static String:SINames[_:SIClasses][] =
{
        "",
        "gas",          // smoker
        "exploding",    // boomer
        "hunter",
        "spitter",
        "jockey",
        "charger",
        "witch",
        "tank",
        ""
};
 
new Handle: hCvarDmgThreshold = INVALID_HANDLE;
new Handle: hSpecialInfectedHP[_:SIClasses] = INVALID_HANDLE;


public Plugin:myinfo =
{
        name = "1v1 Pro Mod",
        author = "Blade + Confogl Team, Tabun",
        description = "A plugin designed to support 1v1.",
        version = "6.0c",
        url = "https://github.com/malathion/promod/"
}


public OnPluginStart()
{      
        decl String:buffer[17];
        for (new i = 1; i < _:SIClasses; i++)
        {
                Format(buffer, sizeof(buffer), "z_%s_health", SINames[i]);
                hSpecialInfectedHP[i] = FindConVar(buffer);
        }
        
        hCvarDmgThreshold = CreateConVar("sm_1v1_dmgthreshold", "33", "Amount of damage done (at once) before SI suicides.", FCVAR_PLUGIN, true, 1.0);
        
        HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}
 
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new victim = GetClientOfUserId(GetEventInt(event, "userid"));
       
        if (!IsClientAndInGame(attacker))
                return;
       
        new damage = GetEventInt(event, "dmg_health");
        new zombie_class = GetZombieClass(attacker);
       
        if (GetClientTeam(attacker) == TEAM_INFECTED && zombie_class != _:TANK_CLASS && damage >= GetConVarInt(hCvarDmgThreshold))
        {
                new remaining_health = GetClientHealth(attacker);
                CPrintToChatAll("{blue}[{default}1v1 Mode{blue}]{default} Infected ({olive}%N{default}) health remaining: {blue}%d{default}", attacker, remaining_health);
                
                ForcePlayerSuicide(attacker);    
                
                new maxHealth = GetSpecialInfectedHP(zombie_class);
                if (!maxHealth)
                        return;    
                
                if (remaining_health == 1)
                {
                        CPrintToChat(victim, "{red}Get owned.");
                }
                else if (remaining_health <= RoundToCeil(maxHealth * TAUNT_LOW_THRESHOLD))
                {
                        CPrintToChat(victim, "{red}You seem upset.");
                }
                else if (remaining_health <= RoundToCeil(maxHealth * TAUNT_MID_THRESHOLD))
                {
                        CPrintToChat(victim, "{red}So close!");
                }
                else if (remaining_health <= RoundToCeil(maxHealth * TAUNT_HIGH_THRESHOLD))
                {
                        CPrintToChat(victim, "{red}Not bad.");
                }
        }
}


stock GetZombieClass(client) return GetEntProp(client, Prop_Send, "m_zombieClass");

stock GetSpecialInfectedHP(class)
{
    if (hSpecialInfectedHP[class] != INVALID_HANDLE)
            return GetConVarInt(hSpecialInfectedHP[class]);
    
    return 0;
}

stock bool:IsClientAndInGame(index)
{
        if (index > 0 && index < MaxClients)
        {
            return IsClientInGame(index);
        }
        return false;
}