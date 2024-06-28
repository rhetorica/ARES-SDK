/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  YS-712 XSU Hardware Driver
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

#define SCREEN 35
#define SCREEN_2 36
#define SCREEN_3 37
#define SCREEN_CONE 34
#define TEXT_START 38
#define TEXT_COUNT 66
#define PROJECTOR 5

integer screen_open = FALSE;

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/5.0)

screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <-0.0915, 0, -0.0340>;
        
		#define conex 0.0945
		
		setp(SCREEN_CONE, [
			PRIM_POS_LOCAL, screen_origin + <conex * 0.5, 0, 0>
		]);
		
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, <0.4900000, 0.4900000, 0.2450000>,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <-0.05, 0, 0.18>,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <-0.05, 0, -0.18>,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, <0.4900000, 0.4900000, conex>,
			PRIM_COLOR, ALL_SIDES, c4, 0.0625,
		PRIM_LINK_TARGET, PROJECTOR,
			PRIM_COLOR, ALL_SIDES, c4, 1,
			PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
			PRIM_GLOW, ALL_SIDES, 1.0
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
                PRIM_POS_LOCAL, (<-0.025 * secondary_scale * secondary_scale, -x * X_STEP, y * X_STEP / 3.0> * secondary_scale + screen_origin),
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
        vector screen_origin = <0.03125, 0, -0.0340>;
        
		setp(SCREEN_CONE, [
			PRIM_SIZE, ZV,
			PRIM_COLOR, ALL_SIDES, c4, 0
		]);
		
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_2,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_3,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, PROJECTOR,
			PRIM_COLOR, ALL_SIDES, base_c * power_on, 1,
			PRIM_FULLBRIGHT, ALL_SIDES, power_on,
			PRIM_GLOW, ALL_SIDES, 0.05 * power_on
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
                PRIM_POS_LOCAL, screen_origin
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

#define original_size 0.026540
#define STEP 0.1
#define movement_range 2

operate_door(integer new_state) {
	integer door_open = !new_state;
	
    float polarity = 1;
    if(door_open) {
        polarity = -1;
        llTriggerSound("3f075de9-738c-1b1e-ae67-8149a84647ee", 1);
    } else {
        llTriggerSound("0c205a19-ebd7-7195-7e8e-426b1bda48d4", 1);
    }
    
    llTriggerSound("10722bf0-fdac-2497-3b2c-f6d9e6625f7c", 1);
    
    vector s = llGetScale();
    float scale = s.x / original_size;
    
    vector so = ZERO_VECTOR; getv(getp(1, [PRIM_POS_LOCAL]), 0);
    
    float initial = movement_range * door_open;
    float target = (movement_range * (!door_open)) - initial;
    
    float i;
    float r;
    
    #define ioff 0.0073
    #define doff 0.003125
        
    vector vo = so + <doff, 0, 0>;
        
    for(i = 0; i <= 1 + STEP; i += STEP) {
        r = i * target + initial;
        
        list f = [];
        integer p = 3;
        while(p--) {
            rotation r0 = llEuler2Rot(<0, 270, p * 120 + 180> * DEG_TO_RAD);
            rotation r1 = llEuler2Rot(<0, -r, 0>);
            
            vector v = <0.020, 0, -0.002>;
            
            f += [
            PRIM_LINK_TARGET, p + 6,
                PRIM_POS_LOCAL, (v * r1 - v) * scale * r0 + vo,
                PRIM_ROT_LOCAL, r1 * r0
            ];
        }
        
        setp(0, f);
    }
    
    if(door_open)
        llTriggerSound("d24539cd-0dd0-c0c3-99c2-3421fdbf5656", 1);
    else
        llTriggerSound("2227d6ea-fe24-dd2f-fb1e-a31e1531b402", 1);
    
    door_open = !door_open;
}

default {
    state_entry() {
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | LOOP | SMOOTH, ALL_SIDES, 0, 0, 0, 1, 101);
		llSetMemoryLimit(0x8000);
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
		if(n == 1) {
			// non-light-bus messages
			if(m == "door 1") {
				operate_door(TRUE);
			} else if(m == "door 0") {
				operate_door(FALSE);
			}
		} else {
			// echo("supervisor screen: " + m);
			if(m == "on") {
				power_on = 1;
			} else if(m == "off") {
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
}
