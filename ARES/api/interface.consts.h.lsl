/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Interface Constants
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 1 (ASCL-i). It is offered to you on a limited basis to
 *  facilitate modification and customization.
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

// This file is *not* included by default.

#ifndef _ARES_INTERFACE_CONSTS_H_
#define _ARES_INTERFACE_CONSTS_H_

// 2: unused (system daemons)

#define MODEL_BADGE 3

// 13-14, 4, and 249-250: mouselook combat stuff
#define CROSSHAIR 4

// 5-10: gauges
#define POWER_GAUGE 5
#define RATE_GAUGE 6
#define HEAT_GAUGE 7
#define FAN_GAUGE 8
#define INTEGRITY_GAUGE 9
#define LUBE_GAUGE 10

#define GAUGE_SIZE <256, 32, 0>

#define BADGE_CLADDING_LEFT 11
#define BADGE_CLADDING_RIGHT 12

// 13-14, 86, and 249-250: mouselook combat stuff
#define INTEGRITY_LABEL 13
#define AMMO_LABEL 14

// 15-22: unused (formerly fixed warnings)

// 23-28: unused
// 23 used for experimental MOAP widget

#define WORKING 28

#define BOOT_PROGRESS 30
#define BOOT_LOGO 31

// 32-63: device icons
#define DEVICE_ICON_BASE 32

#define ALERT_OPTIONS 64
#define ALERT_ANCHOR 67

#define COMPASS_PRIM_DIAL 65
#define COMPASS_PRIM_FRAME 66

#define SPEEDOMETER 68
#define SPEEDOMETER_TEXT 69
#define ALTIMETER_BAR 70
#define ALTIMETER_MARKER 71

#define WARRIOR_START 72
// 72-78: Warrior paper doll
#define WEAPON_SELECT_START 79
// 79-85: Warrior weapon select
#define CLADDING_BACKDROP 86
// 87-91: sexuality
#define LUST_CLADDING 87
#define LUST_GAUGE 88
#define SENSITIVITY_GAUGE 89
#define PLATEAU_MARKER 90
#define ORGASM_MARKER 91

// 92-95: sexuality reserved

// 96-111: sitrep
#define SITREP_BASE 96

#define CPU_BAR 96
#define CPU_LABEL 97

#define FTL_RECHARGE_BAR 98
#define FTL_RECHARGE_LABEL 99

#define SIM_LAG_BAR 100
#define SIM_LAG_LABEL 101

#define SIM_POP_BAR 102
#define SIM_POP_LABEL 103

#define AUX_POWER_BAR 104
#define AUX_POWER_LABEL 105

#define HUMIDITY_BAR 106
#define HUMIDITY_LABEL 107

#define PRESSURE_BAR 108
#define PRESSURE_LABEL 109

#define RADIATION_BAR 110
#define RADIATION_LABEL 111

// 112-126: apps & stuff

// 112-120: sticky notes

#define LL_TARGET_LOCK 121
#define LL_NAV_DEST 122

// 123-126: reserved for modal apps
#define WIZARD 123
#define WIZARD_TEXT 124
#define WIZARD_TEXT_2 125
#define WIZARD_TEXT_3 126

#define APP_0 123
#define APP_1 124
#define APP_2 125
#define APP_3 126

#define SCREEN_ANCHOR 127
#define SCREEN 128
#define TEXT_START 129

#define MSG_TEXT_START 195
#define MSG_TEXT_PRIM_LIMIT 12
// 195-206: alert message text

#define FIXED_WARNING_LIST 207

