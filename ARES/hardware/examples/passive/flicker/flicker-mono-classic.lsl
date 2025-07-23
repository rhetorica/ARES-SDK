// NO NEED TO TOUCH THIS SECTION, IT SETS UP ALL THE BASIC REQUIREMENTS FOR THE SCRIPT TO FUNCTION
float gap = 0;  

integer broken = 0;  

integer channel_lights;

integer ListenID; 

// END OF THE DEFINE STAGE, AGAIN TOUCH NOTHING ABOVE THIS LINE.

vector color = <0.8, 0.9, 1.0>; 

set_lights(float level) {
// THIS IS THE SECTION YOU CAN MODIFY.
// PRESENTLY THIS IS SET UP WITH A CONDITIONAL FOR TESTING OFF AND ON STATES BASED ON THE VARIABLE 'level'
// IN THIS CONDITIONAL 0.1 IS USED AS THE MARKER FOR 'OFF'  FOLLOW THE COMMENTS BELOW FOR INFO ON THE SPECIFICS
// THIS CONDITIONAL IS NOT REQUIRED, YOU CAN EITHER COMMENT IT OUT WITH // MARKS ONE PER LINE, OR DELETE IT AND USE THE SECTION BELOW IT

    if(level != 0.1) // Test for whether the level is the 'off' state 0.1. As long as it isn't, move to the first step
    {
        // If not 'offline' then this line will change the colour. In this example it also sets the glow to 0.1, full brights it. The -1 can be replaced
        // with ALL_SIDES or the face number of the face in the linkset.  
        
        // llSetLinkPrimitiveParamsFast is used to affect all prims in the set, by default, that means the whole object, you may wish to set this to a link number
        // instead.  The commands you send to that prim or set of prims is contained with square brackets. In this case PRIM_COLOR, which is then followed by the
        // face on the prim, -1 or ALL_SIDES in this example, then color * level, followed by the level of transparency desired, 0.80 in this example.
        // after thats set, it sets the PRIM_GLOW, and is optional in your case. Again same format, it is followed by the face, then the value to set.
        // PRIM_FULLBRIGHT is another optional, followed by the face, and whether on 'TRUE' or off 'FALSE'  This is then closed off with a square bracket, round
        // bracket, and a semi colon
        
        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR,-1,color * level,0.80,PRIM_GLOW,-1,0.1,PRIM_FULLBRIGHT,-1,TRUE]);
        
    } else 
    {
        //See above example for an explanation of how this works, same deal, but for the state where your controller is 'off'
        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR,-1,<0,0,0>,0.0,PRIM_GLOW,-1,0.0,PRIM_FULLBRIGHT,-1,FALSE]);
        
    }
    // Remove the // from the next line if you just want a simple flicker, like the orignal template. 
    // llSetLinkColor(LINK_SET, color * level, ALL_SIDES);
    // generically, llSetLinkColor(<LINKED PRIM NUMBER GOES HERE>, color * level, <FACE NUMBER GOES HERE>);
    
    // You can copy and paste these lines as many times as you want.
    
    // If you want to set every face on a prim, use ALL_SIDES in the last parameter
    
    // If you want to modify every prim in the object, use LINK_SET as the first parameter
    
    // If you want to have an element that always glows even when power is turned off, change 'level' to 1.0
    // (or a smaller number for less bright parts)    

    // It is worth learning to use llSetLinkPrimitiveParams and llSetLinkPrimitiveParamsFast, with PRIM_LINK_TARGET as this will make for far faster 
    // transitions, and will be noticable more during code runs like 'rainbow' when texturing multiple faces/prims, as LSL adds sleeps to some functions
    // of about 0.1 second, which adds up the more you have.
    
// NO NEED TO TOUCH ANYTHING BELOW THIS LINE, UNLESS YOU KNOW WHAT IT IS YOU ARE ALTERING.
}

default
{
    
    state_entry()
    {
//DAOR SPECIFIC MOD:
//        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, ALL_SIDES, 0,0, 0.0,1.0,0.5);
//END OF DAOR MOD.
        llSetTimerEvent(gap);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        llWhisper(channel_lights, "power-q");
        ListenID = llListen(channel_lights, "", "", "");
    }
    
    on_rez(integer w) {    
        llListenRemove(ListenID);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        llWhisper(channel_lights, "power-q");
        ListenID = llListen(channel_lights, "", "", "");
    }
    
    listen(integer channel, string name, key id, string message)
    { 
        if (message == "off") {
            gap = 0;
            set_lights(0.1);
        } else if (message == "on") {
            if(broken)
                gap = 0.05;
            else
                gap = 0;
            set_lights(1);
        } else if(message == "broken") {
            gap = 0.05;
            broken = 1;
        } else if(message == "fixed") {
            gap = 0;
            broken = 0;
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

