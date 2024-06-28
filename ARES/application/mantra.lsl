/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Mantra Application
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

string fg_image = "947c7a17-4e88-2f96-b419-dc37b647127d";
string bg_image = "cf45ccd4-9bd0-1835-08f7-3883e234f3e1";

string loop_sound = "70f93e08-31c1-6076-4ea7-47a7b8a6ca3f";
float loop_vol = 0.5;
float start_speed = 0.125;
float stop_speed = 0.25;

// float screen_width = 1920;
// float screen_height = 1008;
// float diagonal_aspect_ratio = llSqrt(1 + llPow(screen_width / screen_height, 2.0));
// float diagonal_aspect_ratio = 2.16; // 2.1513060948717175859320949846553
// (ratio of screen height to diagonal width - minimum 1.0)
// for very wide screens:
// float diagonal_aspect_ratio = 3;
float diagonal_aspect_ratio = 2.16;

vector fg_color;
vector bg_color;

list mantras;

integer content_i;
integer mantra_interval;

end_meditation() {
	task_end("mantra");
	set_timer("mantra", 0);
	
	llResetTime();
	float t = 0;
	while(t < 1) {
		llSleep(0.01);
		t += llGetAndResetTime() * stop_speed;
		if(t > 1) t = 1;
		setp(WIZARD_TEXT + 2, [PRIM_COLOR, ALL_SIDES, bg_color, 1.0 - t]);
	}
	
	llResetTime();
	t = 0;
	while(t < 1) {
		llSleep(0.01);
		t += llGetAndResetTime() * stop_speed;
		if(t > 1) t = 1;
		setp(WIZARD + 2, [PRIM_COLOR, ALL_SIDES, fg_color, 1.0 - t]);
		llAdjustSoundVolume((1.0 - t) * loop_vol);
	}
	
	setp(WIZARD + 2, [
		PRIM_SIZE, ZV,
		PRIM_COLOR, ALL_SIDES, ZV, 0,
		PRIM_ROT_LOCAL, INVISIBLE,
		PRIM_POSITION, OFFSCREEN,
		PRIM_OMEGA, ZV, 0, 0,
	PRIM_LINK_TARGET, WIZARD_TEXT + 2,
		PRIM_SIZE, ZV,
		PRIM_COLOR, ALL_SIDES, ZV, 0,
		PRIM_ROT_LOCAL, INVISIBLE,
		PRIM_POSITION, OFFSCREEN,
		PRIM_OMEGA, ZV, 0, 0,
	PRIM_LINK_TARGET, WIZARD_TEXT,
		PRIM_TEXT, "", ZV, 0,
		PRIM_POSITION, OFFSCREEN
	]);
	llStopSound();
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " start|stop";
		} else {
			string action = gets(argv, 1);
			if(action == "sleep") {
				float duration = (float)gets(argv, 2);
				if(duration <= 0.1) duration = 0.1;
				llSleep(duration);
			} else if(action == "start") {
				task_begin("mantra", user);
				
				if(llLinksetDataRead("mantra") == JSON_INVALID) {
					print(outs, user, "Database not configured. Please run @db load mantra.db");
					return;
				}
				
				print(outs, user, "Mantra session beginning.");
				
				content_i = 0;
				
				loop_sound = getdbl("mantra", ["loop", "sound"]);
				loop_vol = (float)getdbl("mantra", ["loop", "volume"]);
				start_speed = (float)getdbl("mantra", ["speed", "start"]);
				stop_speed = (float)getdbl("mantra", ["speed", "stop"]);
				fg_image = getdbl("mantra", ["fg", "image"]);
				bg_image = getdbl("mantra", ["bg", "image"]);
				float fg_speed = (float)getdbl("mantra", ["fg", "speed"]);
				float bg_speed = (float)getdbl("mantra", ["bg", "speed"]);
				diagonal_aspect_ratio = (float)getdbl("mantra", ["scale"]);
				integer fg_slot = (integer)getdbl("mantra", ["fg", "color"]);
				integer bg_slot = (integer)getdbl("mantra", ["bg", "color"]);
				
				if(fg_speed == 0) fg_speed = -1.0;
				
				if(fg_slot == -1) {
					fg_color = ONES;
				} else {
					string color_1 = getdbl("id", ["color", fg_slot]);
					fg_color = str2vec(color_1);
					if(fg_color == ZV)
						fg_color = <1, 1, 1>;
				}
				
				if(bg_slot == -1) {
					bg_color = ONES;
				} else {
					string color_2 = getdbl("id", ["color", bg_slot]);
					bg_color = str2vec(color_2);
				}
				
				// this ensures the spiral covers the whole screen reliably
				
				setp(WIZARD + 2, [
					PRIM_TEXTURE, ALL_SIDES, fg_image, ONES, ZV, 0,
					PRIM_COLOR, ALL_SIDES, fg_color, 0,
					PRIM_SIZE, ONES * diagonal_aspect_ratio,
					PRIM_POSITION, <-2, 0, 0>,
					PRIM_ROT_LOCAL, VISIBLE,
					PRIM_OMEGA, <1, 0, 0>, fg_speed, 1,
				PRIM_LINK_TARGET, WIZARD_TEXT + 2,
					PRIM_TEXTURE, ALL_SIDES, bg_image, ONES, ZV, 0,
					PRIM_COLOR, ALL_SIDES, bg_color, 0,
					PRIM_SIZE, ONES * diagonal_aspect_ratio,
					PRIM_POSITION, <-1.9, 0, 0>,
					PRIM_ROT_LOCAL, VISIBLE,
					PRIM_OMEGA, <1, 0, 0>, bg_speed, 1,
				PRIM_LINK_TARGET, WIZARD_TEXT,
					PRIM_TEXT, "", ZV, 0,
					PRIM_POSITION, ZV
				]);
				
				llPreloadSound(loop_sound);
				
				llLoopSound(loop_sound, 0);
				
				llSleep(0.4);
				
				llResetTime();
				float t = 0;
				while(t < 1) {
					llSleep(0.01);
					t += llGetAndResetTime() * start_speed;
					if(t > 1) t = 1;
					setp(WIZARD + 2, [PRIM_COLOR, ALL_SIDES, fg_color, t]);
					llAdjustSoundVolume(t * loop_vol);
				}
				
				llResetTime();
				t = 0;
				while(t < 1) {
					llSleep(0.01);
					t += llGetAndResetTime() * start_speed;
					if(t > 1) t = 1;
					setp(WIZARD_TEXT + 2, [PRIM_COLOR, ALL_SIDES, bg_color, t]);
				}
				
				mantra_interval = (integer)getdbl("mantra", ["interval"]);
				mantras = js2list(getdbl("mantra", ["content"]));
				set_timer("mantra", mantra_interval);
				
			} else if(action == "stop") {
				integer lock_in = (integer)getdbl("mantra", ["lock-in"]);
				
				key initiator = getjs(tasks_queue, ["mantra"]);
				if(user == initiator && user == avatar && lock_in) {
					msg = "Nothing is more important than mental clarity.";
				} else if(initiator == user || initiator == JSON_INVALID) {
					print(outs, user, "Mantra session ending.");
					end_meditation();
				} else {
					msg = "Only secondlife:///app/agent/" + (string)initiator + "/about may stop the session.";
				}
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_TIMER) {		
		key initiator = getjs(tasks_queue, ["mantra"]);
		if(initiator == JSON_INVALID) {
			end_meditation();
			return;
		} else {
			string msg = getdbl("mantra", ["content", content_i++]);
			if(msg == JSON_INVALID) {
				integer autowake = (integer)getdbl("mantra", ["autowake"]);
				if(autowake) {
					end_meditation();
					return;
				} else {
					msg = getdbl("mantra", ["content", content_i=0]);
				}
			}
			
			llResetTime();
			float t = 0;
			while(t < 1) {
				llSleep(0.01);
				t += llGetAndResetTime();
				if(t >= 1)
					t = 1;
				setp(WIZARD_TEXT, [
					PRIM_TEXT, msg, ONES, t
				]);
			}
			
			llSleep(mantra_interval / 2);
			
			llResetTime();
			t = 0;
			while(t < 1) {
				llSleep(0.01);
				t += llGetAndResetTime();
				if(t >= 1)
					t = 1;
				setp(WIZARD_TEXT, [
					PRIM_TEXT, msg, ONES, 1.0 - t
				]);
			}
		}
		
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		setp(WIZARD + 2, [
			PRIM_SIZE, ZV,
			PRIM_COLOR, ALL_SIDES, ZV, 0,
			PRIM_ROT_LOCAL, INVISIBLE,
			PRIM_POSITION, OFFSCREEN,
			PRIM_OMEGA, ZV, 0, 0,
		PRIM_LINK_TARGET, WIZARD_TEXT + 2,
			PRIM_SIZE, ZV,
			PRIM_COLOR, ALL_SIDES, ZV, 0,
			PRIM_ROT_LOCAL, INVISIBLE,
			PRIM_POSITION, OFFSCREEN,
			PRIM_OMEGA, ZV, 0, 0,
		PRIM_LINK_TARGET, WIZARD_TEXT,
			PRIM_TEXT, "", ZV, 0,
			PRIM_POSITION, OFFSCREEN
		]);
		llStopSound();
		set_timer("mantra", 0);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
