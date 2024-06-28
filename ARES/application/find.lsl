/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Find Application
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
#define CLIENT_VERSION "0.0.3"
#define CLIENT_VERSION_TAGS "prealpha"

list argsplit(string m) {
	// splits a string based on word boundaries, but groups terms inside double and single quotes
	// tabs and newlines are converted to spaces
	list results;
	string TAB = llChar(9);
	list atoms = llParseStringKeepNulls(m, [], [" ", "\\", "'", "\"", "\n", TAB]);
	integer in_quotes; // 1 = single, 2 = double
	integer ti = 0;
	integer tmax = count(atoms);
	
	string buffer;
	while(ti < tmax) {
		string t = gets(atoms, ti);
		integer c = llOrd(t, 0);
		if(c == 0x22) { // '"'
			if(in_quotes == 0) {
				in_quotes = 2;
			} else if(in_quotes == 2) {
				in_quotes = 0;
			} else {
				buffer += t;
			}
		} else if(c == 0x27) { // '\''
			if(in_quotes == 0) {
				in_quotes = 1;
			} else if(in_quotes == 1) {
				in_quotes = 0;
			} else {
				buffer += t;
			}
		} else if(c == 0x5c) { // '\\'
			string t1 = gets(atoms, ti + 2);
			if(t1 == "\"" || t1 == "'") {
				buffer += t1;
				ti += 2;
			} else {
				buffer += t;
			}
		} else if(c == 0x20 || c == 0x0a || c == 0x09) { // ' ', '\n', '\t'
			if(in_quotes) {
				buffer += " ";
			} else {
				results += buffer;
				buffer = "";
			}
		} else {
			buffer += t;
		}
		++ti;
	}
	
	if(tmax)
		results += buffer;
	
	return results;
}

// this is O(n^2), but the outer loop is usually sparse
// so, it might be faster than reversing the list and using a single normal search

/*
// no longer required; LL added llListFindListNext(haystack, needle, index) which can take -1 as index

integer nsListFindLast(list a, list b) {
	if(a == [] || b == []) // either list is empty; bail
		return NOWHERE;
    integer i = llListFindList(a, b);
    if(!~i) // doesn't exist; bail
        return NOWHERE;
	integer cb = count(b);
	integer ca = count(a);
    if(i == ca - cb) // first match is already at the end
		return i;
	if(!llListFindList(sublist(a, -cb, LAST), b)) // do we have a match at the end?
		return ca - cb;
	
    integer j = i;
    
    list s;
    
    while(~(i = llListFindList(s = llDeleteSubList(a, 0, j), b)))
        j += i + 1;
    
    return j;
} */

#define reverse_index(lis, item) llListFindListNext(lis, item, LAST)

integer first_is_skippable;

integer case_insensitive;
integer stop_after_first_match;
list states; // patterns matched at each offset
list exits; // next state of each state - stored as integer unless there are multiple hits

add_exit(integer where, integer to) {
	if(!~where) {
		#ifdef DEBUG
		echo("can't patch -1 to " + (string)to);
		#endif
		return;
	} else if(llGetListEntryType(exits, where) == TYPE_INTEGER) {
		integer w = geti(exits, where);
		if(~w) {
			exits = alter(exits, [(string)to + "," + (string)w], where, where);
		} else {
			exits = alter(exits, [to], where, where);
		}
	} else {
		exits = alter(exits, [(string)to + "," + gets(exits, where)], where, where);
	}
}

