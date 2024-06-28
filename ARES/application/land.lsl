/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Land Management Utility
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 2 (ASCL-ii). Although it appears in ARES as part of
 *  commercial software, it may be used as the basis of derivative,
 *  non-profit works that retain a compatible license. Derivative works of
 *  ASCL-ii software must retain proper attribution in documentation and
 *  source files as described in the terms of the ASCL. Furthermore, they
 *  must be distributed free of charge and provided with complete, legible
 *  source code included in the package.
 *  
 *  To see the full text of the ASCL, type 'help license' on any standard
 *  ARES distribution, or visit http://nanite-systems.com/ASCL for the
 *  current version.
 *
 *  DISCLAIMER
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS
 *  IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.
 *
 *  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 *  DAMAGES HOWEVER CAUSED ON ANY THEORY OF LIABILITY ARISING IN ANY WAY OUT
 *  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 *  DAMAGE.
 *
 * =========================================================================
 *
 */

/*
	Wrapped LSL functions:
	
	https://wiki.secondlife.com/wiki/LlGetEnv
	
	https://wiki.secondlife.com/wiki/LlGetEnvironment - too complex for now
	https://wiki.secondlife.com/wiki/LlParcelMediaCommandList
	https://wiki.secondlife.com/wiki/LlParcelMediaQuery
	https://wiki.secondlife.com/wiki/LlRequestSimulatorData
	https://wiki.secondlife.com/wiki/LlSetEnvironment - too complex for now
	https://wiki.secondlife.com/wiki/LlGetSimStats
	
	https://wiki.secondlife.com/wiki/LlGetExperienceDetails
	
	https://wiki.secondlife.com/wiki/LlGetParcelDetails
	https://wiki.secondlife.com/wiki/LlGetParcelFlags
	https://wiki.secondlife.com/wiki/LlGetParcelMaxPrims
	https://wiki.secondlife.com/wiki/LlGetParcelPrimCount
	https://wiki.secondlife.com/wiki/LlGetParcelPrimOwners
	
	x https://wiki.secondlife.com/wiki/LlManageEstateAccess
	x https://wiki.secondlife.com/wiki/LlGetRegionFlags
	x https://wiki.secondlife.com/wiki/LlGetSimulatorHostname
	x https://wiki.secondlife.com/wiki/LlGetDayLength
	x https://wiki.secondlife.com/wiki/LlGetDayOffset
	x https://wiki.secondlife.com/wiki/LlAddToLandBanList
	x https://wiki.secondlife.com/wiki/LlAddToLandPassList
	x https://wiki.secondlife.com/wiki/LlEjectFromLand
	x https://wiki.secondlife.com/wiki/LlGetParcelMusicURL
	x https://wiki.secondlife.com/wiki/LlGetRegionAgentCount
	x https://wiki.secondlife.com/wiki/LlGetRegionAgentCount
	x https://wiki.secondlife.com/wiki/LlGetRegionCorner
	x https://wiki.secondlife.com/wiki/LlGetRegionDayLength
	x https://wiki.secondlife.com/wiki/LlGetRegionDayOffset
	x https://wiki.secondlife.com/wiki/LlGetRegionFPS
	x https://wiki.secondlife.com/wiki/LlGetRegionName
	x https://wiki.secondlife.com/wiki/LlGround
	x https://wiki.secondlife.com/wiki/LlGroundSlope
	x https://wiki.secondlife.com/wiki/LlMapDestination
	x https://wiki.secondlife.com/wiki/LlRemoveFromLandBanList
	x https://wiki.secondlife.com/wiki/LlRemoveFromLandPassList
	x https://wiki.secondlife.com/wiki/LlResetLandBanList
	x https://wiki.secondlife.com/wiki/LlResetLandPassList
	x https://wiki.secondlife.com/wiki/LlReturnObjectsByID - still needs permission
	x https://wiki.secondlife.com/wiki/LlReturnObjectsByOwner - still needs permission
	x https://wiki.secondlife.com/wiki/LlSetParcelMusicURL
	x https://wiki.secondlife.com/wiki/LlTeleportAgentHome
	x https://wiki.secondlife.com/wiki/LlWater
	x https://wiki.secondlife.com/wiki/LlWind
	
*/

