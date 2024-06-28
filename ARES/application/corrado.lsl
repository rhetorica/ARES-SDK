/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Corrado Utility
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
#define CLIENT_VERSION "0.1.1"
#define CLIENT_VERSION_TAGS "alpha"

// argsplit() from find.lsl
list argsplit(string m) {
	// splits a string based on word boundaries, but groups terms inside double and single quotes
	// tabs and newlines are converted to spaces
	list results;
	string TAB = llChar(9);
	list atoms = llParseStringKeepNulls(m, [], [" ", "\\", "'", "\"", "\n", TAB]);
	integer in_quotes; // 1 = single, 2 = double
	integer ti = 0;
	integer tmax = count(atoms);
	
	string buffer;
	while(ti < tmax) {
		string t = gets(atoms, ti);
		integer c = llOrd(t, 0);
		if(c == 0x22) { // '"'
			if(in_quotes == 0) {
				in_quotes = 2;
			} else if(in_quotes == 2) {
				in_quotes = 0;
			} else {
				buffer += t;
			}
		} else if(c == 0x27) { // '\''
			if(in_quotes == 0) {
				in_quotes = 1;
			} else if(in_quotes == 1) {
				in_quotes = 0;
			} else {
				buffer += t;
			}
		} else if(c == 0x5c) { // '\\'
			string t1 = gets(atoms, ti + 2);
			if(t1 == "\"" || t1 == "'") {
				buffer += t1;
				ti += 2;
			} else {
				buffer += t;
			}
		} else if(c == 0x20 || c == 0x0a || c == 0x09) { // ' ', '\n', '\t'
			if(in_quotes) {
				buffer += " ";
			} else {
				results += buffer;
				buffer = "";
			}
		} else {
			buffer += t;
		}
		++ti;
	}
	
	if(tmax)
		results += buffer;
	
	return results;
}

string bot_address;
key bot;
string group;
string password;

string callback;

