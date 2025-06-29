/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Main Controller Firmware
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

/*
	DEFINITION OF CTRL FLICKER-AUTOCONF
	
	Like the normal flicker-autoconf program, this uses prim descriptions to mark faces as being lit up. However it is a unique implementation with its own behaviors and mnemonic system.
	
	The basics are the same: a description starting with '#' will assign lighting color A to a comma-separated list (e.g. #0,1 for faces 0 and 1, or #-1 for all faces)
	
	To get other colors, different symbols are used.
	
		# - color A
		% - color B
		& - color C
		@ - color D
		% - color A at 10% intensity (for gauge backgrounds)
	
	Special annotations like "P" and "L" for screen-only mode and point light sources are not used.
*/

// supported screen types:
/*
	SCREEN_NONE - disables all screen-related code
	SCREEN_SXD - on-device planar screen using NS proprietary 8x1 microprims; requires no additional scripting
	SCREEN_AIDE - as SCREEN_SXD, but screen prims do not get color updates
	SCREEN_SUPERVISOR - projected cylindrical display
	SCREEN_PLANAR - projected flat display
	SCREEN_NIGHTFALL - on-device cylindrical screen
	SCREEN_REVENANT - projected hybrid display with accessory positioning HUD
	SCREEN_DAX3 - cylindrical image is on the outside of a tube prim with path cut 0.3625 to 0.6375 (centered at 0.5)
	SCREEN_AEGIS - concave cylindrical display and lever-action hinge
	SCREEN_DAYBREAK - only the background prim exists; non-interactive
*/

#if SCREEN_TYPE == SCREEN_SUPERVISOR
	#define OVERRIDE_TOUCH
	#define HOOK_POWER
	#define HOOK_COLOR
	#define HOOK_FAN
	#define HOOK_MENU
#endif

// all supported hooks and overrides:

// #define ALL_CAPS
// convert all UI text to caps
// #define POWER_OFF_BY_DEFAULT
// default to power off state after compilation (for debugging)

// #define FORCE_INSERT
// attempts to insert the battery when door closing fails
// #define HOOK_POWER
// causes transmission of "on", "off", "power", and "rate" link messages
// #define HOOK_COLOR
// causes transmission of "color", "color-2", "color-3", and "color-4" link messages
// #define HOOK_FAN
// causes transmission of "fan" link messages
// #define HOOK_MENU
// causes transmission of "menu-open" and "menu-close" link messages
// #define HOOK_CONDITION
// causes transmission of "broken", "fixed", "working", and "done" link messages
// #define HOOK_PROJECTOR
// causes forwarding of "projector" link messages
// #define INJECT_STARTUP
// causes state_entry() and on_rez() to call a function named extra_startup()
// #define FULL_COLOR_BOOT
// causes screen to switch to white during boot, and color 4 whenever another menu is displayed (screen color will not update on normal lighting change)

// #define OVERRIDE_TOUCH
// causes transmission of "touch" messages (and suppresses touch event - send "touch-screen", "menu-request", and "touch-hatch" in response)
// #define OVERRIDE_TP
// causes transmission of "tp" messages (and suppresses teleport effects)
// #define OVERRIDE_REPAIR
// causes transmission of "repair", "repaired" and "reclaim" messages (and suppresses these effects)
// #define OVERRIDE_SPARK
// causes transmission of "spark" events (and suppresses these effects)
// #define OVERRIDE_HATCH
// prevents hatch animation and blocking - use in combination with OVERRIDE_TOUCH
// #define INJECT_HATCH
// as OVERRIDE_HATCH, but only for replacing the operate_door() function in the same script

// most of the above are untested; feel free to experiment and file bug reports or submit fixes

// #define GAUGE_TEX_SCALE 1
// resize the gauge texture (added for Federator)

// #define GAUGE_TEX_ROT 0
// rotate the gauge texture (added for Federator)

// #define FAN_AXIS
// set the direction that the fan prim should spin around (default: <0, 0, 1>) - can also be calculated during extra_startup() by setting fan_axis variable
// #define MAX_FAN_SPEED
// set the number of radians per second to spin the fanblade (default: 10 * PI)
// #define REPAIR_LOOP
// sound effect to play while repairing
// #define RESURRECT_SFX_1
// first 9.8 second sample to play during resurrection
// #define RESURRECT_SFX_2
// second sample to play during resurrection
// #define METER_TEX
// image to use for power and rate gauges
// #define IMPACT_SOUNDS
// #define IMPACT_SOUND_COUNT
// sounds (randomly selected) for collisions
// #define HW_TP_SOUND
// sound of teleporting
// #define SPARKS_SOUNDS
// #define SPARK_SOUND_COUNT
// sounds (randomly selected) for sparks
// #define FAN_SOUNDS
// #define FAN_SOUND_COUNT
// sounds (in order from lowest to highest) for cooling system
// #define DOOR_MOVE_SOUND
// sound to play when opening or closing battery socket lid
	
// #define INJECT_LIGHTS
// call list custom_lights() during lights() function
// #define SUPPRESS_POWER_GAUGE
// don't draw linear power gauge
// #define SUPPRESS_RATE_GAUGE
// don't draw linear rate gauge

// #define VT_FONT PSYCHIC_INSTABILITY
// use the PSYCHIC INSTABILITY font for menus
// #define VT_FONT IGNEOUS_EXTRUSIVE
// use the IGNEOUS EXTRUSIVE font for menus
// #define VT_FONT MURKY_TRUTH
// use the MURKY TRUTH font for menus
// #define VT_FONT CLOCK_SKEW
// use the CLOCK SKEW font for menus (default)

// #define ALTER_MENU_IDENTIFIER
// rewrite the menu text to include "ARES" at the start

// #define SCREEN_TEXT_COLOR <formula>
// sets the screen text color to another value
// by default it is: c2 * 0.75 + ONES * 0.25
// c1 through c4 are the colors A through D

// #define SOUND_RADIUS <amount>
// sets the sound radius for speaker audio (default: 32)

#ifndef SOUND_RADIUS
	#define SOUND_RADIUS 32
#endif

// defines for SPARK_SOURCE, SPARK_SOURCE_2, TP_SOURCE, TP_SOURCE_2, and REPAIR_SOURCE
// these are optional and will change which prim generates these particles
// they must all be different prims
// TP_SOURCE and REPAIR_SOURCE will produce sounds, so don't reuse the speaker for them

#ifndef SPARK_SOURCE
	#define SPARK_SOURCE 2
#endif

#ifndef SPARK_SOURCE_2
	#define SPARK_SOURCE_2 3
#endif

#ifndef TP_SOURCE
	#define TP_SOURCE 4
#endif

#ifndef TP_SOURCE_2
	#define TP_SOURCE_2 5
#endif

#ifndef REPAIR_SOURCE
	#define REPAIR_SOURCE 8
#endif

#define VT_NO_POSITIONING
#include <variatype.h.lsl>

string sounds = "{}";

list parts; // [number, name of anything not named "Object"]
list texturables; // [number, color-type, desc of anything starting with a magic character]

key avatar;
key system;
key battery;

integer CL;
integer LL;

vector c1 = <0.7, 0.8, 1>;
vector c2 = <0, 1, 0.5>;
vector c3 = <1, 0, 0>;
vector c4 = <1, 1, 0>;

vector oc1;
vector oc2;
vector oc3;
vector oc4;

integer broken;
integer working;
integer bolts;
integer repairing;

float arousal = 0;
float integrity = 1;
float temperature = 293;
float power = 1.0;
float rate = 780.0;
float fan = 0.1;
float lubricant = 1.0;
#ifdef POWER_OFF_BY_DEFAULT
	integer power_on = 0;
#else
	integer power_on = 1;
#endif
integer opo;
integer obo;

#ifndef SOCKET_NAME
	#define SOCKET_NAME "socket"
