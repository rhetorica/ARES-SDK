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

vector base_c = <0, 0.5, 1>;
vector c4 = <0, 0.75, 1>;

integer open;
integer power_on;
float scale = 1.0;

#define step 0.1
#define span -2.4

#define original_size 0.114149

operate_door() {
    vector s = llGetScale();
    scale = s.x / original_size;
    
    vector so = getv(getp(2, [PRIM_POS_LOCAL]), 0);
    
    
    float polarity = 1;
    if(open) {
        polarity = -1;
        llTriggerSound("3f075de9-738c-1b1e-ae67-8149a84647ee", 1);
    } else {
        llTriggerSound("0c205a19-ebd7-7195-7e8e-426b1bda48d4", 1);
    }
    
    llTriggerSound("10722bf0-fdac-2497-3b2c-f6d9e6625f7c", 1);
    
    float initial = span * open;
    float target = (span * (1 - open)) - initial;
    
    float i;
    float r;
    
    
    #define ioff 0.0073
    #define doff 0.0078
        
    vector vo = so + <0, 0, 0.0317 - doff>;
        
    for(i = 0; i <= 1 + step; i += step) {
        r = i * target + initial;
        
        list f = [];
        integer p = 6;
        while(p--) {
            rotation r0 = llEuler2Rot(<180, 180, p * 60 + 30> * DEG_TO_RAD);
            rotation r1 = llEuler2Rot(<0, r, 0>);
            
            vector v = <-0.014654 - ioff, 0, 0>;
            
            f += [
            PRIM_LINK_TARGET, p + 22,
                PRIM_POS_LOCAL, (<ioff, 0, doff> * r1 + v) * scale * r0 + vo,
                PRIM_ROT_LOCAL, r1 * r0
            ];
        }
        
        setp(0, f);
    }
    
    if(open)
        llTriggerSound("d24539cd-0dd0-c0c3-99c2-3421fdbf5656", 1);
    else
        llTriggerSound("2227d6ea-fe24-dd2f-fb1e-a31e1531b402", 1);
    
    open = !open;
    
    // linked(LINK_THIS, 109, (string)open, "");
    /* 
    r = open * span;
    
    left_rot = llEuler2Rot(<r, 0, 0>);
    right_rot = llEuler2Rot(<-r, 0, 0>);
    
    llSetLinkPrimitiveParams(0, [
        PRIM_LINK_TARGET, L,
            PRIM_POS_LOCAL, door_L_pos * scale + door_L_hinge * scale * r * left_rot + door_L_extend * scale * open,
            PRIM_ROT_LOCAL, ZERO_ROTATION * left_rot,
            
        PRIM_LINK_TARGET, R,
            PRIM_POS_LOCAL, door_R_pos * scale + door_R_hinge * scale * r * right_rot + door_R_extend * scale * open,
            PRIM_ROT_LOCAL, ZERO_ROTATION * right_rot
    ]); */
}

key hatch_operator;

default {
    state_entry() {
		llSetMemoryLimit(0x8000);
	}
	
	touch_start(integer n) {
		while(n--) {
			key toucher = llDetectedKey(n);
			integer pi = llDetectedLinkNumber(n);
			string part = llGetLinkName(pi);
			
			if(part == "lid" && !power_on) {
				linked(LINK_THIS, 0, "touch-hatch", toucher);
				if(open) {
					hatch_operator = toucher;
					integer CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
					tell(llGetOwner(), CL, "hatch-blocked-q");
					llSetTimerEvent(0.75);
				} else {
					operate_door();
				}
			} else {
				// if "Object" || ("lid" && power_on)
				linked(LINK_THIS, 0, "menu-request", toucher);
				/*if(!power_on) {
					
				} else {
					linked(LINK_THIS, 0, "menu-start", toucher);
				}*/
			}
		}
	}
	
	timer() {
		operate_door();
		llSetTimerEvent(0);
	}
	
	link_message(integer s, integer n, string m, key id) {
		if(n == 1) {
			// non-light-bus messages
			if(m == "door 1") {
				if(open)
					operate_door();
			} else if(m == "door 0") {
				if(!open)
					operate_door();
			}
		} else {
			if(m == "on") {
				power_on = 1;
			} else if(m == "off") {
				power_on = 0;
				
				// damp(0);
			} else if(m == "hatch-blocked") {
				// tell(hatch_operator, 0, "Cannot close hatch while ejected battery is present.");
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