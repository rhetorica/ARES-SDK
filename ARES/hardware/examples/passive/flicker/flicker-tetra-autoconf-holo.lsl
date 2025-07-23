/*
 FLICKER AUTOCONF, TETRA HOLO VERSION
 
 Public domain.
 
 Written by rhet0rica, Aug 17, 2021.
 Last updated Aug 15, 2023.
 
 Allows linksets to use the NS lighting bus. Requires setting descriptions on all prims.

 For each link in your linkset, set the description as follows:
 
 1. start with @ to indicate it is a flicker rule (otherwise it will be ignored)
 2. put an optional "L" to indicate this is your lamp prim
    (each linkset may have up to 1 lamp prim, it will be a point lightsource)
 3. put an optional "H" to indicate the listed faces should be invisible when the unit is off or in a booth
    (for holograms; supports block-holo)
 4. list the face numbers to modify, separated by commas
    (-1 for all)
 5. before each face number, write one of the following flag letters:
 
 color/rule flags:
  A = 0 = color A, full intensity
  B = 1 = color B, full intensity
  C = 2 = color C, full intensity
  D = 3 = color D, full intensity
  a = 32 = color A, low intensity
  b = 33 = color B, low intensity
  c = 34 = color C, low intensity
  d = 35 = color D, low intensity
  i = 40 = reactive, industrial type
  p = 47 = reactive, pleasure type
  w = 54 = reactive, working only (pulsates color D when working; other reactive types pulsate color A)
  x = 55 = reactive, combat type
  
  Examples:
  
    "@LA-1" = this is a lamp prim (light source)
        it always looks like color A on all sides, full intensity
    
    "@i2,p3,C5,C6" = industrial reactive on face 2,
        pleasure reactive face 3, full-intensity color C on faces 5 and 6
    
    "@Li2,p3,C5,C6" = as above, but sets a point light using color C
        lamp color is determined by the last face listed
    
    "@Lp3,C5,C6,i2" = as above, but the light now uses "reactive, industrial type" rules
        (face numbers don't have to be in order!)
    
    "@Lp3,C5,C6,i-10" = as above, but without setting any face to industrial
        face -10 doesn't exist, but the lamp reads it anyway
    
    "@Hx-1" = all sides follow the "reactive, combat type" rules
        entire prim disappers when powered off or in a booth
    
    "@LHi7,i6" = lamp prim using "reactive, industrial type" rules on face 6 and 7
        only the listed faces (face 6 and 7) will disappear when powered off
  
  This script preserves the alpha value of each face. However, if you use -1, then face 0's
  alpha will be applied to the other faces of the same prim. To avoid this, list the faces
  manually (e.g. "@A0,A1,A2,A3,A4,A5,A6,A7" instead of "@A-1")
  
  TO DEPLOY THIS SCRIPT, drag it into the Content tab of any prim in your linkset.

  TIPS
  ====
  
  The flag to turn faces holographic (H) applies to all faces listed. If you're creating a holographic
  ornament that also includes a non-holographic light (e.g. on the emitter) then you should split
  up your creation into multiple parts instead of exporting all the materials as one object.
  
  You may choose to restrict copy/modify/transfer; that's up to you. This is a public domain script.
  
  You are allowed to redistribute the NS Color HUD (bismuth) with any product that uses this script.
  
  To reload settings after changes are made, this script must be reset. If you have no idea how to do
  that, just delete and re-add it.
  
  If you do not see the message "Memory Limit set at ##### bytes" after recompiling, the memory limit
  is stuck at 64 KiB. Maybe it's time you got a simpler attachment?
  
  You can also try recompiling this with "Mono" disabled. It will run slower, but never exceed 16 KiB.
  
  TO USE THIS SCRIPT IN A CUSTOM MAIN CONTROLLER, search for the word "uncomment" near the bottom of this file.
*/

