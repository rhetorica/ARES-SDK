/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Pipe Management Utility - Communications Handlers
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

		if(c == rlv_C) {
			list messages = split(m, "/");
			integer mi = count(messages);
			while(mi--) {
				string m = gets(messages, mi);
				#ifdef DEBUG
				echo("pipet: Notification: " + m);
				#endif
				
				list argv = llParseString2List(m, [":", "="], []);
				string rule = gets(argv, 0);
				if(rule == "redirchat") {
					integer channel = (integer)gets(argv, 1);
					if(channel != user_channel) {
						integer applied = (gets(argv, 2) == "n");
						if(applied) {
							// restriction is now in effect; block their channel
							
							// if this is the first redir channel, enable forwarding
							if(!count(gag_channels)) {
								notify_program("_input override-output-pipe " + rlv_pipe, NULL_KEY, avatar, avatar);
								echo("@sendchannel_sec:" + (string)user_channel + "=n");
							}
							
							echo("@sendchannel_except:" + (string)channel + "=n");
							
							gag_channels += channel;
						} else {
							// restriction has been removed; unblock their channel
							
							integer gci = index(gag_channels, channel);
							if(~gci)
								gag_channels = delitem(gag_channels, gci);
							
							echo("@sendchannel_except:" + (string)channel + "=y");
							
							// if that was the last channel, disable forwarding
							if(!count(gag_channels)) {
								notify_program("_input override-output-pipe " + NULL_KEY, NULL_KEY, avatar, avatar);
								echo("@sendchannel_sec:" + (string)user_channel + "=y");
							}
						}
					}
				}
			}
		}