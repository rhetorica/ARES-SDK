/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Main Controller Firmware - Autoexec Sideloader
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

#include <utils.lsl>
#include <objects.lsl>

/*
	GENERIC AUTOEXEC SIDELOADER
	
	This code can and should be merged into the controller-specific screen/hatch script to ensure that there is only one link_message() handler in the main controller's hardware.
*/

key system;
key avatar;
integer CL;

#define AUTOEXEC_FILENAME "autoexec.as"
string system_version;
integer autoexec_line;
key autoexec_q;

default {
	dataserver(key id, string m) {
		if(id == autoexec_q) {
			while(m != NAK && m != EOF) {
				if(llStringTrim(m + "a", STRING_TRIM) != "a" && substr(m, 0, 0) != "#") {
					m = replace(m, "$version", system_version);
					tell(system, CL, "command " + (string)avatar + " " + (string)avatar + " exec " + m);
					llSleep(0.5);
				}
				
				m = llGetNotecardLineSync(AUTOEXEC_FILENAME, ++autoexec_line);
			}
			if(m == NAK)
				autoexec_q = llGetNotecardLine(AUTOEXEC_FILENAME, ++autoexec_line);
			else {
				echo("autoexec parsing complete");
				tell(system, CL, "conf-get id.callsign");
			}
		}
	}

	link_message(integer src, integer n, string m, key id) {
		if(n == 1) {
			list argv = split(m, " ");
			string cmd = gets(argv, 0);
			if(cmd == "sideload") {
				system = id;
				
				system_version = gets(argv, 1);
				// truncate version to major.minor.revision:
				system_version = concat(sublist(split(system_version, "."), 0, 2), ".");
				
				CL = 105 - (integer)("0x" + substr(avatar = llGetOwner(), 29, 35));
				
				autoexec_q = llGetNotecardLine(AUTOEXEC_FILENAME, autoexec_line = 0);
			}
		}
	}
}