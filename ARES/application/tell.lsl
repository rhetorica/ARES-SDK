/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Tell Command
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
#define CLIENT_VERSION "1.2.0"
#define CLIENT_VERSION_TAGS "release"

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(m, " "); // non-standard
		integer argc = count(argv);
		string msg = "";
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " <key> <channel> <message>\n\nIf <key> is 00000000-0000-0000-0000-000000000000 or 'all', sends to everyone. If <channel> is 'lights', message is sent over light bus. If <channel> is 'instant', sends using llInstantMessage(). Cannot send to everyone if channel is 0 (SL restriction). Message will originate from ring 2 via io daemon (io_tell()) unless using 'instant'.";
		} else {
			key target = gets(argv, 1);
			if(target == NULL_KEY)
				return;
			
			if(target == "all")
				target = NULL_KEY;
			integer channel;
			string raw_channel = gets(argv, 2);
			if(raw_channel == "instant") {
				llInstantMessage(target, concat(delrange(argv, 0, 2), " "));
				return;
			} else if(raw_channel == "lights") {
				if(llGetAttached())
					channel = 105 - (integer)("0x" + substr(avatar, 29, 35));
				else
					channel = 105 - (integer)("0x" + substr(KERNEL, 29, 35));
			} else {
				channel = (integer)raw_channel;
			}
			if(channel == 0 && target == NULL_KEY) {
				msg = PROGRAM_NAME + ": failed to execute '" + m + "' (may not broadcast on channel 0)";
			} else {
				io_tell(target, channel, concat(delrange(argv, 0, 2), " "));
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
