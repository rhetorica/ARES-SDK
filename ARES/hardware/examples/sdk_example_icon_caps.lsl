/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *
 *            Copyright (c) 2014–2026 Nanite Systems Corporation
 *
 * =========================================================================
 *
 *  Icon and CAPS Example Device
 *
 *  Drop this script into any object to make it a Light Bus device with
 *  icon support and CAPS (Channel 411) capability advertisement. The
 *  device registers itself on the Light Bus, responds to icon-q
 *  requests, and advertises its capabilities via the hwc message in
 *  response to CAPS info queries.
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 3 (ASCL-iii). It may be redistributed or used as the
 *  basis of commercial, closed-source products so long as steps are taken
 *  to ensure proper attribution as defined in the text of the license.
 *
 * =========================================================================
 *
 */

#include <utils.lsl>
#include <objects.lsl>

#define VENDOR "Nanite Systems"
#define MODEL "SDK Example Device"
#define VERSION "1.0"
#define ICON "a48c33e5-55be-4577-40a7-548ba964edbb"
#define TYPE "example"

#define C_CAPS 411

integer L_LIGHTS;
integer C_LIGHTS;

key avatar;
integer power_on = 1;

default {
    state_entry() {
        avatar = llGetOwner();

        C_LIGHTS = 105 - (integer)("0x" + substr(avatar, 29, 35));
        L_LIGHTS = llListen(C_LIGHTS, "", "", "");

        llListen(C_CAPS, "", "", "");

        tell(avatar, C_LIGHTS, "add " + TYPE);
    }

    on_rez(integer n) {
        avatar = llGetOwner();

        C_LIGHTS = 105 - (integer)("0x" + substr(avatar, 29, 35));
        llListenRemove(L_LIGHTS);
        L_LIGHTS = llListen(C_LIGHTS, "", "", "");

        tell(avatar, C_LIGHTS, "add " + TYPE);
    }

    listen(integer cc, string src, key id, string message) {
        if(cc == C_CAPS) {
            if(substr(message, 0, 4) == "info ") {
                integer rc = (integer)delstring(message, 0, 4);
                tell(id, rc, "hwc " + jsobject([
                    "vendor", VENDOR,
                    "model", MODEL,
                    "version", VERSION,
                    "icon", ICON,
                    "purpose", TYPE,
                    "channel", jsobject(["lights", C_LIGHTS, "caps", C_CAPS]),
                    "private", 1,
                    "busy", 0,
                    "usable", power_on
                ]));
            }
        } else if(cc == C_LIGHTS) {
            if(message == "probe") {
                tell(id, C_LIGHTS, "add " + TYPE);
            } else if(message == "add-confirm") {
                tell(id, C_LIGHTS, "icon " + ICON);
                tell(id, C_LIGHTS, "power-q");
            } else if(message == "icon-q") {
                tell(id, C_LIGHTS, "icon " + ICON);
            } else if(message == "on") {
                power_on = 1;
            } else if(message == "off") {
                power_on = 0;
            }
        }
    }
}
