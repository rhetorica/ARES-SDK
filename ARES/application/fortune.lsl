/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  fortune Utility
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
#define CLIENT_VERSION "0.2.5"
#define CLIENT_VERSION_TAGS "alpha"

// LICENSING CAVEAT: Do not use the myNanite fortune server URL outside of ARES packages. It has been placed in a separate file for clarity. For your own applications using different websites, you can just replace this line with: #define URL "<whatever>"
#include "ARES/application/fortune.h.lsl"

list queue; // = [command, outs, ins, user, r, transport_pipe];

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(action == "help" || action == "-?" || action == "--help" || action == "/?" || action == "-h" || action == "/h") {
			msg = "Syntax: " + PROGRAM_NAME + " <parameters>\n\nDisplays fortunes from the myNanite GNU fortune server.\n\nSee https://linux.die.net/man/6/fortune for a list of available options, and 'help fortune' for the list of available fortune files.";
		} else {
			string command = "proc fetch " + URL + llEscapeURL(concat(delitem(argv, 0), " "));
			key handle = llGenerateKey();
			
			pipe_open(["p:" + (string)handle + " notify " + PROGRAM_NAME + " data"]);
			queue += [command, outs, ins, user, _resolved, handle];
			_resolved = 0;
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		string action = gets(argv, 1);
		if(action == "data") {
			string buffer;
			pipe_read(ins, buffer);
			
			integer qi = index(queue, ins);
			if(~qi) {
				// some fortunes contain terminal control codes that SL just can't replicate:
				list subs = [
					llChar(0x09), "    ", // tab
					llChar(0x7f), "<-", // delete
					llChar(0x08), "<-" // backspace
				];
				integer subi = count(subs);
				while(subi > 0) {
					subi -= 2;
					buffer = replace(buffer, gets(subs, subi), gets(subs, subi + 1));
				}
				
				print(gets(queue, qi - 4), gets(queue, qi - 2), buffer);
				// resolve_io((integer)gets(queue, qi - 1), gets(queue, qi - 4), gets(queue, qi - 3));
				resolve_i((integer)gets(queue, qi - 1), gets(queue, qi - 3));
				queue = delrange(queue, qi - 5, qi);
			}
			
			pipe_close([ins]);
		
		} else if(action == "pipe") {
			integer qi = index(queue, ins);
			if(~qi) {
				key user = gets(queue, qi - 2);
				string command = gets(queue, qi - 5);
				
				notify_program(command, ins, NULL_KEY, user);
			} else {
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