#endif

integer FAN;
integer POWER_GAUGE;
integer RATE_GAUGE;
integer SOCKET;
integer SPEAKER;
integer SWITCH;
integer SCREEN;
integer PORT_0;
integer PORT_1;
integer LID;
integer LID_LEFT;
integer LID_RIGHT;
integer TEXT_START = 257;

integer block_tp = 0;

integer last_fan_sound;
float last_fan_vol;

float last_fan = 0.0001;
float last_rate;

integer door_open;

integer soothe;

#if SCREEN_TYPE == SCREEN_SXD || SCREEN_TYPE == SCREEN_AIDE || SCREEN_TYPE == SCREEN_DAYBREAK
// on these screen types only, suppress beep from displaying menu after session start
integer silence_menu;
#endif

// version reported to system over light bus:
#define VERSION "9.0"

#ifndef FAN_AXIS
	#define FAN_AXIS <0, 0, 1>
#endif

vector fan_axis;

#ifndef MAX_FAN_SPEED
	#define MAX_FAN_SPEED 31.415926535
#endif
#ifndef REPAIR_LOOP
	// #define REPAIR_LOOP "1afae2cb-d052-9898-a136-0158029c3104"
	#define REPAIR_LOOP "b29ac5ce-0331-91f6-f74b-77f2d5331710"
#endif
#ifndef RESURRECT_SFX_1
	#define RESURRECT_SFX_1 "8fb80de7-84dc-6a0b-2c45-9bec5047c861"
#endif
#ifndef RESURRECT_SFX_2
	#define RESURRECT_SFX_2 "7babc155-8786-8434-e0eb-c8bc70e6c902"
#endif
#ifndef METER_TEX
	#define METER_TEX "e8d9ff28-cd08-f792-cdc6-95533ee8d360"
#endif
#ifndef GAUGE_TEX_SCALE
	#define GAUGE_TEX_SCALE 1.0
#endif
#ifndef GAUGE_TEX_ROT
	#define GAUGE_TEX_ROT 0
#endif
#ifndef IMPACT_SOUNDS
	#define IMPACT_SOUNDS ["f5fd6f18-ef7d-85e3-4d5c-e56bd8e0e16a", "1b534a6e-e89b-3e11-ec5a-2da94f845b89", "b687ed67-61fc-bf07-8382-b07aba752df6"]
	#define IMPACT_SOUND_COUNT 3
#endif

#ifndef OVERRIDE_TP
	#ifndef HW_TP_SOUND
		#define HW_TP_SOUND "cac0eb64-a266-d869-d07b-34a5d6186eda"
	#endif
integer timer_tp;
#endif

#ifndef OVERRIDE_SPARK
	#ifndef SPARKS_SOUNDS
		#define SPARK_SOUNDS ["a834541c-7d8a-35bb-65b7-59b46fdfc3b9", "c6d8fbfd-6e35-1e7e-345c-bf11a229da99", "0ff5838b-d499-10a0-323c-ba591ea8c519", "bffe5e9c-68b1-1837-3ed9-8152287b1532"]
		#define SPARK_SOUND_COUNT 4
	#endif
integer timer_spark;
#endif

#ifndef FAN_SOUNDS
	#define FAN_SOUNDS ["93e08981-1ae7-c8bb-9279-bc8b2e0be901", "044ae71b-2dd9-280a-f7cd-fc9b43a059c8", "6009fcd2-d1bd-1ef7-055b-5b1e2fa84ba7", "1d1fef28-c156-c96a-0715-61e3efbec318", "8df963c9-dd37-ebdf-5a80-317b1f9befc2", "bd1116b9-b721-7331-f410-2dbba0dbddec"]
	#define FAN_SOUND_COUNT 6.0
	// yes that's a float, no you may not ask why
#endif

#ifndef DOOR_MOVE_SOUND
	#define DOOR_MOVE_SOUND "23011d73-c761-58a6-3a1d-466c760163cf"
#endif

#ifndef SWITCH_SOUND
	#define SWITCH_SOUND "fa14d152-a621-5a9c-f0d8-b1b67d3b5974"
#endif

#define play_sound(_name) llTriggerSound(getjs(sounds, [_name]), (float)getjs(sounds, ["volume"]))

#if SCREEN_TYPE == SCREEN_DAYBREAK
clear_screen(integer partial) {

}
#elif SCREEN_TYPE != SCREEN_NONE
clear_screen(integer partial) {
	// #define ALIGN_TEXT
	integer pmax = llGetNumberOfPrims();
	integer pi = TEXT_START;
	if(partial) {
		pi = TEXT_START + 18;
		pmax = TEXT_START + 66;
	}
	list acts;
	integer pc;
	while(pi <= pmax) {
		if(llGetLinkName(pi) == "text") {
			#ifdef ALIGN_TEXT
				integer raw_row = pc / 6;
				float row = (float)raw_row;
				row += 0.125;
				if(raw_row > 0) row += 0.875;
				if(raw_row > 1) row += 0.5625;
				if(raw_row > 9) row += 1.75;
				integer col = pc % 6;
				acts += [
					PRIM_LINK_TARGET, pi,
					PRIM_POS_LOCAL, <(float)(col - 2.5) * (-1.01 / 96.0), (float)(row) * (0.9 / 256.0) + 0.035, 0.0305>,
					PRIM_SIZE, <5.0/64.0, 5.0/96.0, 4.0/128.0>,
					PRIM_DESC, "T" + (string)raw_row + "," + (string)col,
					PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0
				];
			#else
				acts += [
					PRIM_LINK_TARGET, pi,
					PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0
				];
			#endif
			++pc;
		}
		++pi;
	}

	setp(0, acts);
}
#endif

