/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Database Utility
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
#define FILE_STEP_SIZE 10
#include <ARES/api/file.h.lsl>
#include <ARES/api/auth.h.lsl>
#define CLIENT_VERSION "1.2.0"
#define CLIENT_VERSION_TAGS "beta"

key dbload_q;

string read_buffer;

/*
 replaces (string)  number   with (integer)number
      and (string)\"number\" with  (string)number
*/
list process_keyname(list keyname) {
	integer ki = count(keyname);
	while(ki--) {
		string ks = gets(keyname, ki);
		if((string)((integer)ks) == ks)
			keyname = alter(keyname, [(integer)ks], ki, ki);
		else if(llOrd(ks, 0) == 0x22 && llOrd(ks, LAST) == 0x22)
			keyname = alter(keyname, [substr(ks, 1, -2)], ki, ki);
			
	}
	return keyname;
}

string db_set(string section, list keyname, string new_value) {
	string old_value = getdbl(section, keyname);
			
	setdbl(section, keyname, new_value);
	
	if(old_value == JSON_INVALID)
		old_value = "(undefined)";
	else if(strlen(old_value) > 100)
		old_value = "(" + (string)strlen(old_value) + " bytes)";
	
	if(strlen(new_value) > 100)
		new_value = "(" + (string)strlen(new_value) + " bytes)";
	
	if(count(keyname) == 0)
		return "overwrote ENTIRE section " + section + ": " + old_value + " --> " + new_value;
	else
		return "modified " + section + " setting " + concat(keyname, ".") + ": " + old_value + " --> " + new_value;
}