/* 207: fixed warnings

FW assignments

activate with:
	system(SIGNAL_TRIGGER_EVENT, (string)EVENT_WARNING + " " + (string)(_slot) + " " + (string)(_msg))

	send msg 0 to clear a slot
	
	slot 0 (prim 15): damage (messages 1-3) applied by repair
		1: CHECK HARDWARE
		2: REPAIRS REQUIRED
		3: REPAIRING
	slot 1 (prim 16): non-combat modes (messages 4-5) applied by repair
		4: OUT OF CHARACTER
		5: DEGREELESSNESS MODE
	slot 2 (prim 17): threats to homeostasis (messages 6-13) applied by status
		6: RADIATION DANGER
		7: HEAT DANGER
		8: ICE DANGER
		9: DUMP HEAT!
		10: BAROMETER FAULT
		11: VACUUM
		12: IN WATER
		13: CRYOLUBRICANT LOW
	slot 3 (prim 18): processor status (messages 14 and 19) applied by baseband
		14: WORKING
		19: KERNEL INITIALIZING
	slot 4 (prim 19): movement status (messages 15-18, 21) applied by ???
		15: NAVIGATING
		16: FOLLOWING
		17: ANCHORED
		18: IMMOBILIZED
		21: CARRIED
	slot 5 (prim 20): dive status (message 20) applied by ???
		20: UNDER REMOTE CONTROL
	slot 6 (prim 21): weapon status (messages 22-24) applied by ??? (display?)
		22: LOW AMMO
		23: NO AMMO
		24: RELOADING
	slot 7 (prim 22): battery status (messages 25-26) applied by status
		25: LOW BATTERY
		26: CHARGING
*/

#define CONFIG_CONTROLS 208

// 209-245: available

#define PERFMON_EVENTS 246
#define PERFMON_CPU 247
#define PERFMON_DRAW 248

// 13-14, 86, and 249-250: mouselook combat stuff
#define INTEGRITY 249
#define AMMO 250

#define ARENA_SCOREBOARD_START 251
#define ARENA_CLOCK 256

#define VISIBLE <0.50000, -0.50000, -0.50000, 0.50000>
#define INVISIBLE <0.00000, -0.00000, -0.70711, 0.70711>

// for FIXED_WARNING_LIST only:
#define VISIBLE_FWL <0.70711, 0.00000, -0.70711, 0.00000>
#define INVISIBLE_FWL <0.50000, -0.50000, -0.50000, -0.50000>

#define OFFSCREEN <0, 0, -1.25>
#define OFFSCREEN_RIGHT <0, -3, 0>
#define OFFSCREEN_LEFT <0, 3, 0>

#define MOVER_TEX "cdf9347e-3a47-08d1-0ebc-1e2d27aa802c"
#define METER_TEX "8c782efc-cee7-c616-af9d-9a196cdd87c7"
#define SITREP_METER_TEX "e28a35b0-1581-4cc3-d2ab-9721b3ee3a19"
// #define AURA_TEX "1e1f83bc-968d-57a7-88a3-b88fc1a77a70"
#define AURA_TEX "cac27a60-722b-c653-c806-2c985ff34cf3"
#define BADGE_DEFAULT "0a1ebe09-5691-357e-e68a-cc90a2466fe2"
#define ALTIMETER_MARKER_TEX "4a860b55-2513-015a-63ba-f928c985bd06"

// #define BOOT_LOGO_TEX llGetInventoryKey("i_boot")
// #define COMPASS_TEX llGetInventoryKey("i_compass")
// #define MENU_TEX llGetInventoryKey("m_main")
// #define ANCHOR_TEX llGetInventoryKey("m_anchor")
// #define CLADDING_LEFT llGetInventoryKey("i_cladding-left")
// #define CLADDING_RIGHT llGetInventoryKey("i_cladding-right")
// #define MLOOK_TEX llGetInventoryKey("i_mlook")
// #define BIGNUM_TEX llGetInventoryKey("i_bignums")
// #define CROSSHAIR_TEX llGetInventoryKey("i_crosshair")
// #define ALTIMETER_TEX llGetInventoryKey("i_altimeter")
#define LUST_TEX llGetInventoryKey("i_sexuality")
// #define SITREP_TEX llGetInventoryKey("i_sitrep")
// #define TARGET_TEX llGetInventoryKey("i_target")
// #define CLADDING_BACKDROP_TEX llGetInventoryKey("i_cladding-backdrop")
// #define ALERT_TEX llGetInventoryKey("i_alert")
// #define WORKING_TEX llGetInventoryKey("i_working")

// moved to utils.lsl:
// #define str2vec(__str) (vector)("<" + replace(__str, " ", ",") + ">")
// #define vec2str(__vec) (__vec.x + " " + __vec.y + " " + __vec.z)

#endif // _ARES_INTERFACE_CONSTS_H_
