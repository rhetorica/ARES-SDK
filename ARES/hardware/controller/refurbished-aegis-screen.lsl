/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  NS-476 Aegis Hardware Driver
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

#define SCREEN 5
// #define SCREEN_2 8
// #define SCREEN_3 9
#define SCREEN_CONE 6
#define TEXT_START 7
#define TEXT_COUNT 66
#define LID 73
#define LOGO 74

integer screen_open = FALSE;

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/52.0)

#define X_BIAS -2.5
#define Y_BIAS -5.0

#define projection_magnitude 0.5

key system;
integer CL;

screen_control(integer open) {
    list acts;
    
    if(open) {
		if(power_on && !door_open)
			operate_door();
		
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <0, 0.625, 0.0>;
        
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, <projection_magnitude * 0.5, projection_magnitude, projection_magnitude> * 1.05,
			PRIM_POS_LOCAL, screen_origin,
		/*PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <-0.05, 0, 0.18>,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <-0.05, 0, -0.18>, */
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, <projection_magnitude * 0.5, projection_magnitude, projection_magnitude> * 1.05,
			PRIM_POS_LOCAL, screen_origin + <0, 0, -0.001>,
			PRIM_COLOR, ALL_SIDES, base_c, 0.05,
		PRIM_LINK_TARGET, 1,
			PRIM_COLOR, 1, base_c, 1,
			PRIM_FULLBRIGHT, 1, TRUE,
			PRIM_GLOW, 1, 0.2
        ];
		
		rotation post_R = llEuler2Rot(<PI_BY_TWO, PI, 0>);
        
        while(pn < TEXT_START + TEXT_COUNT) {
            integer tx = (pn - TEXT_START) % 6;
            integer ty = (pn - TEXT_START) / 6;
            float x = (float)tx + X_BIAS;
            float dy = 10 - ty;
			
			float secondary_scale = 1.0;
			
            if(dy == 9) {
                dy = 9.25;
				secondary_scale = 1;
            } else if(dy == 0) {
                dy = -0.25;
				secondary_scale = 1;
            } else if(dy == 10) {
                dy = 10.5;
				secondary_scale = 1;
            }
			
            float y = (float)(dy) + Y_BIAS;
            rotation R = llEuler2Rot(<0, 0.17075 * -x * PI_BY_TWO, 0>);
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, scale * secondary_scale,
                PRIM_POS_LOCAL, (<0, y * Y_STEP, 0.025 * secondary_scale * secondary_scale> * secondary_scale - <0, 0, projection_magnitude * 0.55>) * R * post_R + screen_origin,
				PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 128,
				// PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_BLEND, 128,
                PRIM_ROT_LOCAL, llEuler2Rot(<-PI_BY_TWO, 0, PI_BY_TWO>) * R * post_R
				//,
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
		/*PRIM_LINK_TARGET, SCREEN_2,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, SCREEN_3,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,*/
		PRIM_LINK_TARGET, SCREEN_CONE,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, ZV,
		PRIM_LINK_TARGET, 1,
			PRIM_COLOR, 1, ZV, 1,
			PRIM_FULLBRIGHT, 1, FALSE,
			PRIM_GLOW, 1, 0
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
		
		if(door_open)
			operate_door();
    }
	
    screen_open = open;
	// echo("screen now " + (string)open);
}

integer power_on;

#define DOOR_MOVE_SOUND "c4f9e160-641f-b61d-7b9e-0bc9d4ac0ea1"
integer door_open;

