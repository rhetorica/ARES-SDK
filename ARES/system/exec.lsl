/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Exec System Module
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
#define CLIENT_VERSION ARES_VERSION
#define CLIENT_VERSION_TAGS ARES_VERSION_TAGS

// it's good enough for real computers:
#define NON_VOLATILE
#define LEGACY_NON_VOLATILE
#define DAEMON_LISTEN

#ifdef TRACE
integer trace;
#endif
string file_name;
integer file_offset;
integer file_length;
string file_unit;
key file_pipe;
key file_outs;
key file_user;
string script;
list script_lines;
integer script_li;
key script_handle = NULL_KEY; // don't continue executing a script until we get a suitable DONE back

string expression(list tokens) {
	if((string)tokens == "undefined")
		return JSON_INVALID;
	
	float value = (float)gets(tokens, 0);
	integer ki = 1;
	integer kmax = count(tokens);
	while(ki < kmax) {
		string op = gets(tokens, ki);
		float r = (float)gets(tokens, ki + 1);
		if(op == "!=") {
			value = (float)(llFabs(value - r) >= 0.001);
		} else if(op == "==") {
			value = (float)(llFabs(value - r) < 0.001);
		} else if(op == ">") {
			value = (float)((value - r) > 0.001);
		} else if(op == "<") {
			value = (float)((r - value) > 0.001);
		} else if(op == ">=") {
			value = (float)((value - r) > -0.001);
		} else if(op == "<=") {
			value = (float)((r - value) > -0.001);
		} else if(op == "+") {
			value += r;
		} else if(op == "-") {
			value -= r;
		} else if(op == "*") {
			value *= r;
		} else if(op == "%") {
			value = (float)((integer)value % (integer)r);
		} else if(op == "**") {
			value = llPow(value, r);
		} else if(op == "/" || op == "\\") {
			if(r != 0) {
				value /= r;
			} else {
				echo("[_exec] division by 0 in expression: " + concat(tokens, " "));
				return "0";
			}
			if(op == "\\")
				value = (integer)value;
		} else {
			echo("[_exec] unknown operator '" + op + "' in expression: " + concat(tokens, " "));
			return "0";
		}
		ki += 2;
	}
	
	// return integer if within a thousandth:
	if(llFabs((float)((integer)value) - value) < 0.001)
		return (string)((integer)value);
	else
		return (string)value;
}

#ifdef PIPES
string pipe_queue = "{}"; // {handle:[[commands], outs, ins, user, rc, [pipe-keys]]} - will replace script handle
#endif

