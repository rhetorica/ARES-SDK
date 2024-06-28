/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Security System Module
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 1 (ASCL-i). It is offered to you on a limited basis to
 *  facilitate modification and customization.
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

integer recognition_inhibited;
integer allow_time = 30;

key name_lookup_pipe;
list name_lookup_queue;

list RANK_LIST = [0, 0, 0, "user", "manager", "owner", "self", "?"];
list RULE_TERMINOLOGY = ["nobody","all","consent","user","manager","owner","self","cycle","toggle"];

main(integer src, integer n, string m, key outs, key ins, key user) {
	@restart_main;
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string target;
		key identified_owner = getdbl("id", ["owner"]);
		integer identified_owner_affected;
		
		if(argc == 1) {
			msg = "ARES security status\n\nType '" + PROGRAM_NAME + " help' for a quick syntax guide or 'help security' for the full manual page.\n";
			print(outs, user, msg);
			
			list topics = ["ban", "guest", "user"];
			
			integer ti = 3;
			while(ti--) {
				string topic = gets(topics, ti);
				list people = jskeys(getdbl("security", [topic]));
				
				if(count(people)) {
					msg = llChar(llOrd(topic, 0) & 0x5f) + substr(topic, 1, LAST) + "s:\n";
					
					integer pi = count(people);
					while(pi--) {
						string person = gets(people, pi);
						integer pvalue = (integer)getdbl("security", [topic, person]);
						string spvalue = "indefinite";
						if(topic == "user") {
							spvalue = gets(RANK_LIST, pvalue);
						} else if(pvalue > 1600000000) {
							if(pvalue < llGetUnixTime()) {
								spvalue = "expired";
								deletedbl("security", [topic, person]);
							} else {
								spvalue = "expires in " + format_time(pvalue - llGetUnixTime());
							}
						}
						msg += " - secondlife:///app/agent/" + person + "/about (" + spvalue + ")\n";
					}
				} else {
					msg = "No " + topic + "s configured.\n";
				}
				
				llSleep(0.0625);
				print(outs, user, msg);
			}
			
			msg = "";
			
		} else {
			string topic;
			target = gets(argv, 2);
			string action = gets(argv, 1);
			
			if(action == "yes" || action == "no" || action == "trust" || action == "block") {
				key h = (key)target;
				string request = getjs(tasks_queue, [h]);
				if(user != avatar) {
					tell(user, 0, "Only the unit may respond to consent prompts.");
					
				} else if(request != JSON_INVALID) {
					key subject = getjs(request, [2]);
					key s_outs = getjs(request, [3]);
					
					string callsign = getdbl("id", ["callsign"]);
					string s_msg;
					
					if(action == "yes" && !recognition_inhibited) {
						setdbl("security", ["guest", (string)subject], (string)(llGetUnixTime() + allow_time));
						s_msg = "You have been granted access to " + callsign + " for " + (string)allow_time + " seconds.";
					} else if(action == "no") {
						setdbl("security", ["ban", (string)subject], (string)(llGetUnixTime() + allow_time));
						s_msg = "You have been denied access to " + callsign + " for " + (string)allow_time + " seconds.";
					} else if(action == "trust" && !recognition_inhibited) {
						setdbl("security", ["guest", (string)subject], "1");
						s_msg = "You have been granted access to " + callsign + " indefinitely.";
					} else if(action == "block") {
						setdbl("security", ["ban", (string)subject], "1");
						s_msg = "You have been denied access to " + callsign + " indefinitely.";
					}
					
					print(s_outs, subject, s_msg);
					
					if(recognition_inhibited && (action == "yes" || action == "trust"))
						echo("Consent failed due to radiation interference. Instruct operator to try again.");
					else
						echo("[" + PROGRAM_NAME + "] implementing consent decision (" + action + ")");
					
					string outcome;
					if(action == "no" || action == "block" || recognition_inhibited)
						outcome = getjs(request, [1]);
					else
						outcome = getjs(request, [0]);
					
					if(outcome != "")
						invoke(outcome, s_outs, NULL_KEY, subject);
					
					task_end(h);
					
					jump add_name;
				} else {
					echo("No pending consent request: " + (string)h);
				}
			} else if(action == "help") {
				msg = "Syntax: \n\n"
					+ "    " + PROGRAM_NAME + " yes|no|trust|block <key>: Respond to a consent prompt.\n"
					+ "    " + PROGRAM_NAME + " user|manager|owner <key>: Add or update a user.\n"
					+ "    " + PROGRAM_NAME + " guest|ban <key> [<time>]: Add a ban or guest, either permanently or for <time> seconds.\n"
					+ "    " + PROGRAM_NAME + " reset|runaway: Clear the unit's user list. Existing owners will be notified.\n"
					+ "    " + PROGRAM_NAME + " forget <key>: Remove a user, guest, or ban.\n"
					+ "    " + PROGRAM_NAME + " guest|ban <key> [<minutes>]: Whitelist or blacklist an avatar.\n";
				
				print(outs, user, msg);
				llSleep(0.5);
				
				msg = "    " + PROGRAM_NAME + " rules: List all security rules.\n"
				    + "    " + PROGRAM_NAME + " bolts on|off|auto|cycle: Control safety bolts (detach prevention)\n"
					+ "    " + PROGRAM_NAME + " audit: Check for missing name entries and assign self-ownership if the unit has no owner.\n"
					+ "    " + PROGRAM_NAME + " <rule> cycle|toggle|0-6: Modify a security rule.\n\n"
					+ "The new value for a security rule can be specified with a mnemonic instead of a number. ('toggle' alternates between 0 and 6.) The rule values are:\n\n"
					+ "0 (nobody): no one may do this\n"
					+ "1 (all): consent is not required to do this\n"
					+ "2 (consent): guests and all users may do this\n"
					+ "3 (user): all users may do this\n"
					+ "4 (manager): managers and owners may do this\n"
					+ "5 (owner): only owners may do this\n"
					+ "6 (self): only the unit may do this (no rank required)\n";
				
			} else if(action == "name") {
				request_name(target, outs, avatar);
			
			} else if(action == "uuid") {
				request_uuid(concat(delrange(argv, 0, 1), " "), outs, avatar);
			
			} else if(action == "rules") {
				string rules = getdbl("security", ["rule"]);
				msg = "Defined rules:\n\n" + rules;
			
			} else if(action == "user" || action == "manager" || action == "owner") {
				if(strlen(target) != 36) {
					msg = "Invalid UUID.";
					jump no_affect;
				}
				
				msg = "Give " + target + " the rank of " + action;
				
				integer current_rank = (integer)getdbl("security", ["user", target]);
				string current_rank_name = gets(RANK_LIST, current_rank);
				
				integer check = sec_check(user, "add-" + action, outs, "", m);
				
				if(check == ALLOWED) {
					if(target == user)
						current_rank = 6; // prevent self-promotion
					integer new_rank = index(RANK_LIST, action);
					if(current_rank == new_rank) {
						msg = target + " already has " + action + " authorization.";
					} else if(new_rank > current_rank) {
						setdbl("security", ["user", target], (string)new_rank);
						msg += ": success.";
						if(getdbl("security", ["guest", target]) != JSON_INVALID) {
							deletedbl("security", ["guest", target]);
							msg += " Guest entry removed.";
						}
						
						if(getdbl("security", ["ban", target]) != JSON_INVALID) {
							deletedbl("security", ["ban", target]);
							msg += " Ban removed.";
						}
						
						if(current_rank == 0)
							jump add_name;
					} else if(sec_check(user, "demote-" + current_rank_name, outs, "", m) == ALLOWED) {
						setdbl("security", ["user", target], (string)new_rank);
						msg += ": success.";
						if(target == identified_owner)
							identified_owner_affected = 1;
					} else {
						current_rank_name += "s";
						if(current_rank_name == "selfs")
							current_rank_name = "yourself";
						msg = "You do not have the authority to demote " + current_rank_name + ".";
					}
					
				} else {
					msg = "You do not have the authority to assign " + action + "s.";
				}
			
			} else if(action == "forget") {
				integer check = sec_check(user, "manage", outs, "", m);
				
				if(check == ALLOWED) {
					msg = "Deleting all knowledge of " + target + "...";
				
					list phases = ["ban", "guest", "user", "name"];
					integer pi = 4;
					while(pi--) {
						string phase = gets(phases, pi);
						string status = getdbl("security", [phase, target]);
						if(status != JSON_INVALID) {
							if(phase == "user") {
								string current_rank_name = gets(RANK_LIST, (integer)status);
								integer check = sec_check(user, "demote-" + current_rank_name, outs, "", m);
								if(check == ALLOWED) {
									msg += "\nRemoving " + current_rank_name + ".";
								} else if(target == user) {
									check = sec_check(user, "demote-self", outs, "", m);
									if(check == ALLOWED) {
										msg += "\nRemoving user's own user entry.";
									}
								}
								
								if(check == ALLOWED) {
									deletedbl("security", ["user", target]);
									if(target == identified_owner)
										identified_owner_affected = 1;
								} else {
									msg = "\nInsufficient authorization to remove " + phase + " entry.";
								}
							} else {
								deletedbl("security", [phase, target]);
								msg += "\nRemoved " + phase + " entry.";
							}
						}
					}
				} else {
					msg = "You do not have the authority to manage this unit.";
				}
				
				msg += "\nFinished.";
				
				// TODO: automatically kick RLV and remote devices
				jump remove_name;
			
			} else if(action == "guest") {
				if(user == avatar) {
					integer end_time = 1;
					
					msg = "secondlife:///app/agent/" + target + "/about is now a guest";
					
					if(argc == 4) {
						end_time = (integer)gets(argv, 3) + llGetUnixTime();
						msg += "; this will expire in " + format_time(end_time - llGetUnixTime());
					}
					
					setdbl("security", ["guest", target], (string)end_time);
					
					msg += "\nYou can cancel this at any time with: @" + PROGRAM_NAME + " forget " + target;
					
					jump add_name;
				} else {
					msg = "Only the unit may add guests.";
				}
			
			} else if(action == "ban") {
				if(sec_check(user, "manage", outs, "", m) == ALLOWED) {
					integer end_time = 1;
					
					msg = "secondlife:///app/agent/" + target + "/about is now banned";
					
					if(argc == 4) {
						end_time = (integer)gets(argv, 3) + llGetUnixTime();
						msg += "; this will expire in " + format_time(end_time - llGetUnixTime());
					}
					
					integer user_record = (integer)getdbl("security", ["user", target]);
					if(user_record) {
						deletedbl("security", ["user", target]);
						msg += "\nRevoked user access.";
					}
					
					integer guest_record = (integer)getdbl("security", ["guest", target]);
					if(guest_record) {
						deletedbl("security", ["guest", target]);
						msg += "\nRevoked guest access.";
					}
					
					setdbl("security", ["ban", target], (string)end_time);
					
					if(target != user)
						msg += "\nYou can cancel this at any time with: @" + PROGRAM_NAME + " forget " + target;
					
					// TODO: automatically kick RLV and remote devices
					jump add_name;
					
				} else {
					msg = "You do not have authorization to manage this unit.";
				}
			
			} else if(action == "reset" || action == "runaway") {
				if(sec_check(user, "run-away", outs, "", m) == ALLOWED) {
					list users = jskeys(getdbl("security", ["user"]));
					integer ui = count(users);
					string callsign = getdbl("id", ["callsign"]);
					while(ui--) {
						target = gets(users, ui);
						integer target_rank = (integer)getdbl("security", ["user", target]);
						llSetObjectName(callsign);
						if(target_rank == SEC_OWNER) {
							echo("Notifying secondlife:///app/agent/" + target + "/about...");
							llInstantMessage(target, llGetUsername(user) + " has initiated a user reset. You will no longer be recognized as an owner of " + llGetUsername(avatar) + ".");
						}
						llSetObjectName(":");
					}
				
					setdbl("security", ["user"], "{}");
					setdbl("security", ["guest"], "{}");
					setdbl("security", ["name"], "{}");
					msg = "Security reset complete. All users and guests have been cleared.";
					setdbl("security", ["user", avatar], "5");
					
					identified_owner_affected = 1;
					
					main(src, n, "security audit", outs, NULL_KEY, user);
				} else {
					msg = "You may not run away.";
				}
			} else if(action == "audit") {
				list names_missing = [];
				integer owners_found = 0;
				list phases = ["ban", "guest", "user"];
				integer pi = 3;
				while(pi--) {
					string phase = gets(phases, pi);
					list keys = jskeys(getdbl("security", [phase]));
					integer ki = count(keys);
					while(ki--) {
						target = gets(keys, ki);
						integer deleted = 0;
						if(phase == "user") {
							integer target_rank = (integer)getdbl("security", ["user", target]);
							if(target_rank == 5)
								++owners_found;
						} else {
							string user_entry = getdbl("security", ["user", target]);
							if(user_entry != JSON_INVALID) {
								msg += "\nRemoving " + phase + " entry for user secondlife:///app/agent/" + target + "/about";
								deletedbl("security", [phase, target]);
								deleted = 2;
							} else {
								integer now = llGetUnixTime();
								integer entry = (integer)getdbl("security", [phase, target]);
								if(entry != 1 && entry < now) {
									deletedbl("security", [phase, target]);
									msg += "\nRemoving expired " + phase + " entry for secondlife:///app/agent/" + target + "/about";
									deleted = 1;
								}
							}
						}
						
						string target_name = getdbl("security", ["name", target]);
						if(deleted != 1 && target_name == JSON_INVALID && !contains(names_missing, target)) {
							names_missing += target;
							// msg += "\nRequesting name of " + target;
						} else if(deleted == 1 && target_name != JSON_INVALID) {
							deletedbl("security", ["name", target]);
							// msg += "\nRemoved obsolete name entry for secondlife:///app/agent/" + target + "/about";
						}
					}
					
					// do this early so self-guest and self-ban can be removed:
					if(phase == "user") {
						if(!owners_found) {
							msg += "\nNo owners found. Granting self-ownership.";
							setdbl("security", ["user", (string)avatar], (string)SEC_OWNER);
							
							string target_name = getdbl("security", ["name", (string)avatar]);
							if(target_name == JSON_INVALID && !contains(names_missing, (string)avatar)) {
								names_missing += (string)avatar;
								// msg += "\nRequesting name of " + (string)avatar;
							}
							
							setdbl("id", ["owner"], avatar);
						}
					}
				}
				
				list name_entries = jskeys(getdbl("security", ["name"]));
				integer nei = count(name_entries);
				while(nei--) {
					target = gets(name_entries, nei);
					pi = 3;
					integer needed = 0;
					while(pi--) {
						string e = getdbl("security", [gets(phases, pi), target]);
						if(e != JSON_INVALID)
							++needed;
					}
					if(!needed) {
						deletedbl("security", ["name", target]);
						// msg += "\nRemoved spurious name entry for secondlife:///app/agent/" + target + "/about";
					}
				}
				
				if(names_missing != []) {
					name_lookup_queue += names_missing;
					if(name_lookup_pipe) {
						request_name(gets(name_lookup_queue, 0), name_lookup_pipe, avatar);
					} else {
						pipe_open(["notify " + PROGRAM_NAME + " name"]);
					}
				}
				
				if(msg == "")
					msg = "Audit completed without any issue.";
				else
					msg = "ARES security self-audit\n" + msg;
				
			} else if(action == "debug") {
				msg = "Waiting tasks: " + tasks_queue + "\n\nWaiting names: " + concat(name_lookup_queue, ", ");
			} else if((topic = getdbl("security", ["rule", action])) != JSON_INVALID) {
				// @security <rule> 0-6|cycle|toggle|nobody|all|consent|user|manager|owner|self
				msg = "The permission '" + action + "' is currently ";
				if(argc > 2) {
					// echo(msg);
					integer my_rank = (integer)getdbl("security", ["user", user]);
					if(my_rank != SEC_OWNER) {
						msg = "Only owners may adjust security rule settings. " + msg;
					} else {
						integer nact;
						// echo("target is " + target);
						if(target != (string)((integer)target)) {
							nact = index(RULE_TERMINOLOGY, target);
						} else {
							nact = (integer)target;
							if(nact > 6) {
								nact = NOWHERE;
							}
						}
						
						// echo("nact is " + (string)nact);
						
						if(~nact) {
							if(nact == 7) {
								nact = (1 + (integer)topic) % 6;
							} else if(nact == 8) {
								nact = 6 * !(integer)topic;
							}
							
							setdbl("security", ["rule", action], (string)nact);
							
							msg = "The permission '" + action + "' will be ";
							topic = (string)nact;
						} else {
							msg = "Invalid action: " + target;
							jump no_affect;
						}
					}
				}
				list responses = [
					"forbidden completely.",
					"allowed for anyone who has not been banned, without the unit's consent.",
					"allowed for guests and users. The unit will be asked to grant guest access to strangers.",
					"allowed for all registered users except guests.",
					"allowed only for managers and owners.",
					"allowed only for owners.",
					"allowed only for the unit itself, even if the unit is banned."
				];
				msg += gets(responses, (integer)topic);
			} else {
				msg = "Unknown action: " + action + ". See 'help security' for a list, or 'security rules' for the list of defined security rules.";
			}
		}
		
		jump no_name;
		@add_name;
		
		name_lookup_queue += target;
		if(name_lookup_pipe) {
			request_name(gets(name_lookup_queue, 0), name_lookup_pipe, avatar);
		} else {
			pipe_open(["notify " + PROGRAM_NAME + " name"]);
		}
		
		jump no_name;
		@remove_name;
		string target_name = getdbl("security", ["name", target]);
		if(target_name != JSON_INVALID)
			deletedbl("security", ["name", target]);
		
		@no_name;
		if(!identified_owner_affected && identified_owner != JSON_INVALID) {
			// echo("identified owner " + (string)identified_owner + " not affected");
			jump no_affect;
		}
		
		list users = js2list(getdbl("security", ["user"]));
		integer ui = count(users);
		key old_identified_owner = identified_owner;
		identified_owner = avatar;
		while(ui) {
			ui -= 2;
			integer user_rank = (integer)gets(users, ui + 1);
			if(user_rank == SEC_OWNER) {
				identified_owner = getk(users, ui);
				if(identified_owner != old_identified_owner)
					echo("[_security] Your primary owner is now secondlife:///app/agent/" + (string)identified_owner + "/about");
				jump new_owner_identified;
			}
		}
		identified_owner = JSON_INVALID;
		// echo("no identifiable owner found");
		@new_owner_identified;
		// echo("identified owner " + (string)identified_owner + " set");
		setdbl("id", ["owner"], identified_owner);
		
		@no_affect;
		
		if(msg != "") {
			print(outs, user, msg);
		}
	} else if(n == SIGNAL_NOTIFY) {
		list argv = splitnulls(m, " ");
		string action = gets(argv, 1);
		if(action == "power") {
			integer power_on = (integer)getdbl("status", ["on"]);
			
			// integer locked = (integer)getdbl("policy", ["lock"]);
			
			integer C_LIGHT_BUS;
			if(llGetAttached())
				C_LIGHT_BUS = 105 - (integer)("0x" + substr(avatar, 29, 35));
			else
				C_LIGHT_BUS = 105 - (integer)("0x" + substr(KERNEL, 29, 35));
			
			integer bolts = (integer)getdbl("status", ["bolts"]);
			if(bolts == 2)
				bolts = power_on;
			
			io_tell(NULL_KEY, C_LIGHT_BUS, "bolts " + gets(["off", "on"], bolts));
				
			if(bolts) {
				effector_restrict("bolts", "detach=?");
			} else {
				effector_release("bolts");
			}
		} else if(action == "consent") {
			list props = js2list(concat(delrange(argv, 0, 1), " "));
			props += [user, outs, llGetTime()];
			
			integer current_ban = (integer)getdbl("security", ["ban", user]);
			integer current_guest = (integer)getdbl("security", ["guest", user]);
			
			if(current_ban > 1 && current_ban < llGetUnixTime()) {
				deletedbl("security", ["ban", user]);
			} else if(current_ban) {
				// no need to consent - reject
				string deny_cmd = gets(props, 1);
				if(deny_cmd != "")
					invoke(deny_cmd, outs, NULL_KEY, user);
				return;
			}
			
			if(current_guest > 1 && current_guest < llGetUnixTime()) {
				deletedbl("security", ["guest", user]);
			} else if(current_guest) {
				// no need to consent - accept
				string retry_cmd = gets(props, 0);
				if(retry_cmd != "")
					invoke(retry_cmd, outs, NULL_KEY, user);
				return;
			}
			
			key h = llGenerateKey();
			task_begin(h, jsarray(props));
			
			/*echo("Your consent is required.\nGuest secondlife:///app/agent/" + (string)user + "/about wishes to:\n\n    "
				+ gets(props, 0)
			+ "\n\nIf you will allow this, type: security trust " + (string)h
			+ "\nOtherwise, type: security ban " + (string)h); */
			
			string command = llStringTrim(gets(props, 0), STRING_TRIM);
			string alert_msg;
			
			string name;
			
			if(object_pos(user) != ZV) {
				// definitely in sim
				if(llGetAgentSize(user) != ZV) {
					// definitely a person in the sim
					name = llGetUsername(user);
					echo("Your consent is required. "+"secondlife:///app/agent/" + (string)user + "/about"+" wants to access your system. See HUD for details.");
				} else {
					// definitely an object in the sim
					name = llKey2Name(user);
					
					echo("Your consent is required. '" + name + "' owned by "+"secondlife:///app/agent/" + (string)user + "/about"+" wants to access your system. See HUD for details.");
					
					if(name == "")
						name = "(unnamed object)";
				}
			} else {
				name = getdbl("security", ["name", user]);
				
				if(name == JSON_INVALID)
					name = "(UUID " + substr(user, 0, 7) + "...)";
				
				// avatar not in sim
				echo("Your consent is required. "+"secondlife:///app/agent/" + (string)user + "/about"+" wants to access your system. See HUD for details.");
			}
			
			if(strlen(name) > 32)
				name = substr(name, 0, 28) + "...";
			
			if(substr(command, 0, 5) == "_menu "
				|| substr(command, 0, 4) == "menu "
				|| command == "_menu"
				|| command == "menu") {
				alert_msg = name + " wants to access your menus";
			} else if(substr(command, 0, 12) == "_device auth ") {
				string device_name = gets(splitnulls(command, " "), 2);
				alert_msg = name + " wants to access your " + device_name;
			} else
				alert_msg = name + " wants to run a command: " + command;
			
			alert(alert_msg, 1, 0, 0, [
				"security yes " + (string)h,
				"security trust " + (string)h,
				"security no " + (string)h,
				"security block " + (string)h
			]);
			
		} else if(action == "memory") {
			// high radiation levels are preventing user recognition
			recognition_inhibited = (gets(argv, 2) == "n");
		} else if(action == "name") {
			if(ins == name_lookup_pipe) {
				string buffer;
				pipe_read(name_lookup_pipe, buffer);
				
				list parts = split(buffer, " = ");
				string uuid = gets(parts, 0);
				string username = gets(parts, 1);
				if(username != "") {
					// echo("[_security] assigned name " + username + " to agent " + uuid);
					setdbl("security", ["name", uuid], username);
				}
			}
			
			if(!count(name_lookup_queue)) {
				// echo("[_security] finished fetching names; retiring pipe");
				pipe_close([name_lookup_pipe]);
				name_lookup_pipe = "";
			} else {
				request_name(gets(name_lookup_queue, 0), name_lookup_pipe, avatar);
				name_lookup_queue = delitem(name_lookup_queue, 0);
			}
		} else if(action == "pipe") {
			if(count(name_lookup_queue)) {
				// echo("[_security] got pipe " + (string)ins + ": " + m);
				name_lookup_pipe = ins;
				request_name(gets(name_lookup_queue, 0), name_lookup_pipe, avatar);
				name_lookup_queue = delitem(name_lookup_queue, 0);
			} else {
				// echo("[_security] got unnecessary pipe; destroying");
				pipe_close([ins]);
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
