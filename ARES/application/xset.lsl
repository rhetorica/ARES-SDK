/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  XSET Command (Standalone)
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
#define CLIENT_VERSION "1.2.1"
#define CLIENT_VERSION_TAGS "release"

/*
 replaces (string)  number   with (integer)number
      and (string)\"number\" with  (string)number
	  
 ... from db.lsl
*/
list process_keyname(list keyname) {
	integer ki = count(keyname);
	while(ki--) {
		string ks = gets(keyname, ki);
		if((string)((integer)ks) == ks)
			keyname = alter(keyname, [(integer)ks], ki, ki);
		else if(llOrd(ks, 0) == 0x22 && llOrd(ks, LAST) == 0x22)
			keyname = alter(keyname, [substr(ks, 1, -2)], ki, ki);
			
	}
	return keyname;
}

list pipes;
list tags;

finish(key tag) {
	integer ti = index(tags, tag);
	
	if(~ti) {
		integer r = (integer)getjs(tasks_queue, [tag, "r"]);
		key ins = getjs(tasks_queue, [tag, "ins"]);
		key outs = getjs(tasks_queue, [tag, "outs"]);
		task_end(tag);
		pipe_close([getk(pipes, ti)]);
		pipes = delitem(pipes, ti);
		tags = delitem(tags, ti);
		// resolve_io(r, outs, ins);
		resolve_i(r, ins);
		#ifdef DEBUG
			echo("xset: resolved");
		#endif
	} else {
		echo("xset: spurious receipt: " + (string)tag);
	}
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(m, " ");
		
		integer quick_mode;
		if(gets(argv, 1) == "-q") {
			quick_mode = 1;
			argv = delitem(argv, 1);
		}
		
		integer argc = count(argv);
		string msg = "";
		
		if(argc < 2) {
			msg = "Syntax: " + PROGRAM_NAME + " [-q] <variable> <command>\n\nxset WILL hang if a job returns no output at all. If this is a risk, specify -q.\n\nNew in 1.2: The command 'db json' will be detected and parsed; try also 'xset <var> = <db.value>' as a nicer alternative.";
		} else if(argc >= 3) {
			string varname = gets(argv, 1);
			string command = concat(delrange(argv, 0, 1), " ");
			
			if(gets(argv, 2) == "=" || (gets(argv, 2) == "db" && gets(argv, 3) == "json")) { // short-circuit tedious 'db json' usage
				if(gets(argv, 2) == "db")
					argv = delitem(argv, 3);
				
				string keyname = gets(argv, 3);
				list keyparts = process_keyname(split(keyname, "."));
				string value = getdbl(gets(keyparts, 0), delitem(keyparts, 0));
				if(value != JSON_INVALID) {
					setdb("env", varname, value); // not dbl
				} else {
					if(getdb("env", varname) != JSON_INVALID) // not dbl
						deletedb("env", varname); // still not dbl
				}
				
			} else {
				key tag = llGenerateKey();
				key pipe = llGenerateKey();
				pipes += pipe; // where we'll receive data from the subtask
				tags += tag; // the receipt we'll get when the subtask resolves
				
				task_begin(tag, jsobject([
					"r", _resolved, // the PID we'll report to when we're done
					"ins", ins, // input stream of initial calling environment (re-used as subtask's output stream)
					"outs", outs, // output stream of initial calling environment (not seen by subtask)
					"var", varname, // env variable we're updating
					"command", command, // the command we're executing
					"user", user, // who we're doing this for
					"done", 0, // turns to 1 once we receive DONE
					"data", quick_mode // turns to 1 once we receive data
				]));
				
				// xset ends a task when both 'done' and 'data' conditions are met
				
				pipe_open(["p:" + (string)pipe + " notify " + PROGRAM_NAME + " data"]);
				
				_resolved = 0;
			}
			
		} else {
			msg = PROGRAM_NAME + ": insufficient arguments: " + m + "; see 'help xset' for usage";
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_DONE) {
		key tag = substr(m, 0, 35);
		integer got_data = (integer)getjs(tasks_queue, [tag, "data"]);
		if(got_data) {
			finish(tag);
		} else {
			tasks_queue = setjs(tasks_queue, [tag, "done"], "1");
		}
		
	} else if(n == SIGNAL_NOTIFY) {
		list argv = splitnulls(m, " ");
		string reason = gets(argv, 1);
		if(reason == "pipe") {
			integer pi = index(pipes, ins);
			if(!~pi) {
				echo("xset: spurious pipe: " + (string)ins);
			} else {
				#ifdef DEBUG
					echo("xset: created pipe " + (string)ins);
				#endif
				key tag = getk(tags, pi);
				string varname = getjs(tasks_queue, [tag, "var"]);
				setdbl("env", [varname], "");
				
				string command = getjs(tasks_queue, [tag, "command"]);
				
				invoke(command, ins, tag, getjs(tasks_queue, [tag, "user"]));
				#ifdef DEBUG
					echo("xset: invoked " + command);
				#endif
			}
		} else if(reason == "data") {
			integer pi = index(pipes, ins);
			if(!~pi) {
				echo("xset: data from non-open pipe: " + (string)ins);
			} else {
				key tag = getk(tags, pi);
				string buffer;
				pipe_read(ins, buffer);
				
				string varname = getjs(tasks_queue, [tag, "var"]);
				#ifdef DEBUG
					echo("xset: data received for " + varname);
				#endif
				
				string current_value = getdbl("env", [varname]);
				if(current_value != "")
					current_value += "\n";
				
				setdb("env", varname, current_value + buffer);
				
				integer got_done = (integer)getjs(tasks_queue, [tag, "done"]);
				if(got_done) {
					finish(tag);
				} else {
					tasks_queue = setjs(tasks_queue, [tag, "data"], "1");
				}
			}
		} else {
			echo("xset: unexpected notify: " + m);
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		set_mode(_mode | MODE_ACCEPT_DONE);
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
