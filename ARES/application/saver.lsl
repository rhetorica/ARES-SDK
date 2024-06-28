/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Screen Saver Program
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

#include <ARES/a>
#include <ARES/api/interface.consts.h.lsl>

#define CLIENT_VERSION "1.0.1"
#define CLIENT_VERSION_TAGS "release"

#define call_interface(_outs, _user, _msg) \
	system(SIGNAL_CALL, E_INTERFACE + E_PROGRAM_NUMBER \
		+ (string)_outs + " " + (string)_user + " interface " + (_msg));

list savers = ["blank", "toasters", "stars", "bounce"];

// #define STARS_TEX "e8105c7f-2595-6bd9-54fb-690764dcac3a"
#define STARS_TEX "e74b5970-f74f-9846-4707-eb9cf97af2f0"
// #define STARS_TEX "3c0d0224-7a9a-5d63-c218-ebd7721f1c08"

#define TOASTER_TEX "d56103e2-2ca9-3a18-40e8-5c3164f2b25c"

#define SS_BG 112
#define SS_FG 113
#define SS_LAYERS 15


#define STARS_LAYERS 8
#define BOUNCE_SPEED 32
#define TOASTERS 14
#define MIN_TOAST_SPEED 4

string model_badge = BADGE_DEFAULT;
integer screen_width = 1920;
integer screen_height = 1008;
float pixel_scale;

string current_saver;

vector bounce_dir = <0, 1, 1>;
vector bounce_pos = ZV;
float last_time;

list toaster_pos;
integer auto_enabled = FALSE;

#define AFK_CHECK_INTERVAL 30

main(integer src, integer n, string m, key outs, key ins, key user) {
	@restart_main;
	
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(action == "stop" || action == "off" || action == "cancel") {
			if(current_saver != "") {
				task_end("screensaver");
				current_saver = "";
				integer n = SS_LAYERS;
				list acts;
				while(n--) {
					acts += [
						PRIM_LINK_TARGET, SS_BG + n,
						PRIM_SIZE, ZV,
						PRIM_POSITION, OFFSCREEN,
						PRIM_COLOR, 0, ZV, 1,
						PRIM_ROTATION, INVISIBLE,
						PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, ZV, ZV, 0
					];
					
					llSetLinkTextureAnim(SS_BG + n, 0, ALL_SIDES, 0, 0, 0, 0, 0);
				}
				setp(0, acts);
			}
			llSetTimerEvent(0);
			call_interface(outs, user, "reconfigure");
			unhook_events([EVENT_TOUCH]);
		} else if(action == "auto") {
			auto_enabled = !auto_enabled;
			string saved_saver = getdbl("screensaver", ["name"]);
			if(saved_saver == JSON_INVALID)
				saved_saver = "random";
			print(outs, user, "Screensaver (" + saved_saver + ") will " + gets(["not activate automatically.", "activate automatically when the unit goes Away."], auto_enabled));
			set_timer("afk-check", AFK_CHECK_INTERVAL * auto_enabled);
			setdbl("screensaver", ["auto"], (string)auto_enabled);
		} else if(action == "random" || contains(savers, action)) {
			if(action == "random")
				current_saver = gets(shuffle(savers, 1), 0);
			else
				current_saver = action;
			
			string saved_saver = getdbl("screensaver", ["name"]);
			if(saved_saver != "random")
				setdbl("screensaver", ["name"], action);
			
			if(current_saver != "blank") {
				if(current_saver == "toasters" || current_saver == "bounce") {
					screen_width = (integer)getdbl("interface", ["width"]);
					if(screen_width == 0) {
						echo("Error: screen width not set. Please set manually with: '@db interface.width <amount>' using the window size information from your viewer's Help > About menu.");
						return;
					}
					screen_height = (integer)getdbl("interface", ["height"]);
					pixel_scale = 1.0 / (float)screen_height;
					
					if(current_saver == "toasters") {
						toaster_pos = [];
						integer n = TOASTERS;
						while(n--) {
							toaster_pos += <0, screen_width, screen_height>;
						}
					} else {
						model_badge = getjs("interface", ["badge"]);
						if(model_badge == JSON_INVALID)
							if((model_badge = getdbl("badge", [replace(getdbl("id", ["model"]), ".", "-")])) == JSON_INVALID)
								model_badge = BADGE_DEFAULT;
					}
				}
				
				llResetTime();
				llSetTimerEvent(0.066);
			}
			
			hook_events([EVENT_TOUCH]);
			task_begin("screensaver", user);
			setp(SS_BG, [
				PRIM_SIZE, <2, 1, 0>,
				PRIM_POSITION, <-4, 0, 0>,
				PRIM_COLOR, 0, ZV, 1,
				PRIM_ROTATION, VISIBLE,
				PRIM_TEXTURE, 0, TEXTURE_BLANK, ZV, ZV, 0
			]);
			
		} else {
			msg =
				PROGRAM_NAME + " stop|off|cancel: interrupts the screensaver\n" +
				PROGRAM_NAME + " <saver>: starts a screensaver immediately\n" +
				PROGRAM_NAME + " auto: toggles automatic triggering of screensaver once the unit has been Away for 0-30 seconds (uses last screensaver manually activated)\n\n" +
				/* PROGRAM_NAME + " clear: removes scheduled screensaver task\n\n" + */
				"Available screensavers: " + concat(savers, ", ") + ", random";
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_EVENT) {
		if((integer)m == EVENT_TOUCH) {
			if(current_saver != "") {
				m = PROGRAM_NAME + " stop";
				n = SIGNAL_INVOKE;
				jump restart_main;
			}
		}
	} else if(n == SIGNAL_TIMER) {
		if(llGetAgentInfo(avatar) & AGENT_AWAY && current_saver == "") {
			string saved_saver = getdbl("screensaver", ["name"]);
			if(saved_saver == JSON_INVALID) {
				m = PROGRAM_NAME + " random";
			} else {
				m = PROGRAM_NAME + " " + saved_saver;
			}
			n = SIGNAL_INVOKE;
			jump restart_main;
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		call_interface(outs, user, "reconfigure");
		llSleep(1.0);
		
		auto_enabled = (integer)getdbl("screensaver", ["auto"]);
		set_timer("afk-check", AFK_CHECK_INTERVAL * auto_enabled);
		
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#define EXT_EVENT_HANDLER "ARES/application/saver.event.lsl"
#include <ARES/program>
