/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Touch-To-Recharge Example (regenerating storage)
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

#define DISCHARGE_RATE 400
#define RECHARGE_RATE 400
#define MAX_CHARGE 9000
#define S_START "a6a6ac7d-c655-66d6-ac5c-93766e013068"
#define S_LOOP "f6210ab3-3c96-f2c8-7ce8-0e203eb3c27b"
#define S_EMPTY "b29b9860-1680-ddc4-31e7-68241e2deff3"
#define S_RECHARGED "a5dded13-1596-ff3b-cdb1-a0bb95b557e1"

integer charge = 9000;
key user;
integer dispensing;
integer recharging;

default {
    state_entry() {
        llStopSound();
        llSetSoundQueueing(FALSE);
        llPlaySound(S_RECHARGED, 1);
        if(llSetMemoryLimit(0x2000)) echo("OK.");
    }

    touch_start(integer n) {
        if(recharging) {
            llTriggerSound(S_EMPTY, 1);
            llSleep(1);
        } else if(!dispensing) {
            user = llDetectedKey(0);
            dispensing = 1;
            llPlaySound(S_START, 1);
            llSleep(1);
            llLoopSound(S_LOOP, 1);
            llSetTimerEvent(0.5);
        }
    }
    
    touch_end(integer n) {
        if(dispensing && user == llDetectedKey(0)) {
            llStopSound();
            dispensing = 0;
            recharging = 1;
        }
    }
    
    timer() {
        if(dispensing) {
            if(charge > 0) {
                charge -= DISCHARGE_RATE;
                tell(user, -9999999, "charge " + (string)DISCHARGE_RATE);
            }
            
            if(charge <= 0) {
                llStopSound();
                llPlaySound(S_EMPTY, 1);
                charge = 0;
                dispensing = 0;
                recharging = 1;
            }
        } else if(recharging) {
            charge += RECHARGE_RATE;
            if(charge >= MAX_CHARGE) {
                charge = MAX_CHARGE;
                llPlaySound(S_RECHARGED, 1);
                recharging = 0;
                llSetTimerEvent(0);
            }
        }
    }
}
