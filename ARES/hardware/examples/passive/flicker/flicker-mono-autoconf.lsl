/*
    Nanite Systems Autoconf Lighting Engine (alpha support enabled)
    
    ALPHA ENABLED: This version is slightly slower but will preserve the opacity of your prims, even if they change. Please use it only when necessary. Special thanks to Linnefer Resident for the idea and initial implementation.
    
    This script reads linkset descriptions to determine how to light up the prim.
    
    To specify prim colorings, start the prim description with # (full brightness) or $ (low brightness, e.g. for gauge backgrounds) followed by a comma-separated list of faces to illuminate, or "-1" for all sides. A single prim cannot have both # and $.
    
    Optionally, you can put "L" at the start of the prim's description to specify that this prim should emit a point light, controllable with the 'lamp' command. Maximum of 1 per linkset. For example, "L#2,3" will fully illuminate faces 2 and 3 and add a light source.

    The "L" light will be affected by the controller's "!lamp on" and "!lamp off" commands (new in Companion 8.4)

    You should be able to use this script without editing it. Just reset it if you make changes to your linkset.
    
    If you're making a main controller, look at line 184 for an extra tweak needed for proper support of color-changing HUDs.
 */

float gap = 0;

integer frame = 0;

integer broken = 0;

integer channel_lights;

integer ListenID;

vector color = <1.0, 0.0, 0.5>;

list on_state;
list off_state;

float radius = 0.5;

integer LIGHT;

integer power_on;

integer lamp_on;

list high_intensity_faces;
list high_intensity_parts;
list low_intensity_faces;
list low_intensity_parts;

set_lights(float level) {
    list command;
    integer x = llGetListLength(high_intensity_faces);
    
    vector c = color * level;
    while(x--) {
        integer p = llList2Integer(high_intensity_parts, x);
        integer f = llList2Integer(high_intensity_faces, x);
        command += [PRIM_LINK_TARGET, p, PRIM_COLOR, f, c, llList2Float(llGetLinkPrimitiveParams(p, [PRIM_COLOR, f]), 1)];
    }

    x = llGetListLength(low_intensity_faces);

    c *= 0.1; // low intensity (1/10th of normal brightness)
    while(x--) {
        integer p = llList2Integer(low_intensity_parts, x);
        integer f = llList2Integer(low_intensity_faces, x);
        command += [PRIM_LINK_TARGET, p, PRIM_COLOR, f, c, llList2Float(llGetLinkPrimitiveParams(p, [PRIM_COLOR, f]), 1)];
    }
    
    llSetLinkPrimitiveParamsFast(1, command);
    
    if(power_on) {        
        if(broken == 0) {
            if(lamp_on)
                llSetLinkPrimitiveParamsFast(LIGHT, on_state);
            else
                llSetLinkPrimitiveParamsFast(LIGHT, off_state);
        }
    } else {
        llSetLinkPrimitiveParamsFast(LIGHT, off_state);
    }
}

#define STEP 0.25

default
{
    
    state_entry()
    {
        integer i = llGetNumberOfPrims();
        while(i != 0) {
            string d = llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]), 0);
            integer dstart = 0;
            if(llGetSubString(d, dstart, dstart) == "L") {
                LIGHT = i;
                dstart = 1;
            }
            
            integer cg = 0;
            
            string c = llGetSubString(d, dstart, dstart);
            
            if(c == "#")
                cg = 1;
            else if(c == "$")
                cg = 2;
            
            if(cg) {
                list faces = llParseString2List(llGetSubString(d, dstart + 1, -1), [","], []);
                integer L = llGetListLength(faces);
                list parts;
                while(L--)
                    parts += i;
                
                if(cg == 1) {
                    high_intensity_faces += faces;
                    high_intensity_parts += parts;
                } else {
                    low_intensity_faces += faces;
                    low_intensity_parts += parts;
                }
            }
            --i;
        }

        on_state = [PRIM_POINT_LIGHT, 1, color, 1.0, radius, 0.75];
        off_state = [PRIM_POINT_LIGHT, 0, color, 1.0, radius, 0.75];

        set_lights(0);

        llSetTimerEvent(gap);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
        
        llRegionSayTo(llGetOwner(), channel_lights, "power-q");
        llRegionSayTo(llGetOwner(), channel_lights, "color-q");
        
        llOwnerSay("Lighting system initialized.");
    }
    
    on_rez(integer w) {
        on_state = [PRIM_POINT_LIGHT, 1, color, 1.0, radius, 0.75];
        off_state = [PRIM_POINT_LIGHT, 0, color, 1.0, radius, 0.75];
        
        llListenRemove(ListenID);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
        
        if(llGetAttached()) {
            llRegionSayTo(llGetOwner(), channel_lights, "power-q");
            llRegionSayTo(llGetOwner(), channel_lights, "color-q");
        }
    }
    
    listen(integer channel, string name, key id, string message)
    { 
        if (message == "off") {
            gap = 0;
            power_on = 0;
            set_lights(0.1);
            llSetLinkPrimitiveParamsFast(LIGHT, off_state);
        } else if(message == "broken") {
            gap = 0.05;
            broken = 1;
        } else if(message == "fixed") {
            gap = 0;
            broken = 0;
            power_on = 1;
            set_lights(1.0);
        } else if(message == "on") {
            power_on = 1;
            set_lights(1.0);
        } else if(message == "lamp on") {
            lamp_on = 1;
            set_lights(1.0);
        } else if(message == "lamp off") {
            lamp_on = 0;
            set_lights(1.0);
            
        } else if(llGetSubString(message, 0, 5) == "color ") {
            list rgb = llParseString2List(llGetSubString(message, 6, -1), [" "], []);

            vector real_color = <llList2Float(rgb, 0), llList2Float(rgb, 1), llList2Float(rgb, 2)>;
            
            color = real_color;

            on_state = [PRIM_POINT_LIGHT, 1, color, 1.0, radius, 0.75];
            off_state = [PRIM_POINT_LIGHT, 0, color, 1.0, radius, 0.75];
            
            set_lights(1.0);
            
            // Uncomment this line if you're developing a custom controller housing:
            
            // llMessageLinked(LINK_ROOT, 28, llGetSubString(message, 6, -1), ""); // send screen handler to system memory
        } else {
            return;
        }
        
        llSetTimerEvent(gap);
    }
        
    timer()
    {
        float t = 1;
        if(llFrand(1.0) < 0.1)
            t = llFrand(2.0);

        set_lights(t);
        
        if(lamp_on)
            llSetLinkPrimitiveParamsFast(LIGHT, [PRIM_POINT_LIGHT, 1, color, t, radius, 0.75]);
    }
}
