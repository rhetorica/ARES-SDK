/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  oXq.205.8i Artifact Hardware Driver
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
vector c2 = <0, 0.75, 1>;
vector c3 = <0, 0.75, 1>;
vector c4 = <0, 0.75, 1>;

#define SCREEN 7
#define SCREEN_2 8
#define SCREEN_3 9
#define SCREEN_CONE 6
#define TEXT_START 10
#define TEXT_COUNT 66

integer screen_open = FALSE;

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/5.0)

screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <-0.059, 0, 0.158>;
        
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, <0.4900000, 0.4900000, 0.2450000>,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <0.18, 0, 0.05>,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, <0.24, 0.06, 0.06>,
			PRIM_POS_LOCAL, screen_origin + <-0.18, 0, 0.05>,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, <0.4900000, 0.4900000, 0.0625>,
			PRIM_POS_LOCAL, screen_origin + <0, 0, -0.059>,
			PRIM_COLOR, ALL_SIDES, c4, 0.0625,
		PRIM_LINK_TARGET, 2,
			PRIM_COLOR, ALL_SIDES, base_c, 1,
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
                PRIM_POS_LOCAL, (<y * X_STEP / 3.0, -x * X_STEP, 0.025 * secondary_scale * secondary_scale> * secondary_scale + screen_origin),
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
		PRIM_LINK_TARGET, 2,
			PRIM_COLOR, ALL_SIDES, ZV, 1,
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

#define DOOR_MOVE_SOUND "23011d73-c761-58a6-3a1d-466c760163cf"

key hatch_operator;
integer timer_close_hatch;
operate_door() {
    llLinkPlaySound(LID, DOOR_MOVE_SOUND, 1, SOUND_PLAY);
    
    door_open = !door_open;
    float sign = (float)(door_open << 1) - 1.0;
    float hi = 0;
    list lid_props = getp(LID, [PRIM_SIZE, PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
    vector lids = getv(lid_props, 0);
    vector lidp = getv(lid_props, 1);
    rotation lidr = getr(lid_props, 2);
    vector lido = <lids.x * 0.5, 0, -lids.z * 0.5>;
    while(hi <= 1) {
        rotation lidnr = llEuler2Rot(<0, 120 * DEG_TO_RAD * hi * sign, 0>);
        setp(LID, [
            PRIM_POS_LOCAL, lidp + (lido - lido * lidnr) * lidr,
            PRIM_ROT_LOCAL, lidnr * lidr
        ]);
        hi += 0.1;
        llSleep(0.022);
    }
    
    tell(system, CL, "door " + (string)door_open);
}

float rate;
float power;

#define LID 3

custom_lights() {
    float d_rate = rate * 0.001;
    if(d_rate < 0)
        d_rate = 1;
    else if(d_rate > 1)
        d_rate = 1;
    
    float angler = (d_rate * 0.5 + 0.25) * PI_BY_TWO;
    vector offsetr = <0.0, 0.4, 0> * llEuler2Rot(<0, 0, angler - PI_BY_TWO * 0.5>);
        
    float anglep = (power * 0.5 + 0.8889 + 0.25) * PI_BY_TWO;
    vector offsetp = <0.0, 0.4, 0> * llEuler2Rot(<0, 0, anglep - PI_BY_TWO * 1.389>);
    
    float ppower = 0.9 * power_on + 0.1;
    float gpower = 0.04 * power_on;
    
    #define BG "00ec3491-3abe-fb43-7a5b-e0b4adb38a77"
    #define G "88bddda1-f8da-ddf9-af2d-1928f78d491b"
    
    vector power_color;
    vector rate_color;
    
    if(rate > 1000)
        rate_color = c4;
    else if(rate < 0)
        rate_color = c2;
    else
        rate_color = base_c;
    
    if(power < 0.1)
        power_color = c3;
    else if(power < 0.2)
        power_color = c4;
    else
        power_color = base_c;
    
    setp(1, [
        PRIM_COLOR, 3, power_color * power_on, 1, PRIM_GLOW, 3, gpower,
        PRIM_COLOR, 6, rate_color * power_on, 1, PRIM_GLOW, 6, gpower,
        PRIM_TEXTURE, 3, G, <0.25, 0.25, 0>, offsetp, anglep, 
        PRIM_TEXTURE, 6, G, <0.25, 0.25, 0>, offsetr, angler,
        PRIM_FULLBRIGHT, 3, power_on,
        PRIM_FULLBRIGHT, 6, power_on,
    PRIM_LINK_TARGET, LID,
        PRIM_COLOR, 4, base_c * ppower, 1, PRIM_GLOW, 4, gpower,
        PRIM_COLOR, 2, base_c * ppower, 1, PRIM_GLOW, 2, gpower,
        PRIM_FULLBRIGHT, 4, power_on,
        PRIM_FULLBRIGHT, 2, power_on,
        PRIM_SPECULAR, 4
    ] + llListReplaceList(llGetLinkPrimitiveParams(LID, [PRIM_SPECULAR, 4]), [base_c * 0.5], 4, 4));
}

integer power_on;

default {
    state_entry() {
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN, ANIM_ON | LOOP, ALL_SIDES, 2, 2, 0, 4, 15);
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
			custom_lights();
		} else if(m == "off") {
			power_on = 0;
			
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
			llSetTimerEvent(0);
			custom_lights();
			
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
			} else if(cmd == "color-3") {
				c3 = (vector)concat(delitem(argv, 0), " ");
				if(screen_open)
					screen_control(TRUE);
			} else if(cmd == "color-2") {
				c2= (vector)concat(delitem(argv, 0), " ");
				if(screen_open)
					screen_control(TRUE);
			} else if(cmd == "rate") {
				rate = (float)gets(argv, 1);
				if(rate > 0)
					power_on = 1;
				// damp(rate * 0.001 + fan * 0.5);
			} else if(cmd == "power") {
				power = (float)gets(argv, 1);
				// damp(rate * 0.001 + fan * 0.5);
			} else {
				return;
			}
			
			custom_lights();
		}
	}
}
