/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  NS-295 Federator Hardware Driver
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

vector base_c = <0, 0.5, 1>;
vector c4 = <0, 0.75, 1>;

#define SCREEN 12
#define SCREEN_2 13
#define SCREEN_3 14
#define SCREEN_CONE 11
#define TEXT_START 15
#define TEXT_COUNT 66

integer screen_open = FALSE;

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/5.0)

float fan;
#define HEATSINK_THRESHOLD 0.875
#define HEATSINK_SOUND "1a8f2ac1-e216-e65f-23c6-c0e942819dc0"
#define HEATSINK_MOVE_SOUND "c4f9e160-641f-b61d-7b9e-0bc9d4ac0ea1"
#define HEATSINK_R_RIGHT <333.0000000, 0.0000000, 0.0000000>
#define HEATSINK_R_LEFT <27.0000000, 0.0000000, 0.0000000>
#define BASE_O <-0.0009541, 0.1932650, -0.2592220>
#define BASE_S 0.2693256
#define HEATSINK_O_RIGHT <-0.01582, 0.08533, 0.00415>
#define HEATSINK_S 0.0446616
#define HEATSINK_O_LEFT <-0.01582, -0.08533, 0.00415>
#define OVERSHOOT 1.125
#define ROD_MOVEMENT 0.0625
#define ROD_S <0.1002346, 0.1002346, 0.3758798>
#define ROD_SCALE_RATE 1.0
#define ROD_DEPTH_OFFSET -1.5
#define ROD_FLAT_OFFSET 0.01

#define LEFT_ROD 7
#define RIGHT_ROD 6
#define LEFT_SINK 9
#define RIGHT_SINK 8
#define LID 2

list steam = [
	PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE,
	PSYS_SRC_BURST_RADIUS,0,
	PSYS_SRC_ANGLE_BEGIN,0,
	PSYS_SRC_ANGLE_END,0,
	PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
	PSYS_PART_END_COLOR,<0.000000,0.000000,0.000000>,
	PSYS_PART_START_ALPHA,0.0625,
	PSYS_PART_END_ALPHA,0.0625,
	PSYS_PART_START_GLOW,0,
	PSYS_PART_END_GLOW,0,
	PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
	PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE,
	PSYS_PART_START_SCALE,<0.031250,0.031250,0.000000>,
	PSYS_PART_END_SCALE,<0.500000,0.500000,0.000000>,
	PSYS_SRC_TEXTURE,"463ff5c3-80a1-dbb1-f429-fcfebde253be",
	PSYS_SRC_MAX_AGE,0,
	PSYS_PART_MAX_AGE,5,
	PSYS_SRC_BURST_RATE,0,
	PSYS_SRC_BURST_PART_COUNT,1,
	PSYS_SRC_ACCEL,<0.000000,0.000000,0.020000>,
	PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
	PSYS_SRC_BURST_SPEED_MIN,0,
	PSYS_SRC_BURST_SPEED_MAX,0.1,
	PSYS_PART_FLAGS, 0x23
];