// how much glow to use for full intensity and reactive faces:
float glow_strength = 0.05;
// how much glow to use for low-intensity faces:
float glow_strength_low = 0.02;

list prims; // prim, face, alpha, color+rule
integer rule_count;
integer light = -1;

vector colorA = <1, 0, 1>;
vector colorB = <0, 1, 0>;
vector colorC = <1, 0, 0>;
vector colorD = <1, 1, 1>;

integer lamp_on = 1;
integer power_on = 1;
integer broken = 0;
integer working = 0;
float integrity = 1.0;
float arousal = 0.0;
float rate = 780.0;
float battery = 1.0;

integer arousal_used; // whether to respond to arousal
integer integrity_used; // whether to respond to integrity
integer basic_used; // whether to respond to working, rate, or power
integer holo_used; // whether we found any holographic faces

key av;
integer CL;
integer LL;

integer unblockable = FALSE; // set to TRUE to ignore holoblockers
list blockers; // if non-empty, holograms are currently hidden

integer last_blocker_check;
float last_repaired_at;
float last_charged_at;
float last_damaged_at;
float current_timer_rate;

float main_timer_rate = 0.1; // set smoothness

colorize() {
    // update timer if needed:
    
    float now = llGetTime();
    float last_rep_clock = now - last_repaired_at;
    float last_chr_clock = now - last_charged_at;
    float last_dmg_clock = now - last_damaged_at;
    
    if(!power_on && current_timer_rate != 0) {
        llSetTimerEvent(current_timer_rate = 0);
    } else if(broken) {
        llSetTimerEvent(current_timer_rate = main_timer_rate * 0.5 + llFrand(2) * llFrand(2));
    } else if((current_timer_rate > 0)
        && !((arousal > 0)
           || (last_chr_clock < 1.0)
           || (last_rep_clock < 1.0)
           || (last_dmg_clock < 1.0)
           || (working))) {
        llSetTimerEvent(current_timer_rate = 0);
    } else {
        llSetTimerEvent(current_timer_rate = main_timer_rate);
    }
    
    list rules;
    integer current_prim = -1;
    integer ri = rule_count;
    
    float intensity = power_on;
    if(broken)
        intensity *= 0.2 + (llFrand(1) > 0.3) * 0.8;
        
    float clocksignal;
    
    if(current_timer_rate) {
        clocksignal = (now); // / TWO_PI;
        clocksignal = llSin((clocksignal - (integer)clocksignal) * TWO_PI); // in range [-1, 1]
    }
    
    while(ri--) {
        integer radix = ri << 2;
        integer p = llList2Integer(prims, radix);
            
        integer fx = llList2Integer(prims, radix + 3);
        float g = 1.0;
        vector c;
        integer h = (fx & 0x100);
        if(h)
            fx = fx & 0xff;
        
        if(fx == 0 || fx == 32) {
            c = colorA;
        } else if(fx == 1 || fx == 33) {
            c = colorB;
        } else if(fx == 2 || fx == 34) {
            c = colorC;
        } else if(fx == 3 || fx == 35) {
            c = colorD;
        } else { // special colors; you may want to edit these rules:
            if(last_dmg_clock < 1 && fx == 55) { // flash color C for 1 second after damage, rule x only
                c = colorC;
            } else if(last_rep_clock < 1 && fx == 55) { // flash color B for 1 second after repair, rule x only
                c = colorB;
            } else if(arousal > 0 && fx == 47) { // show arousal on rule p
                c = colorB * (1.0 + clocksignal * arousal * 0.375 - arousal * 0.25);
                g = 1.0 + clocksignal * arousal;
            } else if(integrity < 0.5 && fx == 55) { // below 50% integrity on rule x
                c = colorC;
            } else if(last_chr_clock < 1.0 && fx != 54) { // show color B for 1 second after power received
                c = colorB;
            } else if(battery < 0.1 && fx != 54) { // show color C when battery below 10%
                c = colorC;
            } else if(battery < 0.2 && fx != 54) { // show color D when battery below 20%
                c = colorD;
            } else if(rate > 925.0 && fx != 54) { // show color D on most types when power usage over 925 W
                c = colorD;
            } else if(working) {
                if(fx == 54)
                    c = colorD;
                else
                    c = colorA;
                
                c *= (clocksignal * 0.25 + 0.75);
            } else { // set the default color for all special faces
                c = colorA;
            }
        }
        
        if(fx >= 32 && fx <= 35) { // dim colors
            c *= 0.1;
            g *= glow_strength_low * intensity;
        } else {
            g *= glow_strength * intensity;
        }
        
        c *= intensity;
            
        if(p != current_prim) {
            rules += [PRIM_LINK_TARGET, p];
            if(p == light)
                rules += [PRIM_POINT_LIGHT, lamp_on, c, 1, 1, 1];
        }
            
        integer f = llList2Integer(prims, radix + 1);
        float a = llList2Float(prims, radix + 2);
        if(h) {
            integer bi;
            if(!power_on) {
                a = 0;
                g = 0;
            } else if(bi = llGetListLength(blockers)) {
                if(llGetUnixTime() - last_blocker_check > 3) {
                    while(bi--) {
                        key b = llList2Key(blockers, bi);
                        if(~llListFindList(llGetAttachedList(av), [b]))
                            jump blocked;
                        else if(b == llList2Key(llGetObjectDetails(av, [OBJECT_ROOT]), 0))
                            jump blocked;
                        else
                            blockers = llDeleteSubList(blockers, bi, bi);
                    }
                    jump unblocked;
                    @blocked;
                    a = 0;
                    g = 0;
                    @unblocked;
                    last_blocker_check = llGetUnixTime();
                }
            }
        }
        
        if(f >= -1)
            rules += [
                PRIM_COLOR, f, c, a, // liquidator brunt
                PRIM_GLOW, f, g,
                PRIM_FULLBRIGHT, f, (intensity > 0.5)
            ];
    }
    
    llSetLinkPrimitiveParamsFast(!llGetLinkNumber(), rules);
}

