/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  VAR/H Metropolis Hardware Driver
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 3 (ASCL-iii). It may be redistributed or used as the
 *  basis of commercial, closed-source products so long as steps are taken
 *  to ensure proper attribution as defined in the text of the license.
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

#include <utils.lsl>
#include <objects.lsl>

#define SND_BUTTON "e4174b28-6011-4b99-040b-b4ae58064f05"
#define TX_SCREEN_DEFAULT "27409425-2804-5be0-5b83-9ccb3fa1888b"
#define TX_SCREEN_INSTRUCTIONS "befc210f-0198-ffba-6948-f201431300be"

#define SND_OPEN "6ce74082-6781-fec8-76fc-a7b80f4993d1"
#define SND_CLOSE "08a7ec6b-ab2d-687f-b639-a2b222f74c56"

#define SND_A_OUT "5dad1f4d-c65b-fd8f-50dd-5d5b384ce060"
#define SND_A_IN "484c0af3-f58a-6102-7e84-93d95f9da585"

list screens = [
	TX_SCREEN_DEFAULT,
	TX_SCREEN_INSTRUCTIONS
];

#define B_POWER 36
#define B_B 27
#define B_A 21
#define B_PREV 24
#define B_NEXT 17
#define B_ANTENNAE 13

#define LID_BASIS 22
#define LID_1 25
#define LID_2 32
#define LID_3 43
#define SCREEN 2

list buttons = [B_POWER, B_B, B_A, B_PREV, B_NEXT, B_ANTENNAE];
list b_names = ["power", "b", "a", "prev", "next", "antennae"];
list commands = [
	"power",
	"command $USER $USER exec echo B pressed",
	"command $USER $USER exec echo A pressed",
	"command $USER $USER exec ray prev",
	"command $USER $USER exec ray next",
	"command $USER $USER exec ray antennae"
];

integer power_on;
key system;
key avatar;
integer CL;

integer door_open;
key hatch_operator;
integer timer_close_hatch;
float next_timer;

#define cmd_format(command) replace(replace(command, "$ME", llGetKey()), "$USER", toucher)

#define LID_DEFAULT_ROT llEuler2Rot(<0, 270, 180> * DEG_TO_RAD)

operate_door() {
	vector door_scale = getv(getp(LID_3, [PRIM_SIZE]), 0);
	vector door_pos = ZV;
	
	vector LID_1_HINGE = door_pos + <0, door_scale.y * -0.5, 0> * llEuler2Rot(<240 * DEG_TO_RAD, 0, 0>);
	vector LID_2_HINGE = door_pos + <0, door_scale.y * -0.5, 0> * llEuler2Rot(<120 * DEG_TO_RAD, 0, 0>);
	vector LID_3_HINGE = door_pos + <0, door_scale.y * -0.5, 0>;
	
	#define THETA 60
	#define STEP_SIZE 4.0
	#define SLEEP_SIZE 0.022
	float origin_theta = (float)door_open * THETA;
	float dest_theta = (float)(1 - door_open) * THETA;
	float step = (door_open * 2 - 1) * -STEP_SIZE; // maps [0,1] to [1,-1]
	
	// echo("from " + (string)origin_theta + " to " + (string)dest_theta + " by " + (string)step);
	
	if(!door_open)
		llLinkPlaySound(LID_BASIS, SND_OPEN, 1.0, SOUND_PLAY);
	else
		llLinkPlaySound(LID_BASIS, SND_CLOSE, 1.0, SOUND_PLAY);
	
	float t = origin_theta;
	while(llFabs(dest_theta - t) > llFabs(step) * 0.5 && (t <= THETA && t >= 0)) {
		setp(0, [
			PRIM_LINK_TARGET, LID_1,
				PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<t * DEG_TO_RAD, 0, 0> * llEuler2Rot(<0, 0, 240 * DEG_TO_RAD>))),
				PRIM_POS_LOCAL, door_pos,
			PRIM_LINK_TARGET, LID_2,
				PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<t * DEG_TO_RAD, 0, 0> * llEuler2Rot(<0, 0, 120 * DEG_TO_RAD>))),
				PRIM_POS_LOCAL, door_pos,
			PRIM_LINK_TARGET, LID_3,
				PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<t * DEG_TO_RAD, 0, 0>)),
				PRIM_POS_LOCAL, door_pos
		]);
		llSleep(SLEEP_SIZE);
		t += step;
	}
	
	setp(0, [
		PRIM_LINK_TARGET, LID_1,
			PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<dest_theta * DEG_TO_RAD, 0, 0> * llEuler2Rot(<0, 0, 240 * DEG_TO_RAD>))),
			PRIM_POS_LOCAL, door_pos,
		PRIM_LINK_TARGET, LID_2,
			PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<dest_theta * DEG_TO_RAD, 0, 0> * llEuler2Rot(<0, 0, 120 * DEG_TO_RAD>))),
			PRIM_POS_LOCAL, door_pos,
		PRIM_LINK_TARGET, LID_3,
			PRIM_ROT_LOCAL, LID_DEFAULT_ROT * (llEuler2Rot(<dest_theta * DEG_TO_RAD, 0, 0>)),
			PRIM_POS_LOCAL, door_pos
	]);
	
	door_open = !door_open;
}