construct_regex(string pattern) {
	list paren_stack; // state indices corresponding to "(" symbols
	list pipe_stack; // state indices corresponding to "|" symbols
	
	first_is_skippable = 0; // set to TRUE if state 0 has ? or *
	
	integer ci = 0;
	integer cmax = strlen(pattern);
	integer cc_open = NOWHERE; // character class open - position of '[' character
	integer sc = 0; // number of states we've emitted so far
	string buffer; // for character classes only
	while(ci < cmax) {
		string c = substr(pattern, ci, ci);
		string d = substr(pattern, ci, ci + 1);
		if(~cc_open) {
			if(d == "\\-" || d == "\\\\") {
				buffer += d;
				ci += 1;
			} else if(d == "\\^" /*|| d == "\\$" || d == "\\[" || d == "\\]" || d == "\\(" || d == "\\)" || d == "\\*" || d == "\\?" || d == "\\." || d == "\\\\"*/ || d == "\\]") {
				buffer += substr(d, 1, 1);
				ci += 1;
			} else if(c == "]") {
				string new_buffer = "\n" + substr(buffer, 0, 0);
				
				integer bi = 1;
				integer bmax = strlen(buffer);
				
				integer found_hyphen = 0;
				string last_e;
				while(bi < bmax) {
					string e = substr(buffer, bi, bi);
					string f = substr(buffer, bi, bi + 1);
					
					if(f == "\\$" || f == "\\[" || f == "\\(" || f == "\\)" || f == "\\*" || f == "\\?" || f == "\\." || f == "\\\\" || f == "\\-") {
						e = substr(f, 1, 1);
						++bi;
					} else if(e == "-") {
						found_hyphen = 2;
					}
					
					if(found_hyphen == 2) {
						found_hyphen = 1;
					} else if(found_hyphen == 1) {
						integer ck = llOrd(last_e, 0) + 1;
						integer end_char = llOrd(e, 0);
						if(ck < end_char) {
							while(ck < end_char)
								new_buffer += llChar(ck++);
						} else if(ck - 2 > end_char) {
							ck -= 2;
							while(ck > end_char)
								new_buffer += llChar(ck--);
						}
						found_hyphen = 0;
						new_buffer += e;
						last_e = e;
					} else {
						new_buffer += e;
						last_e = e;
					}
					
					++bi;
				}
				
				states += new_buffer;
				exits += [NOWHERE];
				add_exit(sc - 1, sc);
				buffer = "";
				++sc;
				cc_open = NOWHERE;
			} else {
				buffer += c;
			}
		} else if(d == "[^" && !~cc_open) {
			cc_open = ci;
			buffer = "^";
			ci += 1;
		} else if(c == "[" && !~cc_open) {
			cc_open = ci;
			buffer = "[";
		} else if(d == "\\^" || d == "\\$" || d == "\\[" || d == "\\]" || d == "\\(" || d == "\\)" || d == "\\*" || d == "\\?" || d == "\\." || d == "\\\\") {
			states += d;
			exits += [NOWHERE];
			add_exit(sc - 1, sc);
			++sc;
			ci += 1;
		} else if(c == "*") {
			if(sc == 1)
				first_is_skippable = TRUE;
			else
				add_exit(sc - 2, sc);
			add_exit(sc - 1, sc - 1);
		} else if(c == "+") {
			add_exit(sc - 1, sc - 1);
		} else if(c == "?") {
			if(sc == 1)
				first_is_skippable = TRUE;
			else
				add_exit(sc - 2, sc);
		} else if(c == "(") {
			paren_stack += [sc];
			states += "";
			exits += [NOWHERE];
			add_exit(sc - 1, sc);
			++sc;
		} else if(d == ")?") {
			// todo
			ci += 1;
		} else if(d == ")*") {
			// todo
			ci += 1;
		} else if(c == ")") {
			// todo
			integer last_open = index(paren_stack, ")");
			// find last "("
			// find all subsequent "|"
			// patch "(" to also point to "|"s
			// patch symbols before "|" to also point to sc
			// patch symbol before ")" to point to sc
		} else if(c == "|") {
			pipe_stack += [sc];
			states += "";
			exits += [NOWHERE];
			add_exit(sc - 1, sc);
			++sc;
		} else if(d == "\\*" || d == "\\.") {
			states += d;
			//exits = alter(exits, [sc], sc - 1, sc - 1) + [NOWHERE];
			add_exit(sc - 1, sc);
			exits += [NOWHERE];
			++sc;
		} else {
			states += c;
			// exits = alter(exits, [sc], sc - 1, sc - 1) + [NOWHERE];
			add_exit(sc - 1, sc);
			exits += [NOWHERE];
			++sc;
		}
		
		++ci;
	}
	
	// fix all jumps to nowhere
	integer si = count(states);
	while(si--) {
		list next = split(gets(exits, si), ",");
		integer affect = 0;
		integer sin;
		while(~(sin = index(next, (string)sc))) {
			next = alter(next, ["-1"], sin, sin);
			affect = 1;
		}
		
		if(affect) {
			if(count(next) > 1)
				exits = alter(exits, [concat(next, ",")], si, si);
			else
				exits = alter(exits, [(integer)gets(next, 0)], si, si);
			#ifdef DEBUG
			echo("fixed jump to nowhere in state " + (string)si);
			#endif
		}
	}
	
	list last_exits = split(gets(exits, LAST), ",");
	integer nli = index(last_exits, (string)NOWHERE);
	if(!~nli) {
		exits = alter(exits, [concat(last_exits, ",") + ",-1"], LAST, LAST);
		#ifdef DEBUG
		echo("patched last exit");
		#endif
	}
}