lights() {
	float power_factor = power_on;
	if(broken && power_on && obo == 1) // first frame of broken state must be at full brightness (protects menus)
		power_factor = llFrand(1.0);
	
	list actions = [];
	if(FAN) {
		if(((last_fan == 0) ^ (fan == 0)) || llFabs(fan - last_fan) > 0.03) {
			// echo("Fan speed -> " + (string)fan);
			actions += [
				PRIM_LINK_TARGET, FAN,
				PRIM_OMEGA, fan_axis, fan * -MAX_FAN_SPEED, 1
			];
			
			last_fan = fan;
		}
		
		integer fan_sound;
		
		if(fan > 0) {
			fan_sound = (integer)(llSqrt(fan) * FAN_SOUND_COUNT);
		} else if(fan_sound) {
			fan_sound = 0;
		}
		
		if(fan_sound) {
			float fan_vol = llSqrt(fan);
			
			if(fan_sound != last_fan_sound) {
				llLinkPlaySound(FAN, gets(FAN_SOUNDS, fan_sound - 1), fan_vol, SOUND_LOOP);
			} else if(fan_vol != last_fan_vol) {
				llLinkAdjustSoundVolume(FAN, llSqrt(fan));
			}
			
			last_fan_vol = fan_vol;
			
		} else if(last_fan_sound) {
			llLinkStopSound(FAN);
			last_fan_vol = 0;
		}
		
		last_fan_sound = fan_sound;
	}
	
	#ifdef INJECT_LIGHTS
		actions += custom_lights();
	#endif
	
	#ifndef SUPPRESS_POWER_GAUGE
	if(POWER_GAUGE) {
		vector pc = c1;
		if(power < 0.10)
			pc = c3;
		else if(power < 0.20)
			pc = c4;
		
		actions += [
			PRIM_LINK_TARGET, POWER_GAUGE,
			PRIM_TEXTURE, ALL_SIDES, METER_TEX, <0.25, 1.0, 0> / GAUGE_TEX_SCALE, <power * -0.25 + 0.125, 0.125, 0>, GAUGE_TEX_ROT,
			PRIM_COLOR, ALL_SIDES, pc * power_factor, 1
		];
	}
	#endif
	
	#ifndef SUPPRESS_RATE_GAUGE
	if(RATE_GAUGE) {
		float p_rate = rate * 0.001;
		if(llFabs(p_rate - last_rate) > 0.001) {
			vector rc = c1;
			
			if(p_rate < 0) {
				p_rate = 1;
				rc = c2; // charging
			} else if(p_rate > 1) {
				p_rate = 1;
				rc = c4; // overpower
			}
			actions += [
				PRIM_LINK_TARGET, RATE_GAUGE,
				PRIM_TEXTURE, ALL_SIDES, METER_TEX, <0.25, 1.0, 0> / GAUGE_TEX_SCALE, <p_rate * -0.25 + 0.125, 0.375, 0>, GAUGE_TEX_ROT,
				PRIM_COLOR, ALL_SIDES, rc * power_factor, 1
			];
			// echo("Rate now: " + (string)rate);
			last_rate = p_rate;
		}
	}
	#endif
	
	integer major_pf = oc1 != c1 || oc2 != c2 || oc3 != c3 || oc4 != c4 || broken != obo || power_on != opo;
	
	if(major_pf || (power_on && broken)) {
		integer li = count(texturables);
		while(li) {
			li -= 3;
			vector pc = c1;
			integer pcm = geti(texturables, li + 1);
			if(pcm == 2)
				pc = c2;
			else if(pcm == 3)
				pc = c3;
			else if(pcm == 4)
				pc = c4;
			else if(pcm == 5)
				#ifndef SCREEN_TEXT_COLOR
				pc = c2 * 0.75 + ONES * 0.25;
				#else
				pc = SCREEN_TEXT_COLOR;
				#endif
			else if(pcm == 6)
				pc = c1 * 0.125;
			
			integer f = (integer)geti(texturables, li + 2);
			
			// pcm 5 explanation: use color c2 but transparently when off (text elements)
			
			if(pcm != 5 || major_pf) {
				// skip pcm 5 elements if we're only updating to animate the !broken state (too many, would be very laggy)
				// these elements will still be refreshed when entering/leaving !broken though
				
				actions += [
					PRIM_LINK_TARGET, geti(texturables, li),
					PRIM_COLOR, f, pc * power_factor, !(pcm == 5 && !power_on),
					PRIM_GLOW, f, 0.05 * power_factor,
					PRIM_FULLBRIGHT, f, (power_factor > 0.5)
				];
			}
			
			if(count(actions) > 12) {
				setp(0, actions);
				actions = [];
			}
		}
		
		obo = broken;
		opo = power_on;
		oc1 = c1;
		oc2 = c2;
		oc3 = c3;
		oc4 = c4;
	}
	
	setp(0, actions);
}

float next_timer;