#define ANTENNAE_BASIS 18
#define A_SCALE_MODEL 37
#define A_RIGHT 38
#define A_RIGHT_BALL 4
#define A_RIGHT_BASE 34
#define A_LEFT 47
#define A_LEFT_BALL 45
#define A_LEFT_BASE 44

integer antennae_extended = 1;
integer antennae_should_extend = 1;
antennae(integer extended) {
	// echo("Antennae now " + (string)extended);
	if(extended != antennae_extended) {
	
		antennae_extended = extended;
		
		vector ball_scale = getv(getp(A_SCALE_MODEL, [PRIM_SIZE]), 0);
		vector antenna_scale = <8, 1, 1> * ball_scale.x;
		float antenna_length = antenna_scale.x;
		vector antenna_L_pos = getv(getp(A_LEFT_BASE, [PRIM_POS_LOCAL]), 0);
		vector antenna_R_pos = getv(getp(A_RIGHT_BASE, [PRIM_POS_LOCAL]), 0);
		rotation antenna_L_rot = getr(getp(A_LEFT_BASE, [PRIM_ROT_LOCAL]), 0);
		rotation antenna_R_rot = getr(getp(A_RIGHT_BASE, [PRIM_ROT_LOCAL]), 0);
		float t;
		
		#define X_MIN 0.01625
		#define X_MAX 0.4
		
		#define A_STEP_SIZE 0.006
		#define A_SLEEP_SIZE 0.022
		
		float rtd = llGetRegionTimeDilation();
		if(rtd < 0.2)
			rtd = 0.2;
		
		float dest_x = (float)antennae_extended * (X_MAX - X_MIN) + X_MIN;
		float origin_x = (float)(1.0 - antennae_extended) * (X_MAX - X_MIN) + X_MIN;
		float step = (antennae_extended * 2 - 1) * A_STEP_SIZE / rtd; // maps [0,1] to [-1,1]
		
		llResetTime();
		if(extended)
			llLinkPlaySound(ANTENNAE_BASIS, SND_A_OUT, 1.0, SOUND_PLAY);
		else
			llLinkPlaySound(ANTENNAE_BASIS, SND_A_IN, 1.0, SOUND_PLAY);
		
		float last_time = llGetTime();
		float x = origin_x;
		while(llFabs(dest_x - x) > llFabs(step) * 0.5 && (x >= X_MIN && x <= X_MAX)) {
			setp(0, [
				PRIM_LINK_TARGET, A_RIGHT,
					PRIM_POS_LOCAL,
						antenna_R_pos - <antenna_length * x, 0, 0> * (antenna_R_rot),
					PRIM_SIZE,
						<8 * ((x) / (X_MAX)), 1, 1> * ball_scale.x,
				PRIM_LINK_TARGET, A_RIGHT_BALL,
					PRIM_POS_LOCAL,
						antenna_R_pos - <antenna_length * x, 0, 0> * (antenna_R_rot),
				PRIM_LINK_TARGET, A_LEFT,
					PRIM_POS_LOCAL,
						antenna_L_pos - <antenna_length * x, 0, 0> * (antenna_L_rot),
					PRIM_SIZE,
						<8 * ((x) / (X_MAX)), 1, 1> * ball_scale.x,
				PRIM_LINK_TARGET, A_LEFT_BALL,
					PRIM_POS_LOCAL,
						antenna_L_pos - <antenna_length * x, 0, 0> * (antenna_L_rot)
			]);
		
			llSleep(A_SLEEP_SIZE * rtd);
			float now = llGetTime();
			x += step * (now - last_time) / (A_SLEEP_SIZE * rtd);
			last_time = now;
		}

		x = dest_x;
		setp(0, [
			PRIM_LINK_TARGET, A_RIGHT,
				PRIM_POS_LOCAL,
					antenna_R_pos - <antenna_length * x, 0, 0> * (antenna_R_rot),
				PRIM_SIZE,
					<8 * ((x) / (X_MAX)), 1, 1> * ball_scale.x,
			PRIM_LINK_TARGET, A_RIGHT_BALL,
				PRIM_POS_LOCAL,
					antenna_R_pos - <antenna_length * x, 0, 0> * (antenna_R_rot),
			PRIM_LINK_TARGET, A_LEFT,
				PRIM_POS_LOCAL,
					antenna_L_pos - <antenna_length * x, 0, 0> * (antenna_L_rot),
				PRIM_SIZE,
					<8 * ((x) / (X_MAX)), 1, 1> * ball_scale.x,
			PRIM_LINK_TARGET, A_LEFT_BALL,
				PRIM_POS_LOCAL,
					antenna_L_pos - <antenna_length * x, 0, 0> * (antenna_L_rot)
		]);
		// echo((string)llGetTime());
	}
}

