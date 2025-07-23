/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2014–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Chromatic Communicator (Akashic Icon) Template (single-color version)
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

// edit line 83 to control which faces/prims light up


#include <utils.lsl>
#include <objects.lsl>

#define ICON_VERSION "9.0"

integer L_CONTROL = 0;
integer L_LIGHTS = 0;

vector yes = <0.0, 1.0, 0.5>;
vector no = <1.0, 0.0, 0.5>;
vector love = <0.8, 0.0, 1.0>;

vector victory = <0.8, 0.9, 1.0>;
vector particles = <0.4, 0.9, 1.0>;
vector defeat = <1.0, 0.0, 0.0>;
vector question = <0.0, 0.5, 1.0>;

vector jeep = <0.5, 1.0, 0.0>;

vector off = <0.0, 0.0, 0.0>;

vector color = <0.7, 0.8, 1>;
// vector color = <0.388, 0.275, 0.796>;

float min_glow = 0.1;
float max_glow = 0.4;

#define C_CAPS 411
#define C_PUBLIC -9999999
integer C_CONTROL;
integer C_LIGHTS;

integer power_on = 1;
integer broken = 0;
integer emitting = 0;

integer SINK_PRIORITY = 200;

integer current_si;
key kid;
string tex;

key avatar;

color_me(vector color, float level) {
    setp(LINK_THIS, [
        PRIM_COLOR, ALL_SIDES, color * level, 1
    ]);
}

startParticles() {
    emitting = 1;
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_INTERP_SCALE_MASK |PSYS_PART_INTERP_COLOR_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_BURST_RADIUS, 0,
        PSYS_PART_START_COLOR, color,
        PSYS_PART_START_ALPHA, 0.1,
        PSYS_PART_END_COLOR, color,
        PSYS_PART_END_ALPHA, 0.2,
        PSYS_PART_START_SCALE, <0.1, 0.1, 0>,
        PSYS_PART_END_SCALE, <0.3, 0.3, 0>,
        PSYS_PART_START_GLOW, 0.2,
        PSYS_PART_END_GLOW, 0.3,
        PSYS_PART_BLEND_FUNC_SOURCE, PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
        PSYS_SRC_ACCEL, <1, 0, 0> * llGetRot() + <0, 0, 0.4>,
        PSYS_SRC_OMEGA, <0.01, 0.1, 0>,
        PSYS_SRC_TEXTURE, tex,
        PSYS_SRC_TARGET_KEY, kid
    ]);
}