integer process_input(key outs, key handle, key user, string cml, integer in_script) {
	@internal_restart;
	if(in_script)
		script_handle = handle = llGenerateKey();
	
	#ifdef TRACE
	if(trace)
		echo(" >> " + cml);
	#endif
	
	string first = substr(cml, 0, 0);
	string second = substr(cml, 0, 1);
	
	if(~strpos(cml, "\\n"))
		cml = replace(cml, "\\n", "\n");
	
	// =======================================
	// shell control commands
	// =======================================
	
	integer varpos = strpos(cml, "$");
	
	if(~varpos) {
		integer vi = varpos;
		integer vL = strlen(cml);
		string varacc;
		integer vaL = 0;
		integer vaStart;
		integer vp_state = 0;
		while(vi < vL) {
			integer vc = llOrd(cml, vi);
			++vi;
			if(vc == 0x24 && vp_state == 0) { // '$'
				if(llOrd(cml, vi - 2) == 0x5c) { // '\'
					cml = delstring(cml, vi - 2, vi - 2);
					--vi;
					--vL;
				} else {
					varacc = "";
					vaL = 0;
					vaStart = vi - 1;
					vp_state = 1;
				}
			} else if(vp_state == 1) {
				integer vd = llOrd(cml, vi);
				//if(vc == 0x2e) echo((string)vd);
				if((vc >= 0x41 && vc <= 0x5a) // uppercase
				   || (vc >= 0x61 && vc <= 0x7a) // lowercase
				   || vc == 0x5f || vc == 0x2d // _ and -
				   || (vaL > 0 && vc == 0x2e && (vd >= 0x61 && vd <= 0x7a)) // . followed by lowercase letter
				   || (vaL > 0 && vc == 0x2e && (vd >= 0x30 && vd <= 0x39)) // . followed by digit
				   || (vaL > 0 && (vc >= 0x30 && vc <= 0x39))) { // digits if non-first
					varacc += llChar(vc);
					// echo("added " + (string)vc);
					++vaL;
				} else {
					vp_state = 0;
				}
				
				if(vi == vL && vp_state) {
					vp_state = 0; // end automatically at string end
					++vi;
				}
			}
			
			if(vaL && vp_state == 0) {
				// echo("subbing in " + varacc);
				string sub;
				if(varacc == "name") {
					sub = llGetDisplayName(user);
				} else if(varacc == "user") {
					sub = (string)user;
				} else if(varacc == "self") {
					sub = (string)avatar;
				} else if(varacc == "me") {
					sub = getdbl("id", ["callsign"]);
				} else {
					sub = getdbl("env", split(varacc, "."));
				}
				cml = delstring(cml, vaStart, vi - 2);
				cml = llInsertString(cml, vaStart, sub);
				vi -= vaL;
				vi += strlen(sub) - 2;
				vL = strlen(cml);
				vaStart = 0;
				vaL = 0;
				varacc = "";
			}
		}
	}

	list cargv = splitnulls(cml, " ");
	string prog = gets(cargv, 0);
	string aliascmd;
	
	if((aliascmd = getdbl("input", ["alias", prog])) != JSON_INVALID) {
		cml = aliascmd + " " + concat(delitem(cargv, 0), " ");
		cargv = splitnulls(cml, " ");
		prog = gets(cargv, 0);
	}
	
	#ifdef PIPES
	// string pipe_queue; // {handle:[[commands], outs, ins, user, rc]} - will replace script handle
	
	cml = replace(cml, "\\|", NAK);
	integer pipe_pos = strpos(cml, "|");
	if(~pipe_pos) {
		list commands = split(replace(cml, "|", "|exec "), "|");
		list pipe_keys;
		
		integer cimax = count(commands);
		integer ci = cimax;
		while(ci--) {
			pipe_keys += [llGenerateKey()];
			commands = alter(commands, [replace(gets(commands, ci), NAK, "|")], ci, ci);
		}
		
		key new_handle = getk(pipe_keys, cimax - 1);
		key feed_handle = getk(pipe_keys, 1);
		
		pipe_keys += [outs];
		
		if(in_script)
			script_handle = new_handle;
		
		ci = cimax;
		while(ci--)
			// patch last two pipes so we can resolve them properly:
			if(ci > 0)
				commands = alter(commands, [
					"p:" + gets(pipe_keys, ci) +
					" n:" + gets(pipe_keys, ci + 1) +
					" " + gets(commands, ci)
				], ci, ci);
		
		//if(count(commands) > 2) {
			//commands = alter(commands, ["n:" + (string)new_handle + " " + gets(commands, -2)], -2, -2);
			// commands = alter(commands, ["p:" + (string)feed_handle + " " + gets(commands, 1)], 1, 1);
		
		if(cimax == 2)
			feed_handle = new_handle;
		
		pipe_queue = setjs(pipe_queue, [new_handle], jsarray([
			jsarray(commands), outs, handle, user, _resolved, feed_handle, jsarray(pipe_keys), in_script
		]));
		
		#ifdef DEBUG
		echo("pipes formed to: " + pipe_queue);
		#endif
		
		pipe_open(delitem(commands, 0));
		return TRUE;
	} else if(~strpos(cml, NAK)) {
		cml = replace(cml, NAK, "|");
		cargv = splitnulls(cml, " ");
		prog = gets(cargv, 0);
	}
	#endif
	
	string filetype;
	integer invtype;
	string error_msg;
	
	if(prog == "runaway") {
		if(llGetInventoryType("_security") == INVENTORY_SCRIPT) {
			invoke("_security runaway", outs, handle, user);
		} else {
			error_msg = "Can't run away: _security is not installed (yikes)";
		}
	} else if(prog == "safeword") {
		if(llGetInventoryType("restraint") == INVENTORY_SCRIPT) {
			invoke("restraint safeword", outs, handle, user);
		} else {
			error_msg = "Can't safeword: restraint is not installed";
		}
	} else if(prog == "alias") {
		string word = gets(cargv, 1);
		string command = concat(delrange(cargv, 0, 1), " ");
		if(word == "delete" && command != "") {
			string alias = getdbl("input", ["alias", command]);
			if(alias != JSON_INVALID)
				setdbl("input", ["alias", command], JSON_DELETE);
			error_msg = "OK.";
		} else if(command != "") {
			setdbl("input", ["alias", word], command);
		} else if(word != "") {
			error_msg = getdbl("input", ["alias", word]);
		} else {
			list aliases = js2list(getdbl("input", ["alias"]));
			integer ai = count(aliases) >> 1;
			if(!ai)
				error_msg = "No aliases defined.";
			else while(ai--) {
				error_msg += "\n - " + gets(aliases, ai << 1) + ": " + gets(aliases, (ai << 1) + 1);
			}
		}
	#ifdef TRACE
	} else if(prog == "trace") {
		if(count(cargv) > 1)
			trace = llListFindList(["off", "on"], [gets(cargv, 1)]);
		else
			error_msg = "Trace is " + gets(["off.", "on."], trace);
		if(!~trace)
			trace = 0;
	#endif
	} else if(prog == "to") {
		string statement = concat(delrange(cargv, 0, 1), " ");
		
		outs = gets(cargv, 1);
		cml = statement;
		jump internal_restart;
		// process_input(gets(cargv, 1), user, statement, in_script);
	} else if(prog == "from") {
		handle = gets(cargv, 1);
		if(in_script)
			script_handle = handle;
		invoke(concat(delrange(cargv, 0, 1), " "), outs, handle, user);
	} else if(prog == "do") {
		setdbl("env", ["arg"], jsarray(delrange(cargv, 0, 0)));
		setdbl("env", ["args"], (string)(count(cargv) - 2));
		
		file_offset = file_length = NOWHERE;
		file_outs = outs;
		file_user = user;
		file_open(file_pipe = llGenerateKey(), file_name = gets(cargv, 1));
		// task_begin(file_pipe, file_name);
		
		// not checking in_script; allow manual interruption
		if(script_lines != []) {
			llSetTimerEvent(0);
			script_lines = [];
			script_li = 0;
			script_handle = NULL_KEY;
			set_mode(_mode & ~MODE_ACCEPT_DONE);
			// resolve_io(script_trigger_resolve, script_trigger_outs, script_trigger_ins);
			resolve_i(script_trigger_resolve, script_trigger_ins);
			echo("[_exec] interrupted by new script");
		}
		
		script_trigger_ins = handle;
		script_trigger_outs = outs;
		script_trigger_resolve = _resolved;
		
		return TRUE; // do not continue_script();
	} else if(prog == "nudge") {
		string msg;
		if(!count(script_lines)) {
			msg = "exec: not in a script";
		} else {
			msg = "exec: bypassing line " + gets(script_lines, script_li);
			llSetTimerEvent(0.1);
		}
		print(outs, user, msg);
		
	} else if(prog == "exit") {
		// not checking in_script; allow manual interruption
		if(script_lines != []) {
			script_lines = [];
			script_li = 0;
			script_handle = NULL_KEY;
			set_mode(_mode & ~MODE_ACCEPT_DONE);
			// resolve_io(script_trigger_resolve, script_trigger_outs, script_trigger_ins);
			resolve_i(script_trigger_resolve, script_trigger_ins);
			llSetTimerEvent(0);
		}
		setdbl("env", ["arg"], "[]");
		setdbl("env", ["args"], "0");
		
		return FALSE; // do not continue_script();
	} else if(prog == "say") {
		/*cml = concat(delitem(cargv, 0), " ");
		say_restart = TRUE;
		jump internal_restart;*/
		if((user == avatar) && !(integer)getdbl("input", ["mind"]) && !in_script) {
			print(outs, user, "You cannot think.");
		} else {
			invoke("input " + cml, outs, handle, user);
		}
		return FALSE;
		// process_input(outs, user, concat(delitem(cargv, 0), " "), in_script);
	} else if(prog == "jump") {
		integer new_script_li = index(script_lines, "@" + gets(cargv, 1) + ":");
		if(~new_script_li) {
			script_li = new_script_li + 1;
		} else {
			error_msg = "[_exec] script error: no label " + gets(cargv, 1);
		}
	} else if(prog == "echo") {
		string a1 = gets(cargv, 1);
		if(a1 == "-c") {
			echo(replace(concat(delrange(cargv, 0, 1), " "), "\\n", "\n"));
		} else if(a1 == "-d") {
			llWhisper(DEBUG_CHANNEL, replace(concat(delrange(cargv, 0, 1), " "), "\\n", "\n"));
		} else {
			print(outs, user, replace(concat(delitem(cargv, 0), " "), "\\n", "\n"));
		}
	} else if(prog == "set") {
		if(count(cargv) > 2) {
			string value;
			if(gets(cargv, 2) == "=")
				value = expression(delrange(cargv, 0, 2));
			else
				value = concat(delrange(cargv, 0, 1), " ");
			
			string sv = gets(cargv, 2);
			
			if(value == "%key") {
				value = llGenerateKey();
			} else if(value == "%undefined") {
				value = JSON_DELETE;
			} else if(value == "%empty") {
				value = "";
			} else if(sv == "%keys") {
				value = concat(delrange(cargv, 0, 2), " ");
				value = concat(jskeys(value), " ");
			} else if(sv == "%count") {
				string mode = gets(cargv, 3);
				value = concat(delrange(cargv, 0, 3), " ");
				if(mode == "words") {
					value = (string)count(llParseString2List(value, [" ", "\n"], []));
				} else if(mode == "lines") {
					value = (string)count(splitnulls(value, "\n"));
				} else if(mode == "chars") {
					value = (string)strlen(value);
				} else if(mode == "keys") {
					value = (string)count(jskeys(value));
				}
			} else if((gets(cargv, 4) == "of") && (sv == "%index")) {
				// set <var> %index $a of $json
				// set <var> %index $a.$b of $json
				list indices = split(gets(cargv, 3), ".");
				// echo("getting indices " + concat(indices, ", "));
				value = concat(delrange(cargv, 0, 4), " ");
				value = getjs(value, indices);
			} else if((gets(cargv, 4) == "in") && (sv == "%word" || sv == "%line" || sv == "%char")) {
				// set <var> %word $i in $text
				integer i = (integer)gets(cargv, 3);
				value = concat(delrange(cargv, 0, 4), " ");
				// echo("command: " + cml);
				// echo("extracting " + sv + " #" + (string)i + " from " + value);
				if(sv == "%word") {
					value = gets(llParseString2List(value, [" ", "\n"], []), i);
				} else if(sv == "%line") {
					value = gets(splitnulls(value, "\n"), i);
				} else if(sv == "%char") {
					value = substr(value, i, i);
				}
				// echo("got " + value);
			}
			
			setdb("env", gets(cargv, 1), value);
		} else {
			error_msg = "[_exec] not enough arguments: set";
		}
	} else if(prog == "if") {
		integer negate = 0;
		if(gets(cargv, 1) == "not") {
			cargv = delitem(cargv, 1);
			negate = 1;
			
		}
		
		integer endpoint = index(cargv, "then");
		if(~endpoint) {
			string statement = concat(delrange(cargv, 0, endpoint), " ");
			
			integer success = 0;
			if(gets(cargv, 1) == "exists") {
				string filename = concat(sublist(cargv, 2, endpoint - 1), " ");
				success = llGetInventoryType(filename) != INVENTORY_NONE;
			} else {
				integer mid_pos = index(cargv, "is");
				if(mid_pos > 1 && mid_pos < endpoint) {
					string LHS = concat(sublist(cargv, 1, mid_pos - 1), " ");
					string RHS = concat(sublist(cargv, mid_pos + 1, endpoint - 1), " ");
					
					// echo("cargv: " + concat(cargv, " ") + "\nLHS: " + LHS + "\nRHS: " + RHS);
					
					if(LHS == "%undefined")
						LHS = JSON_INVALID;
					else if(LHS == "%empty" || LHS == "\"\"")
						LHS = "";
					
					if(RHS == "%undefined")
						RHS = JSON_INVALID;
					else if(RHS == "%empty" || RHS == "\"\"")
						RHS = "";
					
					success = (LHS == RHS);
					
					// echo("success? " + (string)success);
				} else {
					mid_pos = index(cargv, "in");
					if(mid_pos > 1 && mid_pos < endpoint) {
						string LHS = concat(sublist(cargv, 1, mid_pos - 1), " ");
						string RHS = concat(sublist(cargv, mid_pos + 1, endpoint - 1), " ");
						
						success = (getjs(RHS, [LHS]) != JSON_INVALID);
						
					} else {
						string value = expression(sublist(cargv, 1, endpoint - 1));
						success = (llFabs((float)value) >= 0.001);
					}
				}
			}
			
			if(negate)
				success = !success;
			
			if(success) {
				cml = statement;
				jump internal_restart;
				
				/*process_input(outs, user, statement, in_script);
				return; // do not continue_script(); - the true branch will handle that
				*/
			}
		} else {
			error_msg = "[_exec] script error: incomplete statement " + cml;
		}
	} else if(prog == "service") {
		system(SIGNAL_CALL, E_UNKNOWN + E_PROGRAM_NUMBER + (string)outs + " " + (string)user + " " + concat(delitem(cargv, 0), " "));
	} else if(~index(js2list(getdbl("input", ["device-command"])), prog)) {
		system(SIGNAL_CALL, E_HARDWARE + E_PROGRAM_NUMBER + (string)outs + " " + (string)user + " hardware command " + cml);
	} else if((invtype = llGetInventoryType("_" + prog)) == INVENTORY_SCRIPT) {
		invoke("_" + cml, outs, handle, user);
		return FALSE;
	} else if((invtype = llGetInventoryType(prog)) == INVENTORY_SCRIPT) {
		invoke(cml, outs, handle, user);
		return FALSE;
	} else {
		integer exists = (invtype != INVENTORY_NONE);
		if(!exists) {
			exists = ((filetype = getdbl("fs:root", [prog])) != JSON_INVALID);
		}
		
		if(exists) {
			string ext = gets(splitnulls(prog, "."), LAST);
			string assoc = getdbl("fs", ["open", ext]);
			if(~strpos(prog, ".")) {
				if(assoc != JSON_INVALID) {
					invoke(assoc + " " + cml, outs, handle, user);
					return FALSE;
				} else {
					error_msg = "No association for file type: ." + ext;
				}
			}
		} else {
			error_msg = prog + ": not found";
		}
	}
	
	if(error_msg)
		print(outs, user, error_msg);
	
	// reduces interference from user acting during script execution
	if(in_script) {
		llSetTimerEvent(0.1); // continue_script()
		return TRUE;
	} else
		return FALSE;
}