string db_show_2(string value, integer sp) {
	if(llOrd(value, 0) == 0x7b && llOrd(value, LAST) == 0x7d) { // { and }
		list keys = jskeys(value);
		integer kmax = count(keys);
		if(kmax == 0) {
			if(strlen(value) > 100)
				return "(" + (string)strlen(value) + " bytes)";
			else
				return value;
		}
		
		string sps = "  ";
		if(sp) {
			integer spi = sp;
			while(spi--)
				sps += "  ";
		}
		
		list vout;
		integer ki = 0;
		while(ki < kmax) {
			string k = gets(keys, ki);
			string subval = getjs(value, [k]);
			if(llGetFreeMemory() > 2000)
				vout += k + ": " + db_show_2(subval, sp + 1);
			else
				vout += k + ": (out of memory)";
			
			++ki;
		}
		
		return "\n" + sps + concat(vout, "\n" + sps);
	} else {
		return value;
	}
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		string action = gets(argv, 1);
		integer argc = count(argv);
		
		string msg;
		
		integer allowed = sec_check(user, "database", outs, m, m);
		if(allowed == DENIED) {
			print(outs, user, "secondlife:///app/agent/" + (string)user + "/about is not authorized to access the database directly.");
			return;
		} else if(allowed == PENDING) {
			return;
		}
		
		list parts;
		string section;
		list keyname;
		
		integer user_rank = (integer)getdbl("security", ["user", user]);
		
		if(action == "clone") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			list parts2 = splitnulls(gets(argv, 3), ".");
			string section2 = gets(parts2, 0);
			if(section2 == "security" && user_rank != SEC_OWNER) {
				jump security_fail;
			} else {
				string text = getdbl(section, process_keyname(delitem(parts, 0)));
				if(text == JSON_INVALID) {
					msg = "Could not clone from " + gets(argv, 2) + " to " + gets(argv, 3) + ": entry " + gets(argv, 2) + " does not exist.";
				} else {
					setdbl(section2, process_keyname(delitem(parts2, 0)), text);
					integer tl = strlen(text);
					msg = "Cloned data from " + gets(argv, 2) + " to " + gets(argv, 3) + ".";
					if(tl != 1)
						msg += " (" + (string)tl + " bytes)";
					else
						msg += " (1 byte)";
				}
			}
		} else if(action == "load") {
			if(user_rank != SEC_OWNER) {
				msg = "Only owners may perform database imports.";
			} else if(gets(argv, 2) == "cancel") {
				msg = "Aborted.";
				resolve((integer)getjs(tasks_queue, [dbload_q, FILE_R]));
				task_end(dbload_q);
				dbload_q = "";
			} else if(dbload_q) {
				msg = "A database import is already in progress; run 'db load cancel' to abort.";
			} else {
				read_buffer = "";
				string dbload_fn = gets(argv, 2);
				dbload_q = fopen(outs, ins, user, dbload_fn);
				msg = "Importing " + dbload_fn;
			}
		} else if(action == "delete" || action == "remove") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			if(section == "security" && user_rank != SEC_OWNER)
				jump security_fail;
			keyname = process_keyname(delitem(parts, 0));
			
			if(getdbl(section, keyname) != JSON_INVALID) {
				deletedbl(section, keyname);
				msg = "Deleted " + concat(keyname, ".") + " in section " + section;
			} else {
				msg = concat(keyname, ".") + " in section " + section + " not present";
			}
		} else if(action == "toggle") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			if(section == "security" && user_rank != SEC_OWNER)
				jump security_fail;
			keyname = process_keyname(delitem(parts, 0));
			
			integer val = !(integer)getdbl(section, keyname);
			if(val)
				msg = "Enabled ";
			else
				msg = "Disabled ";
			
			setdbl(section, keyname, (string)val);
			
			msg += gets(argv, 2);
			
		} else if(action == "drop") {
			section = gets(argv, 2);
			if(section == "security" && user_rank != SEC_OWNER)
				jump security_fail;
			llLinksetDataDelete(section);
			msg = "Deleted ENTIRE section " + section;
			
		} else if(action == "set") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			if(section == "security" && user_rank != SEC_OWNER)
				jump security_fail;
			keyname = process_keyname(delitem(parts, 0));
			string new_value = concat(delrange(argv, 0, 2), " ");
			msg = db_set(section, keyname, new_value);
			
		} else if(action == "append") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			if(section == "security" && user_rank != SEC_OWNER)
				jump security_fail;
			keyname = process_keyname(delitem(parts, 0)) + [JSON_APPEND];
			
			string new_value = concat(delrange(argv, 0, 2), " ");
			setdbl(section, keyname, new_value);
			
			msg = "Added '" + new_value + "' to section " + section + " key " + concat(keyname, ".");
		} else if(action == "") {
			list all_keys = llLinksetDataListKeys(0, 0);
			integer aki = count(all_keys);
			
			// limited regex support can't handle ^(?!p:).+$
			while(aki--)
				if(substr(gets(all_keys, aki), 0, 1) == "p:")
					all_keys = delitem(all_keys, aki);
			
			msg = "Stored sections: " + concat(all_keys, ", ")
				+ "\nLSD status: "
				+ (string)llLinksetDataCountKeys() + " keys total, "
				+ (string)llLinksetDataAvailable() + " bytes free.";
		} else if(action == "u" || action == "usage") {
			// list all_keys = llLinksetDataListKeys(0, 0);
			integer akmax;
			integer aki = akmax = llLinksetDataCountKeys(); // count(all_keys);
			list fields;
			while(aki--) {
				string kn = gets(llLinksetDataListKeys(aki, 1), 0);
				// msg += " - " + kn + "    " + (string)strlen(llLinksetDataRead(kn)) + "\n";
				fields += [kn, strlen_byte_inline(llLinksetDataRead(kn))];
			}
			fields = llListSortStrided(fields, 2, 1, TRUE);
			aki = akmax;
			while(aki--) {
				integer L = geti(fields, (aki << 1) + 1);
				string line = " - " + gets(fields, (aki << 1)) + "    " + (string)L;
				if(L != 1)
					line += " bytes";
				else
					line += " byte";
				// fields = alter(fields, [line], (aki << 1), (aki << 1) + 1);
				fields = delrange(fields, (aki << 1), (aki << 1) + 1);
				print(outs, user, line);
				llSleep(0.05);
			}
			
			msg = /*concat(fields, "\n")
				+ */"\nLSD status: "
				+ (string)llLinksetDataCountKeys() + " keys total, "
				+ (string)llLinksetDataAvailable() + " bytes free.";
		} else if(action == "show") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			keyname = process_keyname(delitem(parts, 0));
			// msg = db_show(section, keyname);
			jump db_show;
		} else if(action == "json") {
			parts = splitnulls(gets(argv, 2), ".");
			section = gets(parts, 0);
			keyname = process_keyname(delitem(parts, 0));
			msg = getdbl(section, keyname);
			if(msg == JSON_INVALID)
				msg = "(undefined)";
		} else {
			parts = splitnulls(action, ".");
			section = gets(parts, 0);
			if(llLinksetDataRead(section) != "") {
				keyname = process_keyname(delitem(parts, 0));
				if(argc > 2) {
					if(count(keyname) > 0) {
						if(section == "security" && user_rank != SEC_OWNER)
							jump security_fail;
						string new_value = concat(delrange(argv, 0, 1), " ");
						msg = db_set(section, keyname, new_value);
					} else {
						msg = "Did you mean to do that? For safety, you must use 'db set' to replace an entire section.";
					}
				} else {
					// msg = db_show(section, keyname);
					jump db_show;
				}
			} else {
				msg = PROGRAM_NAME + ": No section: " + action + "; see 'help db' for syntax.";
			}
		}
		
		jump security_pass;
		@db_show;
			// (section and keyname are already populated)
			string value;
			if(count(keyname)) {
				value = getdbl(section, keyname);
			} else {
				value = llLinksetDataRead(section);
			}
			
			if(value == JSON_INVALID) {
				value = "(undefined)";
			} else if(strlen(value) > 800 && count(jskeys(value))) {
				value = "(keys only) " + concat(jskeys(value), ", ");
			} else {
				value = db_show_2(value, 0);
			}
			
			if(!count(keyname))
				value = "(entire section) " + value;
			
			msg = concat([section] + keyname, ".") + " " + value;
		jump security_pass;
		@security_fail;
			msg = "Only the unit's owner may directly modify the 'security' section of the database.";
		@security_pass;
		if(msg != "")
			print(outs, user, msg);
		return;
		
	} else if(n == SIGNAL_NOTIFY) {
		if(m == PROGRAM_NAME + " file") {
			if(ins == dbload_q) {
				user = getjs(tasks_queue, [dbload_q, FILE_USER]);
				outs = getjs(tasks_queue, [dbload_q, FILE_OUTS]);
				string fn = getjs(tasks_queue, [dbload_q, FILE_NAME]);
				string unit = getjs(tasks_queue, [dbload_q, FILE_UNIT]);
				
				string result = fread(dbload_q);
				string msg;
				
				list parts;
				string section;
				list keyname;
				
				if(result == JSON_FALSE) {
					msg = "No file: " + fn;
					dbload_q = "";
				} else if(result == JSON_TRUE) {
					msg = "Loading " + getjs(tasks_queue, [dbload_q, FILE_LENGTH]) + " " + getjs(tasks_queue, [dbload_q, FILE_UNIT]);
				} else {
					list lines = split(result, "\n");
					if(unit != "l") {
						lines = alter(lines, [read_buffer + gets(lines, 0)], 0, 0);
						if(getjs(tasks_queue, [dbload_q]) == JSON_INVALID) {
							// the end of the file; last line can be trusted
							read_buffer = "";
						} else {
							read_buffer = gets(lines, LAST);
							lines = delitem(lines, LAST);
						}
					}
					integer li = 0;
					integer lmax = count(lines);
					while(li < lmax) {
						string m = llStringTrim(gets(lines, li++), STRING_TRIM_HEAD);
						if(m != "" && substr(m, 0, 0) == "#") {
							// skip comments
						} else {
							list argv = splitnulls(m, " ");
							integer mode = 0; // set
							string mode_name = llToUpper(gets(argv, 0));
							if(mode_name == "DELETE" || mode_name == "-") {
								mode = 1;
								argv = delitem(argv, 0);
							} else if(mode_name == "CREATE" || mode_name == "+") {
								mode = 2;
								argv = delitem(argv, 0);
							} else if(mode_name == "APPEND" || mode_name == "++") {
								mode = 3;
								argv = delitem(argv, 0);
								// echo(m);
							} else if(mode_name == "MERGE" || mode_name == "+=") {
								mode = 5;
								argv = delitem(argv, 0);
							} else if(mode_name == "SET" || mode_name == "=") {
								mode = 0;
								argv = delitem(argv, 0);
							} else if(mode_name == "DROP") {
								mode = 4;
								argv = delitem(argv, 0);
							}
							
							string varkey = gets(argv, 0);
							if(varkey != "") {
								string varvalue = concat(delitem(argv, 0), " ");
								keyname = split(varkey, ".");
								section = gets(keyname, 0);
								keyname = process_keyname(delitem(keyname, 0));
								string section_data = llLinksetDataRead(section);
								if(mode == 1 && section_data == "") {
									// nothing to delete
								} else if(mode == 4) {
									if(section_data != "") {
										msg += "Deleted ENTIRE section " + section + "\n";
									}
									llLinksetDataDelete(section);
								} else {
									if(section_data == "") {
										section_data = "{}";
										msg += "Created section: " + section + "\n";
									}
									
									if(mode == 1)
										varvalue = JSON_DELETE;
									else if(mode == 3)
										keyname += [JSON_APPEND];
									
									if(mode == 2 && getjs(section_data, keyname) != JSON_INVALID) {
										// value already exists; not replacing
									} else {
										// perform the update in memory:
										if(mode == 5) {
											list keys = jskeys(varvalue);
											integer ki = count(keys);
											while(ki--) {
												string k = gets(keys, ki);
												section_data = setjs(section_data, keyname + [k], getjs(varvalue, [k]));
											}
										} else {
											section_data = setjs(section_data, keyname, varvalue);
										}
										// apply the update if successful:
										if(section_data != JSON_INVALID) {
											// only commit on successful update:
											llLinksetDataWrite(section, section_data);
										} else if(mode != 1) {
											msg += "Operation failed: " + m + "\n";
										} // else DELETEs fail silently
									}
								}
							}
						}
					}
					
					if(getjs(tasks_queue, [dbload_q]) == JSON_INVALID) {
						msg += "Finished database import of " + fn
						+ "\nLSD status: " + (string)llLinksetDataCountKeys() + " sections, " + (string)llLinksetDataAvailable() + " bytes free.";
						dbload_q = "";
					}
				}
				
				if(msg != "")
					print(outs, user, msg);
			} else {
				echo("[" + PROGRAM_NAME + "] file data offered via unexpected pipe: " + (string)ins);
			}
		}
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
