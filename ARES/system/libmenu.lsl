/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Menu Library
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
#include <ARES/api/auth.h.lsl>
#define CLIENT_VERSION ARES_VERSION
#define CLIENT_VERSION_TAGS ARES_VERSION_TAGS

string software_server_topic;

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(argc == 1 || action == "help") {
			msg = "Syntax: \n"
				+ PROGRAM_NAME + " cf <database entry>: step database entry by +0.1, wrapping around in the range [0.0, 1.0]\n"
				+ PROGRAM_NAME + " build <menu> [<topic>]: repopulate dynamic menu\n"
				+ PROGRAM_NAME + " field <menu> <value>: update the 'last used' legend on the specified menu\n"
				+ PROGRAM_NAME + " prompt <command>: display a generic text input prompt to provide parameters for a system command"
			;
		} else if(action == "cf") {
			string item = gets(argv, 2);
			integer authorization = sec_check(user, "database", outs, "", m);
			if(authorization == ALLOWED) {
				list parts = split(item, ".");
				string section = gets(parts, 0);
				parts = delitem(parts, 0);
				float f = (float)getdbl(section, parts);
				f += 0.1;
				if(f > 1.05)
					f = 0;
				else if(f > 0.95)
					f = 1;
				setdbl(section, parts, (string)f);
			} else if(authorization == DENIED) {
				msg = "You do not have permission to adjust this setting.";
			}
		} else if(action == "field") {
			string menu = gets(argv, 2);
			string value = concat(delrange(argv, 0, 2), " ");
			string current = getdbl("m:" + menu, ["f"]);
			if(current != JSON_INVALID) {
				setdbl("m:" + menu, ["f"], value);
			} else {
				msg = "Menu m:" + menu + " does not exist or has no appropriate field.";
			}
		} else if(action == "build") {
			// old: menu build <category>; topic inferred from context of session
			// new: libmenu build <category> $topic
			
			// string s_fs = llLinksetDataRead("fs");
			string category = gets(argv, 2);
			string topic = gets(argv, 3); // getjs(sessions, [(string)outs, SESSION_TOPIC]);
			string menu_name;
			string buttons;
			
			if(category == "chime") {
				string raw = getdbl("chime", []);
				list items;
				if(raw != JSON_INVALID) {
					items = jskeys(raw);
					integer i = count(items);
					while(i--) {
						string name = getk(items, i);
						// string sinfo = getjs(raw, [server]);
						items = alter(items, [jsarray([
							name, 0, "id chime load " + name
						])], i, i);
					}
				}
				
				setdbl("m:chime", ["d"], jsarray(items));
			} else if(category == "security") {
				integer add = 0;
				string otopic = topic;
				
				if(substr(topic, 0, 3) == "add-") {
					topic = delstring(topic, 0, 3);
					add = 1;
				}
			
				if(topic == "user" || topic == "ban" || topic == "guest") {
					list entries;
					
					if(add)
						entries = llGetAgentList(AGENT_LIST_PARCEL_OWNER, []);
					else
						entries = jskeys(getdbl("security", [topic]));
					
					list buttons = [];
					integer ei = count(entries);
					while(ei--) {
						string entry = gets(entries, ei);
						string name;
						string b;
						if(add) {
							name = llGetUsername(entry);
							b = jsarray([
								name, 0, "security " + topic + " " + entry
							]);
						} else {
							name = getdbl("security", ["name", entry]);
							b = jsarray([
								name, 1, "m:" + topic + "-info", entry
							]);
						}
						
						buttons = b + buttons;
					}
					
					setdbl("m:" + otopic, ["d"], jsarray(buttons));
				}
			} else if(category == "ax-source") {
				string raw = getdbl("ax", ["source"]);
				list items;
				if(raw != JSON_INVALID) {
					items = jskeys(raw);
					integer i = count(items);
					while(i--) {
						key server = getk(items, i);
						// string sinfo = getjs(raw, [server]);
						if(object_pos(server) == ZV) {
							items = delitem(items, i);
						} else {
							items = alter(items, [jsarray([
								llKey2Name(server), 1, "m:ax-server", server
							])], i, i);
						}
					}
				}
				
				if(!count(items))
					msg = "No trusted sources in region. See http://support.nanite-systems.com/ax_servers for a list of package servers and where to find them.";
				
				setdbl("m:ax-source", ["d"], jsarray(items));
			} else if(category == "ax-server") {
				if(topic != "" && topic != JSON_INVALID)
					software_server_topic = topic;
				
				string raw = llLinksetDataRead("pkg:" + (string)software_server_topic);
				list items;
				if(raw != JSON_INVALID) {
					items = jskeys(raw);
					integer i = count(items);
					while(i--) {
						string name = gets(items, i);
						string data = getjs(raw, [name]);
						items = alter(items, [jsarray([
							name + " " + data, 1, "m:ax-sd", name
						])], i, i);
					}
				}
				
				if(!count(items))
					msg = "Catalog empty for this server. Try 'update regional catalog' (@ax update) first.";
				
				setdbl("m:ax-server", ["d"], jsarray(items));
			
			} else if(category == "ax-local") {
				list pkgs = js2list(getdbl("pkg", ["version"])); // object
				integer pi = count(pkgs);
				while(pi > 0) {
					pi -= 2;
					string name = gets(pkgs, pi);
					string version = gets(pkgs, pi + 1);
					pkgs = alter(pkgs, [
						jsarray([name + " " + version, 1, "m:ax-ld", name])
					], pi, pi + 1);
				}
				setdbl("m:ax-local", ["d"], jsarray(pkgs));
			} else if(category == "ax-cache") {
				list pkgs = js2list(llLinksetDataRead("fs:package")); // array
				integer pi = count(pkgs);
				while(pi--) {
					string fn = gets(pkgs, pi);
					string nameversion = concat(delitem(splitnulls(fn, "."), LAST), ".");
					pkgs = alter(pkgs, [jsarray([nameversion, 1, "m:ax-cd", nameversion])], pi, pi);
				}
				setdbl("m:ax-cache", ["d"], jsarray(pkgs));
			} else if(category == "fs") {
				list sources = jskeys(getdbl("fs", ["source"]));
				list views = jskeys(getdbl("fs", ["view"]));
				integer pi;
				if(~(pi = index(views, "parc")))
					views = delitem(views, pi);
					
				integer vmax = count(views);
				integer vi;
				while(vi < vmax) {
					string view = gets(views, vi);
					buttons = setjs(buttons, [JSON_APPEND], jsarray([
						view + " files...",
						1,
						"m:fs-view",
						view
					]));
					++vi;
				}
				
				vmax = count(sources);
				vi = 0;
				while(vi < vmax) {
					string source = gets(sources, vi);
					buttons = setjs(buttons, [JSON_APPEND], jsarray([
						source + ":>",
						1,
						"m:fs-source",
						source
					]));
					++vi;
				}
				
				menu_name = "m:fs";
			} else { // including 'source' and 'view'
				integer is_source = (category == "source");
				if(category == "view" || category == "source") {
					menu_name = "m:fs-" + category;
					category = topic;
				} else {
					menu_name = getdbl("fs", ["view", category, "menu"]);
				}
				
				if(menu_name != JSON_INVALID) {
					setdbl(menu_name, ["d"], "[]");
					
					list files;
					if(is_source)
						files = split(llLinksetDataRead("fs:" + category), "\n");
					else
						files = js2list(llLinksetDataRead("fs:" + category));
					
					files = llListSort(files, 1, TRUE);
					
					integer fmax = count(files);
					integer fi = 0;
					while(fi < fmax) {
						string fn = gets(files, fi);
						if(is_source)
							fn = gets(split(fn, " "), 0);
						buttons = setjs(buttons, [JSON_APPEND], jsarray([
							fn,
							4
						]));
						++fi;
					}
				} else {
					echo("[_menu] "+"no .menu definition for filesystem view '" + category + "'");
					return;
				}
			}
			
			// s_fs = "";
			setdbl(menu_name, ["d"], buttons);
			
		} else if(action == "prompt") {
			string cmd = concat(delrange(argv, 0, 1), " ");
			e_call(C_BASEBAND, E_SIGNAL_CALL,
				(string)outs + " " + (string)user + " baseband prompt " + jsobject([
					"message", "Specify parameters for the following command:\n\n\t" + cmd
					+ "\n\nhelp: http://support.nanite-systems.com/?id=2832#" + gets(argv, 2),
					"ins", ins,
					"command", cmd
				])
			);
		} else {
			msg = "Unknown action: " + action + ". See '" + gets(argv, 0) + " help' for more information.";
		}
		
		if(msg != "")
			print(outs, user, msg);
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