fan_control(integer open) {
	float dest_t = (float)open;
	float origin_t = 1.0 - dest_t;
	float t = origin_t;
	float step;

	if(open) {
		step = 0.03;
		llLinkPlaySound(LID, HEATSINK_SOUND, 1, SOUND_PLAY);
		llLinkParticleSystem(LEFT_SINK, steam);
		llLinkParticleSystem(RIGHT_SINK, steam);
	} else {
		step = -0.03;
		llLinkParticleSystem(LEFT_SINK, []);
		llLinkParticleSystem(RIGHT_SINK, []);
	}
	llLinkPlaySound(LEFT_SINK, HEATSINK_MOVE_SOUND, 0.25, SOUND_PLAY);
	llLinkPlaySound(RIGHT_SINK, HEATSINK_MOVE_SOUND, 0.25, SOUND_PLAY);
	
	vector current_scale = llGetScale();
	float effective_scale = current_scale.y / BASE_S;
	float travel_distance = HEATSINK_S * effective_scale * OVERSHOOT;
	
	while(llFabs(dest_t - t) >= llFabs(step)) {
		vector rod_scale = ROD_S * effective_scale;
		rod_scale.z *= (1.0 + t * ROD_SCALE_RATE);
		
		setp(RIGHT_SINK, [
			PRIM_POS_LOCAL, HEATSINK_O_RIGHT * effective_scale + <0, 0, travel_distance * t * OVERSHOOT> * llEuler2Rot(HEATSINK_R_RIGHT * DEG_TO_RAD),
		PRIM_LINK_TARGET, RIGHT_ROD,
			PRIM_POS_LOCAL, HEATSINK_O_RIGHT * effective_scale + <0, 0, travel_distance * (t + ROD_DEPTH_OFFSET) * OVERSHOOT * ROD_MOVEMENT - ROD_FLAT_OFFSET * effective_scale> * llEuler2Rot(HEATSINK_R_RIGHT * DEG_TO_RAD),
			PRIM_SIZE, rod_scale,
		PRIM_LINK_TARGET, LEFT_SINK,
			PRIM_POS_LOCAL, HEATSINK_O_LEFT * effective_scale + <0, 0, travel_distance * t * OVERSHOOT> * llEuler2Rot(HEATSINK_R_LEFT * DEG_TO_RAD),
		PRIM_LINK_TARGET, LEFT_ROD,
			PRIM_POS_LOCAL, HEATSINK_O_LEFT * effective_scale + <0, 0, travel_distance * (t + ROD_DEPTH_OFFSET) * OVERSHOOT * ROD_MOVEMENT - ROD_FLAT_OFFSET * effective_scale> * llEuler2Rot(HEATSINK_R_LEFT * DEG_TO_RAD),
			PRIM_SIZE, rod_scale
		]);
		
		t += step;
	}
}

screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <0.0625, 0, 0.13>;
        
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, <0.4900000, 0.4900000, 0.2450000>,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, <0.24, 0.06, 0.06> * 1.5,
			PRIM_POS_LOCAL, screen_origin + <-0.18, 0, 0.05>,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <0.18, 0, 0.05>,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, <0.4900000, 0.4900000, 0.125>,
			PRIM_POS_LOCAL, screen_origin + <0, 0, -0.059>,
			PRIM_COLOR, ALL_SIDES, c4, 0.0625,
		PRIM_LINK_TARGET, 1,
			PRIM_COLOR, 5, base_c, 1,
			PRIM_FULLBRIGHT, 5, TRUE,
			PRIM_GLOW, 5, 0.05
        ];
        
        while(pn < TEXT_START + TEXT_COUNT) {
            integer tx = (pn - TEXT_START) % 6;
            integer ty = (pn - TEXT_START) / 6;
            float x = (float)tx - 2.5;
            float dy = 10 - ty;
			
			float secondary_scale = 1.0;
			
            if(dy == 9) {
                dy = 8.5;
				secondary_scale = 1.3;
            } else if(dy == 0) {
                dy = -0.25;
				secondary_scale = 1.1;
            } else if(dy == 10) {
                dy = 10.5;
				secondary_scale = 1.1;
            }
			
            float y = (float)(dy) - 5.5;
            // rotation R = llEuler2Rot(<0, 0.17075 * x * PI_BY_TWO, 0>);
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, scale * secondary_scale,
                PRIM_POS_LOCAL, (<-y * X_STEP / 3.0, x * X_STEP, 0.025 * secondary_scale * secondary_scale> * secondary_scale + screen_origin),
				PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 128
                // PRIM_ROT_LOCAL, llEuler2Rot(<-PI_BY_TWO, 0, PI_BY_TWO>) * R,
                //PRIM_COLOR, ALL_SIDES, ONES, 1
            ];
            ++pn;
            if(llGetFreeMemory() < 256) {
                setp(0, acts);
                acts = [];
            }
        }
        setp(0, acts);
    } else {
        integer pn = TEXT_START;
        vector screen_origin = <0, 0, 0.25>;
        
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, SCREEN_2,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, SCREEN_3,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, SCREEN_CONE,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, 1,
			PRIM_COLOR, 5, ZV, 1,
			PRIM_FULLBRIGHT, 5, FALSE,
			PRIM_GLOW, 5, 0
        ];
        
        while(pn < TEXT_START + TEXT_COUNT) {
            integer tx = (pn - TEXT_START) % 6;
            integer ty = (pn - TEXT_START) / 6;
            float x = (float)tx - 2.5;
            float dy = 10 - ty;
            if(dy == 9)
                dy = 9.25;
            else if(dy == 0)
                dy = -0.25;
            else if(dy == 10)
                dy = 10.5;
                
            float y = (float)(dy) - 5.5;
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, ZV,
                PRIM_POS_LOCAL, ZV
                // PRIM_ROT_LOCAL, ZR,
                // PRIM_COLOR, ALL_SIDES, ONES, 1
            ];
            ++pn;
            if(llGetFreeMemory() < 256) {
                setp(0, acts);
                acts = [];
            }
        }
        setp(0, acts);
    }
	
    screen_open = open;
	// echo("screen now " + (string)open);
}

