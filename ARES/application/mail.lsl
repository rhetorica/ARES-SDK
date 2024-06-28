/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Mail Utility
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
#define CLIENT_VERSION "1.1.1"
#define CLIENT_VERSION_TAGS "release"

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		if(argc == 1 || argc == 2) {
			msg = "Syntax: " + PROGRAM_NAME + " <address> <subject> [-b <body>]\n\nSends email to the targeted recipient. If -b is not specified, the body is read from the input stream.\n\nCaveats:\n - LSL enforces a 20-second sleep after each email is sent.\n - A given avatar may only generate 500 emails per hour.\n - Sending non-ASCII characters in the subject line may cause the email to fail entirely.\n - Only one recipient may be targeted.\n - The entire message (including all email headers) must fit in 4096 bytes, so keep it short.";
		} else {
			string recipient = gets(argv, 1);
			string subject = "(no subject)";
			string body;
			integer bi = index(argv, "-b");
			if(~bi) {
				if(bi == 1) {
					msg = "No recipient specified.";
					jump fail;
				} else if(bi > 1) {
					if(bi == argc - 1) {
						msg = "No body specified.";
						jump fail;
					}
					
					body = concat(sublist(argv, bi + 1, LAST), " ");
				
					if(bi > 2)
						subject = concat(sublist(argv, 2, bi - 1), " ");
				}
			} else if(ins == NULL_KEY || ins == user) {
				msg = "No body specified.";
				jump fail;
			} else {
				subject = concat(delrange(argv, 0, 1), " ");
				pipe_read(ins, body);
				if(body == "") {
					msg = "Empty body.";
					jump fail;
				}
			}
			
			print(outs, user, "Sending email to " + recipient + "...");
			llEmail(recipient, subject, body);
			msg = "Email sent to " + recipient + ".";
			@fail;
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