default {
    state_entry() {
        llScriptProfiler(TRUE);
        LL = llListen(CL = 105 - (integer)("0x" + llGetSubString(av = llGetOwner(), 29, 35)), "", "", "");
        
        integer L1 = llGetLinkNumber();
        integer pi = llGetNumberOfPrims() + L1;
        while(pi > L1) {
            --pi;
            string d = llList2String(llGetLinkPrimitiveParams(pi, [PRIM_DESC]), 0);
            if(llOrd(d, 0) == 0x40) { // '@'
                if(llOrd(d, 1) == 0x4C) { // 'L'
                    light = pi;
                    d = llDeleteSubString(d, 0, 1);
                } else {
                    d = llDeleteSubString(d, 0, 0);
                }
                
                integer rule_boost = 0;
                
                if(llOrd(d, 0) == 0x48) { // 'H'
                    rule_boost = 0x100;
                }
                
                list facecodes = llParseString2List(d, [","], []);
                integer fi = llGetListLength(facecodes);
                while(fi--) {
                    // prim, face, alpha, color+rule
                    string fs = llList2String(facecodes, fi);
                    integer fx = llOrd(fs, 0) - 0x41; // 'A' => 0
                    integer fni = (integer)llDeleteSubString(fs, 0, 0);
                    
                    if(fx > 35)
                        basic_used = 1;
                    if(fx == 47)
                        arousal_used = 1;
                    if(fx == 55)
                        integrity_used = 1;
                    if(rule_boost == 0x100)
                        holo_used = 1;
                    
                    fx += rule_boost;
                    
                    // llOwnerSay("fni " + (string)fni + " is rule " + (string)fx + " (" + fs + ")");
                    prims += [pi, fni, llList2Float(llGetLinkPrimitiveParams(pi, [PRIM_COLOR, fni]), 1), fx];
                    
                    ++rule_count;
                }
            }
        }
        
        llRegionSayTo(av, CL, "power-q");
        llRegionSayTo(av, CL, "color-q");
        
        colorize();
        
        llScriptProfiler(FALSE);
        integer ml = llGetSPMaxMemory();
        llOwnerSay("SP memory limit: " + (string)ml + " bytes.");
        if(llSetMemoryLimit(ml += 0x0400 * rule_count))
            llOwnerSay("Memory limit set at " + (string)ml + " bytes.");
    }
    
    changed(integer c) {
        if(c & CHANGED_OWNER) {
            llListenRemove(LL);
            LL = llListen(CL = 105 - (integer)("0x" + llGetSubString(av = llGetOwner(), 29, 35)), "", "", "");
            llRegionSayTo(av, CL, "power-q");
            llRegionSayTo(av, CL, "color-q");
        }
    }
    
    on_rez(integer n) {
        if(av == llGetOwner()) {
            llRegionSayTo(av, CL, "power-q");
            llRegionSayTo(av, CL, "color-q");
        }
    }
    
    listen(integer c, string n, key id, string m) {
        if(m == "block-holo" && !unblockable && holo_used) {
            if(llGetAttached())
                blockers += id;
        } else if(m == "on") {
            power_on = 1;
        } else if(m == "off") {
            power_on = 0;
        } else if(m == "broken") {
            broken = 1;
        } else if(m == "error") {
            broken = 2;
        } else if(m == "fixed") {
            broken = 0;
        } else if(m == "working" && basic_used) {
            working = 1;
        } else if(m == "done" && basic_used) {
            working = 0;
        } else if(m == "bolts on") {
            llOwnerSay("@detach=n");
        } else if(m == "bolts off") {
            llOwnerSay("@detach=y");
        } else if(m == "lamp on" && ~light) {
            lamp_on = 1;
        } else if(m == "lamp off" && ~light) {
            lamp_on = 0;
        } else {
            list argv = llParseString2List(m, [" "], []);
            string cmd = llList2String(argv, 0);
            if(cmd == "color") {
                colorA = <(float)llList2String(argv, 1), 
                          (float)llList2String(argv, 2), 
                          (float)llList2String(argv, 3)>;
                
                // uncomment this line to use this as the lighting script for a main controller:
                // llMessageLinked(LINK_ROOT, 28, llGetSubString(m, 6, -1), "");
            } else if(cmd == "color-2") {
                colorB = <(float)llList2String(argv, 1), 
                          (float)llList2String(argv, 2), 
                          (float)llList2String(argv, 3)>;
            } else if(cmd == "color-3") {
                colorC = <(float)llList2String(argv, 1), 
                          (float)llList2String(argv, 2), 
                          (float)llList2String(argv, 3)>;
            } else if(cmd == "color-4") {
                colorD = <(float)llList2String(argv, 1), 
                          (float)llList2String(argv, 2), 
                          (float)llList2String(argv, 3)>;
            } else if(cmd == "rate" && basic_used) {
                rate = (float)llList2String(argv, 1);
                if(rate < 0)
                    last_charged_at = llGetTime();
            } else if(cmd == "arousal" && arousal_used) {
                arousal = (float)llList2String(argv, 1);
            } else if(cmd == "power" && basic_used) {
                float new_battery = (float)llList2String(argv, 1);
                if(new_battery > battery)
                    last_charged_at = llGetTime();
                battery = new_battery;
            } else if(cmd == "integrity" && integrity_used) {
                float new_integrity = (float)llList2String(argv, 1);
                if(new_integrity > integrity)
                    last_repaired_at = llGetTime();
                else if(new_integrity < integrity)
                    last_damaged_at = llGetTime();
                integrity = new_integrity;
            } else {
                return;
            }
        }
        colorize();
    }
    
    timer() {
        colorize();
    }
}