operate_door() {
    llLinkPlaySound(LID, DOOR_MOVE_SOUND, 1, SOUND_PLAY);
    
    if(door_open && !power_on)
        tell(system, CL, "door 0");
    
    // door_open = 1;
    
    door_open = !door_open;
    float sign = (float)(door_open << 1) - 1.0;
    float hi = 0;
    list lid_props = getp(LID, [PRIM_SIZE, PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
    list lid2_props = getp(LOGO, [PRIM_SIZE]);
    vector lids = getv(lid_props, 0);
    vector lidp = getv(lid_props, 1);
    rotation lidr = getr(lid_props, 2);
    vector lido = <0, lids.y * -0.5, lids.z * -0.5>;
    
    vector lid2s = getv(lid2_props, 0);
    
    vector lid2o = <0, -0.01, -0.01125>;
	
	float lid2_scale_factor = lid2s.y / 0.0246600;
	
    rotation postR_logo = llEuler2Rot(<0, 0, PI>);
    while(hi <= 1) {
        rotation lidnr = llEuler2Rot(<120 * DEG_TO_RAD * hi * sign, 0, 0>);
        rotation lid2nr = llEuler2Rot(<120 * DEG_TO_RAD * hi * sign, 0, 0>);
        setp(LID, [
            PRIM_POS_LOCAL, lidp + (lido - lido * lidnr) * lidr,
            PRIM_ROT_LOCAL, lidnr * lidr,
        PRIM_LINK_TARGET, LOGO,
            PRIM_POS_LOCAL, lidp + (lido - (lid2o * lid2_scale_factor + lido) * lidnr) * lidr,
            PRIM_ROT_LOCAL, postR_logo * lidnr * lidr
        ]);
        hi += 0.1;
        llSleep(0.022);
    }
    
    if(door_open && !power_on)
        tell(system, CL, "door 1");
}

integer timer_close_hatch;

default {
    state_entry() {
		// llLinkStopSound(LINK_SET);
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN, ANIM_ON | SMOOTH | LOOP | PING_PONG, 1, 0, 0, 0, 1, 100);
		llSetMemoryLimit(0x8000);
		#ifdef TEST_SCREEN
			power_on = 1;
			screen_control(TRUE);
			linked(LINK_THIS, 0, "menu-start", "");
		#else
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
		#endif
		// damp(0);
        /* echo(llGetLinkName(HOSE_L));
        echo(llGetLinkName(HOSE_R)); */
        // damp(0.0);
        /*integer pn = llGetNumberOfPrims();
        while(pn--) {
            echo((string)pn + " = " + llGetLinkName(pn));
        }*/
        
    }
	
	touch_start(integer n) {
		while(n--) {
			key toucher = llDetectedKey(n);
			integer pi = llDetectedLinkNumber(n);
			string part = llGetLinkName(pi);
			
			if(part == "lid" && !power_on) {
				
				if(door_open) {
					timer_close_hatch = 1;
					// tell(llGetOwner(), CL, "hatch-blocked-q");
					linked(LINK_THIS, 0, "touch-hatch", toucher);
					
					llSetTimerEvent(0.75);
				} else {
					operate_door();
				}
				//operate_door();
			} else if(part == "text" && power_on) {
				linked(LINK_THIS, pi, "touch-screen", toucher);
			} else if(part == "lid" && power_on) {
				if(door_open && screen_open) {
					screen_control(FALSE);
				} else {
					linked(LINK_THIS, 0, "menu-start", toucher);
					screen_control(TRUE);
				}
			} else if(part == "screen") {
				
			} else {
				// if "Object" || ("lid" && power_on)
				if((power_on && screen_open) || !power_on) {
					linked(LINK_THIS, 0, "menu-request", toucher);
				} else {
					linked(LINK_THIS, 0, "menu-request", toucher);
					/*
					linked(LINK_THIS, 0, "menu-start", toucher);
					screen_control(TRUE);
					*/
				}
			}
		}
	}
	
	timer() { // hatch open
		llSetTimerEvent(0);
		
		if(door_open && timer_close_hatch && !power_on)
			operate_door();
		
		timer_close_hatch = 0;
	}
	
	link_message(integer s, integer n, string m, key id) {
		// echo("supervisor screen: " + m);
		if(m == "hatch-blocked") {
			llSetTimerEvent(0);
			timer_close_hatch = 0;
		} else if(m == "on") {
			timer_close_hatch = 0;
			llSetTimerEvent(0);
			power_on = 1;
			system = id;
			CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
		} else if(m == "off") {
			power_on = 0;
			system = id;
			CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
			
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
			
			// damp(0);
		} else if(m == "menu-open") {
			if(!screen_open)
				screen_control(TRUE);
		} else if(m == "menu-close") {
			system = id;
			
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
		} else {
			list argv = split(m, " ");
			string cmd = gets(argv, 0);
			/*if(cmd == "fan") {
				fan = (float)gets(argv, 1);
				damp(rate * 0.001 + fan * 0.5);
			} else*/
			if(cmd == "color") {
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
