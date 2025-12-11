/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Dispatch Program
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
#define CLIENT_VERSION "0.1.1"
#define CLIENT_VERSION_TAGS "alpha"

integer charging;
integer ext_repairing;
integer auto_repairing;
float charge_ratio = 0.75;
float integrity = 1.0;
integer power_on = 1;

string supported_triggers = "{
	\"shutdown\":\"\",
	\"boot\":\"\",
	\"power-10\":\"\",
	\"power-20\":\"\",
	\"power-up\":\"\",
	\"power-100\":\"\",
	\"charge-start\":\"\",
	\"charge-end\":\"\",
	\"autorepair-start\":\"\",
	\"autorepair-end\":\"\",
	\"ext-repair-start\":\"\",
	\"ext-repair-end\":\"\",
	\"integrity-100\":\"\",
	\"device-add\":\"\",
	\"device-remove\":\"\",
	\"guest-allow\":\"\",
	\"guest-reject\":\"\",
	\"region-change\":\"\",
	\"teleport\":\"\"
}";

list e_map = [
	EVENT_TELEPORT, "teleport",
	EVENT_NEW_DEVICE, "device-add",
	EVENT_REMOVE_DEVICE, "device-remove",
	EVENT_REGION_CHANGE, "region-change"
];

event_trigger(string e_name, string e_args, key outs, key user) {
	string command = getjs(supported_triggers, [e_name]);
	if(command != "" && command != JSON_INVALID) {
		if(e_args != "")
			command += " " + e_args;
		invoke(command, outs, NULL_KEY, user);
	}
	#ifdef DEBUG
	else {
		echo("[" + PROGRAM_NAME + "] no action configured for event " + e_name);
	}
	#endif
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(argc == 1 || action == "help") {
			list event_names = jskeys(supported_triggers);
			msg = "Syntax: " + PROGRAM_NAME + " on <event> <command>|nothing\nwhere <command> is a system command without the @ prefix and <event> is one of: " + concat(event_names, ", ");
		} else if(action == "on") {
			string e = gets(argv, 2);
			string cmd = concat(delrange(argv, 0, 2), " ");
			if(getjs(supported_triggers, [e]) != JSON_INVALID) {
				if(cmd == "nothing")
					cmd = "";
				
				string new_supported_triggers = setjs(supported_triggers, [e], cmd);
				if(new_supported_triggers == JSON_INVALID) {
					msg = "Error: command '" + cmd + "' contains unencodable characters";
				} else {
					if(cmd != "")
						msg = "Updated event mapping.";
					else
						msg = "Removed event mapping.";
					
					setdbl("dispatch", ["trigger"], supported_triggers = new_supported_triggers);
				}
			} else {
				msg = "Unsupported event: " + e + ".";
			}
		} else {
			msg = "Run '@" + PROGRAM_NAME + " help' for instructions.";
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_EVENT || n == SIGNAL_TIMER) {
		list argv = splitnulls(m, " ");
		integer ei = (integer)gets(argv, 0);
		
		string e_name;
		
		if(ei != EVENT_WARNING && n != SIGNAL_TIMER) {
			e_name = gets(e_map, index(e_map, ei) + 1);
		} else {
			integer sloti = (integer)gets(argv, 1);
			argv = [];
			
			if(sloti == 7 || n == SIGNAL_TIMER) {
				integer new_charging = (integer)getdbl("status", ["charging"]);
				float new_charge_ratio = (float)getdbl("status", ["charge-ratio"]);
				
				string power_event;
				
				if(new_charge_ratio > 0.99 && charge_ratio <= 0.99) {
					power_event = "power-100";
				} else if(new_charge_ratio > 0.20 && charge_ratio <= 0.20) {
					power_event = "power-up";
				} else if((new_charge_ratio <= 0.20 && charge_ratio > 0.20)
				        || (new_charge_ratio > 0.10 && charge_ratio <= 0.10)) {
					power_event = "power-20";
				} else if(new_charge_ratio <= 0.10 && charge_ratio > 0.10) {
					power_event = "power-10";
				}
				
				if(charging != new_charging) {
					if(charging) {
						e_name = "charge-end";
					} else {
						e_name = "charge-start";
					}
				}
				
				if(power_event != "")
					event_trigger(power_event, "", avatar, avatar);
				
				charge_ratio = new_charge_ratio;
				charging = new_charging;
				
			} else if(sloti == 0 || n == SIGNAL_TIMER) {
				integer new_ext_repairing = (integer)getdbl("repair", ["ext-repair"]);
				integer new_auto_repairing = (integer)getdbl("repair", ["autorepairing"]);
				float new_integrity = (float)getdbl("repair", ["integrity"]);
				
				if(new_integrity == 1.00 && integrity < 1.00) {
					event_trigger("integrity-100", "", avatar, avatar);
				}
				
				if(new_ext_repairing != ext_repairing) {
					string exte;
					if(new_ext_repairing)
						exte = "ext-repair-start";
					else
						exte = "ext-repair-end";
					
					event_trigger(exte, "", avatar, avatar);
				}
				
				if(new_auto_repairing != auto_repairing) {
					if(new_auto_repairing)
						e_name = "autorepair-start";
					else
						e_name = "autorepair-end";
				}
				
				integrity = new_integrity;
				ext_repairing = new_ext_repairing;
				auto_repairing = new_auto_repairing;
			}
		}
		
		if(e_name != "") {
			event_trigger(e_name, concat(delitem(argv, 0), " "), avatar, avatar);
		}
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string action = gets(argv, 1);
		if(action == "power") {
			integer new_power_on = (integer)getdbl("status", ["on"]);
			if(new_power_on != power_on) {
				power_on = new_power_on;
				if(power_on) {
					event_trigger("boot", "", outs, user);
				} else {
					event_trigger("shutdown", "", outs, user);
				}
			}
		} else if(action == "security") {
			string subaction = gets(argv, 2);
			if(subaction == "yes" || subaction == "trust") {
				event_trigger("guest-allow", "", outs, user);
			} else if(subaction == "no" || subaction == "block") {
				event_trigger("guest-reject", "", outs, user);
			}
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init signal");
		#endif
		hook_events([
			EVENT_WARNING
		] + llList2ListStrided(e_map, 0, LAST, 2));
		
		string new_supported_triggers = getdbl("dispatch", ["trigger"]);
		if(new_supported_triggers == JSON_INVALID) {
			setdbl("dispatch", ["trigger"], supported_triggers);
		} else {
			supported_triggers = new_supported_triggers;
		}
		
		set_timer("dispatch", 5);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
