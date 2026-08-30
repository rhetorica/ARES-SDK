/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  PATH Filesystem Driver
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 2 (ASCL-ii). Although it appears in ARES as part of
 *  commercial software, it may be used as the basis of derivative,
 *  non-profit works that retain a compatible license. Derivative works of
 *  ASCL-ii software must retain proper attribution in documentation and
 *  source files as described in the terms of the ASCL. Furthermore, they
 *  must be distributed free of charge and provided with complete, legible
 *  source code included in the package.
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

#include <glob.lsl>
#include <ARES/api/auth.h.lsl>

#define CLIENT_VERSION ARES_VERSION
#define CLIENT_VERSION_TAGS ARES_VERSION_TAGS

#define LIST_MICRO_SLEEP

#define C_PHASE_PROTOCOL 1608011905
integer L_PHASE_PROTOCOL;

#define IMPLEMENTATION "ARES-" + PROGRAM_NAME + "-" + CLIENT_VERSION

// hard limit is 4096:
#define MAX_PAGE_SIZE 2048

#define PERMISSION_NONE 0
#define PERMISSION_READ 1
#define PERMISSION_DELETE 2
#define PERMISSION_WRITE 4

// Wait for 2 server ticks after each page read?
// #define MICRO_SLEEP

// notecards are immutable, so PERMISSION_FULL gets downgraded to PERMISSION_READ_DELETE:
#define NO_WRITE

// storage unit must be "b" (bytes) because of HTTP
#define STORAGE_UNIT "b"

// where to keep basic file data (lengths):
#define DIRECTORY_FILE "path:local"

// where to keep extended file metadata (UUIDs):
#define DIRECTORY_META "path:meta"

// where to keep dir_cache:
#define DIRECTORY_CACHE "path:cache"

// unused tokens:
list tokens = [];

// replaced with llGetObjectDesc():
string DISK_LABEL = "ARES.local";

// respond to null connects to search for this storage device?
integer DISCOVERABLE = 1;

// respond to web connects?
integer WEB_DISCOVERABLE = 1;

string hosts = "{}"; // host-id:[token, permission, callback-url]
string token_to_host = "{}"; // token:host-id

integer scanning; // 0 = no, 1 = in progress, 2 = lockstep
string scan_changes;
integer scan_progress;
string scan_ks = "{}"; // <dataserver handle>:[<filename>, <current line>, <byte length so far>]

string read_ks = "{}"; // <dataserver handle>:[<0 filename>, <1 current line>, <2 byte length so far>, <3 web handle>, <4 target start byte>, <5 target end byte>, <6 url-encoded text>]

integer initializing;

string url;
key url_key;

list waiting_scan_replies; // [src, ins, src, ins, ...]

