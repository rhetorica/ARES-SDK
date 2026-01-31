/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2025–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Instructor Application
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
#include <ARES/api/interface.consts.h.lsl>

#define CLIENT_VERSION "1.0.0"
#define CLIENT_VERSION_TAGS "release"

#define DEFAULT_INTERVAL 30
#define DEFAULT_ANCHOR CLADDING_BACKDROP

integer enabled = FALSE;
integer interval = DEFAULT_INTERVAL;
string section = "instruction";
integer random = FALSE;
integer anchor = DEFAULT_ANCHOR;
integer offset = 0;

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(argc == 1 || action == "help") {
			msg = "Usage: " + PROGRAM_NAME + " ...\n\n    "
				+ PROGRAM_NAME + " help: this message\n    "
			    + PROGRAM_NAME + " anchor <n>: set anchor prim (currently: " + (string)anchor + "); 0 for chat\n    "
				+ PROGRAM_NAME + " on|off|toggle: enable/disable/toggle instructor (currently: " + gets(["off", "on"], enabled) + ")\n    "
				+ PROGRAM_NAME + " interval <n>: set interval to <n> sec (currently: " + (string)interval + " sec)\n    "
				+ PROGRAM_NAME + " random|sequential: set random message selection on/off (currently: " + gets(["off", "on"], random) + ")\n    "
				+ PROGRAM_NAME + " from <section>: use LSD:<section> as input (currently: " + section + ")"
			;
		} else if(action == "anchor") {
			setdbl("instructor", ["anchor"], (string)(anchor = (integer)gets(argv, 2)));
			if(anchor < 0)
				anchor = 0;
			
		} else if(action == "on") {
			setdbl("instructor", ["enabled"], (string)(enabled = TRUE));
			set_timer("instruct", interval);
			
		} else if(action == "off") {
			setdbl("instructor", ["enabled"], (string)(enabled = FALSE));
			set_timer("instruct", 0);
			
		} else if(action == "toggle") {
			setdbl("instructor", ["enabled"], (string)(enabled = !enabled));
			if(enabled)
				set_timer("instruct", interval);
			else
				set_timer("instruct", 0);
			
		} else if(action == "interval") {
			integer new_interval = (integer)gets(argv, 2);
			if(new_interval >= 6) {
				setdbl("instructor", ["interval"], (string)(interval = new_interval));
				if(enabled)
					set_timer("instruct", interval);
				
			} else {
				msg = "Interval must be at least 6 sec. Use '@" + PROGRAM_NAME + " off' to disable instruction.";
			}
			
		} else if(action == "random") {
			setdbl("instructor", ["random"], (string)(random = TRUE));
			
		} else if(action == "sequential") {
			setdbl("instructor", ["random"], (string)(random = FALSE));
			
		} else if(action == "from") {
			string new_section = gets(argv, 2);
			if(llOrd(llLinksetDataRead(new_section), 0) == 0x5b) { // '['
				setdbl("instructor", ["section"], section = new_section);
			} else {
				msg = "Section '" + new_section + "' does not contain a JSON array.";
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		enabled = (integer)getdbl("instructor", ["enabled"]);
		random = (integer)getdbl("instructor", ["random"]);
		interval = (integer)getdbl("instructor", ["interval"]);
		string raw_anchor = getdbl("instructor", ["anchor"]);
		if(raw_anchor == JSON_INVALID) {
			setdbl("instructor", ["anchor"], (string)(anchor = DEFAULT_ANCHOR));
		} else {
			anchor = (integer)raw_anchor;
		}
		if(anchor < 0)
			anchor = 0;
		
		section = getdbl("instructor", ["section"]);
		
		if(interval == 0)
			setdbl("instructor", ["interval"], (string)(interval = DEFAULT_INTERVAL));
		
		if(enabled)
			set_timer("instruct", interval);
		
	} else if(n == SIGNAL_TIMER) {
		if(enabled) {
			integer line_count = count(js2list(llLinksetDataRead(section)));
			if(!line_count) {
				echo("[" + PROGRAM_NAME + "] no usable data in " + section + "; please fix");
				return;
			}
			
			if(random)
				offset = (integer)llFrand(0x7fffffff) % line_count;
			else
				offset = (offset + 1) % line_count;
			
			string message = getdbl(section, [offset]);
			
			if(!anchor) {
				echo(getdbl(section, [offset]));
			} else {
				vector color = getv(getp(2, [PRIM_COLOR, 1]), 0);
				
				float fade = 0;
				while(fade < 1.0) {
					if(fade >= 0.9375)
						fade = 1.0;
					setp(anchor, [
						PRIM_TEXT, message + "\n \n \n ", color, fade
					]);
					fade += 0.0625;
					llSleep(0.022);
				}
				
				fade = 1.0;
				
				llSleep(interval * 0.5 - 2);
				
				while(fade > 0.0) {
					if(fade < 0.0625)
						fade = 0.0;
					setp(anchor, [
						PRIM_TEXT, message + "\n \n \n ", color, fade
					]);
					fade -= 0.0625;
					llSleep(0.022);
				}
				
				setp(anchor, [
					PRIM_TEXT, "", ZV, 0
				]);
			}
		} else {
			set_timer("instruct", 0);
		}
		
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
