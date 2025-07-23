/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2015–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Parsing a Public Bus Ping Response
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

integer listen_ping;
integer channel_ping;

key controller;
string unit_name;
integer serial;
string version;
key owner;
string model;

default
{
    touch_start(integer num) {
        listen_ping = llListen(channel_ping, "", "", "");
        llRegionSayTo(llDetectedKey(0), -9999999, "ping " + (string)channel_ping);
        llSetTimerEvent(10);
    }
    
    listen(integer channel, string n, key id, string m) {
        if(channel == channel_ping) {
//        if(llGetOwnerKey(id) == llGetOwner()) { // only for worn peripherals
            list parts = llParseString2List(m, [" "], []);
                controller = id;

                unit_name = n;
                llSetObjectName(n + " (local console)");
                serial = (integer)llList2String(parts, 0);
                version = llList2String(parts, 1);
                owner = (key)llList2String(parts, 2);
                model = llList2String(parts, 3);
                llOwnerSay("Connected to " + unit_name + ": " + model + " " + version + " owned by secondlife:///app/agent/" + (string)owner + "/about");
                llListenRemove(listen_ping);
//            }
        }
    }
    
    timer() {
        llOwnerSay("No controller; cancelling...");
        llListenRemove(listen_ping);
        llSetTimerEvent(0);
    }
}