after_scan() {
	// now we check for dead entries in the directory that need to be purged
	list filenames = jskeys(llLinksetDataRead(DIRECTORY_FILE));
	integer fnmax = count(filenames);
	integer fni = 0;
	while(fni < fnmax) {
		string filename = gets(filenames, fni);
		if(llGetInventoryType(filename) != INVENTORY_NOTECARD) {
			if(scan_changes == "")
				scan_changes = "deleted " + filename;
			else
				scan_changes = "update";
			llSetMemoryLimit(0x0fffe);
			llSetMemoryLimit(0x10000);
			deletedbl(DIRECTORY_FILE, [filename]);
			llSetMemoryLimit(0x0fffe);
			llSetMemoryLimit(0x10000);
			deletedbl(DIRECTORY_META, [filename]);
		}
		++fni;
	}
	
	// force 'update' message even if nothing changed, this typically indicates an object was added/removed
	// required for proper ax function
	if(scan_changes == "")
		scan_changes = "update";
	
	// then we decide what update message to broadcast
	string message = NULL_KEY + " " + scan_changes;
	
	/* if(initializing)
		echo("[_path] building directory cache..."); */
	
	llSetMemoryLimit(0x0fffe);
	llSetMemoryLimit(0x10000);
	// echo("IN: " + (string)llGetFreeMemory() + " + " + (string)(llGetMemoryLimit() - llGetUsedMemory() - llGetFreeMemory()) + " " + (string)llGetUsedMemory());
	{
		// string dir_file = llLinksetDataRead(DIRECTORY_FILE);
		// echo("CACHE: " + (string)llGetFreeMemory() + " + " + (string)(llGetMemoryLimit() - llGetUsedMemory() - llGetFreeMemory()) + " " + (string)llGetUsedMemory());
		#define ONE_STEP_CACHE
		#ifndef ONE_STEP_CACHE
			llLinksetDataWrite(DIRECTORY_CACHE, "");
			integer nmax = llGetInventoryNumber(INVENTORY_NOTECARD);
			integer ni = 0;
			while(ni < nmax) {
				llSetMemoryLimit(0x0fffe);
				llSetMemoryLimit(0x10000);
				string filename = llGetInventoryName(INVENTORY_NOTECARD, ni);
				string length = getjs(llLinksetDataRead(DIRECTORY_FILE), [filename]);
				// dir_cache += [filename + " " + getjs(dir_file, [filename, 2])];
				llLinksetDataWrite(DIRECTORY_CACHE, llLinksetDataRead(DIRECTORY_CACHE) + "\n" + filename + " " + length);
				// dir_file = setjs(dir_file, [filename], JSON_DELETE);
				//echo("STEP: " + (string)llGetFreeMemory() + " + " + (string)(llGetMemoryLimit() - llGetUsedMemory() - llGetFreeMemory()) + " " + (string)llGetUsedMemory());
				++ni;
			}
			
			llSetMemoryLimit(0x0fffe);
			llSetMemoryLimit(0x10000);
			// trim:
			llLinksetDataWrite(DIRECTORY_CACHE, delstring(llLinksetDataRead(DIRECTORY_CACHE), 0, 0));
		#else
			// this may or may not work:
			llLinksetDataWrite(DIRECTORY_CACHE,
				getjs(
				"[" + substr(
					replace(
						replace(llLinksetDataRead(DIRECTORY_FILE), "\":", " "),
						",\"",
						"\n"
					), 1, -2
				) + "\"]"
				, [0])
			);
		#endif
		// llLinksetDataWrite(DIRECTORY_CACHE, concat(dir_cache, "\n"));
	}
	llSetMemoryLimit(0x0fffe);
	llSetMemoryLimit(0x10000);
	
	
	// echo("DONE: " + (string)llGetFreeMemory() + " + " + (string)(llGetMemoryLimit() - llGetUsedMemory() - llGetFreeMemory()) + " " + (string)llGetUsedMemory());
	
	scanning = FALSE;
	
	broadcast(message);
	
	integer wsri = count(waiting_scan_replies);
	while(wsri > 0) {
		wsri -= 2;
		resolve_i(geti(waiting_scan_replies, wsri), getk(waiting_scan_replies, wsri + 1));
	}
	waiting_scan_replies = [];
	
	if(initializing)
		llRegionSay(C_PHASE_PROTOCOL, NULL_KEY + " reset " + DISK_LABEL);
	
	initializing = 0;
	end_working("path scan");
	/*if(scan_changes == "")
		echo("[_path] scan complete; no changes");
	else if(scan_changes != "update") 
		echo("[_path] scan complete: " + scan_changes);
	else*/
		// echo("[_path] scan complete");
	scan_changes = "";
}

// message all connected hosts:
broadcast(string message) {
	list host_keys = jskeys(hosts);
	integer hi = count(host_keys);
	list args = split(message, " ");
	while(hi--) {
		key host = getk(host_keys, hi);
		string callback = getjs(hosts, [(string)host, 2]);
		if(callback != "" && callback != JSON_INVALID) {
			string body = jsobject([
				"session", getjs(hosts, [(string)host, 0]),
				"message", gets(args, 1),
				"args", jsarray(delrange(args, 0, 1))
			]);
			llHTTPRequest(callback, [HTTP_METHOD, "POST"], body);
		} else if(object_exists(host) && !is_avatar(host)) {
			tell(host, C_PHASE_PROTOCOL, message);
		}
	}
}