#include <ARES/a>
#define CLIENT_VERSION "0.2.1"
#define CLIENT_VERSION_TAGS "alpha"

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " <action>\n\nUtility for managing and inspecting land.\n\nSupported actions:\n\nParcel info: parcel [name], parcel capacity, parcel id, parcel desc, parcel prims, parcel owner, parcel group, area, flags \nSurveying: wind, water, ground, slope, day length, day offset, region day length, region day offset\nParcel media: music [<new URL>] (requires land ownership)\nMisc: map <url>\nAccess control: kick <uuid>, eject <uuid>, evict <uuid>, return <space-separated list of object UUIDs>, pass clear, pass revoke <uuid>, pass <uuid> [<hours>], ban clear, ban revoke <uuid>, unban <uuid>, unban all, ban <uuid> [<hours>], exile <uuid>\nRegion info: region [name], region flags, region host, region pop[ulation], region pos, region fps, uptime, region uptime, region version\nEstate: estate ban <uuid>, estate unban <uuid>, estate pass [group] <uuid>, estate revoke [group] <uuid>";
		} else {
			string action = gets(argv, 1);
			string subject = gets(argv, 2);
			string topic = gets(argv, 3);
			string fourth = gets(argv, 4);
			
			if(action == "parcel") {
				if(argc == 2 || subject == "name")
					msg = gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]), 0);
				else if(subject == "id")
					msg = gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_ID]), 0);
				else if(subject == "desc")
					msg = gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_DESC]), 0);
				else if(subject == "group")
					msg = gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0);
				else if(subject == "owner")
					msg = gets(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_OWNER]), 0);
				else if(subject == "capacity")
					msg = (string)geti(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_PRIM_CAPACITY]), 0);
				else if(subject == "prims")
					msg = (string)geti(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_PRIM_USED]), 0);
			} else if(action == "area")
				msg = (string)geti(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_AREA]), 0);
			else if(action == "flags")
				msg = (string)llGetParcelFlags(llGetPos());
			else if(action == "wind")
				msg = (string)llWind(ZV);
			else if(action == "water")
				msg = (string)llWater(ZV);
			else if(action == "ground")
				msg = (string)llGround(ZV);
			else if(action == "slope")
				msg = (string)llGroundSlope(ZV);
			else if(action == "music") {
				if(subject != "") {
					llSetParcelMusicURL(subject);
				} else {
					msg = llGetParcelMusicURL();
				}
			} else if(action == "map") {
				list url = split(subject, "/");
				
				string region = gets(url, -4);
				vector coords = <(float)gets(url, -3), (float)gets(url, -2), (float)gets(url, -1)>;
				llMapDestination(region, coords, ZV);
			} else if(action == "day") {
				if(subject == "length")
					msg = (string)llGetDayLength();
				else if(subject == "offset")
					msg = (string)llGetDayOffset();
			} else if(action == "kick")
				llTeleportAgentHome(subject);
			else if(action == "eject")
				llEjectFromLand(subject);
			else if(action == "evict")
				llReturnObjectsByOwner(subject, OBJECT_RETURN_PARCEL);
			else if(action == "return")
				llReturnObjectsByID(delrange(argv, 0, 1));
			else if(action == "pass") {
				if(subject == "clear")
					llResetLandPassList();
				else if(subject == "revoke")
					llRemoveFromLandPassList(topic);
				else
					llAddToLandPassList(subject, (integer)fourth);
			} else if(action == "ban") {
				if(subject == "clear")
					llResetLandBanList();
				else if(subject == "revoke")
					llRemoveFromLandBanList(topic);
				else
					llAddToLandBanList(subject, (integer)fourth);
			} else if(action == "unban") {
				if(subject == "all")
					llResetLandBanList();
				else
					llRemoveFromLandBanList(subject);
			} else if(action == "exile") {
				llTeleportAgentHome(subject);
				llAddToLandBanList(subject, 0);
				llReturnObjectsByOwner(subject, OBJECT_RETURN_PARCEL_OWNER);
			} else if(action == "uptime")
				msg = format_time(llGetUnixTime() - (integer)llGetEnv("region_start_time"));
			else if(action == "day") {
				if(subject == "length")
					msg = (string)llGetRegionDayLength();
				else if(subject == "offset")
					msg = (string)llGetRegionDayOffset();
			} else if(action == "region") {
				if(subject == "flags")
					msg = (string)llGetRegionFlags();
				else if(subject == "host")
					msg = llGetEnv("simulator_hostname");
				else if(subject == "version")
					msg = llGetEnv("sim_channel") + " " + llGetEnv("sim_version");
				else if(subject == "population" || subject == "pop")
					msg = (string)llGetRegionAgentCount();
				else if(subject == "pos")
					msg = (string)llGetRegionCorner();
				else if(subject == "fps")
					msg = (string)llGetRegionFPS();
				else if(subject == "uptime")
					msg = (string)(llGetUnixTime() - (integer)llGetEnv("region_start_time"));
				else if(subject == "day") {
					if(topic == "length")
						msg = (string)llGetRegionDayLength();
					else if(topic == "offset")
						msg = (string)llGetRegionDayOffset();
				} else if(subject == "name" || subject == "")
					msg = llGetRegionName();
			} else if(action == "estate") {
				if(subject == "ban") {
					llManageEstateAccess(ESTATE_ACCESS_BANNED_AGENT_ADD, topic);
				} else if(subject == "unban") {
					llManageEstateAccess(ESTATE_ACCESS_BANNED_AGENT_REMOVE, topic);
				} else if(subject == "pass") {
					if(topic == "group")
						llManageEstateAccess(ESTATE_ACCESS_ALLOWED_GROUP_ADD, fourth);
					else
						llManageEstateAccess(ESTATE_ACCESS_ALLOWED_AGENT_ADD, topic);
				} else if(subject == "revoke") {
					if(topic == "group")
						llManageEstateAccess(ESTATE_ACCESS_ALLOWED_GROUP_REMOVE, fourth);
					else
						llManageEstateAccess(ESTATE_ACCESS_ALLOWED_AGENT_REMOVE, topic);
				} else if(subject == "name" || subject == "") {
					msg = llGetEnv("estate_name");
				} else if(subject == "id") {
					msg = llGetEnv("estate_id");
				}
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
