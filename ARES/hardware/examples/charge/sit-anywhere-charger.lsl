/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2014–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  SitAnywhere Charger
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

float RATE = 20.0; // units to charge per hit
float FREQ = 1.0; // how often to charge!

key sitter;

default
{
    changed(integer change) {
        if(change & CHANGED_LINK) {
            key new_sitter = llAvatarOnSitTarget();
            if(new_sitter) {
                llSetTimerEvent(FREQ);
                llRegionSayTo(new_sitter, 0, "Unit connected. Beginning charge.");
                llPlaySound("abf708b6-342b-3232-d621-46aec87b88ce", 1.0);
            } else {
                llRegionSayTo(new_sitter, 0, "Unit disconnected. Charging terminated.");
                llPlaySound("068f47e4-65e6-e755-cc43-63472ab48409", 1.0);
                llSetTimerEvent(0);
            }
            sitter = new_sitter;
        }
    }
    
    timer() {
        if(llAvatarOnSitTarget()) {
            llRegionSayTo(sitter, -9999999, "charge " + (string)RATE);
        } else {
            llRegionSayTo(sitter, 0, "Unit disconnected. Charging terminated.");
            llPlaySound("459e376f-2870-d0ef-305c-17f324bb44ad", 1.0);
            llSetTimerEvent(0);
            sitter = NULL_KEY;
        }
    }
}
