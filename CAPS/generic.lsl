
// Generic CAPS listening device

// rhet0rica, 2026-07-03
// provided under ASCL-iii license (BSD-like)

#define C_CAPS 411

#ifndef DEVICE_VENDOR
// who created the device?
#define DEVICE_VENDOR "Nanite Systems Consumer Products"
#endif

#ifndef DEVICE_URL
// link to documentation
#define DEVICE_URL "http://support.nanite-systems.com/"
#endif

#ifndef DEVICE_VERSION
// current version number
#define DEVICE_VERSION "1.0"
#endif

#ifndef DEVICE_PURPOSE
// comma-separated list of functions; see caps protocol.txt Appendix A for a list
#define DEVICE_PURPOSE "info"
#endif

#ifndef DEVICE_CHANNELS
// pairwise array of service names and channels, see caps protocol.txt Appendix B for channels that must be included
#define DEVICE_CHANNELS ["caps", C_CAPS]
#endif

#ifndef DEVICE_PRIVATE
// does the device place any restrictions on who can access its primary functions?
#define DEVICE_PRIVATE TRUE
#endif

#ifndef DEVICE_BUSY
// is the device currently engaged in a task?
#define DEVICE_BUSY FALSE
#endif

#ifndef DEVICE_USABLE
// does the device have all its requirements met for performing its primary function right now? (if powered off, no)
#define DEVICE_USABLE TRUE
#endif

#ifndef DEVICE_HEALTH
// on a scale of 1.0 to 0.0, how much of the device's hardware is in working, undamaged condition?
#define DEVICE_HEALTH 1.0
#endif

default() {
	state_entry() {
        llListen(C_CAPS, "", "", "");
	}

    listen(integer channel, string name, key id, string message) {
        if(channel == C_CAPS) {
            if(substr(message, 0, 4) == "info ") {
                integer rc = (integer)delstring(message, 0, 4);
                tell(id, rc, "hwc " + jsobject([
                    "vendor", DEVICE_VENDOR,
                    "version", DEVICE_VERSION,
                    "purpose", DEVICE_PURPOSE,
                    "channel", jsobject(DEVICE_CHANNELS),
                    "private", DEVICE_PRIVATE,
                    "busy", DEVICE_BUSY,
                    "usable", DEVICE_USABLE,
                    "health", DEVICE_HEALTH,
                    "info", DEVICE_URL
                ]));
            }
		}
	}
}