integer power_on;

default {
    state_entry() {
		llSetLinkTextureAnim(SCREEN_3, 0, ALL_SIDES, 1, 1, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetMemoryLimit(0x8000);
		llLinkParticleSystem(LINK_SET, []);
		//screen_control(FALSE);
		screen_control(FALSE);
		linked(LINK_THIS, 0, "menu-end", "");
		// damp(0);
        /* echo(llGetLinkName(HOSE_L));
        echo(llGetLinkName(HOSE_R)); */
        // damp(0.0);
        /*integer pn = llGetNumberOfPrims();
        while(pn--) {
            echo((string)pn + " = " + llGetLinkName(pn));
        }*/
        
    }
	/*
	touch_start(integer n) {
		while(n--) {
			key toucher = llDetectedKey(n);
			integer pi = llDetectedLinkNumber(n);
			string part = llGetLinkName(pi);
			
			if((part == "lidl" || part == "lidr") && !power_on) {
				linked(LINK_THIS, 0, "touch-hatch", toucher);
			} else if(part == "text" && power_on) {
				linked(LINK_THIS, pi, "touch-screen", toucher);
			} else if(part == "screen") {
				
			} else {
				// if "Object" || ("lid" && power_on)
				if((power_on && screen_open) || !power_on) {
					linked(LINK_THIS, 0, "menu-request", toucher);
				} else {
					linked(LINK_THIS, 0, "menu-start", toucher);
					screen_control(TRUE);
				}
			}
		}
	}
	*/
	timer() { // menu expiry
		// echo("(supervisor screen menu expiry)");
		if(screen_open) {
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
		}
		llSetTimerEvent(0);
		// echo("memory status: " + (string)llGetUsedMemory() + " used; " + (string)llGetFreeMemory() + " virgin");
	}
	
	link_message(integer s, integer n, string m, key id) {
		// echo("supervisor screen: " + m);
		if(m == "on") {
			if(!power_on)
				llPlaySound("5b319890-4f37-9d8e-2678-5d1cfc06e317", 1);
			power_on = 1;
		} else if(m == "off") {
			if(power_on)
				llPlaySound("a171125e-6be0-6f18-6e94-22191b9e3dc3", 1);
			power_on = 0;
			
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
			llSetTimerEvent(0);
			
			// damp(0);
		} else if(m == "menu-open") {
			if(!screen_open)
				screen_control(TRUE);
			llSetTimerEvent(15);
		} else if(m == "menu-close") {
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
			llSetTimerEvent(0);
		} else {
			list argv = split(m, " ");
			string cmd = gets(argv, 0);
			/*if(cmd == "fan") {
				fan = (float)gets(argv, 1);
				damp(rate * 0.001 + fan * 0.5);
			} else*/
			if(cmd == "fan") {
				float new_fan = (float)gets(argv, 1);
				if(new_fan >= HEATSINK_THRESHOLD && fan < HEATSINK_THRESHOLD) {
					fan_control(1);
				} else if(new_fan < HEATSINK_THRESHOLD && fan >= HEATSINK_THRESHOLD) {
					fan_control(0);
				}
				fan = new_fan;
				// echo((string)m);
			} else if(cmd == "color") {
				base_c = (vector)concat(delitem(argv, 0), " ");
				/* if(screen_open)
					screen_control(TRUE); */
			} else if(cmd == "color-4") {
				c4 = (vector)concat(delitem(argv, 0), " ");
				if(screen_open)
					screen_control(TRUE);
			}
			/*else if(cmd == "rate") {
				rate = (float)gets(argv, 1);
				if(rate > 0)
					power_on = 1;
				// damp(rate * 0.001 + fan * 0.5);
			}*/
		}
	}
}
