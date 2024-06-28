/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  NS-119 Arecibo Hardware Driver
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

vector c1 = <0, 0.5, 1>;
vector c2 = <1, 0.5, 0>;
vector c3 = <0.5, 1, 0>;
vector c4 = <0, 0.75, 1>;

#define DORSAL llEuler2Rot(<0, -PI_BY_TWO, 0>)
#define VENTRAL llEuler2Rot(<PI, -PI_BY_TWO, 0>)
rotation MASTER_ROT;
vector MASTER_OFFSET;
vector custom_offset;
#define VENTRAL_OFFSET <0.25, 0, 0.2>

#define LID 6
#define SCREEN 9
#define SCREEN_2 10
#define SCREEN_3 11
#define SCREEN_4 12
#define SCREEN_5 13
#define SCREEN_CONE 8
#define TEXT_START 14
#define TEXT_COUNT 66
#define PROJECTOR 7

integer screen_open = FALSE;

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/52.0)

#define X_BIAS -2.5
#define Y_BIAS -5.0

#define projection_magnitude 0.5

screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <0, 0, 0.0>;
		
		#define POST_ROT llEuler2Rot(<PI_BY_TWO, PI_BY_TWO, 0>)
        
		#define SCREEN_OMEGA_AXIS <0, 0, 1>
		
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, ONES * 0.75 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.1,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, 1, 1,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, ONES * 0.5 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.03125, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.05,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, -2, 1,
		PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, ONES * 0.25 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.025, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.1,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, -0.25, 1,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, ONES * 0.75 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.1, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.05,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, 0.5, 1,
		PRIM_LINK_TARGET, SCREEN_4,
			PRIM_SIZE, ONES * 0.5 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.065, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.05,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, 1.125, 1,
		PRIM_LINK_TARGET, SCREEN_5,
			PRIM_SIZE, ONES * 0.875 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.13, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, c1, 0.05,
			PRIM_OMEGA, SCREEN_OMEGA_AXIS, -0.375, 1,
		PRIM_LINK_TARGET, PROJECTOR,
			PRIM_COLOR, ALL_SIDES, c1, 1,
			PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
			PRIM_GLOW, ALL_SIDES, 0.5
        ];
        
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
			
			#define final_text_offset <-0.25, 0, 0>
			
            float y = (float)(dy) + Y_BIAS;
            rotation R = llEuler2Rot(<0, 0.085375 * x * PI_BY_TWO, 0>);
            acts += [
                PRIM_LINK_TARGET, pn,
                // PRIM_DESC, "T" + (string)ty + "," + (string)tx,
                PRIM_SIZE, scale * secondary_scale,
                PRIM_POS_LOCAL, ((<0, y * Y_STEP, 0.025 * secondary_scale * secondary_scale> * secondary_scale + <0, 0, projection_magnitude * 0.95>) * R * POST_ROT + final_text_offset + screen_origin + MASTER_OFFSET) * MASTER_ROT,
				PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 128,
				// PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_BLEND, 128,
                PRIM_ROT_LOCAL, llEuler2Rot(<-PI_BY_TWO, 0, PI_BY_TWO>) * R * POST_ROT * MASTER_ROT
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
        vector screen_origin = <-0.0625, 0, 0>;
        
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
		PRIM_LINK_TARGET, SCREEN_4,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_5,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, SCREEN_CONE,
            PRIM_SIZE, ZV,
			PRIM_POS_LOCAL, screen_origin,
		PRIM_LINK_TARGET, PROJECTOR,
			PRIM_COLOR, ALL_SIDES, c1 * power_on, 1,
			PRIM_FULLBRIGHT, ALL_SIDES, power_on,
			PRIM_GLOW, ALL_SIDES, 0.05 * (float)power_on
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

float rate;
float power;

list custom_lights() {
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
        rate_color = c1;
    
    if(power < 0.1)
        power_color = c3;
    else if(power < 0.2)
        power_color = c4;
    else
        power_color = c1;
    
    return [
    PRIM_LINK_TARGET, 3,
        PRIM_COLOR, 3, power_color * power_on, 1, PRIM_GLOW, 3, gpower,
        PRIM_COLOR, 6, rate_color * power_on, 1, PRIM_GLOW, 6, gpower,
        PRIM_TEXTURE, 3, G, <0.25, 0.25, 0>, offsetp, anglep, 
        PRIM_TEXTURE, 6, G, <0.25, 0.25, 0>, offsetr, angler,
        PRIM_FULLBRIGHT, 3, power_on,
        PRIM_FULLBRIGHT, 6, power_on,
    PRIM_LINK_TARGET, LID,
        PRIM_COLOR, 4, c1 * ppower, 1, PRIM_GLOW, 4, gpower,
        PRIM_COLOR, 2, c3 * ppower, 1, PRIM_GLOW, 2, gpower,
        PRIM_FULLBRIGHT, 4, power_on,
        PRIM_FULLBRIGHT, 2, power_on,
        PRIM_SPECULAR, 4
    ] + llListReplaceList(llGetLinkPrimitiveParams(LID, [PRIM_SPECULAR, 4]), [c1 * 0.5], 4, 4);
}

integer power_on = 1;

default {
    state_entry() {
		#ifdef STOP_SOUND
		llLinkStopSound(LINK_SET);
		llSetLinkTextureAnim(LINK_SET, 0, ALL_SIDES, 0, 0, 0, 0, 0);
		#endif
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN_2, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		//llSetMemoryLimit(0x8000);
		
		MASTER_ROT = DORSAL;
		
		#ifdef TEST_SCREEN
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
			power_on = 1;
			setp(0, custom_lights());
		} else if(m == "off") {
			power_on = 0;
			
			screen_control(FALSE);
			linked(LINK_THIS, 0, "menu-end", "");
			llSetTimerEvent(0);
			setp(0, custom_lights());
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
			if(cmd == "rate") {
				rate = (float)gets(argv, 1);
				setp(0, custom_lights());
			} else if(cmd == "power") {
				power = (float)gets(argv, 1);
				setp(0, custom_lights());
			} else if(cmd == "color") {
				c1 = (vector)concat(delitem(argv, 0), " ");
				/* if(screen_open)
					screen_control(TRUE); */
			} else if(cmd == "color-2") {
				c2 = (vector)concat(delitem(argv, 0), " ");
			} else if(cmd == "color-3") {
				c3 = (vector)concat(delitem(argv, 0), " ");
			} else if(cmd == "color-4") {
				c4 = (vector)concat(delitem(argv, 0), " ");
				if(screen_open)
					screen_control(TRUE);
			} else if(cmd == "projector") {
				string action = gets(argv, 1);
				if(action == "offset") {
					custom_offset = <(float)gets(argv, 2), (float)gets(argv, 3), (float)gets(argv, 4)>;
					if(MASTER_ROT == VENTRAL) {
						MASTER_OFFSET = custom_offset + VENTRAL_OFFSET;
					} else if(MASTER_ROT == DORSAL) {
						MASTER_OFFSET = custom_offset + ZV;
					}
				} else if(action == "orientation") {
					string target = gets(argv, 2);
					if(target == "ventral") {
						MASTER_ROT = VENTRAL;
						MASTER_OFFSET = custom_offset + VENTRAL_OFFSET;
					} else {
						MASTER_ROT = DORSAL;
						MASTER_OFFSET = custom_offset + ZV;
					}
				} else if(action == "dcb") {
					integer CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
					echo("/" + (string)CL + " projector offset " + (string)custom_offset.z + " " + (string)custom_offset.y + " " + (string)custom_offset.x);
					if(MASTER_ROT == VENTRAL)
						echo("/" + (string)CL + " projector orientation ventral");
					else
						echo("/" + (string)CL + " projector orientation dorsal");
					return;
				}
				screen_control(TRUE);
				llSetTimerEvent(15);
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