/* // unused
	send_message(key id, string message) {
		key host = getjs(token_to_host, [token]);
		list args = split(message, " ");
		
		if(host != JSON_INVALID) {
			string callback = getjs(hosts, [(string)host, 2]);
			if(callback != "" && callback != JSON_INVALID) {
				string body = jsobject([
					"session", gets(hosts, [(string)host, 0]),
					"message", gets(args, 1),
					"args", jsarray(delrange(args, 0, 1))
				]);
				llHTTPRequest(callback, [HTTP_METHOD, "POST"], body);
			} else if(object_exists(host) && !is_avatar(host)) {
				tell(host, C_PHASE_PROTOCOL, message);
			}
		}
	}
*/

disconnect(string token) {
	key host = getjs(token_to_host, [token]);
	
	if(host != JSON_INVALID) {
		hosts = setjs(hosts, [(string)host], JSON_DELETE);
		token_to_host = setjs(token_to_host, [token], JSON_DELETE);
	}
}

// based on provided id, token, and requested mode, determine level of access to be granted
integer validate_token(key id, string token, string mode) {
	integer i_mode = PERMISSION_NONE;
	if(mode == "ro")
		i_mode = PERMISSION_READ;
	else if(mode == "rd")
		i_mode = PERMISSION_READ | PERMISSION_DELETE;
	else if(mode == "rw")
		#ifdef NO_WRITE
			// notecards don't support writing, dummy:
			i_mode = PERMISSION_READ | PERMISSION_DELETE;
		#else
			i_mode = PERMISSION_READ | PERMISSION_DELETE | PERMISSION_WRITE;
		#endif
	else
		return PERMISSION_NONE;
	
	/*
		permission logic
		
		if token is in list: OK, and remove token from list
		
		if object is owned by avatar: OK
		
		otherwise: reject
	*/
	
	integer ti;
	if(~(ti = index(tokens, (key)token))) {
		tokens = delitem(tokens, ti);
		return i_mode;
	} else if(llGetOwnerKey(id) == avatar) {
		return i_mode;
	} else {
		return PERMISSION_NONE;
	}
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		string topic = gets(argv, 2);
		
		if(action == "help") {
			msg = "path filesystem control:\n    "
			 + PROGRAM_NAME + " help\n    "
			 + PROGRAM_NAME + " scan [force]: check for changes\n    "
			 + PROGRAM_NAME + " label <new label>: change volume label\n    "
			 + PROGRAM_NAME + " debug: get storage info\n    "
			 + PROGRAM_NAME + " desc: get description of inventory item (even non-files)\n    "
			 + PROGRAM_NAME + " token <new token>: add token\n    "
			 + PROGRAM_NAME + " connect <mode> <system> <handle>: offer connection as storage to remote host <system>\n    "
			 + PROGRAM_NAME + " list: list all files on volume";
		} else if(action == "label") {
			DISK_LABEL = replace(concat(delrange(argv, 0, 1), " "), " ", "_");
			msg = "New disk label: " + DISK_LABEL;
			llSetObjectDesc(DISK_LABEL);
		} else if(action == "scan") {
			waiting_scan_replies += [src, ins];
			_resolved = 0;
			if(scanning && topic != "force") {
				msg = "scan already in progress";
			} else {
				jump begin_scan;
			}
		} else if(action == "list") {
			msg = llLinksetDataRead(DIRECTORY_CACHE);
		} else if(action == "desc") {
			if(llGetInventoryType(topic) != INVENTORY_NONE)
				msg = llGetInventoryDesc(topic);
		} else if(action == "token") {
			// _path token <UUID>
			if(!contains(tokens, (key)topic))
				tokens += [(key)topic];
			
		} else if(action == "connect") {
			// _path connect <mode> <system> <handle> [<callback-url>]
			
			string mode = gets(argv, 2);
			key id = (key)gets(argv, 3);
			key who = llGetOwnerKey(id);
			string handle = gets(argv, 4);
			string callback_url = gets(argv, 5);
			
			// check existing connections and close any stale ones:
			list host_keys = jskeys(hosts);
			integer hi = count(host_keys);
			while(hi--) {
				key host = gets(host_keys, hi);
				string callback = getjs(hosts, [(string)host, 2]);
				if((callback == "" || callback == JSON_INVALID)
				&& object_exists(host) && !is_avatar(host))
					disconnect(host);
			}
			
			if(user == who) {
				integer authorized = (who == avatar);
				if(!authorized)
					authorized = sec_check(who, "storage-" + mode, who, m, m);
				
				if(authorized == DENIED) {
					tell(id, C_PHASE_PROTOCOL, handle + " denied");
				} else if(authorized == ALLOWED) {
					integer i_mode = validate_token(id, handle, mode);
					
					if(i_mode) {
						string current_record = getjs(hosts, [(string)id]);
						if(current_record != JSON_INVALID)
							hosts = setjs(hosts, [(string)id], JSON_DELETE);
						
						// is this token already in use? if so, preempt it
						string old_host = getjs(token_to_host, [handle]);
						if(old_host != JSON_INVALID) {
							if(old_host != id) {
								echo("[" + PROGRAM_NAME + "] preempting connection to " + (string)old_host);
								disconnect(handle);
							}
						}
					
						hosts = setjs(hosts, [(string)id], jsarray([
							handle,
							i_mode,
							callback_url
						]));
						
						token_to_host = setjs(token_to_host, [handle], id);
						
						string effective_mode = gets(["none", "ro", "rd", "rw"], i_mode);
						tell(id, C_PHASE_PROTOCOL, handle + " access " + effective_mode + " " + STORAGE_UNIT + " " + DISK_LABEL + " " + url + "/" + handle + "/");
					} else {
						tell(id, C_PHASE_PROTOCOL, handle + " denied");
					}
				}
			} else {
				msg = "Only secondlife:///app/agent/" + (string)who + "/about may manually initiate a reverse filesystem connection to that system.";
			}
		} else if(action == "debug" || action == "") {
			// print(outs, user, llLinksetDataRead(DIRECTORY_CACHE));
			llSleep(0.25);
			llSetMemoryLimit(0x0fffe);
			llSetMemoryLimit(0x10000);
			msg = IMPLEMENTATION + " at " + url + "\nFree memory: " + (string)llGetFreeMemory() + "; used: " + (string)llGetUsedMemory() + "; " + (string)llGetInventoryNumber(INVENTORY_NOTECARD) + " file(s); cache = " + (string)strlen(llLinksetDataRead(DIRECTORY_CACHE)) + "\n\nType '@" + PROGRAM_NAME + " help' for usage instructions.";
		
		} else {
			msg = "Unknown action: " + action + ". See '@help path' for more information.";
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		if(url != "")
			llReleaseURL(url);
		url_key = llRequestURL();
		
		hook_events([EVENT_ON_REZ]);
		DISK_LABEL = replace(llGetObjectDesc(), " ", "_");
		initializing = 1;
		llListenRemove(L_PHASE_PROTOCOL);
		L_PHASE_PROTOCOL = llListen(C_PHASE_PROTOCOL, "", "", "");
		llWhisper(C_PHASE_PROTOCOL, (string)llGetKey() + " reset");
		jump begin_scan;
	} else if(n == SIGNAL_EVENT) {
		// must be EVENT_ON_REZ:
		if(url != "")
			llReleaseURL(url);
		url_key = llRequestURL();
		hosts = "";
		token_to_host = "";
		tokens = [];
		llWhisper(C_PHASE_PROTOCOL, NULL_KEY + " reset " + DISK_LABEL);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
	
	jump end;
	@begin_scan;
	begin_working("path scan");
	// echo("[_path] beginning scan");
	scanning = TRUE;
	scan_changes = "";
	scan_ks = "{}";
	scan_progress = 0;
	llSetTimerEvent(0.044);
	@end;
	
}

#define EXT_EVENT_HANDLER "ARES/system/path.event.lsl"
#define EXT_COM_HANDLER "ARES/system/path.com.lsl"
#include <ARES/program>