integer match(string q, string t) {
	if(q == ".")
		return (t != "");
	
	if(q == "\\^" || q == "\\$" || q == "\\[" || q == "\\]" || q == "\\(" || q == "\\)" || q == "\\*" || q == "\\?" || q == "\\." || q == "\\\\")
		return (llOrd(t, 0) == llOrd(q, 1));
	
	if(case_insensitive) {
		q = llToLower(q);
		t = llToLower(t);
	}
	
	if(llOrd(q, 0) == 0x0a) { // character ranges become '\n[' if positive and '\n^' if negative
		if(llOrd(q, 1) == 0x5e) // '^'
			return !~strpos(substr(q, 2, LAST), t);
		else // implies '['
			return TRUE && ~strpos(substr(q, 2, LAST), t);
	}
	
	return (q == t);
}

list find(string text) {
	integer ti_start = NOWHERE;
	integer ti;
	integer tmax = strlen(text);
	integer si;
	string result;
	list path;
	integer smax = count(states);
	integer last_exit = NOWHERE;
	while(~si && ti < tmax) {
		list next = split(gets(exits, si), ",");
		string st = gets(states, si);
		string tt = substr(text, ti, ti);
		if(match(st, tt)) {
			if(!count(path))
				ti_start = ti;
			
			result += tt;
			
			#ifdef DEBUG
			echo("matched \"" + (string)result + "\" ('" + tt + "' at char " + (string)ti + " vs. '" + st + "' from state " + (string)si + ")");
			#endif
			
			path += si;
			si = geti(next, 0);
			
			// todo: for backreferences this must be changed to the appropriate length
			
			if(st != "")
				++ti; // null symbols are legal but don't advance the character counter
			
			if(!~si) {
				return [ti_start, result];
			}
		} else if(si != last_exit) {
			if(!count(path)) {
				ti_start = ti = ti + 1;
				si = 0;
				next = split(gets(exits, 0), ",");
				#ifdef DEBUG
				echo("could not start matching with '" + tt + "' at char " + (string)ti);
				#endif
			} else {
				integer prev = geti(path, LAST);
				next = split(gets(exits, prev), ",");
				#ifdef DEBUG
				echo("Available 'next' options: " + concat(next, ","));
				#endif
				integer sj = index(next, (string)si);
				next = delrange(next, 0, sj);
				#ifdef DEBUG
				echo("did not match ('" + tt + "' at char " + (string)ti + " vs. '" + st + "' from state " + (string)si + "); sj was " + (string)sj);
				#endif
				si = geti(next, 0);
			}
		} else {
			integer dpi = count(path);
			/* path = delitem(path, LAST);
			result = delstring(result, LAST, LAST); */
			integer dsi = si;
			while(dpi--) {
				integer dprev = geti(path, dpi);
				list dnext = split(gets(exits, dprev), ",");
				integer dlast_exit = geti(dnext, LAST);
				if(dlast_exit != dsi) {
					integer dsj = index(dnext, (string)dsi);
					si = geti(dnext, dsj + 1);
					#ifdef DEBUG
					echo("backtracked to state " + (string)dprev + "; trying " + (string)si + "; dsj was " + (string)dsj);
					#endif
					jump got_it; // backtrack was successful
				} else {
					dsi = dprev;
					string dst = gets(states, geti(path, LAST));
					path = delitem(path, LAST);
					
					// todo: for backreferences this must be changed to the appropriate length
					
					if(dst != "")
						result = delstring(result, LAST, LAST);
					
					#ifdef DEBUG
					echo("backtracked past " + (string)dprev + " = '" + gets(states, dprev) + "'");
					#endif
				}
			}
			// match failed - step forward
			if(~ti_start) {
				ti_start = ti = ti_start + 1;
			} else {
				ti += 1;
			}
			si = 0;
			@got_it;
		}
		
		last_exit = geti(next, LAST);
	}
	return [NOWHERE, ""];
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = argsplit(m);
		integer argc = count(argv);
		string msg = "";
		
		case_insensitive = 0;
		stop_after_first_match = 0;
		
		list options = ["-i", "-1"];
		integer opt;
		while(~(opt = index(options, gets(argv, 1)))) {
			argv = delitem(argv, 1);
			--argc;
			if(opt == 0) {
				case_insensitive = 1;
			} else if(opt == 1) {
				stop_after_first_match = 1;
			}
		}
		
		if(argc == 1) {
			msg = "Syntax: " + PROGRAM_NAME + " [-i -1] <pattern> [<filename> ...]";
		} else {
			states = exits = [];
			string pattern = gets(argv, 1);
			argv = delitem(argv, 1);
			llResetTime();
			construct_regex(pattern);
			// echo("Compiled regular expression in " + (string)llGetTime() + " sec"); // usually returns zero!
			
			echo("States: " + concat(states, "•"));
			echo("Exits: " + concat(exits, "•"));
			
			string query_string;
			if(ins == NULL_KEY) {
				pipe_read(ins, query_string);
			}
			
			if(query_string == "") {
				query_string = concat(delitem(argv, 0), " ");
			}
			
			msg = concat(find(query_string), ": ");
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
