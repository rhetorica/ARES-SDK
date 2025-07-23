/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Touch-to-Repair Example
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

// This example program demonstrates how to use the light bus to get integrity info while a robot is being repaired.
// This is not the only way to get this information, but because the light bus transmits the data spontaneously
// following a power level change, it is convenient.

integer public_bus = -9999999; // public channel for sending normal system commands (and a few extras) to robots
integer channel_lights; // private channel that NS robots use for talking to attachments
integer listen_lights;
key unit;
key controller;

float integrity; // unit's health, from 0.0 (dead) to 1.0 (full)

float timer_interval = 1.0; // how often to repair (in seconds)
float repair_amount = 0.04; // how much to repair when the timer triggers (around 1% per second is strongly recommended)

integer repairing = FALSE; // are we working?

default {
    state_entry() {
        llSetText("Touch this object to start or stop repairing.\nRepairs will stop at full integrity.", <1, 1, 1>, 1);
    }

    touch_start(integer total_number) {
        unit = llDetectedKey(0);
        
        // remove any old stuff left over from a past user:
        if(repairing) {
            repairing = FALSE;
            llSetTimerEvent(0);
            llListenRemove(listen_lights);
            llWhisper(0, "Repair stopped!");
            
            llRegionSayTo(controller, public_bus, "repair stop"); // re-enable auto-repair
            
        } else {        
            channel_lights = 105 - (integer)("0x" + llGetSubString(unit, 29, 35)); // determine the unit's private light bus channel
            listen_lights = llListen(channel_lights, "", "", ""); // listen for all activity on the private light bus channel
            
            // to determine the UUID of the controller, we can send the "ping" message to the avatar
            // messages sent to an avatar also go to all of the avatar's attachments
            // (although note an object can never receive messages from itself this way)
            llRegionSayTo(unit, channel_lights, "ping");
            // expected reply: "pong"
            // there are two "ping" commands; we only want the light bus version
            
            // the public bus version of "ping" sends a lot more data but doesn't contain any unique signifier,
            // so we would need another listener (which would add to code complexity, server load, etc.)
            // see "Parsing a Nanite Systems Ping Command" in the SDK for more info on the public bus ping
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if(message == "pong") {
            // reply to "ping" command, to identify the controller
            controller = id;
            llRegionSayTo(controller, public_bus, "identify " + (string)channel_lights);
            // ask ATOS to identify itself on a channel of our choosing
            // format details: http://develop.nanite-systems.com/?id=276#identify
            
            // we could skip ping/pong and just send "identify" to the whole avatar,
            // but this is a tutorial, not real life
            
            // "identify" doesn't have to be told to use channel_lights, 
            // but because we're already listening on it and "identification" messages
            // are easy to detect (see below), this saves resources
            
        } else if(llGetSubString(message, 0, 14) == "identification ") {
            // response to our "identify" query from above
            // format details: http://develop.nanite-systems.com/?combat#identification
            // since this message does include the unit's integrity,
            // we could tell a timer to send the "identify" message periodically,
            // but that can create a whole new set of synchronicity problems
            // in very laggy environments; instead, we'll let the controller
            // send light bus "integrity" messages (see below) whenever anything
            // interesting happens
            
            list argv = llParseString2List(message, [" "], []);
            // argv now contains:
            // "identification", "<integrity>", "<temperature>", "<repairing>", "<serial>", "<os_name>", "<os_version>", "<group_key>"
            // for example:
            // "identification", "1.000000", "31.446230", "0", "999545620", "ATOS/E", "12.0.25", "00000000-0000-0000-0000-000000000000"

            // llOwnerSay(message);
            
            integrity = (float)llList2String(argv, 1); // always in range 0.0 to 1.0
            if(integrity < 1.0) {
                string percentage = (string)llRound(integrity * 100);
                llRegionSayTo(unit, 0, "You need repairs! I will repair you. You are at " + percentage + "% integrity.");
                llSetTimerEvent(timer_interval);
                llRegionSayTo(controller, public_bus, "repair start"); // disable auto-repair
                repairing = TRUE;
            } else {
                llRegionSayTo(unit, 0, "You do not require repairs.");
            }
            
        } else if(llGetSubString(message, 0, 9) == "integrity ") {
            // integrity message spontaneously sent by controller
            // defined here: http://develop.nanite-systems.com/?id=276#integrity
            // integrity <integrity> <chassis-strength> <max-integrity>
            
            // split it just like with the identification message:
            list argv = llParseString2List(message, [" "], []);
            
            integrity = (float)llList2String(argv, 1);
            
            // are we repaired yet?
            // (be careful with using "==" and floating point numbers, they're often slightly wrong, but 1.0 is safe here):
            if(integrity == 1.0) { 
                repairing = FALSE;
                llSetTimerEvent(0);
                llListenRemove(listen_lights);
                listen_lights = 0;
                    // ^ this line is technically unnecessary because "repairing" acts as a guard flag
                    //   however it's still a good idea to clean up after yourself
                    //   (other parts of the code may not be so clean)
                llWhisper(0, "Repairs complete!");
                
                llRegionSayTo(controller, public_bus, "repair stop"); // re-enable auto-repair
                
                llRegionSayTo(unit, 0, "Goodbye!"); // say bye to the avatar on channel 0 so they know we care
                
                // note that we never set channel_lights to 0, because there's no benefit to doing so
                // single integers stored as global variables always take up the same amount of memory anyway
            }
        }
    }
    
    timer() {
        // always, always remember to check for people disconnecting or leaving the sim:
        if(llGetAgentSize(unit) == ZERO_VECTOR) {
            repairing = FALSE;
            llSetTimerEvent(0);
            llListenRemove(listen_lights);
            llWhisper(0, "Robots who leave while being repaired are the WORST.");
            // unfortunately since the person has left, we can't send "repair stop" to them
            // as of ATOS/E 12.0.25, there's no way to fix this except by triggering "repair stop" again later from another source
        } else {
            llRegionSayTo(controller, public_bus, "repair " + (string)repair_amount); // repair the robot by a small amount
        }
    }
}