key hatch_operator;
#ifndef OVERRIDE_HATCH
	integer timer_close_hatch;
	#ifndef INJECT_HATCH
		// to use INJECT_HATCH, #define INJECT_HATCH, and then modify a copy of this function:
		operate_door() {
			llLinkPlaySound(LID, DOOR_MOVE_SOUND, 1, SOUND_PLAY);
			
			door_open = !door_open;
			float sign = (float)(door_open << 1) - 1.0;
			float hi = 0;
			list lid_props = getp(LID, [PRIM_SIZE, PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
			vector lids = getv(lid_props, 0);
			vector lidp = getv(lid_props, 1);
			rotation lidr = getr(lid_props, 2);
			vector lido = <0, lids.y * 0.5, 0>; // lid on the SXD/A9 is sliced to be at the middle
			while(hi <= 1) {
				rotation lidnr = llEuler2Rot(<-120 * DEG_TO_RAD * hi * sign, 0, 0>);
				setp(LID, [
					PRIM_POS_LOCAL, lidp + (lido - lido * lidnr) * lidr,
					PRIM_ROT_LOCAL, lidnr * lidr
				]);
				hi += 0.1;
				llSleep(0.022);
			}
			
			tell(system, CL, "door " + (string)door_open);
		}
	#endif // INJECT_HATCH
#endif // OVERRIDE_HATCH

#ifdef OVERRIDE_TOUCH
screen_touch(key toucher, integer pi) {
	list ps = llParseString2List(gets(getp(pi, [PRIM_DESC]), 0), ["T", ","], []);
	integer row = (integer)gets(ps, 0);
	integer col = (integer)gets(ps, 1);
	if(row > 1 && row < 10) {
		integer num = (row - 2);
		if(button_count > 16) {
			num += (col & 6) << 2;
		} else if(button_count > 8) {
			num += (col / 3) << 3;
		}
		tell(system, CL, "menu select " + (string)num + " " + menu_name + " " + gets(splitnulls(current_menu, "\n"), num + 4)  + " " + (string)toucher);
	}
}
#endif

integer button_count = 0;
string current_menu;
string menu_name;

#if SCREEN_TYPE == SCREEN_SUPERVISOR || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS
	integer menu_is_open = 0;
#endif

default {
#if defined(OVERRIDE_TOUCH) || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS
	link_message(integer s, integer n, string m, key id) {
		// echo("ctrl: " + m);
		#ifdef OVERRIDE_TOUCH
			if(m == "touch-screen") {
				screen_touch(id, n);
			#ifndef OVERRIDE_HATCH
			} else if(m == "touch-hatch") {
				if(door_open) {
					timer_close_hatch = 1;
					hatch_operator = id;
					tell(llGetOwner(), CL, "hatch-blocked-q");
					if(next_timer < llGetTime() + 0.5) {
						next_timer = llGetTime() + 0.5;
						llSetTimerEvent(0.5);
					}
				} else {
					operate_door();
				}
			#else 
			} else if(m == "touch-hatch") {
				hatch_operator = id;
			#endif
			} else
		#endif
		if(m == "menu-request") {
			tell(system, CL, "menu request " + (string)id);
		} else if(m == "menu-start") {
			tell(system, CL, "menu start " + (string)id);
		} else if(m == "menu-end") {
			tell(system, CL, "menu end " + (string)id);
			#if SCREEN_TYPE == SCREEN_SUPERVISOR || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS
				menu_is_open = 0;
				// echo("menu closed");
			#endif
		}
	}
#endif

	changed(integer w) {
		if(w & CHANGED_TELEPORT) {
			if(block_tp) {
				block_tp = 0;
			} else if(power_on && !soothe) {
				#ifdef OVERRIDE_TP
				linked(LINK_THIS, 0, "tp", "");
				#else
				llLinkPlaySound(4, HW_TP_SOUND, 1, SOUND_PLAY);
			
				llLinkParticleSystem(TP_SOURCE, [
					PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
					PSYS_SRC_BURST_RADIUS,0.3,
					PSYS_PART_START_COLOR,c1,
					PSYS_PART_END_COLOR,<0.000000,0.000000,0.000000>,
					PSYS_PART_START_ALPHA,1,
					PSYS_PART_END_ALPHA,1,
					PSYS_PART_START_GLOW,1,
					PSYS_PART_END_GLOW,0,
					PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
					PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
					PSYS_PART_START_SCALE,<0.0625,4.000000,0.000000>,
					PSYS_PART_END_SCALE,<0.0625,2.000000,0.000000>,
					PSYS_SRC_TEXTURE,"",
					PSYS_SRC_MAX_AGE,0.5,
					PSYS_PART_MAX_AGE,0.3,
					PSYS_SRC_BURST_RATE,0,
					PSYS_SRC_BURST_PART_COUNT,80,
					PSYS_SRC_BURST_SPEED_MIN,0.1,
					PSYS_SRC_BURST_SPEED_MAX,0.2,
					PSYS_PART_FLAGS, 0x123
						/*PSYS_PART_EMISSIVE_MASK |
						PSYS_PART_FOLLOW_VELOCITY_MASK |
						PSYS_PART_INTERP_COLOR_MASK |
						PSYS_PART_INTERP_SCALE_MASK*/
				]);

				llLinkParticleSystem(TP_SOURCE_2, [
					PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
					PSYS_SRC_BURST_RADIUS,0.7,
					PSYS_SRC_TARGET_KEY,llGetKey(),
					PSYS_PART_START_COLOR,c1,
					PSYS_PART_END_COLOR,<0.000000,0.000000,0.000000>,
					PSYS_PART_START_ALPHA,1,
					PSYS_PART_END_ALPHA,1,
					PSYS_PART_START_GLOW,1,
					PSYS_PART_END_GLOW,0,
					PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
					PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
					PSYS_PART_START_SCALE,<2.000000,2.000000,0.000000>,
					PSYS_PART_END_SCALE,<3.000000,3.000000,0.000000>,
					PSYS_SRC_TEXTURE,"",
					PSYS_SRC_MAX_AGE,0.3,
					PSYS_PART_MAX_AGE,0.3,
					PSYS_SRC_BURST_RATE,0,
					PSYS_SRC_BURST_PART_COUNT,20,
					PSYS_SRC_BURST_SPEED_MIN,24,
					PSYS_SRC_BURST_SPEED_MAX,24,
					PSYS_PART_FLAGS, 0x163
						/* PSYS_PART_EMISSIVE_MASK |
						PSYS_PART_FOLLOW_VELOCITY_MASK |
						PSYS_PART_INTERP_COLOR_MASK |
						PSYS_PART_INTERP_SCALE_MASK |
						PSYS_PART_TARGET_POS_MASK */
				]);
				
				timer_tp = 1;
				if(next_timer < llGetTime() + 1) {
					next_timer = llGetTime() + 2;
					llSetTimerEvent(2);
				}
				#endif
			}
		}
	}
	
	timer() {
		#ifndef OVERRIDE_TP
		if(timer_tp) {
			llLinkParticleSystem(TP_SOURCE, []);
			llLinkParticleSystem(TP_SOURCE_2, []);
			timer_tp = 0;
		}
		#endif
		
		#ifndef OVERRIDE_SPARK
		if(timer_spark) {
			llLinkParticleSystem(SPARK_SOURCE, []);
			llLinkParticleSystem(SPARK_SOURCE_2, []);
			timer_spark = 0;
		}
		#endif
		
		#ifndef OVERRIDE_HATCH
		if(timer_close_hatch) {
			operate_door();
			timer_close_hatch = 0;
		}
		#endif
		
		if(broken && power_on) {
			lights();
		}
		
		if(!broken)
			llSetTimerEvent(0);
		next_timer = 0;
		llResetTime();
	}

	#ifndef OVERRIDE_TOUCH
	touch_start(integer n) {
		while(n--) {
			key toucher = llDetectedKey(n);
			integer pi = llDetectedLinkNumber(n);
			string part = llGetLinkName(pi);
			
			if((part == "lid" || part == "lidl" || part == "lidr") && !power_on) {
				#ifdef OVERRIDE_HATCH
				linked(LINK_THIS, 0, "hatch", "");
				#else
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
				#endif
			#if (SCREEN_TYPE != SCREEN_NONE) && (SCREEN_TYPE != SCREEN_DAYBREAK)
			} else if(part == "text" && power_on) {
				list ps = llParseString2List(gets(getp(pi, [PRIM_DESC]), 0), ["T", ","], []);
				integer row = (integer)gets(ps, 0);
				integer col = (integer)gets(ps, 1);
				if(row > 1 && row < 10) {
					integer num = (row - 2);
					if(button_count > 16) {
						num += (col & 6) << 2;
					} else if(button_count > 8) {
						num += (col / 3) << 3;
					}
					tell(system, CL, "menu select " + (string)num + " " + menu_name + " " + gets(splitnulls(current_menu, "\n"), num + 4)  + " " + (string)toucher);
				}
			#endif
			} else if(part == "switch" && power_on) {
				tell(system, CL, "command " + (string)toucher + " " + (string)toucher + " power off");
			} else if(part == "Object" || part == "lid" || part == "lidl" || part == "lidr" || part == "switch" || pi == 1) {
				// if "Object" || ("lid" && power_on)
				if(power_on) {
					#if SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS
						if(menu_is_open) {
							tell(system, CL, "menu request " + (string)toucher);
						} else {
							tell(system, CL, "menu start " + (string)toucher);
						}
					#else
						tell(system, CL, "menu request " + (string)toucher);
					#endif
				} else {
					tell(system, CL, "command " + (string)toucher + " " + (string)toucher + " power on");
				}
			}
			
			if(part == "switch")
				llTriggerSound(SWITCH_SOUND, 1);
		}
	}
	#endif

	listen(integer c, string n, key id, string m) {
		if(llGetOwnerKey(id) == avatar) {
			if(m == "hatch-blocked") {
				#ifdef FORCE_INSERT
					tell(system, CL, "command " + (string)hatch_operator + " " + (string)NULL_KEY + " device battery add-confirm");
					if(door_open) {
						llSleep(1);
						operate_door();
					}
				#else
					tell(hatch_operator, 0, "Cannot close hatch while ejected battery is present.");
				#endif
				#if defined(OVERRIDE_HATCH) && !defined(FORCE_INSERT)
					linked(LINK_THIS, 0, "hatch-blocked", id);
				#else
					timer_close_hatch = 0;
				#endif
			} else if(m == "pong" || m == "probe") {
				system = id;
				tell(system, c, "add controller " + VERSION);
				#ifdef HOOK_MENU
					linked(LINK_THIS, 0, "menu-close", system);
				#endif
			} else if(m == "on") {
				#ifdef HOOK_POWER
				linked(LINK_THIS, 0, "on", system);
				#endif
				#if SCREEN_TYPE == SCREEN_SUPERVISOR || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS
					if(!power_on) {
						menu_is_open = 0;
						// echo("menu closed");
					}
				#endif
				power_on = 1;
				#ifndef OVERRIDE_HATCH
				if(door_open)
					operate_door();
				#endif
				if(SWITCH)
					setp(SWITCH, [PRIM_ROT_LOCAL, llEuler2Rot(<PI, 0, PI>)]);
			} else if(m == "off") {
				#ifdef HOOK_POWER
				linked(LINK_THIS, 0, "off", system);
				linked(LINK_THIS, 0, "rate 0", "");
				#endif
				#ifdef HOOK_FAN
				linked(LINK_THIS, 0, "fan 0", "");
				#endif
				power_on = 0;
				fan = rate = 0;
				#ifndef OVERRIDE_REPAIR
				if(repairing) {
					llLinkStopSound(REPAIR_SOURCE);
					llLinkParticleSystem(REPAIR_SOURCE, []);
				}
				#endif
				if(SWITCH)
					setp(SWITCH, [PRIM_ROT_LOCAL, llEuler2Rot(<PI, 0, PI * 1.25>)]);
			} else if(m == "broken") {
				broken = 1;
				#ifdef HOOK_CONDITION
					linked(LINK_THIS, 0, "broken", "");
				#endif
				if(
					#ifndef OVERRIDE_TP
						timer_tp == 0 &&
					#endif
					#ifndef OVERRIDE_HATCH
						timer_close_hatch == 0 &&
					#endif
					timer_spark == 0) {
					llSetTimerEvent(0.25);
				}
			} else if(m == "fixed") {
				#ifdef HOOK_CONDITION
					linked(LINK_THIS, 0, "fixed", "");
				#endif
				broken = 0;
			} else if(m == "working") {
				#ifdef HOOK_CONDITION
					linked(LINK_THIS, 0, "working", "");
				#endif
				working = 1;
			} else if(m == "done") {
				#ifdef HOOK_CONDITION
					linked(LINK_THIS, 0, "done", "");
				#endif
				working = 0;
			} else if(m == "bolts on") {
				bolts = 1;
				echo("@detach=n");
			} else if(m == "bolts off") {
				bolts = 0;
				echo("@detach=y");
			} else if(m == "add-confirm" && id == system) {
				tell(system, c, "power-q");
				tell(system, c, "color-q");
				llSleep(0.1);
				tell(system, c, "conf-get id.callsign");
				llSleep(0.2);
				tell(system, c, "conf-get interface.sound");
				llSleep(0.2);
				tell(system, c, "conf-get hardware.controller");
				#ifndef OVERRIDE_TOUCH
					#if SCREEN_TYPE != SCREEN_NONE && SCREEN_TYPE != SCREEN_DAYBREAK
						tell(system, c, "menu start " + (string)avatar); // menu <session> get|touch|... [<button>] <uuid> 
					#endif
				#endif
				
				#ifdef HOOK_MENU
					linked(LINK_THIS, 0, "menu-close", "");
				#endif
				
				jump socket_aperture;
			} else if(m == "socket-aperture-q") {
				jump socket_aperture;
				// echo("Main controller installed.");
			} else {
				list argv = splitnulls(m, " ");
				string cmd = gets(argv, 0);
				if(cmd == "fx") {
					string type = gets(argv, 1);
					if(type == "s") { // fx s <sound> <vol> (speaker sound)
						if(SPEAKER) {
							llLinkPlaySound(SPEAKER, gets(argv, 2), (float)gets(argv, 3), SOUND_PLAY);
						}
					} else if(type == "tp") { // block next tp effect
						block_tp = 1;
						// echo("next TP effect blocked?");
						
					} else if(type == "reclaim") {
						#ifdef OVERRIDE_REPAIR
						linked(LINK_THIS, 0, "reclaim", "");
						#else
						llLinkParticleSystem(REPAIR_SOURCE, [
							PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE,
							PSYS_SRC_BURST_RADIUS,0.1,
							PSYS_SRC_ANGLE_BEGIN,0.5,
							PSYS_SRC_ANGLE_END,1.2,
							PSYS_PART_START_COLOR,<0.000000,1.000000,1.000000>,
							PSYS_PART_END_COLOR,<0.000000,1.000000,0.000000>,
							PSYS_PART_START_ALPHA,1,
							PSYS_PART_END_ALPHA,1,
							PSYS_PART_START_GLOW,0.2,
							PSYS_PART_END_GLOW,0.2,
							PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
							PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
							PSYS_PART_START_SCALE,<0.062500,0.125000,0.000000>,
							PSYS_PART_END_SCALE,<0.062500,0.250000,0.000000>,
							PSYS_SRC_TEXTURE,"4d96f59b-73e9-b503-b653-cc415582aa1e",
							PSYS_SRC_MAX_AGE,19,
							PSYS_PART_MAX_AGE,0.8,
							PSYS_SRC_BURST_RATE,0.022,
							PSYS_SRC_BURST_PART_COUNT,20,
							PSYS_SRC_ACCEL,<0.000000,0.000000,-2.000000>,
							PSYS_SRC_OMEGA,<0.000000,0.000000,6.282000>,
							PSYS_SRC_BURST_SPEED_MIN,0.4,
							PSYS_SRC_BURST_SPEED_MAX,1.8,
							PSYS_PART_FLAGS, 0x123
								/*PSYS_PART_EMISSIVE_MASK |
								PSYS_PART_FOLLOW_VELOCITY_MASK |
								PSYS_PART_INTERP_COLOR_MASK |
								PSYS_PART_INTERP_SCALE_MASK*/
						]);
						llLinkStopSound(REPAIR_SOURCE);
						llLinkSetSoundQueueing(REPAIR_SOURCE, TRUE);
						llLinkPlaySound(REPAIR_SOURCE, RESURRECT_SFX_1, 1, SOUND_PLAY);
						llSleep(9.98);
						llLinkPlaySound(REPAIR_SOURCE, RESURRECT_SFX_2, 1, SOUND_PLAY);
						llSleep(9.5);
						llLinkParticleSystem(REPAIR_SOURCE, []);
						#endif
					
					} else if(type == "repair") { // fx repair on|off
						if(repairing = (gets(argv, 2) == "on")) {
							#ifdef OVERRIDE_REPAIR
							linked(LINK_THIS, 0, "repair", "");
							#else
							llLinkPlaySound(REPAIR_SOURCE, REPAIR_LOOP, 1, SOUND_LOOP);
						
							llLinkParticleSystem(REPAIR_SOURCE, [
								PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
								PSYS_SRC_BURST_RADIUS,0.2,
								PSYS_SRC_ANGLE_BEGIN,1.3,
								PSYS_SRC_ANGLE_END,2.5,
								PSYS_SRC_TARGET_KEY,llGetKey(),
								PSYS_PART_START_COLOR,<0.000000,1.000000,1.000000>,
								PSYS_PART_END_COLOR,<0.000000,1.000000,0.000000>,
								PSYS_PART_START_ALPHA,1,
								PSYS_PART_END_ALPHA,1,
								PSYS_PART_START_GLOW,0.1,
								PSYS_PART_END_GLOW,0.1,
								PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
								PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
								PSYS_PART_START_SCALE,<0.062500,0.125000,0.000000>,
								PSYS_PART_END_SCALE,<0.062500,0.250000,0.000000>,
								PSYS_SRC_TEXTURE,"4d96f59b-73e9-b503-b653-cc415582aa1e",
								PSYS_SRC_MAX_AGE,0,
								PSYS_PART_MAX_AGE,2,
								PSYS_SRC_BURST_RATE,0.125,
								PSYS_SRC_BURST_PART_COUNT,50,
								PSYS_SRC_ACCEL,<0.000000,0.000000,-5.000000>,
								PSYS_SRC_BURST_SPEED_MIN,0.5,
								PSYS_SRC_BURST_SPEED_MAX,3,
								PSYS_PART_FLAGS, 0x163
									/*PSYS_PART_EMISSIVE_MASK |
									PSYS_PART_FOLLOW_VELOCITY_MASK |
									PSYS_PART_INTERP_COLOR_MASK |
									PSYS_PART_INTERP_SCALE_MASK |
									PSYS_PART_TARGET_POS_MASK */
							]);
							/*
							llLinkParticleSystem(8, [
								PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
								PSYS_SRC_BURST_RADIUS,0.1,
								PSYS_SRC_ANGLE_BEGIN,3.14,
								PSYS_SRC_ANGLE_END,3,
								PSYS_SRC_TARGET_KEY,llGetKey(),
								PSYS_PART_START_COLOR,c1,
								PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
								PSYS_PART_START_ALPHA,1,
								PSYS_PART_END_ALPHA,1,
								PSYS_PART_START_GLOW,1,
								PSYS_PART_END_GLOW,1,
								PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
								PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
								PSYS_PART_START_SCALE,<0.063000,0.063000,0.000000>,
								PSYS_PART_END_SCALE,<0.500000,0.500000,0.000000>,
								PSYS_SRC_TEXTURE,"c49f8b90-d50f-8e2c-93ae-570e0f9da5cb",
								PSYS_SRC_MAX_AGE,0,
								PSYS_PART_MAX_AGE,3,
								PSYS_SRC_BURST_RATE,0.3,
								PSYS_SRC_BURST_PART_COUNT,5,
								PSYS_SRC_ACCEL,<0.000000,0.000000,1.100000>,
								PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
								PSYS_SRC_BURST_SPEED_MIN,0.5,
								PSYS_SRC_BURST_SPEED_MAX,1,
								PSYS_PART_FLAGS,
									0 |
									PSYS_PART_EMISSIVE_MASK |
									PSYS_PART_FOLLOW_VELOCITY_MASK |
									PSYS_PART_TARGET_POS_MASK
							]);
							llLinkParticleSystem(9, [
								PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
								PSYS_SRC_BURST_RADIUS,0.1,
								PSYS_SRC_ANGLE_BEGIN,3.14,
								PSYS_SRC_ANGLE_END,3,
								PSYS_SRC_TARGET_KEY,llGetKey(),
								PSYS_PART_START_COLOR,c1,
								PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
								PSYS_PART_START_ALPHA,1,
								PSYS_PART_END_ALPHA,1,
								PSYS_PART_START_GLOW,1,
								PSYS_PART_END_GLOW,1,
								PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
								PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
								PSYS_PART_START_SCALE,<0.063000,0.063000,0.000000>,
								PSYS_PART_END_SCALE,<0.500000,0.500000,0.000000>,
								PSYS_SRC_TEXTURE,"c49f8b90-d50f-8e2c-93ae-570e0f9da5cb",
								PSYS_SRC_MAX_AGE,0,
								PSYS_PART_MAX_AGE,3,
								PSYS_SRC_BURST_RATE,0.3,
								PSYS_SRC_BURST_PART_COUNT,5,
								PSYS_SRC_ACCEL,<0.000000,0.000000,-2.30000>,
								PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
								PSYS_SRC_BURST_SPEED_MIN,0.5,
								PSYS_SRC_BURST_SPEED_MAX,1,
								PSYS_PART_FLAGS,
									0 |
									PSYS_PART_EMISSIVE_MASK |
									PSYS_PART_FOLLOW_VELOCITY_MASK |
									PSYS_PART_TARGET_POS_MASK
							]);
							*/
							#endif
						} else {
							#ifdef OVERRIDE_REPAIR
							linked(LINK_THIS, 0, "repaired", "");
							#else
							llLinkStopSound(REPAIR_SOURCE);
							llLinkParticleSystem(REPAIR_SOURCE, []);
							// llLinkParticleSystem(9, []);
							#endif
						}
					} else if(type == "spark") { // fx spark
						#ifdef OVERRIDE_SPARK
						linked(LINK_THIS, 0, "spark", "");
						#else
						llTriggerSound(gets(SPARK_SOUNDS, (integer)llFrand(SPARK_SOUND_COUNT)), 1);
						
						vector sparkc = c3 * 0.5 + ONES * 0.5;
						
						llLinkParticleSystem(SPARK_SOURCE, [
							PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
							PSYS_SRC_BURST_RADIUS,0,
							PSYS_PART_START_COLOR,sparkc,
							PSYS_PART_END_COLOR,c3,
							PSYS_PART_START_ALPHA,1,
							PSYS_PART_END_ALPHA,1,
							PSYS_PART_START_GLOW,1,
							PSYS_PART_END_GLOW,0,
							PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
							PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
							PSYS_PART_START_SCALE,<0.062500,0.062500,0.000000>,
							PSYS_PART_END_SCALE,<0.062500,2.000000,0.000000>,
							PSYS_SRC_TEXTURE,"eb0639b7-ebf6-6417-e61d-6c4261e74d43",
							PSYS_SRC_MAX_AGE,0.2,
							PSYS_PART_MAX_AGE,2,
							PSYS_SRC_BURST_RATE,0,
							PSYS_SRC_BURST_PART_COUNT,25,
							PSYS_SRC_ACCEL,<0.000000,0.000000,-19.000000>,
							PSYS_SRC_BURST_SPEED_MIN,4,
							PSYS_SRC_BURST_SPEED_MAX,11,
							PSYS_PART_FLAGS, 0x12b
								/*
								PSYS_PART_EMISSIVE_MASK |
								PSYS_PART_FOLLOW_VELOCITY_MASK |
								PSYS_PART_INTERP_COLOR_MASK |
								PSYS_PART_INTERP_SCALE_MASK |
								PSYS_PART_WIND_MASK */
						]);
						
						llLinkParticleSystem(SPARK_SOURCE_2, [
							PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
							PSYS_SRC_BURST_RADIUS,0.1,
							PSYS_PART_START_COLOR,sparkc,
							PSYS_PART_END_COLOR,ZV,
							PSYS_PART_START_ALPHA,1,
							PSYS_PART_END_ALPHA,0,
							PSYS_PART_START_GLOW,0,
							PSYS_PART_END_GLOW,0,
							PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
							PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
							PSYS_PART_START_SCALE,<0.5, 0.5, 0>,
							PSYS_PART_END_SCALE,<0.25, 0.25, 0>,
							PSYS_SRC_TEXTURE,"dde81071-8e1f-119b-76b0-03fe5aa02175",
							PSYS_SRC_MAX_AGE,0.3,
							PSYS_PART_MAX_AGE,0.3,
							PSYS_SRC_BURST_RATE,0.1,
							PSYS_SRC_BURST_PART_COUNT,45,
							PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
							PSYS_SRC_BURST_SPEED_MIN,0,
							PSYS_SRC_BURST_SPEED_MAX,0,
							PSYS_SRC_TARGET_KEY,llGetKey(),
							PSYS_PART_FLAGS, 0x14b
								/*
								PSYS_PART_TARGET_POS_MASK |
								PSYS_PART_EMISSIVE_MASK |
								PSYS_PART_INTERP_COLOR_MASK |
								PSYS_PART_INTERP_SCALE_MASK |
								PSYS_PART_WIND_MASK */
						]);
						
						timer_spark = 1;
						if(next_timer < llGetTime() + 0.5) {
							next_timer = llGetTime() + 1;
							llSetTimerEvent(1);
						}
						#endif
					}
				} else if(cmd == "device") {
					string dname = gets(argv, 1);
					if(dname == "battery") {
						battery = gets(argv, 2);
					}
				#ifdef HOOK_PROJECTOR
				} else if(cmd == "projector") {
					linked(LINK_THIS, 0, m, id);
				#endif
				} else if(cmd == "color") {
					c1 = <(float)gets(argv, 1), (float)gets(argv, 2), (float)gets(argv, 3)>;
					#ifdef HOOK_COLOR
					linked(LINK_THIS, 0, "color " + (string)c1, "");
					#endif
				} else if(cmd == "color-2") {
					c2 = <(float)gets(argv, 1), (float)gets(argv, 2), (float)gets(argv, 3)>;
					#ifdef HOOK_COLOR
					linked(LINK_THIS, 0, "color-2 " + (string)c2, "");
					#endif
				} else if(cmd == "color-3") {
					c3 = <(float)gets(argv, 1), (float)gets(argv, 2), (float)gets(argv, 3)>;
					#ifdef HOOK_COLOR
					linked(LINK_THIS, 0, "color-3 " + (string)c3, "");
					#endif
				} else if(cmd == "color-4") {
					c4 = <(float)gets(argv, 1), (float)gets(argv, 2), (float)gets(argv, 3)>;
					#ifdef HOOK_COLOR
					linked(LINK_THIS, 0, "color-4 " + (string)c4, "");
					#endif
				} else if(cmd == "fan") {
					fan = (float)gets(argv, 1) * 0.01;
					if(fan < 0.02)
						fan = 0.02;
					if(!power_on)
						fan = 0;
					#ifdef HOOK_FAN
					linked(LINK_THIS, 0, "fan " + (string)fan, "");
					#endif
				} else if(cmd == "power") {
					power = (float)gets(argv, 1);
					#ifdef HOOK_POWER
					linked(LINK_THIS, 0, m, "");
					#endif
				} else if(cmd == "rate") {
					rate = (float)gets(argv, 1);
					#ifdef HOOK_POWER
					linked(LINK_THIS, 0, m, "");
					#endif
					/*if(rate > 0)
						fan = llSqrt(rate) * 0.005;
					else
						fan = 0;
					
					if(fan > 1.0)
						fan = 1.0; */
				} else if(cmd == "arousal") {
					arousal = (float)gets(argv, 1);
				} else if(cmd == "lubricant") {
					float nlv = (float)gets(argv, 2);
					if(nlv > 0)
						lubricant = (float)gets(argv, 1) / nlv;
				} else if(cmd == "temperature") {
					temperature = (float)gets(argv, 1);
				} else if(cmd == "conf") {
					/*list lines = split(delstring(m, 0, 4), "\n"); // remove 'conf '
					integer i = count(lines);
					while(i--) {
						argv = split(gets(lines, i), " ");*/
						string a1 = gets(argv, 1);
						string p = concat(delrange(argv, 0, 1), " ");
						if(a1 == "hardware.controller") {
							soothe = (integer)getjs(p, ["soothe"]);
						} else if(a1 == "id.callsign") {
							llSetObjectName(p + " (controller)");
						} else if(a1 == "interface.sound") {
							sounds = p;
						}
					// }
				#if SCREEN_TYPE != SCREEN_NONE
				} else if(cmd == "menu" && power_on) {
					current_menu = m;
					menu_name = gets(argv, 1);
					if(llOrd(menu_name, LAST) == 0x0a)
						menu_name = delstring(menu_name, LAST, LAST);
					
					if(menu_name == "boot" || menu_name == "end") {
						#ifdef HOOK_MENU
						if(menu_name == "end")
							linked(LINK_THIS, 0, "menu-close", "");
						#endif
						clear_screen(FALSE);
						#if SCREEN_TYPE == SCREEN_SXD || SCREEN_TYPE == SCREEN_AIDE || SCREEN_TYPE == SCREEN_DAYBREAK
							setp(SCREEN, [PRIM_TEXTURE, ALL_SIDES, llGetInventoryKey("m_boot"), ONES, ZV, 
							#if SCREEN_TYPE == SCREEN_DAYBREAK
								PI_BY_TWO
							#else
								0
							#endif
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, ALL_SIDES, ONES, 1
							#endif
							]);
							
							#ifndef OVERRIDE_TOUCH
							if(menu_name == "end") {
								silence_menu = 1;
								tell(system, CL, "menu start " + (string)avatar);
							}
							#endif
						
						#elif SCREEN_TYPE == SCREEN_PLANAR
							setp(SCREEN, [PRIM_TEXTURE, ALL_SIDES, llGetInventoryKey("m_boot"), ONES, ZV, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, ALL_SIDES, ONES, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_SUPERVISOR
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <3.6, 1, 0>, <0.9, 1, 0>, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, ONES, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_NIGHTFALL
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <4, 1, 0>, <0, 0, 0>, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, ONES, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_AEGIS
							setp(SCREEN, [PRIM_TEXTURE, 2, llGetInventoryKey("m_boot"), <-3, 3.8, 0>, <0, -0.445, 0>, PI_BY_TWO
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, ONES, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_DAX3
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <3, 0.9, 0>, <0, 0, 0>, PI_BY_TWO
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, ONES, 1
							#endif
							]);
						#endif
					} else {
						#if SCREEN_TYPE == SCREEN_SXD || SCREEN_TYPE == SCREEN_AIDE || SCREEN_TYPE == SCREEN_DAYBREAK
							if(silence_menu) {
								silence_menu = 0;
							} else {
								play_sound("go");
							}
						#else
							play_sound("go");
						#endif
						clear_screen(TRUE);
						#if SCREEN_TYPE == SCREEN_SXD || SCREEN_TYPE == SCREEN_AIDE || SCREEN_TYPE == SCREEN_DAYBREAK
							setp(SCREEN, [PRIM_TEXTURE, ALL_SIDES, llGetInventoryKey("m_main"), ONES, ZV, 
							#if SCREEN_TYPE == SCREEN_DAYBREAK
								PI_BY_TWO
							#else
								0
							#endif
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, ALL_SIDES, c4, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_PLANAR
							setp(SCREEN, [PRIM_TEXTURE, ALL_SIDES, llGetInventoryKey("m_main"), ONES, ZV, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, ALL_SIDES, c4, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_SUPERVISOR
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_main"), <3.6, 1, 0>, <0.9, 1, 0>, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, c4, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_NIGHTFALL
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_main"), <4, 1, 0>, <0, 0, 0>, 0
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, c4, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_DAX3
							setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_main"), <3, 0.9, 0>, <0, 0, 0>, PI_BY_TWO
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, c4, 1
							#endif
							]);
						#elif SCREEN_TYPE == SCREEN_AEGIS
							setp(SCREEN, [PRIM_TEXTURE, 2, llGetInventoryKey("m_main"), <-3, 3.8, 0>, <0, -0.445, 0>, PI_BY_TWO
							#ifdef FULL_COLOR_BOOT
							, PRIM_COLOR, 1, c4, 1
							#endif
							]);
						#endif
						
					}
					
					#ifdef HOOK_MENU
					if(menu_name != "end") {
						#if SCREEN_TYPE == SCREEN_SUPERVISOR || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3
							menu_is_open = 1;
							// echo("menu open");
						#endif
						linked(LINK_THIS, 0, "menu-open", "");
					}
					#endif
					
					#if SCREEN_TYPE != SCREEN_DAYBREAK
						if(menu_name != "end"
						#if SCREEN_TYPE == SCREEN_SUPERVISOR || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAX3 || SCREEN_TYPE == SCREEN_AEGIS || SCREEN_TYPE == SCREEN_NIGHTFALL
							// hide text from the boot screen?
							&& menu_name != "boot"
						#endif
							) {
							
							list lines = splitnulls(m, "\n");
							string l1 = gets(lines, 1);
							#if SCREEN_TYPE == SCREEN_PLANAR || defined(ALTER_MENU_IDENTIFIER)
								if(substr(l1, 0, 31) == "               Command Interface")
									l1 = "ARES" + substr(l1, 14, LAST);
							#endif
							#ifdef ALL_CAPS
								variatype(llToUpper(l1), TEXT_START, 12);
								variatype(llToUpper(gets(lines, 3)), TEXT_START + 6, 12);
								variatype(llToUpper(gets(lines, 2)), TEXT_START + 60, 6);
							#else
								variatype(l1, TEXT_START, 12);
								variatype(gets(lines, 3), TEXT_START + 6, 12);
								variatype(gets(lines, 2), TEXT_START + 60, 6);
							#endif
							integer lmax = button_count = count(lines) - 4;
							integer li = 0;
							integer max_width = 6;
							
							if(lmax > 16)
								max_width = 2;
							else if(lmax > 8)
								max_width = 3;
							
							// integer max_width = 6 / (integer)(lmax / 8);
							
							while(li < lmax) {
								integer li_y = li % 8 + 2;
								integer li_col = (li >> 3) * max_width;
								#ifdef ALL_CAPS
									variatype(llToUpper(gets(lines, li + 4)), TEXT_START + (li_y * 6 + li_col), max_width);
								#else
									variatype(gets(lines, li + 4), TEXT_START + (li_y * 6 + li_col), max_width);
								#endif
								++li;
							}
						}
					#endif
				#endif
				} else if(cmd == "integrity") {
					// integrity <integrity> <chassis-strength-multiplier> <remaining-durability>
					float old_integrity = integrity;
					integrity = (float)gets(argv, 1);
					if(integrity < old_integrity) {
						llTriggerSound(gets(IMPACT_SOUNDS, (integer)llFrand(IMPACT_SOUND_COUNT)), 1);
					}
				} else {
					// echo("/me (ctrl) << " + m);
					return;
				}
			}
			
			lights();
		}
		
		jump end_listen;
		@socket_aperture;
		if(llGetAttached() == ATTACH_CHEST) {
			list socket_metrics = getp(SOCKET, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE]);
			list root_metrics = getp(LINK_ROOT, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
			// echo("socket metrics: " + concat(socket_metrics, "; "));
			// echo("root metrics: " + concat(root_metrics, "; "));
			// echo("rotations:\n" + (string)(llRot2Euler(getr(socket_metrics, 1)) * RAD_TO_DEG)+
			// "\n"+ (string)(llRot2Euler(getr(root_metrics, 1)) * RAD_TO_DEG));
			// rotation rot = ZR / (getr(root_metrics, 1) * getr(socket_metrics, 1));
			rotation rot = getr(socket_metrics, 1) * getr(root_metrics, 1);
			vector socket_size = getv(socket_metrics, 2);
			vector pos = getv(root_metrics, 0)
				+ (getv(socket_metrics, 0) + <0, 0, socket_size.z * SOCKET_INNER_OFFSET>)
				* getr(root_metrics, 1)
				- <0, 0, socket_size.z * SOCKET_OUTER_OFFSET>;
			/* pos.y = -pos.y;
			pos.z = -pos.z; */
			vector erot = llRot2Euler(rot);
			tell(system, c, "socket-aperture "
				+ vec2str(pos) + " " + vec2str(erot));
		}
		
		@end_listen;
	}
	
	on_rez(integer n) {
		llLinkParticleSystem(LINK_ALL_CHILDREN, []);
		
		llListenRemove(LL);
		LL = llListen(CL = 105 - (integer)("0x" + substr(avatar = llGetOwner(), 29, 35)), "", "", "");
		tell(avatar, CL, "ping");
		#ifdef INJECT_STARTUP
			extra_startup();
		#endif
	}

	state_entry() {
		#ifndef SCREEN_TYPE
			echo("Warning: No SCREEN_TYPE defined. Default behavior is SCREEN_NONE.");
			#define SCREEN_TYPE SCREEN_NONE
		#endif
	
		fan_axis = FAN_AXIS;
	
		integer pi = llGetNumberOfPrims();
		while(pi > 0) {
			string pn = llGetLinkName(pi);
			string pd = gets(getp(pi, [PRIM_DESC]), 0);
			if(pn != "Object") {
				// parts += [pi, pn];

				if(pn == "text") {
					TEXT_START = pi;
					#if SCREEN_TYPE != SCREEN_AIDE
					texturables += [pi, 5, -1];
					#endif
				} else if(pn == "fan")
					FAN = pi;
				else if(pn == "power_gauge")
					POWER_GAUGE = pi;
				else if(pn == "rate_gauge")
					RATE_GAUGE = pi;
				else if(pn == SOCKET_NAME)
					SOCKET = pi;
				else if(pn == "speaker") {
					llLinkSetSoundQueueing(pi, TRUE);
					llLinkSetSoundRadius(pi, SOUND_RADIUS);
					SPEAKER = pi;
				} else if(pn == "switch")
					SWITCH = pi;
				else if(pn == "screen")
					SCREEN = pi;
				else if(pn == "port_0")
					PORT_0 = pi;
				else if(pn == "port_1")
					PORT_1 = pi;
				else if(pn == "lid")
					LID = pi;
				else if(pn == "lidl")
					LID_LEFT = pi;
				else if(pn == "lidr")
					LID_RIGHT = pi;
				
				#ifdef DEBUG_LINKS
					echo("found " + pn + " at link address :" + (string)pi);
				#endif
			}
			
			integer pc;
			list pds;
			integer pdi = llOrd(pd, 0);
			if(pdi == 0x23) { // '#'
				pc = 1;
			} else if(pdi == 0x24) { // '$'
				pc = 6;
			} else if(pdi == 0x25) { // '%'
				pc = 2;
			} else if(pdi == 0x26) { // '&'
				pc = 3;
			} else if(pdi == 0x40) { // '@'
				pc = 4;
			}
			if(pc) {
				pds = split(delstring(pd, 0, 0), ",");
				integer pdsi = count(pds);
				while(pdsi--)
					texturables += [pi, pc, geti(pds, pdsi)];
			}
			--pi;
		}
		
		#if SCREEN_TYPE != SCREEN_NONE
		clear_screen(FALSE);
		if(SCREEN) {
			#if SCREEN_TYPE == SCREEN_SXD || SCREEN_TYPE == SCREEN_AIDE || SCREEN_TYPE == SCREEN_PLANAR || SCREEN_TYPE == SCREEN_DAYBREAK
				setp(SCREEN, [PRIM_TEXTURE, ALL_SIDES, llGetInventoryKey("m_boot"), ONES, ZV, 
				#if SCREEN_TYPE == SCREEN_DAYBREAK
					PI_BY_TWO
				#else
					0
				#endif
				#ifdef FULL_COLOR_BOOT
				, PRIM_COLOR, 1, ONES, 1
				#endif
				]);

			#elif SCREEN_TYPE == SCREEN_SUPERVISOR
				setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <3.6, 1, 0>, <0.9, 1, 0>, 0
				#ifdef FULL_COLOR_BOOT
				, PRIM_COLOR, 1, ONES, 1
				#endif
				]);
			#elif SCREEN_TYPE == SCREEN_NIGHTFALL
				setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <4, 1, 0>, <0, 0, 0>, 0
				#ifdef FULL_COLOR_BOOT
				, PRIM_COLOR, 1, ONES, 1
				#endif
				]);
			#elif SCREEN_TYPE == SCREEN_DAX3
				setp(SCREEN, [PRIM_TEXTURE, 1, llGetInventoryKey("m_boot"), <3, 0.9, 0>, <0, 0, 0>, PI_BY_TWO
				#ifdef FULL_COLOR_BOOT
				, PRIM_COLOR, 1, ONES, 1
				#endif
				]);
			#elif SCREEN_TYPE == SCREEN_AEGIS
				setp(SCREEN, [PRIM_TEXTURE, 2, llGetInventoryKey("m_boot"), <-3, 3.8, 0>, <0, -0.445, 0>, PI_BY_TWO
				#ifdef FULL_COLOR_BOOT
				, PRIM_COLOR, 1, ONES, 1
				#endif
				]);
			#endif
		}
		#endif
		
		if(SPEAKER)
			llLinkSetSoundQueueing(SPEAKER, TRUE);
		
		/*
		variatype("               Command Executive               version 9.0 blueprint", TEXT_START + 6 * 0, 6);
		variatype("main menu", TEXT_START + 6 * 1, 6);
		variatype("personalities...", TEXT_START + 6 * 2, 2); variatype("settings...", TEXT_START + 6 * 2 + 4, 2);
		variatype("power control...", TEXT_START + 6 * 3, 2); variatype("access controls...", TEXT_START + 6 * 3 + 4, 2);
		variatype("chat filtering...", TEXT_START + 6 * 4, 2); variatype("devices...", TEXT_START + 6 * 4 + 4, 2);
		variatype("scripts...", TEXT_START + 6 * 5, 2); variatype("system status", TEXT_START + 6 * 5 + 4, 2);
		variatype("extensions...", TEXT_START + 6 * 6, 2); variatype("help", TEXT_START + 6 * 6 + 4, 2);
		variatype("applications...", TEXT_START + 6 * 7, 2); variatype("about", TEXT_START + 6 * 7 + 4, 2);
		variatype("movement...", TEXT_START + 6 * 8, 2); variatype("shutdown", TEXT_START + 6 * 8 + 4, 2);
		variatype("file system...", TEXT_START + 6 * 9, 2); variatype("reboot", TEXT_START + 6 * 9 + 4, 2);
		variatype("(c) 2022-23 Nanite Systems                    SXD-000-00-0000", TEXT_START + 6 * 10, 6);
		*/
		
		LL = llListen(CL = 105 - (integer)("0x" + substr(avatar = llGetOwner(), 29, 35)), "", "", "");
		tell(avatar, CL, "ping");
		echo((string)llGetUsedMemory() + " bytes used.");
		
		#ifdef INJECT_STARTUP
			extra_startup();
		#endif
	}
}