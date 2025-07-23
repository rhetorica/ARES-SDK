/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2014–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  SitAnywhere Flicker (Single-Color Version)
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

integer sitter_listen;

key sitter;

integer power = 1; // 0 = off, 1 = on
vector color = <0.8, 0.9, 1.0>; // default color

set_lights(float level) {
    // to recolor everything, remove "//" from the following line:
    
    // llSetLinkColor(LINK_SET, color * level, ALL_SIDES);
    
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
    changed(integer change) {
        if(change & CHANGED_LINK) {
            key new_sitter = llAvatarOnSitTarget();
            if(new_sitter) {
                if(sitter_listen)
                    llListenRemove(sitter_listen);
                
                integer channel_lights = -1 - (integer)("0x" + llGetSubString( (string) new_sitter, -7, -1) ) + 106;
                
                sitter_listen = llListen(channel_lights, "", "", "");
                
                llRegionSayTo(new_sitter, channel_lights, "power-q");
                llRegionSayTo(new_sitter, channel_lights, "color-q");
            } else {
                if(sitter_listen)
                    llListenRemove(sitter_listen);
                
                sitter_listen = 0;
            }
            sitter = new_sitter;
        }
    }
    
    listen(integer c, string n, key id, string message) {
        if(message == "off") {
            power = 0;
            set_lights(0.1);
        } else if(message == "on") {
            power = 1;
            set_lights(1.0);
        } else if(llGetSubString(message, 0, 5) == "color ") {
            list rgb = llParseString2List(llGetSubString(message, 6, -1), [" "], []);
            color = <llList2Float(rgb, 0), llList2Float(rgb, 1), llList2Float(rgb, 2)>;
            
            set_lights(1.0);
        }
    }
}