default {   
    state_entry() {
//        llScriptProfiler(TRUE);
        avatar = llGetOwner();
        
        C_CONTROL = 100 - (integer)("0x" + substr(avatar, 29, 35));
        L_CONTROL = llListen(C_CONTROL, "", "", "");
        
        C_LIGHTS = 105 - (integer)("0x" + substr(avatar, 29, 35));
        L_LIGHTS = llListen(C_LIGHTS, "", "", "");
        
        llListen(C_PUBLIC, "", "", "");
        llListen(C_CAPS, "", "", "");
        
        power_on = 1;
        
        tell(avatar, C_LIGHTS, "add icon");

    //    llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
    //    llSetTextureAnim(ANIM_ON | SMOOTH | LOOP | ROTATE , ALL_SIDES, 9, 9, 0.2, 0.6, -0.1);
    
/*        integer memlimit = llGetSPMaxMemory() + 1000;
        while(!llSetMemoryLimit(memlimit)) {
            memlimit *= 2;
        }
        llScriptProfiler(FALSE);
        echo((string)memlimit + " bytes allocated.");*/
    }

    on_rez(integer n) {
        avatar = llGetOwner();
        
        C_CONTROL = 100 - (integer)("0x" + substr(avatar, 29, 35));
        llListenRemove(L_CONTROL);
        L_CONTROL = llListen(C_CONTROL, "", "", "");
        
        C_LIGHTS = 105 - (integer)("0x" + substr(avatar, 29, 35));
        llListenRemove(L_LIGHTS);
        L_LIGHTS = llListen(C_LIGHTS, "", "", "");
        
        power_on = 1;
        
        tell(avatar, C_LIGHTS, "add icon");
        
        // llSetTextureAnim(ANIM_ON | SMOOTH | LOOP | ROTATE, ALL_SIDES, 9, 9, 0.2, 0.6, -0.1);
    }
    
    listen(integer cc, string src, key id, string message) {
        if(cc == C_CAPS) {
            if(substr(message, 0, 4) == "info ") {
                integer rc = (integer)delstring(message, 0, 4);
                tell(id, rc, "hwc " + jsobject([
                    "vendor", "Nanite Systems Consumer Products",
                    "version", ICON_VERSION,
                    "purpose", "light,comm",
                    "channel", jsobject(["lights", C_LIGHTS, "command", C_CONTROL, "public", C_PUBLIC, "caps", C_CAPS]),
                    "private", 1,
                    "busy", 0,
                    "usable", power_on,
                    "health", 1.0,
                    "info", "http://nanite-systems.com/icon"
                ]));
            }
        } else if(cc == C_PUBLIC) {
            if(message == "sink") {
                llRegionSay(C_PUBLIC, (string)SINK_PRIORITY);
            } else if(message == (string)((integer)message)) {
                integer mi = (integer)message;
//                echo("Found sink " + src + " with priority " + message);
                if(llGetOwnerKey(id) == llGetOwnerKey(kid)) {
                    if(mi > current_si) {
                        current_si = mi;
                        kid = id;
                    }
                }
            }
        } else if(cc == C_CONTROL) {
            jump executive;
        } else if(cc == C_LIGHTS) {
            list argv = split(message, " ");
            string cmd = gets(argv, 0);
            
            float gap;
            if(message == "off") {
                llParticleSystem([]);
                gap = 0;
                color_me(off, 1);
                power_on = 0;
            } else if(message == "on") {
                power_on = 1;
                color_me(color, 1);
            } else if(message == "bolts on") {
                echo("@detach=n");
            } else if(message == "bolts off") {
                echo("@detach=y");
            } else if(message == "broken") {
                gap = 0.05;
                broken = 1;
            } else if(message == "fixed") {
                gap = 0;
                broken = 0;
                color_me(color, 1);
            } else if(cmd == "light") {
                color_me(color, 1);
                power_on = 1;
            } else if(cmd == "color") {
                color = <(float)gets(argv, 1), (float)gets(argv, 2), (float)gets(argv, 3)>;
                color_me(color, 1);
            } else if(substr(message, 0, 4) == "name ") {
                llSetObjectName(src + " (icon)");
            } else if(message == "probe") {
                tell(id, C_LIGHTS, "add icon");
            } else if(message == "add-confirm") {
                tell(id, C_LIGHTS, "add-command icon");
                tell(id, C_LIGHTS, "color-q");
                tell(id, C_LIGHTS, "power-q");
            } else if(cmd == "command") {
                if(gets(argv, 2) == "icon") {
                    message = concat(delrange(argv, 0, 2), " ");
                    jump executive;
                }
            }
            
            llSetTimerEvent(gap);
        }
        
        jump end;
        @executive;
        if(power_on == 0) {
            echo("Can't blink: turned off.");
            return;
        }
        
        float x;
        vector c;
        for(x = 1.0; x > -0.1; x -= 0.1) {
            color_me(color, x);
            llSleep(0.01);
        }
        
        if(message == "yes") {
            llPlaySound("yes", 1.0);
            c = yes;
        } else if(message == "no") {
            llPlaySound("no", 1.0);
            c = no;
        } else if(message == "love") {
            llPlaySound("love", 1.0);
            c = love;
        } else if(substr(message, 0, 9) == "particles ") {
            current_si = 0;
            list parts = split(message, " ");
            kid = (key)gets(parts, 1);
            tell(kid, -9999999, "sink");
    //                echo("Sent sink priority request.");
            tex = "Scarf-Chirp";
            startParticles();
            llPlaySound("love", 1.0);
            c = particles;
            llSetTimerEvent(0.1);
        } else if(message == "stop_particles") {
            llParticleSystem([]);
            emitting = 0;
            c = particles;
            if(broken == 0)
                llSetTimerEvent(0);
            else
                llSetTimerEvent(0.15);
        } else if(message == "victory") {
            llPlaySound("victory", 1.0);
            c = victory;
        } else if(message == "defeat") {
            llPlaySound("defeat", 1.0);
            c = defeat;
        } else if(message == "question") {
            llPlaySound("question", 1.0);
            c = question;
        } else if(message == "explain") {
            llPlaySound("yes", 1.0);
            llWhisper(0, "This unit is equipped with a Nanite Systems Chromatic Communications Interface. Listen for the tone and observe the forehead light to determine what it wishes to indicate.");
            c = <1.0, 1.0, 1.0>;
        } else if(message == "jeep") {
            llPlaySound("jeep", 1.0);
            llWhisper(0, "Beep beep!");
            c = jeep;
        }
        
        setp(LINK_THIS, [PRIM_GLOW, ALL_SIDES, max_glow]);
        
        for(x = 0.0; x < 1.0; x += 0.1) {
            color_me(c, x);
            llSleep(0.001);
        }
        
        llSleep(0.4);
        
        for(x = 1.0; x > -0.1; x -= 0.1) {
            color_me(c, x);
            llSleep(0.03);
        }
        
        setp(LINK_THIS, [PRIM_GLOW, ALL_SIDES, min_glow]);
        
        llSleep(0.2);
        
        for(x = 0.0; x < 1.0; x += 0.1) {
            color_me(color, x);
            llSleep(0.01);
        }
        @end;
    }
    
    timer() {
        if(broken) {
            float t = 1;
            if(llFrand(1.0) < 0.1)
                t = llFrand(0.2);
                    
            color_me(color, t);
        }
        
        if(emitting) {
            if(llFrand(1) < 0.333)
                tex = "Scarf-Chirp";
            else if(llFrand(1 < 0.5))
                tex = "Scarf-Segment";
            else
                tex = "Scarf-Sigil";
                
            startParticles();
        }
    }
}