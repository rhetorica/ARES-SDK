/*
    Generic Nanite Systems flicker template

    Install, edit, and enjoy! You should need no more than one copy per attachment.
*/

float gap = 0;

integer frame = 0;

integer broken = 0;

integer channel_lights;

integer ListenID;

vector color = <0.8, 0.9, 1.0>; // default color. This will can be overridden by typing !recolor on the main controller.

set_lights(float level) {
    // to recolor everything, remove "//" from the following line:
    
    llSetLinkColor(LINK_SET, color * level, ALL_SIDES);
    
    // to recolor face 2 on object 1, remove "//" from the following line:
    
    // llSetLinkColor(1, color * level, 2);
    
    // generically, llSetLinkColor(<LINKED PRIM NUMBER GOES HERE>, color * level, <FACE NUMBER GOES HERE>);
    
    // You can copy and paste these lines as many times as you want.
    
    // If you want to set every face on a prim, use ALL_SIDES in the last parameter
    
    // If you want to modify every prim in the object, use LINK_SET as the first parameter
    
    // If you want to have an element that always glows even when power is turned off, change 'level' to 1.0
    // (or a smaller number for less bright parts)
}

default
{
    
    state_entry()
    {
        llSetTimerEvent(gap);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
    }
    
    on_rez(integer w) {    
        llListenRemove(ListenID);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
    }
    
    listen(integer channel, string name, key id, string message)
    { 
        if (message == "off") {
            gap = 0;
            set_lights(0.1);
        } else if(message == "broken") {
            gap = 0.05;
            broken = 1;
        } else if(message == "fixed") {
            gap = 0;
            broken = 0;
            set_lights(1.0);
        } else if(llGetSubString(message, 0, 5) == "light ") {        
            set_lights(1.0);
        } else if(llGetSubString(message, 0, 5) == "color ") {
            list rgb = llParseString2List(llGetSubString(message, 6, -1), [" "], []);
            color = <llList2Float(rgb, 0), llList2Float(rgb, 1), llList2Float(rgb, 2)>;
            
            set_lights(1.0);
        }
        
        llSetTimerEvent(gap);
    }
        
    timer()
    {
        float t = 1;
        if(llFrand(1.0) < 0.1)
            t = llFrand(2.0);

        set_lights(t);
    }
}
