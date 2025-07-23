/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2017–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Safety Bolts Minimal Example
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

/*
    Install, edit, and enjoy! You should need no more than one copy per attachment.
    
    Make sure you turn on the Firestorm LSL Preprocessor for best results.
*/

integer channel_lights;
integer ListenID;

default
{
    
    state_entry()
    {
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
        llRegionSay(channel_lights, "power-q");
    }
    
    on_rez(integer w) {    
        llListenRemove(ListenID);
        channel_lights = -1 - (integer)("0x" + llGetSubString( (string) llGetOwner(), -7, -1) ) + 106;
        ListenID = llListen(channel_lights, "", "", "");
        llRegionSay(channel_lights, "power-q");
    }
    
    listen(integer channel, string name, key id, string message)
    { 
        if(message == "bolts off") {
            llOwnerSay("@detach=y");
        } else if(message == "bolts on") {
            llOwnerSay("@detach=n");
        }
    }
}