shutdown() {
	setp(SCREEN, [
		PRIM_COLOR, ALL_SIDES, ZV, 0,
		PRIM_GLOW, ALL_SIDES, 0
	]);
	
	// antennae are always retracted when powered down:
	antennae(FALSE);
	power_on = 0;
	
	if(!timer_close_hatch) // should always be the case
		llSetTimerEvent(0);
}

boot() {
	setp(SCREEN, [
		PRIM_COLOR, ALL_SIDES, ONES, 1,
		PRIM_GLOW, ALL_SIDES, 0.125
	]);
	
	// restore user preference:
	if(antennae_should_extend)
		antennae(TRUE);
	power_on = 1;
	if(door_open)
		operate_door();
	
	llSetTimerEvent(auto_cycle);
}

integer auto_cycle = 0;
integer image_index = 0;

default {
	state_entry() {
		CL = 105 - (integer)("0x" + substr(avatar = llGetOwner(), 29, 35));
		system = "";
		tell(avatar, CL, "ping");
		/* echo(llGetLinkName(LID_1));
		echo(llGetLinkName(LID_2));
		echo(llGetLinkName(LID_3)); */
	}
	
	timer() {
		if(timer_close_hatch) {
			operate_door();
			timer_close_hatch = 0;
		}
		
		if(auto_cycle && power_on) {
			if(++image_index >= count(screens)) {
				image_index = 0;
			}
			
			setp(SCREEN, [
				PRIM_TEXTURE, ALL_SIDES, gets(screens, image_index), <2, 1, 0>, ZV, PI_BY_TWO
			]);
		}
		
		if(!timer_close_hatch && !auto_cycle) {
			llSetTimerEvent(0);
		} else if(auto_cycle) {
			llSetTimerEvent(auto_cycle);
		}
	}
	
	on_rez(integer n) {
		CL = 105 - (integer)("0x" + substr(avatar = llGetOwner(), 29, 35));
		system = "";
	}
	
	touch_start(integer n) {
		while(n--) {
			integer pi = llDetectedLinkNumber(n);
			string part = llGetLinkName(pi);
			key toucher = llDetectedKey(n);
			
			integer pj = index(buttons, pi);
			if(~pj) {
				llTriggerSound(SND_BUTTON, 1);
				string c = gets(commands, pj);
				if(system) {
					if(c == "power") {
						if(power_on)
							c = "command $USER $USER power off";
						else
							c = "command $USER $USER power on";
					}
					tell(system, CL, cmd_format(c));
				} else {
					tell(avatar, CL, "ping");
					tell(toucher, 0, "Not yet connected to ARES. Please try again.");
				}
			} else if((part == "lid") && !power_on) {
				if(door_open) {
					timer_close_hatch = 1;
					hatch_operator = toucher;
					tell(llGetOwner(), CL, "hatch-blocked-q");
					if(next_timer < llGetTime() + 0.5) {
						next_timer = llGetTime() + 0.5;
						llSetTimerEvent(0.5);
					}
				} else {
					operate_door();
				}
			} else if(part != "socket" && !power_on) {
				tell(system, CL, "command " + (string)toucher + " " + (string)toucher + " power on");
			} else if(power_on) {
				tell(system, CL, "menu request " + (string)toucher);
			}
		}
	}
	
	link_message(integer src, integer n, string m, key id) {
		// echo((string)n + ": " + m + " (" + (string)id + ")");
		list argv = splitnulls(m, " ");
		string cmd = gets(argv, 0);
		if(n == 0) {
			if(m == "add-confirm" || ((m == "on" || m == "off"))) {
				
				if(m == "add-confirm" || system == "") {
					// register special commands here:
					
					system = id;
					tell(id, CL, "add-command ray");
				}
				
				if(m != "add-confirm") {
					integer new_power_on = (m == "on");
					if(new_power_on != power_on) {
						if(power_on)
							shutdown();
						else
							boot();
					}
				}
			} else if(cmd == "command") {
				// echo("Got command: " + m);
				key user = gets(argv, 1);
				string cmd = gets(argv, 2);
				string action = gets(argv, 3);
				if(action == "") {
					tell(user, 0,
						"Syntax: @ray <action>"
						+ "\n\nWhere <action> is one of: "
						+ "\n    next: Cycle to next image"
						+ "\n    prev: Cycle to previous image"
						+ "\n    auto <interval>: Automatically cycle images every <interval> seconds (0 = off)"
						+ "\n    reset: Restore default images"
						+ "\n    add <uuid> [<uuid>...]: Add a new image"
						+ "\n    remove: Remove current image"
						+ "\n    screens: List current screen images"
						+ "\n    command <button> <string>: Set command for button"
						+ "\n        Supported buttons: power, b, a, prev, next, antennae"
						+ "\n    commands: List current commands for all buttons"
						+ "\n    antennae [on|off]: Toggle or set antennae state"
					);
				} else if(action == "auto") {
					string new_auto = gets(argv, 4);
					if(new_auto != "") {
						auto_cycle = (integer)new_auto;
						if(power_on)
							llSetTimerEvent(auto_cycle);
					} else {
						tell(user, 0, "Auto cycle interval: " + (string)auto_cycle);
					}
				} else if(action == "next") {
					if(++image_index == count(screens)) {
						image_index = 0;
					}
					
					setp(SCREEN, [
						PRIM_TEXTURE, ALL_SIDES, gets(screens, image_index), <2, 1, 0>, ZV, PI_BY_TWO
					]);
				} else if(action == "prev") {
					if(--image_index < 0) {
						image_index = count(screens) - 1;
					}
					
					// echo("Screen now " + (string)image_index);
					
					setp(SCREEN, [
						PRIM_TEXTURE, ALL_SIDES, gets(screens, image_index), <2, 1, 0>, ZV, PI_BY_TWO
					]);
				} else if(action == "reset") {
					screens = [
						TX_SCREEN_DEFAULT,
						TX_SCREEN_INSTRUCTIONS
					];
					
				} else if(action == "add") {
					list new_screens = delrange(argv, 0, 3);
					if(count(new_screens)) {
						screens = llListInsertList(screens, new_screens, image_index + 1);
						image_index += 1;
						setp(SCREEN, [
							PRIM_TEXTURE, ALL_SIDES, gets(screens, image_index), <2, 1, 0>, ZV, PI_BY_TWO
						]);
						tell(user, 0, "Added " + (string)count(new_screens) + " screen(s).");
					} else {
						tell(user, 0, "No new screens specified. Please add by UUID.");
					}
					
				} else if(action == "remove") {
					screens = delitem(screens, image_index);
					tell(user, 0, "Removed 1 screen.");
					if(count(screens) == image_index) {
						if(image_index == 0) {
							tell(user, 0, "All images removed. Restoring default set.");
							screens = [
								TX_SCREEN_DEFAULT,
								TX_SCREEN_INSTRUCTIONS
							];
						} else {
							image_index = 0;
						}
						
						setp(SCREEN, [
							PRIM_TEXTURE, ALL_SIDES, gets(screens, image_index), <2, 1, 0>, ZV, PI_BY_TWO
						]);
					}
				} else if(action == "screens") {
					tell(user, 0, "Current screens: " + concat(screens, ", "));
				} else if(action == "command") {
					tell(user, 0, "Unimplemented. FIX BEFORE SHIPPING AAAAAHHHHH");
					string b_name = gets(argv, 4);
					integer b = index(b_names, b_name);
					if(~b) {
						string command = concat(delrange(argv, 0, 4), " ");
						if(gets(argv, 5) == "raw") {
							command = concat(delrange(argv, 0, 5), " ");
						} else if(command != "power" && gets(argv, 5) != "command") {
							command = "command $USER $USER exec " + command;
						}
						commands = alter(commands, [command], b, b);
						tell(user, 0, "Action for button " + b_name + " updated.");
					} else {
						tell(user, 0, "Invalid button name: " + b_name + ". Must be one of: " + concat(b_names, ", ") + ".");
					}
				} else if(action == "commands") {
					tell(user, 0, "Current commands:\n" + format_table(zip(b_names, commands), 2, ": "));
				} else if(action == "antennae") {
					integer new = !antennae_extended;
					string subaction = gets(argv, 4);
					if(subaction == "on")
						new = 1;
					else if(subaction == "off")
						new = 0;
					
					// user preference:
					antennae_should_extend = new;
					antennae(new);
				} else {
					tell(user, 0, "Unknown action: " + action + ". See '@ray' for instructions.");
				}
			} else if(cmd == "power" || cmd == "rate") {
				// ignore it
			} /*else {
				echo((string)n + ": " + m + " (" + (string)id + ")");
			}*/
		}
	}
}
