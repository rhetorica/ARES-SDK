/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Policy System Module
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

list opt_de = ["disabled", "enabled"];
list opt_af = ["allowed", "forbidden"];
list opt_standard = ["off", "on", "toggle"];

integer C_LIGHT_BUS = NOWHERE;

main(integer src, integer n, string m, key outs, key ins, key user) {
	@restart_main;
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		
		string action = gets(argv, 1);
		string target = gets(argv, 2);
		
		integer result;
		
		if(argc == 1) {
			string policies = llLinksetDataRead("policy");
				
			msg = "Current policy status\n"
			+ "\nChat release: "
				+ gets(opt_af, (integer)getjs(policies, ["release"]))
			+ "\nOutfit (apparel) restriction: "
				+ gets(opt_de, (integer)getjs(policies, ["outfit"]))
			+ "\nCurfew enforcement: "
				+ gets(opt_de, (integer)getjs(policies, ["curfew", "enabled"]))
			+ "\nPrivate radio communications: "
				+ getjs(policies, ["radio"])
			/*+ "\nDistress beacon: "
				+ gets(opt_de, (integer)getjs(policies, ["beacon", "enabled"]))*/
			+ "\nAuto-Lock: "
				+ gets(opt_de, (integer)getjs(policies, ["autolock", "enabled"]))
			+ "\nSafety bolts: "
				+ gets(opt_de, (integer)getdbl("status", ["bolts"]));
		} else if(action == "help") {
			string selfname = gets(argv, 0);
			msg = "Syntax:\n";
				selfname + " help: This message\n" +
				selfname + " bolts [on|off|auto|cycle]: control anti-theft safety bolts\n" +
				selfname + " outfit|apparel [on|off|toggle]: control apparel (outfit) enforcement\n" +
				selfname + " curfew [on|off|toggle]: control curfew enforcement\n" +
				selfname + " curfew time <hhnn>: set curfew time to hh:nn SLT (24-hour clock); 0 = midnight\n" +
				selfname + " curfew home <SLURL|here>: set curfew home\n";
			print(outs, user, msg);
			llSleep(0.5);
			msg =
				selfname + " radio [open|closed|receive|transmit|cycle]: control radio policy\n" +
				selfname + " release [on|off|toggle]: block chat release\n" +
				selfname + " autolock [on|off|toggle]: control Auto-Lock\n" +
				selfname + " autolock time <secs>: automatically lock after <secs> time\n" +
				selfname + " lock: lock local commands and menu, preventing access\n" +
				selfname + " unlock <password>: unlock\n" +
				selfname + " password <password>: change lock password\n";
		} else if(action == "beacon") {
			msg = "The distress beacon is not yet implemented.";
		} else if(action == "lock") {
			string password = getdbl("policy", ["password"]);
			if(password == "" || password == JSON_INVALID) {
				m = "* unlock";
				jump restart_main;
			} else {
				setdbl("policy", ["lock"], "1");
				msg = "Unit locked.";
				
				announce("lock-1");
				io_tell(NULL_KEY, C_LIGHT_BUS, "locked");
				notify_program("security power", outs, NULL_KEY, user);
			}
			
		} else if(action == "unlock") {
			string password = getdbl("policy", ["password"]);
			string attempt = concat(delrange(argv, 0, 1), " ");
			if(password == "" || password == JSON_INVALID) {
				msg = "Cannot lock console: no password set.";
				setdbl("policy", ["lock"], "0");
				announce("lock-0");
				io_tell(NULL_KEY, C_LIGHT_BUS, "unlocked");
				notify_program("security power", outs, NULL_KEY, user);
			} else if(attempt != password) {
				msg = "Incorrect password.";
				announce("denied");
				io_tell(NULL_KEY, C_LIGHT_BUS, "locked");
			} else {
				msg = "Unlocked.";
				setdbl("policy", ["lock"], "0");
				announce("lock-0");
				io_tell(NULL_KEY, C_LIGHT_BUS, "unlocked");
				notify_program("security power", outs, NULL_KEY, user);
			}
		} else {
			integer check = sec_check(user, "manage", outs, m, m);
			
			if(check == DENIED) {
				msg = "Authorization denied.";
			} else if(check == ALLOWED) {
				if(action == "bolts") {
					integer bolts = (integer)getdbl("status", ["bolts"]);
					if(target == "on") {
						bolts = 1;
					} else if(target == "off") {
						bolts = 0;
					} else if(target == "auto") {
						bolts = 2;
					} else if(target == "cycle") {
						bolts = (bolts + 1) % 3;
					}
					
					setdbl("status", ["bolts"], (string)bolts);
					msg = "Safety bolts are now " + gets(["disengaged", "always engaged", "engaged only while the unit is powered on"], bolts) + ".";
					
					notify_program("security power", outs, NULL_KEY, user);
					
				} else if(action == "outfit" || action == "apparel") {
					result = (integer)getdbl("policy", ["outfit"]);
					if(contains(opt_standard, target)) {
						setdbl("policy", ["outfit"],
							(string)(result = geti([0, 1, !result],
							index(opt_standard, target)))
						);
						msg = "Changing outfits is now " + gets(opt_af, result) + ".";
						
						if(result)
							effector_restrict("policy_apparel", "unsharedwear=?,unsharedunwear=?");
						else
							effector_release("policy_apparel");
						
					} else {
						msg = "Changing outfits is " + gets(opt_af, result) + ".";
					}
				} else if(action == "release") {
					result = (integer)getdbl("policy", ["release"]);
					if(contains(opt_standard, target)) {
						setdbl("policy", ["release"],
							(string)(result = geti([0, 1, !result],
							index(opt_standard, target)))
						);
						msg = "Releasing chat is now " + gets(opt_af, result) + ".";
						notify_program("input release " + gets(["y", "n"], result), outs, NULL_KEY, user);
						
					} else {
						msg = "Releasing chat is " + gets(opt_af, result) + ".";
					}
					
				} else if(action == "curfew") {
					result = (integer)getdbl("policy", ["curfew", "enabled"]);
					if(contains(opt_standard, target)) {
						setdbl("policy", ["curfew", "enabled"],
							(string)(result = geti([0, 1, !result],
							index(opt_standard, target)))
						);
						msg = "Curfew enforcement is now " + gets(opt_de, result) + ".";
						
					} else {
						msg = "Curfew enforcement is " + gets(opt_de, result) + ".";
						if(result)
							msg += " The unit must be near " + getdbl("policy", ["curfew", "home"])
								 + " at " + getdbl("policy", ["curfew", "time"]) + " SLT, or it will be teleported there.";
					}
					
					// TODO: actual effects
					
					
				} else if(action == "radio") {
					list opt_radio = ["open", "closed", "receive", "transmit"];
					/* list radio_explanation = [
						"The unit may IM anyone, provided it has power and is not otherwise restricted.",
						"The unit may not IM anyone except registered users.",
						"The unit may only send IMs to registered users. Anyone may IM it.",
						"The unit may only receive IMs from registered users. It may IM anyone."
					]; */
					
					string current_radio = getdbl("policy", ["radio"]);
					integer ri = index(opt_radio, current_radio);
					
					if(target == "cycle" || contains(opt_radio, target)) {
						if(target == "cycle") {
							current_radio = gets(opt_radio, ri = ((ri + 1) % 4));
						} else {
							current_radio = target;
						}
						setdbl("policy", ["radio"], current_radio);
						
						msg = "Private radio communications are now in '" + current_radio + "' mode."; // + gets(radio_explanation, ri);
						
						// TODO: actual effects
						
					} else {
						msg = "Private radio communications are in '" + current_radio + "' mode."; // + gets(radio_explanation, ri);
					}
				} else if(action == "password") {
					string password = concat(delrange(argv, 0, 1), " ");
					if(password == "NONE" || password == "none")
						password = "";
					setdbl("policy", ["password"], password);
					if(password == "") {
						msg = "Lock password removed.";
						setdbl("policy", ["autolock", "enabled"], "0");
						set_timer("autolock", 0); // shouldn't be possible; disable
					} else {
						msg = "Lock password is now: " + password;
					}
				} else if(action == "autolock") {
					string password = getdbl("policy", ["password"]);
					result = (integer)getdbl("policy", ["autolock", "enabled"]);
					if(contains(opt_standard, target)) {
						if(password == "" || password == JSON_INVALID) {
							msg = "You must set a password to enable Auto-Lock.";
							setdbl("policy", ["autolock", "enabled"], "0");
							set_timer("autolock", 0);
						} else {
							setdbl("policy", ["autolock", "enabled"],
								(string)(result = geti([0, 1, !result],
								index(opt_standard, target)))
							);
							msg = "Auto-Lock is now " + gets(opt_de, result) + ".";
							
							if(result) {
								integer time = (integer)getdbl("policy", ["autolock", "time"]);
								set_timer("autolock", time);
							} else {
								set_timer("autolock", 0);
							}
						}
						
					} else if(target == "time") {
						integer time = (integer)getdbl("policy", ["autolock", "time"]);
						target = gets(argv, 3);
						if(target != "") {
							if((integer)target < 15)
								target = "15";
							
							setdbl("policy", ["autolock", "time"],
							(string)(time = (integer)target));
							
							integer result = (integer)getdbl("policy", ["autolock", "enabled"]);
							if(result) {
								set_timer("autolock", time);
							}
						}
						msg = "Auto-Lock will now activate after " + (string)time + " seconds of inactivity.";
						
					} else {
						msg = "Auto-Lock is " + gets(opt_de, result) + ".";
					}
				} else {
					msg = "Unknown action: " + action;
				}
			} // check allowed
		} // argc > 1

		if(msg != "") {
			print(outs, user, msg);
		}
	} else if(n == SIGNAL_NOTIFY) {
		if(gets(split(m, " "), 1) == "delay") {
			integer time = (integer)getdbl("policy", ["autolock", "time"]);
			integer result = (integer)getdbl("policy", ["autolock", "enabled"]);
			if(result) {
				set_timer("autolock", time); // push back time
				// echo("(delaying autolock)");
			} else {
				set_timer("autolock", 0); // clear any errant messages
			}
		} else {
			echo("[" + PROGRAM_NAME + "] " + m + "?");
		}
	} else if(n == SIGNAL_TIMER) {
		if(m == "autolock") {
			integer time = (integer)getdbl("policy", ["autolock", "time"]);
			integer result = (integer)getdbl("policy", ["autolock", "enabled"]);
			string password = getdbl("policy", ["password"]);
			if(result) {
				if(password == "" || password == JSON_INVALID)  {
					setdbl("policy", ["autolock", "enabled"], "0");
					set_timer("autolock", 0); // shouldn't be possible; disable
				} else {
					integer locked = (integer)getdbl("policy", ["lock"]);
					if(!locked) {
						setdbl("policy", ["lock"], "1");
						announce("lock-1");
						io_tell(NULL_KEY, C_LIGHT_BUS, "locked");
						notify_program("security power", outs, NULL_KEY, user);
					}
					set_timer("autolock", time); // set next time
				}
			} else {
				set_timer("autolock", 0); // clear any errant messages
			}
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		
		if(llGetAttached())
			C_LIGHT_BUS = 105 - (integer)("0x" + substr(avatar, 29, 35));
		else
			C_LIGHT_BUS = 105 - (integer)("0x" + substr(KERNEL, 29, 35));
		
		if((integer)getdbl("policy", ["outfit"]))
			effector_restrict("policy_apparel", "unsharedwear=?,unsharedunwear=?");
		else
			effector_release("policy_apparel");
		
		integer time = (integer)getdbl("policy", ["autolock", "time"]);
		if((integer)getdbl("policy", ["autolock", "enabled"]))
			set_timer("autolock", time); // set next time
		
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