key http_fetch_reply;
list waiting_queries; // [src, ins, handle, outs, user, post_body_pipe, post_reply_pipe, bot_address]
list active_queries; // [src, ins, handle, outs, user]

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string arg0 = gets(argv, 0);
		if(arg0 == PROGRAM_NAME || arg0 == "*") {
			string arg1 = gets(argv, 1);
			if(arg1 == "http") {
				string path = gets(argv, 2);
				if(substr(path, 0, 0) == "/") {
					string buffer = read(ins);
					// echo(PROGRAM_NAME + ": received query at " + path);
					if(buffer != "") {
						print(user, user, buffer);
					}
					
					http_reply(outs, 200, "OK");
					/*
					pipe_write(outs, "OK");
					notify_program("_proc reply 200", NULL_KEY, outs, user);
					*/
				} else if(substr(path, 0, 3) == "http") {
					echo(PROGRAM_NAME + ": got URL " + path);
					callback = path + "/";
				} else if(path == URL_REQUEST_DENIED) {
					echo(PROGRAM_NAME + ": URL recruitment failed.");
					callback = "";
				}
			} else if(arg1 == "fetched") {
				string buffer = read(ins);
				key handle = gets(argv, 2);
				integer aqi = index(active_queries, handle);
				if(~aqi) {
					integer r = geti(active_queries, aqi - 2);
					key r_ins = getk(active_queries, aqi - 1);
					key r_outs = getk(active_queries, aqi + 1);
					key r_user = getk(active_queries, aqi + 2);
					active_queries = delrange(active_queries, aqi - 2, aqi + 2);
					
					print(r_outs, r_user, buffer);
					resolvec(r, r_ins);
				} else {
					echo("invalid aqi: " + m);
				}
				pipe_close(ins);
			} else if(arg1 == "pipe") {
				// notify <PROGRAM_NAME> fetched <handle>
				if(gets(argv, 2) == "notify"
					&& gets(argv, 3) == PROGRAM_NAME
					&& gets(argv, 4) == "fetched") {
					key handle = gets(argv, 5);
					integer wqi = index(waiting_queries, handle);
					if(~wqi) {
						active_queries += sublist(waiting_queries, wqi - 2, wqi + 2);
						
						string q_addr = gets(waiting_queries, wqi + 5);
						key q_reply_p = getk(waiting_queries, wqi + 4);
						key q_body_p = getk(waiting_queries, wqi + 3);
						
						http_post(q_addr, q_reply_p, q_body_p, handle);
						waiting_queries = delrange(waiting_queries, wqi - 2, wqi + 5);
						// echo("dispatched query");
					} else {
						echo("invalid wqi: " + m);
					}
				} else {
					echo("unexpected pipe open: " + m);
				}
			}
		}
		
	} else if(n == SIGNAL_INVOKE) {
		list argv = argsplit(m); // non-standard
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " [-] [-t] [-v] [-f] [-a <key>|-u <HTTP URL>] [-g <group>] [-p <password>] [--<arg> <value> [...]] [<command> [<message>]]\n\nConfigures and sends commands to a Corrade agent. Messages are formatted as JSON and sent over IM.\n\n    -a <key>: Sets the agent UUID.\n    -u <HTTP URL>: Sets the Corrade HTTP URL.\n    -g <group>: Sets the authentication group name.\n    -p <password>: Sets the authentication group password.\n\nIf any of the above settings are missing, the previous values will be re-used. -a and -u are mutually exclusive.\n\n    <command>: One of https://grimore.org/secondlife/scripted_agents/corrade/api/commands\n    <message>: Contextual; usually mapped to the third parameter listed on the Complete List of Commands page.\n    --<arg> <value>: Sets additional arguments. Use \"double quotes\" to wrap values containing spaces.\n    -t: Test only; do not send. Useful for determining what <message> maps to.\n    -v: Verbose (warn about missing or empty <message> parameters)\n    -f: Don't wait for response when using HTTP; just send command and quit.\n    -: Read <message> from standard input, discarding <message> if non-empty.";
		/*} else if(gets(argv, 1) == "-F") {
			if(http_fetch_reply != "") {
				pipe_close(http_fetch_reply);
			}
			http_fetch_reply = llGenerateKey();
			pipe_open("p:" + (string)http_fetch_reply + " notify " + PROGRAM_NAME + " fetched"); */
		} else if(gets(argv, 1) == "-L") {
			// notify_program("_proc listen " + PROGRAM_NAME + " http", NULL_KEY, NULL_KEY, user);
			http_listen("http", user);
			callback = "";
		} else if(gets(argv, 1) == "-R") {
			// notify_program("_proc release " + PROGRAM_NAME + " http", NULL_KEY, NULL_KEY, user);
			http_release("http");
			callback = "";
		} else {
			integer no_http_wait = 0;
			integer warn = 0;
			integer test = 0;
			integer pipe_in = 0;
			string command;
			string message;
			integer argi = 1;
			
			string json = "{}";
			if(group != "")
				json = setjs(json, ["group"], group);
			if(password != "")
				json = setjs(json, ["password"], password);
			if(callback != "")
				json = setjs(json, ["callback"], callback);
			
			while(argi < argc) {
				string term = gets(argv, argi);
				if(message == "") {
					if(term == "-") {
						pipe_in = 1;
					} else if(term == "-f") {
						no_http_wait = 1;
					} else if(term == "-v") {
						warn = 1;
					} else if(term == "-t") {
						test = 1;
					} else if(term == "-a") {
						bot = (key)gets(argv, ++argi);
						bot_address = "";
					} else if(term == "-u") {
						bot_address = gets(argv, ++argi);
						bot = "";
					} else if(term == "-g") {
						group = gets(argv, ++argi);
						json = setjs(json, ["group"], group);
					} else if(term == "-p") {
						password = gets(argv, ++argi);
						json = setjs(json, ["password"], password);
					} else if(substr(term, 0, 1) == "--") {
						json = setjs(json, [delstring(term, 0, 1)], gets(argv, ++argi));
					} else if(command == "") {
						command = term;
						json = setjs(json, ["command"], command);
					} else {
						message = term;
					}
				} else {
					message += " " + term;
				}
			
				++argi;
			}
			
			if(pipe_in) {
				string pipe_buffer = read(ins);
				if(pipe_buffer != "")
					message = pipe_buffer;
			}
			
			if(command == "") {
				msg = "No command specified. See https://grimore.org/secondlife/scripted_agents/corrade/api/commands for a list of available commands.";
			} else if(bot == "" && bot_address == "") {
				msg = "No Corrade bot specified. Please set with -a <UUID> or -u <HTTP URL>";
			} else if(group == "") {
				msg = "No authentication group specified. Please set with -a <name> (use quotes)";
			} else if(password == "") {
				msg = "No authentication password specified. Please set with -p <password> (use quotes)";
			} else if(json == JSON_INVALID) {
				msg = "JSON encoding failed, likely due to imbalanced braces or square brackets in one or more parameters.";
			} else {
				string message_key;
				{
					string message_mappings = jsobject([
						"addclassified", "name",
						"addpick", "name",
						"addtorole", "agent",
						"agentaccess", "action",
						"animation", "item",
						"attach", "attachments",
						"attachobject", "item",
						"autopilot", "position",
						"avatarnotes", "data",
						"avatarzoffset", "offset",
						"away", "action",
						"ban", "avatars",
						"batchaddtorole", "avatars",
						"batchanimation", "item",
						"batchattachobjects", "attachments",
						"batchavatarkeytoname", "avatars",
						"batchavatarnametokey", "avatars",
						"batchdeletefromrole", "avatars",
						"batchderez", "item",
						"batchdropobject", "attachments",
						"batcheject", "avatars",
						"batchgetavatarappearancedata", "agents",
						"batchgetavatardisplayname", "agents",
						"batchgetavatarseat", "agents",
						"batchgetprofiledata", "data",
						"batchgive", "item",
						"batchgroupkeytoname", "groups",
						"batchgroupnametokey", "groups",
						"batchinvite", "avatars",
						"batchlure", "avatars",
						"batchmute", "mutes",
						"batchsetinventorydata", "data",
						"batchsetobjectgroup", "item",
						"batchsetobjectpermissions", "item",
						"batchsetobjectpositions", "item",
						"batchsetobjectrotations", "item",
						"batchsetparcellist", "avatars",
						"batchsetprimitivedescriptions", "item",
						"batchsetprimitivenames", "item",
						"batchsetprimitivepositions", "item",
						"batchsetprimitiverotations", "item",
						"batchtell", "message",
						"batchupdateprimitiveinventory", "entity",
						"busy", "action",
						"changeappearance", "folder",
						"changeprimitivelink", "item",
						"click", "item",
						"compilescript", "data",
						"conference", "avatars",
						"configuration", "path",
						"copynotecardasset", "item",
						"creategrass", "position",
						"creategroup", "data",
						"createlandmark", "name",
						"createnotecard", "name",
						"createprimitive", "name",
						"createrole", "role",
						"createtree", "position",
						"crouch", "action",
						"deleteclassified", "name",
						"deletefromrole", "agent",
						"deletepick", "name",
						"deleterole", "role",
						"deleteviewereffect", "id",
						"derez", "item",
						"detach", "attachments",
						"directoryquery", "name",
						"directorysearch", "name",
						"displayname", "name",
						"download", "item",
						"dropobject", "item",
						"eject", "agent",
						"estateteleportusershome", "avatars",
						"execute", "file",
						"exportdae", "item",
						"exportoar", "item",
						"exportxml", "item",
						"fly", "action",
						"flyto", "position",
						"getassetdata", "item",
						"getavatarappearancedata", "agent",
						"getavatarclassifieddata", "item",
						"getavatarclassifieds", "agent",
						"getavatardata", "agent",
						"getavatardisplayname", "agent",
						"getavatargroupdata", "agent",
						"getavatargroupsdata", "agent",
						"getavatarpickdata", "item",
						"getavatarpicks", "agent",
						"getavatarpositions", "entity",
						"getavatarsappearancedata", "entity",
						"getavatarsdata", "entity",
						"getavatarseat", "agents",
						"getavatarsseats", "agents",
						"getcameradata", "data",
						"getconferencememberdata", "agent",
						"getconferencemembersdata", "session",
						"getconfigurationdata", "data",
						"getcurrentgroupsdata", "data",
						"getestatebanlist", "type",
						"getestateinfodata", "data",
						"getestatelist", "type",
						"geteventinfodata", "id",
						"getfrienddata", "agent",
						"getgridregiondata", "data",
						"getgroupaccountsummarydata", "target",
						"getgroupdata", "target",
						"getgrouplandinfodata", "target",
						"getgroupmemberdata", "target",
						"getgroupmembersdata", "target",
						"getgroupsdata", "target",
						"getheartbeatdata", "data",
						"getinventorydata", "item",
						"getinventorypath", "path",
						"getmapavatarpositions", "region",
						"getmemberroles", "target",
						"getmembers", "target",
						"getmembersoffline", "target",
						"getmembersonline", "target",
						"getmovementdata", "data",
						"getnetworkdata", "data",
						"getobjectdata", "data",
						"getobjectlink", "item",
						"getobjectmediadata", "data",
						"getobjectpermissions", "item",
						"getobjectsdata", "data",
						"getparceldata", "data",
						"getparceldwell", "position",
						"getparcelinfodata", "data",
						"getparcellist", "type",
						"getparcelobjectresourcedetaildata", "data",
						"getparcelobjectsresourcedetaildata", "data",
						"getparticlesystem", "item",
						"getprimitivedata", "data",
						"getprimitiveflexibledata", "data",
						"getprimitiveinventory", "item",
						"getprimitiveinventorydata", "data",
						"getprimitivelightdata", "data",
						"getprimitiveowners", "position",
						"getprimitivepayprices", "item",
						"getprimitivephysicsdata", "data",
						"getprimitivepropertiesdata", "data",
						"getprimitivescripttext", "target",
						"getprimitivesculptdata", "data",
						"getprimitivesdata", "data",
						"getprimitiveshapedata", "data",
						"getprimitivetexturedata", "data",
						"getprofiledata", "data",
						"getprofilesdata", "data",
						"getregiondata", "data",
						"getregionparcellocations", "region",
						"getregionparcelsboundingbox", "region",
						"getregiontop", "type",
						"getremoteparcelinfodata", "data",
						"getrolemembers", "role",
						"getrolepowers", "role",
						"getroles", "target",
						"getrolesmembers", "target",
						"getscriptrunning", "entity",
						"getselfdata", "data",
						"getterrainheight", "region",
						"gettitles", "target",
						"getviewereffects", "effect",
						"give", "item",
						"grab", "item",
						"grantfriendrights", "rights",
						"http", "URL",
						"importxml", "data",
						"inventory", "action",
						"invite", "agent",
						"join", "target",
						"jump", "action",
						"leave", "target",
						"login", "location",
						"logs", "search",
						"look", "position",
						"lure", "agent",
						"mapfriend", "agent",
						"moderate", "agent",
						"mqtt", "payload",
						"mute", "agent",
						"notice", "message",
						"notify", "tag",
						"nudge", "direction",
						"objectdeed", "item",
						"offerfriendship", "agent",
						"parcelbuy", "position",
						"parceldeed", "position",
						"parceleject", "agent",
						"parcelfreeze", "agent",
						"parcelreclaim", "position",
						"parcelrelease", "position",
						"pay", "description",
						"playgesture", "item",
						"playsound", "item",
						"primitivebuy", "item",
						"readfile", "path",
						"recompilescript", "target",
						"removeconfigurationgroup", "target",
						"removeitem", "item",
						"renameitem", "item",
						"replytofriendshiprequest", "agent",
						"replytogroupinvite", "session",
						"replytoinventoryoffer", "session",
						"replytoscriptdialog", "dialog",
						"replytoscriptpermissionrequest", "task",
						"replytoteleportlure", "session",
						"requestlure", "agent",
						"restartregion", "action",
						"returnprimitives", "agent",
						"rez", "item",
						"run", "action",
						"scriptreset", "item",
						"searchinventory", "pattern",
						"setcameradata", "data",
						"setconfigurationdata", "data",
						"setestatecovenant", "item",
						"setestatelist", "action",
						"setgroupdata", "data",
						"setinventorydata", "data",
						"setmovementdata", "data",
						"setobjectgroup", "item",
						"setobjectmediadata", "data",
						"setobjectpermissions", "permissions",
						"setobjectposition", "position",
						"setobjectrotation", "rotation",
						"setobjectsaleinfo", "price",
						"setobjectscale", "scale",
						"setparceldata", "data",
						"setparcellist", "agent",
						"setprimitivedescription", "description",
						"setprimitiveflags", "item",
						"setprimitiveflexibledata", "data",
						"setprimitiveinventorydata", "data",
						"setprimitivelightdata", "data",
						"setprimitivematerial", "material",
						"setprimitivename", "name",
						"setprimitiveposition", "position",
						"setprimitiverotation", "rotation",
						"setprimitivescale", "scale",
						"setprimitivesculptdata", "data",
						"setprimitiveshapedata", "data",
						"setprimitivetexturedata", "data",
						"setprofiledata", "data",
						"setregionterrainheights", "data",
						"setregionterraintextures", "data",
						"setrolepowers", "role",
						"setscriptrunning", "entity",
						"setviewereffect", "item",
						"simulatorpause", "region",
						"simulatorresume", "region",
						"sit", "item",
						"softban", "avatars",
						"startproposal", "text",
						"tag", "title",
						"teleport", "position",
						"tell", "message",
						"terminatefriendship", "agent",
						"terrain", "data",
						"toggleparcelflags", "flags",
						"touch", "item",
						"trashitem", "item",
						"turn", "radians",
						"turnto", "position",
						"typing", "action",
						"unwear", "wearables",
						"updatenotecard", "data",
						"updateprimitiveinventory", "item",
						"updatescript", "data",
						"upload", "data",
						"walkto", "position",
						"wear", "wearables",
						"writefile", "data"
					]);
					
					message_key = getjs(message_mappings, [command]);
				}
				
				if((message_key == "" || message_key == JSON_INVALID)) {
					if(message != "")
						msg = "Warning: discarded <message> value.";
					
				} else if(message == "" && (message_key != "" && message_key != JSON_INVALID)) {
					if(getjs(json, [message_key]) != JSON_INVALID) {
						// already set manually; we're fine!
					} else if(warn) {
						msg = "Warning: <message> was expected but not provided.";
					}
				} else {
					json = setjs(json, [message_key], message);
				}
				
				if(test)
					msg = setjs(json, ["password"], "[REDACTED]");
				else {
					if(bot_address != "") {
						key post_body_pipe = llGenerateKey();
						pipe_write(post_body_pipe, json);
						if(no_http_wait) {
							http_post(bot_address, NULL_KEY, post_body_pipe, NULL_KEY);
						} else {
							key handle = llGenerateKey();
							key post_reply_pipe = llGenerateKey();
							
							
							waiting_queries += [
								src, ins, handle, outs, user, post_body_pipe, post_reply_pipe, bot_address
							];
							
							pipe_open("p:" + (string)post_reply_pipe + " notify " + PROGRAM_NAME + " fetched " + (string)handle);
							
							_resolved = 0;
						}
						
						/*
						if(http_fetch_reply != "" || no_http_wait) {
							key post_body_pipe = llGenerateKey();
							key handle = llGenerateKey();
							pipe_write(post_body_pipe, json);
							if(!no_http_wait) {
								http_post(bot_address, http_fetch_reply, post_body_pipe, handle);
								_resolved = 0;
								active_queries += [
									src, ins, handle, outs, user
								];
							} else {
								http_post(bot_address, NULL_KEY, post_body_pipe, handle);
							}
						} else {
							
							
							
							// msg = "Run '" + PROGRAM_NAME + " -F' first.";
						}
						*/
					} else if(bot == "") {
						llInstantMessage(avatar, json);
					} else {
						llInstantMessage(bot, json);
					}
				}
			}
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
