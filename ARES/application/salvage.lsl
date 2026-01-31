
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2025–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Salvage Utility
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
 
 
#include <ARES/a>
#define CLIENT_VERSION "1.0"
#define CLIENT_VERSION_TAGS "release"

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(argc == 1 || action == "help") {
			msg = PROGRAM_NAME + " version " + CLIENT_VERSION + " (" + CLIENT_VERSION_TAGS + ")"
				+ "\nUsage: " + PROGRAM_NAME + " <action> [<arguments>]"
				+ "\nSupported actions:"
				+ "\n    help: this message"
				+ "\n    dbread <entry>: read from LSD storage"
				+ "\n    dbwrite <entry> <value>: write to LSD storage (self only)"
				+ "\n    dbdelete <entry>: delete from LSD storage (self only)"
				+ "\n    dbdrop <section>: delete a whole section from LSD storage (self only)"
				+ "\n    dblist: list all LSD entries"
				+ "\n    invdrop on|off: enable/disable inventory drop (self only)"
			;
		} else if(action == "dbread") {
			string path = gets(argv, 2);
			list ks = splitnulls(path, ".");
			msg = getdbl(gets(ks, 0), delitem(ks, 0));
			if(msg == "")
				msg = "(empty)";
			else if(msg == JSON_INVALID)
				msg = "(undefined)";
			
		} else if(action == "dbwrite") {
			if(user != avatar) {
				msg = "Only " + (string)avatar + " may issue the " + action + " command.";
			} else {
				string path = gets(argv, 2);
				list ks = splitnulls(path, ".");
				string h = gets(ks, 0);
				ks = delitem(ks, 0);
				
				string old = getdbl(h, ks);
				string new = concat(delrange(argv, 0, 2), " ");
				
				string ksname = concat(ks, ".");
				if(ksname == "")
					ksname = "<root>";
				
				tell(user, 0, "Writing database entry at (" + h + ", " + ksname + "):");
				
				string test = llLinksetDataRead(h);
				if(test != JSON_INVALID && setjs(test, ks, new) == JSON_INVALID) {
					tell(user, 0, " !!! Cannot write database entry: result would be invalid JSON. Check for unbalanced {} and [] characters.");
				} else {				
					setdbl(h, ks, new);
					
					if(old == "")
						old = "(empty)";
					else if(old == JSON_INVALID)
						old = "(undefined)";
					
					tell(user, 0, " --- old value: " + old);
					
					if(new == "")
						new = "(empty)";
					else if(new == JSON_INVALID)
						new = "(undefined)";
					
					tell(user, 0, " --- new value: " + new);
				}
			}
		
		} else if(action == "dbdelete") {
			if(user != avatar) {
				msg = "Only " + (string)avatar + " may issue the " + action + " command.";
			} else {
				string path = gets(argv, 2);
				list ks = splitnulls(path, ".");
				string h = gets(ks, 0);
				ks = delitem(ks, 0);
				
				string old = getdbl(h, ks);
				string ksname = concat(ks, ".");
				if(ksname == "")
					ksname = "<root>";
					
				if(old == JSON_INVALID) {
					msg = "Cannot delete (" + h + ", " + ksname + "): it does not exist.";
				} else {
					tell(user, 0, "Deleting database entry at (" + h + ", " + ksname + "):");
					
					string test = llLinksetDataRead(h);
					if(test != JSON_INVALID && setjs(test, ks, JSON_DELETE) == JSON_INVALID) {
						tell(user, 0, " !!! Cannot write database entry: result would be invalid JSON. Check for unbalanced {} and [] characters.");
					} else {
						setdbl(h, ks, JSON_DELETE);
						
						if(old == "")
							old = "(empty)";
						
						tell(user, 0, " --- old value: " + old);
						tell(user, 0, " --- deleted successfully.");
					}
				}
			}
		
		} else if(action == "dbdrop") {
			if(user != avatar) {
				msg = "Only " + (string)avatar + " may issue the " + action + " command.";
			} else {
				string k = gets(argv, 2);
				list candidates = llLinksetDataFindKeys(k, 0, 0);
				if(contains(candidates, k) || gets(argv, 3) == "force") {
					tell(user, 0, "Deleting key " + k);
					tell(user, 0, "Contents were: " + llLinksetDataRead(k));
					llLinksetDataDelete(k);
				} else {
					msg = "No key found: " + k + "\nIs it an accidental regex? If so, try: @" + PROGRAM_NAME + " dbdrop " + k + " force";
				}
			}
		
		} else if(action == "dblist") {
			integer lsmax = llLinksetDataCountKeys();
			integer li = 0;
			while(li < lsmax) {
				string k = gets(llLinksetDataListKeys(li, 1), 0);
				tell(user, 0, " - " + k + " (" + (string)strlen(llLinksetDataRead(k)) + " bytes)");
				++li;
				llSleep(0.044);
			}
			tell(user, 0, (string)lsmax + " key(s), " + (string)llLinksetDataAvailable() + " byte(s) free");
			
		} else if(action == "invdrop") {
			if(user != avatar) {
				msg = "Only " + (string)avatar + " may issue the " + action + " command.";
			} else {
				integer new = index((["off", "on"]), gets(argv, 2));
				if(new == 1) {
					inventory_drop(TRUE);
					msg = "Inventory drop enabled.";
				} else if(new == 0) {
					inventory_drop(FALSE);
					msg = "Inventory drop disabled.";
				} else {
					msg = "Invalid option. Syntax must be: @" + PROGRAM_NAME + " invdrop on|off";
				}
			}
		} else {
			msg = "Unknown action: " + action + ". For usage, see: @" + PROGRAM_NAME + " help";
		}
		
		if(msg != "")
			tell(user, 0, msg);
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
