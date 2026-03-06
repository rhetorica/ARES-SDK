/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Pipe Management Utility
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
#define CLIENT_VERSION "0.0.1"
#define CLIENT_VERSION_TAGS "placeholder"

integer extend_rlv;

// listener for this must be in same prim:

// 'PIPE':
#define rlv_C 0x50495045
integer rlv_L;

#define rlv_pipe "50495045-0000-0000-0000-000000000000"

list gag_channels = [];

integer user_channel = 7770;

update_extend_rlv() {
	if(!extend_rlv) {
		pipe_close([rlv_pipe]);
		echo("@notify:" + (string)rlv_C + ";redir=y");
		llListenRemove(rlv_L);
		rlv_L = 0;
		integer gci = count(gag_channels);
		while(gci--) {
			integer c = geti(gag_channels, gci);
			echo("@sendchannel_except:" + (string)c + "=y");
		}
		echo("@sendchannel_sec:" + (string)user_channel + "=y");
		
		gag_channels = [];
	} else {
		user_channel = (integer)getdbl("input", ["channel"]);
		pipe_open(["p:" + rlv_pipe + " permanent " + PROGRAM_NAME]);
		echo("@getstatusall:redir=" + (string)rlv_C);
		echo("@notify:" + (string)rlv_C + ";redir=n");
		rlv_L = llListen(rlv_C, "", avatar, ""); 
	}
}

list queued_actions = []; // outs, user

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		if(ins == rlv_pipe) {
			string payload = read(ins);
			integer gci = count(gag_channels);
			if(gci) {
				while(gci--) {
					tell(avatar, geti(gag_channels, gci), payload);
				}
			} else {
				echo("[" + PROGRAM_NAME + "] error: received input message while no redirects were active");
				print(OUTPUT_SAY, user, payload);
			}
		} else {
			list argv = splitnulls(m, " ");
			integer argc = count(argv);
			string msg = "";
			string action = gets(argv, 1);
			if(action == "help") {
				msg = PROGRAM_NAME + " version " + CLIENT_VERSION + " (" + CLIENT_VERSION_TAGS + ")"
					+ "\nUsage: " + PROGRAM_NAME + " <action> [<arguments>]"
					+ "\nSupported actions:"
					+ "\n    help: this message"
					+ "\n    list: show current pipes (default action)"
					+ "\n    open <spec> [\"|\" <spec> ...]: open one or more new pipes"
					+ "\n    close <uuid> [<uuid> ...]: close one or more pipes"
					+ "\n    extend <last> <next>: direct output from <last> to <next>"
					+ "\n    print <uuid> <text>: print text to target pipe"
					+ "\n    rlv on|off|toggle: controls automatic extension of chat output into RLV devices (gag compatibility mode)"
					+ "\nFormat for <spec>:"
					+ "\n    [p:<uuid>] [n:<uuid>] <args>"
					+ "\nwhere:"
					+ "\n    p:<uuid> assigns a static identifier to the pipe (otherwise one will be generated)"
					+ "\n    n:<uuid> assigns the identifier of the next pipe (if absent on last pipe created, defaults to null)"
					+ "\n\nIn most situations, <args> should be the word 'permanent' followed by the command you wish to invoke. For full documentation, see: @help " + PROGRAM_NAME
				;
			} else if(action == "list" || argc == 1) {
				e_call(C_IO, E_SIGNAL_VOX, (string)outs + " " + (string)user + " debug");
				
				/*if(argc == 2) {
					
				} else {
					e_call(C_IO, E_SIGNAL_VOX, (string)outs + " " + (string)user + " " + concat(delrange(argv, 0, 1), " "));
				}
				*/
			} else if(action == "rlv") {
				if(argc == 2)
					msg = "RLV extension mode is " + gets(["off", "on"], extend_rlv) + ".";
				else {
					string subaction = gets(argv, 2);
					if(subaction == "on")
						extend_rlv = 1;
					else if(subaction == "off")
						extend_rlv = 0;
					else if(subaction == "toggle")
						extend_rlv = !extend_rlv;
					else {
						msg = "Unknown option: " + subaction;
						jump done_rlv;
					}
					
					setdbl("pipet", ["rlv"], (string)extend_rlv);
					update_extend_rlv();
				}
				@done_rlv;
			} else if(action == "print") {
				print(getk(argv, 2), user, concat(delrange(argv, 0, 2), " "));
			} else if(action == "open") {
				if(argc == 2) {
					msg = "Incorrect number of arguments: " + m;
				} else {
					queued_actions += [outs, user];
					list pipes = split(concat(delrange(argv, 0, 1), " "), "|");
					pipe_open(pipes);
				}
			} else if(action == "close") {
				if(argc == 2) {
					msg = "Incorrect number of arguments: " + m;
				} else {
					list pipes = delrange(argv, 0, 1);
					pipe_close(pipes);
				}
			} else if(action == "extend") {
				if(argc == 4) {
					string old = gets(argv, 2);
					string new = gets(argv, 3);
					pipe_extend(old, new);
				} else {
					msg = "Incorrect number of arguments: " + m;
				}
			}
			
			if(msg != "")
				print(outs, user, msg);
		}
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string action = gets(argv, 1);
		if(action == "pipe") {
			if(ins != rlv_pipe) {
				outs = getk(queued_actions, 0);
				user = getk(queued_actions, 1);
				queued_actions = delrange(queued_actions, 0, 1);
				print(outs, user, (string)ins);
			}
		} else {
			echo("?" + m);
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		
		extend_rlv = (integer)getdbl("pipet", ["rlv"]);
		update_extend_rlv();
		
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#define EXT_COM_HANDLER "ARES/application/pipet.com.lsl"
#include <ARES/program>
