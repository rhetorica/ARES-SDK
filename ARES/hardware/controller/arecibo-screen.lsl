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

vector base_c = <0, 0.5, 1>;
vector c4 = <0, 0.75, 1>;

#define DORSAL ZERO_ROTATION
#define VENTRAL llEuler2Rot(<PI, PI, 0>)
rotation MASTER_ROT;
vector MASTER_OFFSET;
vector custom_offset;
#define VENTRAL_OFFSET <0.25, 0, 0.2>

#define SCREEN 17
#define SCREEN_2 20
#define SCREEN_3 21
#define SCREEN_4 3
#define SCREEN_5 19
#define SCREEN_CONE 18
#define TEXT_START 22
#define TEXT_COUNT 66

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
        
        acts += [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_SIZE, ONES * 0.75 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.1,
			PRIM_OMEGA, <1, 0, 0>, 1, 1,
		PRIM_LINK_TARGET, SCREEN_CONE,
			PRIM_SIZE, ONES * 0.5 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.03125, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.05,
			PRIM_OMEGA, <1, 0, 0>, -2, 1,
		PRIM_LINK_TARGET, SCREEN_2,
			PRIM_SIZE, ONES * 0.25 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.0225, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.1,
			PRIM_OMEGA, <1, 0, 0>, -0.25, 1,
		PRIM_LINK_TARGET, SCREEN_3,
			PRIM_SIZE, ONES * 0.75 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.1, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.05,
			PRIM_OMEGA, <1, 0, 0>, 0.5, 1,
		PRIM_LINK_TARGET, SCREEN_4,
			PRIM_SIZE, ONES * 0.5 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin - <0.065, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.05,
			PRIM_OMEGA, <1, 0, 0>, 1.125, 1,
		PRIM_LINK_TARGET, SCREEN_5,
			PRIM_SIZE, ONES * 0.875 * projection_magnitude,
			PRIM_POS_LOCAL, (screen_origin + <0.13, 0, 0> + MASTER_OFFSET) * MASTER_ROT,
			PRIM_ROT_LOCAL, POST_ROT * MASTER_ROT,
			PRIM_COLOR, ALL_SIDES, base_c, 0.05,
			PRIM_OMEGA, <1, 0, 0>, -0.375, 1,
		PRIM_LINK_TARGET, 12,
			PRIM_COLOR, 1, base_c, 1,
			PRIM_FULLBRIGHT, 1, TRUE,
			PRIM_GLOW, 1, 0.2
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
		PRIM_LINK_TARGET, 12,
			PRIM_COLOR, 1, c4 * power_on, 1,
			PRIM_FULLBRIGHT, 1, power_on,
			PRIM_GLOW, 1, 0.2 * (float)power_on
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

integer power_on = 1;

default {
    state_entry() {
		// llLinkStopSound(LINK_SET);
		llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		llSetLinkTextureAnim(SCREEN_4, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
		//llSetMemoryLimit(0x8000);
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