integer script_trigger_resolve;
key script_trigger_ins = NULL_KEY;
key script_trigger_outs = NULL_KEY;

continue_script() {
	integer script_length = count(script_lines);
	if(script_li < script_length) {
		string line;
		integer fc;
		while(script_li < script_length && (line == "" || fc == 0x40 || fc == 0x23)) {
			// skip blank lines and lines starting with '@' or '#'
			// echo((string)script_li + "/" + (string)script_length + " skipped");
			line = llStringTrim(gets(script_lines, script_li++), STRING_TRIM);
			fc = llOrd(line, 0);
		}
		
		// echo((string)script_li + "/" + (string)script_length + ": " + line);
		
		if(script_li <= script_length) {
			process_input(file_outs, NULL_KEY, file_user, line, TRUE);
			return;
		}
	}
	
	#ifdef DEBUG
	echo("[_exec] script done; resolving " + (string)script_trigger_ins);
	#endif
	setdbl("env", ["arg"], "[]");
	setdbl("env", ["args"], "0");
	script_lines = [];
	script_li = 0;
	script_handle = NULL_KEY;
	llSetTimerEvent(0);
	set_mode(_mode & ~MODE_ACCEPT_DONE);
	
	// resolve_io(script_trigger_resolve, script_trigger_outs, script_trigger_ins);
	resolve_i(script_trigger_resolve, script_trigger_ins);
	
	script_trigger_resolve = 0;
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_DONE) {
		// echo("[_exec] receipt: " + m);
		ins = substr(m, 0, 35);
		
		#ifdef PIPES
		string pipestruct = getjs(pipe_queue, [ins]);
		if(pipestruct != JSON_INVALID) {
			echo("[_exec] finished pipe procedure " + (string)ins);
			pipe_queue = setjs(pipe_queue, [ins], JSON_DELETE);
		}
		#endif
		
		if(_mode & MODE_ACCEPT_DONE && ins == script_handle) {
			continue_script();
		} else {
			echo("[_exec] script '" + file_name + "' still running; type '@exit' to abort");
			// echo("(got " + (string)ins + " instead of " + (string)script_handle);
		}
		
	} else if(n == SIGNAL_INVOKE) {
		list argv = splitnulls(llStringTrim(m, STRING_TRIM), " ");
		
		integer argc = count(argv);
		integer still_awake; // started a script
		if(argc > 1) {
			key handle = ins;
			if(handle == NULL_KEY)
				handle = llGenerateKey();
			still_awake = process_input(outs, handle, user, llStringTrim(concat(delitem(argv, 0), " "), STRING_TRIM), FALSE);
			/*
			string action = gets(argv, 1);
			if(action == "reset") {
				main(0, SIGNAL_INIT, "", "", "", "");
				resolve_io(src, outs, ins);
			} else if(action == "do") {
				process_input(outs, NULL_KEY, user, "@do " + concat(delrange(argv, 0, 1), " "), FALSE, FALSE);
				script_trigger_resolve = src;
				script_trigger_outs = ins;
				script_trigger_ins = ins;
			} else if(action == "say") {
				process_input(outs, ins, user, concat(delrange(argv, 0, 1), " "), FALSE, FALSE);
			} else {
				print(outs, user, "usage: " + gets(argv, 0) + " reset|do <filename>|say <message>");
				resolve_io(src, outs, ins);
			}*/
		}
		
		// must include this here since exec never sleeps:
		if(!still_awake)
			resolve_i(src, ins);
		
	} else if(n == SIGNAL_NOTIFY) {
		// echo("EXEC notify: " + m);
		list argv = splitnulls(m, " ");
		string action = gets(argv, 1);
		
		#ifdef PIPES
		if(action == "pipe") {
			#ifdef DEBUG
			echo("exec: pipe created (" + (string)ins + "): " + m);
			#endif
			string pipestruct = getjs(pipe_queue, [ins]);
			if(pipestruct != JSON_INVALID) {
				#ifdef DEBUG
				echo("exec: pipe struct " + pipestruct);
				#endif
				key feed_handle = getjs(pipestruct, [5]);
				string first_command = getjs(pipestruct, [0, 0]);
				key user = getjs(pipestruct, [3]);
				// invoke(first_command, feed_handle, NULL_KEY, user);
				// process_input(key outs, key handle, key user, string cml, integer in_script) {
				process_input(feed_handle, llGenerateKey(), user, first_command, (integer)getjs(pipestruct, [7]));
			} else {
				echo("exec: unknown pipe (struct not found): " + m);
			}
		} else 
		#endif
		if(action == "file") { // file data available
			if(ins == file_pipe) {
				string file_buffer;
				pipe_read(file_pipe, file_buffer);
				integer read_length = 2;
				
				if(file_length != NOWHERE) {
					if(file_unit == "b")
						read_length *= FILE_PAGE_LENGTH;
					
					file_offset += read_length;
					if(file_offset + read_length > file_length)
						read_length = file_length - file_offset;
					
					// print(file_outs, file_user, file_buffer);
					script += file_buffer;
					
					if(file_offset < file_length)
						file_read(file_pipe, file_name, (string)file_offset + " " + (string)read_length);
					else {
						file_close(file_pipe);
						// print(avatar, avatar, script);
						
						set_mode(MODE_MASK_BATCH);
						
						// start run script:
						
						script_lines = split(script, "\n");
						script = "";
						script_li = 0;
						continue_script();
						
						// task_end(file_pipe);
					}
				} else {
					list bfs = splitnulls(file_buffer, " ");
					file_length = (integer)gets(bfs, 0);
					file_unit = gets(bfs, 1);
					if(file_unit == "b")
						read_length *= FILE_PAGE_LENGTH;
					
					// echo("File " + file_name + " stat: " + (string)file_buffer);
					
					if(file_length > 0) {
						file_offset = 0;
						if(file_offset + read_length > file_length)
							read_length = file_length - file_offset;
						file_read(file_pipe, file_name, (string)file_offset + " " + (string)read_length);
					} else { // file not found or file empty
						print(file_user, file_user, "No file: " + file_name);
						file_close(file_pipe);
						// task_end(file_pipe);
					}
				}
			} /*else {
				echo("File data offered via unexpected pipe: " + (string)ins);
			}*/
		} else {
			echo("Unknown notify: " + m);
		}
		
		resolve_i(src, ins);
	} else if(n == SIGNAL_INIT) {
		// NOP
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#define EXT_EVENT_HANDLER "ARES/system/exec.event.lsl"
#include <ARES/program>
