/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  PATH Filesystem Communications Handlers
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
 
	if(c == C_PHASE_PROTOCOL) {
		list argv = split(m, " ");
		string handle = gets(argv, 0);
		string cmd = gets(argv, 1);
		
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] received: " + m);
		#endif
		if(cmd == "connect") { // <handle> connect <mode> [<callback>]
			if(handle == NULL_KEY) {
				tell(id, c, handle + " version " + IMPLEMENTATION + " " + DISK_LABEL);
			} else {
				string mode = gets(argv, 2);
				if(mode != "ro" && mode != "rw" && mode != "rd") {
					tell(id, c, handle + " denied");
				} else {
					key who = llGetOwnerKey(id);
					
					#ifdef NO_WRITE
					if(mode == "rw")
						mode = "rd";
					#endif
					
					invoke(PROGRAM_NAME + " connect " + mode + " " + (string)id + " " + handle + " " + gets(argv, 3), who, NULL_KEY, who);
				}
			}
		} else if(getjs(hosts, [(string)id]) != JSON_INVALID) {
			integer permissions = (integer)getjs(hosts, [(string)id, 1]);
			if(cmd == "disconnect") { // <handle> disconnect
				disconnect(id);
			} else if(cmd == "callback") { // <handle> callback <callback-url>
				hosts = setjs(hosts, [(string)id, 2], gets(argv, 2));
			}
		} else if(cmd != "denied" && cmd != "reset") {
			// not connected:
			tell(id, c, handle + " denied");
		}
	}