/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Personality System Module
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

#define CLIENT_VERSION "1.0.2"
#define CLIENT_VERSION_TAGS "release"

string persona = "default";

key file_pipe;
integer file_offset;
integer file_length;
list available_personas;

// for activating a persona:
key a_user;
key a_outs;

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(m, " ");
		integer argc = count(argv);
		string msg;
		if(argc == 1) {
			available_personas = js2list(llLinksetDataRead("fs:persona"));
			msg = "active persona: " + persona + "\n\npersonas available: " + concat(available_personas, ", ");
		} else {
			string action = gets(argv, 1);
			if(action == "set") {
				integer permission = sec_check(user, "persona", outs, "", m);
			
				if(permission == ALLOWED) {
					list blocked_settings = js2list(getdbl("persona", ["block"]));
					string setting = gets(argv, 2);
					if(!contains(blocked_settings, setting) && setting != "block")
						setdb("persona", setting, concat(delrange(argv, 0, 2), " "));
				} else if(permission == DENIED) {
					msg = "denied: special authorization is required to change this unit's persona";
				}
			} else if(llOrd(action, 0) == 0x2e) { // '.'
				//echo("do persona . command: " + action);
				string command = getdbl("persona", ["action", delstring(action, 0, 0)]);
				if(command != JSON_INVALID) {
					invoke("input say " + command, outs, ins, NULL_KEY);
				} else if(action == ".info") {
					string pslist = "." + concat(jskeys(getdbl("persona", ["action"])), ", .");
					if(pslist == ".")
						pslist = "(none)";
					msg = "Available actions: " + pslist;
				} else {
					msg = "Not recognized: '" + action + "'. Type '.info' for a list of available persona actions.";
				}
			} else {
				integer permission = sec_check(user, "persona", outs, "", m);
					
				if(permission == ALLOWED) {
					available_personas = js2list(llLinksetDataRead("fs:persona"));
					
					if(contains(available_personas, action)
					|| contains(available_personas, action + ".p")) {
						if(substr(action, -2, LAST) == ".p")
							action = delstring(action, -2, LAST);
						
						setdbl("m:persona", ["f"], action);
						string status_persona = action;
						
						if(status_persona == "default")
							status_persona = "";
						
						e_call(C_STATUS, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " status persona " + status_persona);
						
						string rlv_path = getdbl("persona", ["path"]);
						effector_rlv("detachall:" + rlv_path + "=force");
						
						persona = action;
						
						msg = "activating persona: " + persona;
						
						if(user != avatar)
							echo(msg);
						
						setdbl("persona", ["persona"], persona);
						a_outs = outs;
						task_begin(a_user = user, "persona");
						set_mode(_mode | MODE_ACCEPT_DONE);
						invoke("exec do " + persona + ".p", outs, ins, user);
					} else {
						#ifdef DEBUG
							msg = "bad command (no file): " + m;
						#else
							msg = "no matching persona file found: " + action;
						#endif
					}
				} else if(permission == DENIED) {
					msg = "denied: special authorization is required to change this unit's persona";
				}
			}
		}
		
		if(msg)
			print(outs, user, msg);
	} else if(n == SIGNAL_DONE) {
		if(_mode & MODE_ACCEPT_DONE) {
			set_mode(_mode & ~MODE_ACCEPT_DONE);
			task_end(a_user);
			print(a_outs, a_user, "[" + PROGRAM_NAME + "] activated " + persona);
			if(persona != "default")
				announce("persona-1");
			else
				announce("persona-0");
			string rlv_path = getdbl("persona", ["path"]);
			effector_rlv("attachallover:" + rlv_path + "=force");
		}
	
	} else if(n == SIGNAL_INIT) {
		print(outs, user, "[" + PROGRAM_NAME + "] init event");
		available_personas = js2list(llLinksetDataRead("fs:persona"));
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		print(outs, user, "[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
