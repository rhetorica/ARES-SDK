/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  CX/S Supervisor Hardware Driver
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

float current_temp = 0.5;
#define TEMP_DAMP_RATE 0.022

integer HOSE_L = 83;
integer HOSE_R = 88;

vector base_c = <0, 0.5, 1>;

float fan;
float rate;

damp(float target_temp) {
	if(target_temp < 0)
		target_temp = llFabs(target_temp);
	
	if(target_temp > 1)
		target_temp = 1;
	
    float temp = current_temp;
    llResetTime();
    float step_dir;
    
    if(target_temp > current_temp)
        step_dir = 1;
    else
        if(target_temp < current_temp) step_dir = -1;
    else
        return;
    
    while(llFabs(target_temp - temp) > 0.01) {
        temp += step_dir * TEMP_DAMP_RATE;
        if(((temp > target_temp) && (target_temp > current_temp))
        || ((temp < target_temp) && (target_temp < current_temp)))
            temp = target_temp;
        llSetLinkTextureAnim(HOSE_L, ANIM_ON | LOOP | SMOOTH, 1, 0, 0, 0, 0, 4 * temp);
        llSetLinkTextureAnim(HOSE_R, ANIM_ON | LOOP | SMOOTH, 1, 0, 0, 0, 0, 4 * temp);

        float fy = temp;
        float fx = 1.5 - temp;

        vector mod_c = <llPow(base_c.x, fx) * fy,
                        llPow(base_c.y, fx) * fy,
                        llPow(base_c.z, fx) * fy>;
        
        setp(HOSE_L, [
            PRIM_COLOR, 1, mod_c, 0.9,
            PRIM_GLOW, 1, temp,
            PRIM_FULLBRIGHT, 1, temp > 0.1,
        PRIM_LINK_TARGET, HOSE_R,
            PRIM_COLOR, 1, mod_c, 0.9,
            PRIM_GLOW, 1, temp,
            PRIM_FULLBRIGHT, 1, temp > 0.1
        ]);
        
        llSleep(0.044);
    }
    
    current_temp = target_temp;
    
    if(current_temp == 0) {
        llSetLinkTextureAnim(HOSE_L, 0 | LOOP | SMOOTH, 1, 0, 0, 0, 0, 0.25 * 0);
        llSetLinkTextureAnim(HOSE_R, 0 | LOOP | SMOOTH, 1, 0, 0, 0, 0, 0.25 * 0);    
    }
}

#define SCREEN 2
#define TEXT_START 4
#define TEXT_COUNT 66

integer screen_open = FALSE;

screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 1.0/3.0, 0.2>;
        integer pn = TEXT_START;
        vector screen_origin = <0, 0, 0.25>;
        
        acts += [
            PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, <0.4900000, 0.4900000, 0.2450000>
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
            rotation R = llEuler2Rot(<0, 0.17075 * x * PI_BY_TWO, 0>);
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, scale,
                PRIM_POS_LOCAL, (<0, y * 0.01875, 0> + screen_origin) * R,
                // PRIM_ROT_LOCAL, llEuler2Rot(<-PI_BY_TWO, 0, PI_BY_TWO>) * R,
                PRIM_COLOR, ALL_SIDES, ONES, 1
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
            PRIM_SIZE, ZV
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
            rotation R = llEuler2Rot(<0, 0.17075 * x * PI_BY_TWO, 0>);
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, ZV,
                PRIM_POS_LOCAL, ZV,
                // PRIM_ROT_LOCAL, ZR,
                PRIM_COLOR, ALL_SIDES, ONES, 1
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
}

integer power_on;

default {
    state_entry() {
		llSetMemoryLimit(0x8000);
		screen_control(FALSE);
		damp(0);
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
			power_on = 1;
		} else if(m == "off") {
			power_on = 0;
			if(screen_open) {
				screen_control(FALSE);
				linked(LINK_THIS, 0, "menu-end", "");
				llSetTimerEvent(0);
			}
			fan = 0;
			rate = 0;
			damp(0);
		} else if(m == "menu-open") {
			if(!screen_open)
				screen_control(TRUE);
			llSetTimerEvent(15);
		} else if(m == "menu-close") {
			screen_control(FALSE);
			llSetTimerEvent(0);
		} else {
			list argv = split(m, " ");
			string cmd = gets(argv, 0);
			if(cmd == "fan") {
				fan = (float)gets(argv, 1);
				damp(rate * 0.001 + fan * 0.5);
			} else if(cmd == "color") {
				base_c = (vector)concat(delitem(argv, 0), " ");
				if(power_on) {
					float jiggle = current_temp - 0.01 + llFrand(0.02);
					if(jiggle < 0)
						jiggle = 0;
					damp(jiggle);
				}
			} else if(cmd == "rate") {
				rate = (float)gets(argv, 1);
				if(rate > 0)
					power_on = 1;
				damp(rate * 0.001 + fan * 0.5);
			}
		}
	}
}
