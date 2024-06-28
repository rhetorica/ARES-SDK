/* 
	
	LSLisp 0.2
	Implementation copyright 2018, Nanite Systems Research
	
*/

#define INTERPRETER_VERSION "0.2.3"
#define INLINE_OCCUR
// #define COMPANION

#include <utils.lsl>
#include <lslisp.h.lsl>

#ifdef COMPANION
	#include <system.lsl>
	#include <System/pipes.lsl>
	#include <System/tasks.lsl>
#endif

// floats with a decimal place smaller than this value
// will be rounded to the nearest integer:
#define ROUNDING_ERROR 0.00000762939453125
// (~6 bits of mantissa error in an IEEE 32-bit float)

// #define GENERAL_DEBUG

list v_names;
list v_values;

string filename;
key parse_q; // retrieval key
integer parse_n; // line number

list parse_queue; // tokens waiting to be analyzed

string interrupted_frame;
list interrupted_stack;
key interrupt; // increment PC and resume execution when matching value arrives

key user;
#ifdef ARES
	key outs;
#endif

/* structure for program frames
	[
		'c':json - parsed symbol tree (SF)
		'i':json array - program counter (S)
		'p':integer - stack location of previous stack frame (S)
		'sp':integer - stack location of previous verb symbol (SV)
		'v':json {v_names:v_values} - variables in this scope (S)
		'r':integer - one of:
			0: return value and backtrack (S)
			1: conditional (used in (if) and (while)) (S)
		't':integer - one of:
			0: stack frame (S)
			1: verb frame (V)
			2: function frame (F)
		's':string - symbol for verb name (V)
		'a':string - space-separated arglist (F)
	]
*/

#define stack_frame(code_json, ixx, parent_stack_index, vars, retmode, last_symbol) ( \
		  "{\"c\":" + code_json \
		+ ",\"i\":" + list2js(JSON_ARRAY, ixx) \
		+ ",\"sp\":" + (string)last_symbol \
		+ ",\"p\":" + (string)parent_stack_index \
		+ ",\"v\":" + vars \
		+ ",\"r\":" + (string)retmode \
		+ ",\"t\":0}" \
	)
	
#define verb_frame(symbol, last_symbol) ( \
          "{\"s\":\"" + symbol + "\"" \
		+ ",\"t\":1,\"sp\":" + (string)last_symbol \
	+ "}")

#define func_frame(arg_list, code_json) ( \
          "{\"c\":" + code_json + "" \
		+ ",\"t\":2,\"a\":\"" + (string)arg_list + "\"}" \
	)

list execute(list stack) {
	string prog;
	list ix;
	integer parent;
	string local_vars;
	integer return_mode;
	integer last_symbol;
	
	{
		string frame = gets(stack, LAST);
		stack = delitem(stack, LAST);
		
		prog = getjs(frame, (list)"c");
		ix = js2list(getjs(frame, (list)"i"));
		parent = (integer)getjs(frame, (list)"p");
		local_vars = getjs(frame, (list)"v");
		return_mode = (integer)getjs(frame, (list)"r");
		last_symbol = (integer)getjs(frame, (list)"sp");
	}
	
	// resuming interrupted code:
	
	if(interrupt) {
		interrupted_frame = "";
		interrupted_stack = [];
		interrupt = "";
	}
	
	// no program:
	if(prog == "")
		return stack;
	
	// the next token will be the head of a list:
	integer descending = FALSE;
	
	// we just ended a parenthesized expression:
	integer backtrack = FALSE;
	
	if(ix == []) {
		ix = (list)NOWHERE; // start at -1 since we begin with incrementing this
		descending = TRUE;
	}
	
	while(TRUE) {
		@next;
		
		// llOwnerSay("Stack: " + concat(stack, "; "));
		
		// step forward:
		ix = alter(ix, [1 + geti(ix, LAST)], LAST, LAST);
		
		// integer pcount = 0;
		
		if(jstype(prog, ix) == JSON_INVALID) { // no successor node
			if(count(ix) == 1) { // EOF
				if(parent == NOWHERE) {
					//echo(">> Return to nowhere. Done.");
					return stack;
				} else {
					//echo(">> Return to " + (string)parent);
					
					integer previous_return_mode = return_mode;
					
					string frame = gets(stack, parent);
					
					if(substr(frame, 0, 0) != "{") {
						echo(">> No frame at " + (string)parent + " in: " + list2js(JSON_ARRAY, stack));
						return [];
					}
					
					stack = delitem(stack, parent);
					
					prog = getjs(frame, (list)"c");
					ix = js2list(getjs(frame, (list)"i"));
					parent = (integer)getjs(frame, (list)"p");
					local_vars = getjs(frame, (list)"v");
					return_mode = (integer)getjs(frame, (list)"r");
					last_symbol = (integer)getjs(frame, (list)"sp");
					
					#ifdef GENERAL_DEBUG
					if(~last_symbol)
						echo(">> Return from subframe; last symbol was " + gets(stack, last_symbol));
					else
						echo(">> Return from subframe; no last symbol");
					#endif
					
					string structure = getjs(prog, ix);
					
					list step_again = ix;
					
					if(previous_return_mode == 1) { // leaving a conditional expression						
						integer retval = (integer)gets(stack, LAST);
						// echo(">> " + structure + " conditional results: rv=" + (string)retval + "; ix=" + concat(ix, "."));
						stack = delitem(stack, LAST);
						
						//frame = stack_frame(prog, ix, parent, local_vars, return_mode);
												
						ix = delitem(ix, LAST);
						
						//list step_forward = ix; // alter(ix, [1 + geti(ix, LAST)], LAST, LAST);
						
						if(structure == "if") { // entering 'if' or 'else' body
							string next_frame = setjs(frame, (list)"i", list2js(JSON_ARRAY, ix));
							list subix = ix;
							if(retval) {
								subix += 2;
							} else if(jstype(prog, ix + 3) == JSON_ARRAY) { // else branch exists; activate
								subix += 3;
							} else { // else 'else' branch doesn't exist; carry on
								// ix = step_forward;
								// proceed to increment
								jump next;
							}
							prog = "[" + getjs(prog, subix) + "]";
							stack += next_frame;
							return_mode = 0;
						} else if(structure == "while") { // entering 'while' body							
							if(retval) {
								// echo(">> ENTERING A WHILE BODY; ix IS " + concat(ix, "."));
								stack += frame;
								prog = "[" + getjs(prog, ix + 2) + "]";
								descending = TRUE;
								return_mode = 2;
								//echo(">> stack: " + list2js(JSON_ARRAY, stack));
							} else {
								// echo(">> NOT ENTERING A WHILE BODY; TEST FAILED");
								// ix = step_forward;
								// proceed to increment
								jump next;
							}
						} /*else {
							echo(">>#12: " + structure);
						}*/
						
						// init new stack frame for descent
						
						local_vars = "{}";
						parent = count(stack) - 1;
						last_symbol = NOWHERE;
						ix = [NOWHERE];
						
						// echo(">> Initialized new stack frame; " + (string)parent + " is now address of parent");
						
					} else if(previous_return_mode == 2) { // leaving a 'while' body; evaluate conditional again
						// echo(">> LEAVING A WHILE BODY; ix IS " + concat(ix, "."));
						
						stack += frame; //stack_frame(prog, ix, parent, local_vars, return_mode);
						prog = "[" + getjs(prog, alter(step_again, (list)1, LAST, LAST)) + "]";
						
						// echo(">> RE-CHECKING CONDITION " + (string)prog);
						
						// echo(">> stack after re-check frame is added: " + list2js(JSON_ARRAY, stack));
						
						return_mode = 1;
						local_vars = "{}";
						parent = count(stack) - 1;
						ix = [NOWHERE];
						last_symbol = NOWHERE;
						descending = TRUE;
					} /*else {
						echo(">>#11:" + structure);
					}*/
					jump next;
				}
			}
			
			backtrack = TRUE;
			// pcount = geti(ix, LAST);
			/*if(jstype(prog, ix) == JSON_ARRAY) {
				echo(">> Empty backtrack warning.");
				// ++pcount;
			}*/
			
			ix = delitem(ix, LAST);
			// ix = alter(ix, (list)(1 + geti(ix, -2)), LAST, LAST); // back out
		
		} else while(jstype(prog, ix) == JSON_ARRAY) { // at a list, so go in
			// echo(">> Engage descent");
			ix += 0;
			/*if(jstype(prog, ix) == JSON_ARRAY) { // THIS is the implicit progn
				echo(">> Empty descent!");
				// stack += JSON_NULL;
			}*/
			descending = TRUE;
		}
		
		string type = jstype(prog, ix);
		
		// we have an entry point; continue
		// parse should be in depth-first *exit*, so (9 (8 (5 (3 1 2) 4) 6 7)) (13 (12 10 11))
		
		if(type == JSON_NUMBER) {
			// echo(">> Number");
			stack += (float)getjs(prog, ix);
		} else if(descending) {
			string verb = getjs(prog, ix);
			
			#ifdef GENERAL_DEBUG
			echo(">> verb: " + verb);
			#endif
						
			if(verb == "if" || verb == "while") {
				/*
				ix = delitem(ix, LAST);
				string condition = "[" + getjs(prog, ix + [1]) + "]";
				string body = "[" + getjs(prog, ix + [2]) + "]";
				string alternative = "[" + getjs(prog, ix + [3]) + "]";
				
				// construct frame, put on stack and replace state with conditional
				
				list retval = execute([stack_frame(condition, [], TODO:parent, "{}", 1)]);
				
				// move to retmode evaluation within EOF backtracking case
				
				if(geti(retval, 0)) {
					stack += execute(stack_frame(body, [], TODO:parent, "{}", 0));
				} else if(alternative != JSON_INVALID) {
					stack += execute(stack_frame(alternative, [], TODO:parent, "{}", 0));
				}
				
				descending = FALSE;
				*/
				
				stack += stack_frame(prog, ix, parent, local_vars, return_mode, last_symbol); // push old state
				
				// set up conditional frame:
				prog = "[" + getjs(prog, delitem(ix, LAST) + 1) + "]";
				return_mode = 1;
				local_vars = "{}";
				parent = count(stack) - 1;
				ix = (list)NOWHERE;
				last_symbol = NOWHERE;
				
				// entering conditional structure:
				descending = TRUE;
				
				// do not backtrack:
				jump next;
				
			} else if(verb == "lambda") {
				ix = delitem(ix, LAST);
				string arglist = concat(js2list(getjs(prog, ix + 1)), " ");
				string code = getjs(prog, ix + 2);
				descending = backtrack = FALSE;
				stack += func_frame(arglist, code);
				jump next;

			} else {
				stack += verb_frame(verb, last_symbol);
				last_symbol = count(stack) - 1;
				// echo(">> (descend verb " + verb + " is non-structural)");
			}
		} else if(type == JSON_STRING) {
			// variable name or other literal:
			string s = getjs(prog, ix);
			if(s == "\\\"\\\"") {
				stack += "";
			} else if(substr(s, 0, 1) == "\\\"") { // list2js eats quotes
				stack += substr(s, 2, (integer)-3);
				// stack += s;
			} else if(substr(s, 0, 0) == "$") {
				string name = delstring(s, 0, 0);
				string local_type = jstype(local_vars, (list)name);
				integer temp_parent = parent;
				
				#ifdef GENERAL_DEBUG
					echo(">> searching for var " + name + " in stack (p=" + (string)parent + "):");
					integer sti = count(stack);
					while(sti--)
						echo("/me .. [" + (string)sti + "] " + gets(stack, sti));
				#endif
				
				string value;
				
				if(local_type != JSON_INVALID) {
					value = getjs(local_vars, (list)name);
				} else while(local_type == JSON_INVALID) {
					#ifdef GENERAL_DEBUG
						echo(">> get looking for " + name + " in " + (string)temp_parent);
					#endif
					if(~temp_parent) {
						string fr = gets(stack, temp_parent);
						local_type = jstype(fr, ["v", name]);
						value = getjs(fr, ["v", name]);
						
						#ifdef GENERAL_DEBUG
							if(local_type != JSON_INVALID)
								echo(">> get found " + name + " = " + value + " in " + (string)temp_parent);
						#endif
						temp_parent = (integer)getjs(fr, (list)"p");
					} else {
						integer si = index(v_names, name);
						if(~si) {
							integer global_type = llGetListEntryType(v_values, si);
							if(global_type == TYPE_FLOAT)
								stack += getf(v_values, si);
							else if(global_type == TYPE_INTEGER)
								stack += geti(v_values, si);
							else
								stack += gets(v_values, si);
							
							// stack += value;
							jump next;
						} else {
							// value = "?uninitialized?";
							echo(">> uninitialized variable: " + s);
							return [];
						}
					}
				}
				
				if(local_type == JSON_NUMBER) {
					if(llFabs((float)value - (float)( (integer)((float)value + 0.5) )) < ROUNDING_ERROR)
						stack += (integer)value;
					else
						stack += (float)value;
				} else {
					stack += value;
				}
				
			/*} else if(s == "") {
				echo(">> Literal null string");*/
			} else { // no idea; transmit literally
				// echo(">> Literal oddity " + s);
				stack += s;
			}
		} else if(backtrack) { // we are leaving; pop stack
			// integer pcount = geti(ix, LAST);
			
			/*
			if(!~last_symbol) {
				echo(">>attempted to dereference void symbol");
				return stack;
			}
			*/
			
			string verbf = gets(stack, last_symbol);
			string verb = getjs(verbf, (list)"s");
			
			if(verb == "") {
				last_symbol = (integer)getjs(verbf, (list)"sp");
				backtrack = descending = FALSE;
				jump next;
			}
			
			integer c;
			list params;
			{
				integer scount = count(stack) - last_symbol;
				c = scount - 1;
				if(c)
					params = sublist(stack, last_symbol + 1, LAST);
			}
			
			#ifdef GENERAL_DEBUG
				echo(">> " + verbf + " execute: (" + verb + " " + concat(params, " ") + "), c=" + (string)c);
			#endif
			
			stack = delrange(stack, last_symbol, LAST);
			
			last_symbol = (integer)getjs(verbf, (list)"sp");
			/*
			echo(">> Backtrack verb: " + verb);
			if(~parent)
				echo(">> Stack: " + concat(alter(stack, ["~"], parent, parent), "; "));
			else
				echo(">> Stack: " + concat(stack, "; "));*/
			
			if(verb == "list") {
				stack += list2js(JSON_ARRAY, params);
			} else if(verb == "print") {
				#ifdef COMPANION
					pipe_send((string)(params), user);
				#elif defined(ARES)
					print(outs, user, (string)params);
				#else
					echo((string)params);
				#endif
			} else if(verb == "global")	{
				string name = gets(params, 0);
				string data;
				if(c > 2)
					data = list2js(JSON_ARRAY, sublist(params, 1, LAST));
				else if(c == 2)
					data = gets(params, 1);
				
				integer si = index(v_names, name);
				if(~si) {
					v_values = alter(v_values, [data], si, si);
				} else {
					v_names += name;
					v_values += data;
				}
			
			} else if(verb == "set") {
				if(c < 2) {
					echo(">> unary set.");
					return [];
				}
				
				string name = gets(params, 0);
				list data = sublist(params, 1, LAST);
				
				string local_type = jstype(local_vars, (list)name);
				integer old_parent = NOWHERE;
				integer temp_parent = parent;
				
				string fr;
				
				while(local_type == JSON_INVALID) {
					#ifdef GENERAL_DEBUG
						echo(">> set looking for " + name + " in " + (string)temp_parent);
						echo(">> stack: " + list2js(JSON_ARRAY, stack));
					#endif
					if(~temp_parent) {
						fr = gets(stack, temp_parent);
						local_type = jstype(fr, ["v", name]);
						old_parent = temp_parent;
						temp_parent = (integer)getjs(fr, (list)"p");
						#ifdef GENERAL_DEBUG
							if(local_type != JSON_INVALID)
								echo(">> set storing " + list2js(JSON_ARRAY, data) + " in frame " + (string)old_parent + " as " + name);
						#endif
					} else {
						integer si = index(v_names, name);
						if(~si) {
							#ifdef GENERAL_DEBUG
							echo(">> set storing " + list2js(JSON_ARRAY, data) + " in globals as " + name);
							#endif
							v_values = alter(v_values, data, si, si);
						} else {
							local_vars = setjs(local_vars, (list)name, (string)data);
							#ifdef GENERAL_DEBUG
							echo(">> set creating " + list2js(JSON_ARRAY, data) + " in locals as " + name);
							#endif
						}
						jump done_set;
					}
				}
				
				if(~old_parent)
					stack = alter(stack, (list)setjs(fr, ["v", name], (string)data), old_parent, old_parent);
				else
					local_vars = setjs(local_vars, (list)name, (string)data);

				@done_set;
				
			// } else if(verb == "sum" || verb == "+" || verb == "add") {
			} else if(verb == "+") {
				float out = 0;
				while(c--)
					out += getf(params, c);
				
				stack += out;
				
				//stack += llListStatistics(LIST_STAT_SUM, params);
				
			//} else if(verb == "product" || verb == "*") {			
			} else if(verb == "*") {
				float out = 1;
				while(c--)
					out *= getf(params, c);
				
				stack += out;
			
			//} else if(verb == "eq" || verb == "==") {
			} else if(verb == "==") {
				if(etype(params, 0) == TYPE_STRING)
					stack += gets(params, 0) == gets(params, 1);
				else if(etype(params, 0) == TYPE_INTEGER)
					stack += geti(params, 0) == geti(params, 1);
				else
					stack += getf(params, 0) == getf(params, 1);
					
			// } else if(verb == "ne" || verb == "!=") {
			} else if(verb == "!=") {
				if(etype(params, 0) == TYPE_STRING)
					stack += gets(params, 0) != gets(params, 1);
				else if(etype(params, 0) == TYPE_INTEGER)
					stack += geti(params, 0) ^ geti(params, 1);
				else
					stack += getf(params, 0) != getf(params, 1);
			
			// } else if(verb == "lt" || verb == "<") {
			} else if(verb == "<") {
				stack += getf(params, 0) < getf(params, 1);
			
			//} else if(verb == "gt" || verb == ">") {
			} else if(verb == ">") {
				stack += getf(params, 0) > getf(params, 1);
				
			//} else if(verb == "lte" || verb == "<=") {
			} else if(verb == "<=") {
				stack += getf(params, 0) <= getf(params, 1);
			
			//} else if(verb == "gte" || verb == ">=") {
			} else if(verb == ">=") {
				stack += getf(params, 0) >= getf(params, 1);
			
			} else if(verb == "and") {
				integer out = 1;
				while(c--)
					out = out & geti(params, c);
				
				stack += out;
				
			} else if(verb == "or") {
				integer out = 0;
				while(c--)
					out = out | geti(params, c);
				
				stack += out;
				
			} else if(verb == "not" || verb == "!") {
				stack += !geti(params, 0);
				
			//} else if(verb == "-" || verb == "neg" || verb == "sub") {
			} else if(verb == "-") {
				if(c > 1) {
					float out = getf(params, 0);
					--c;
					while(c--) {
						out -= getf(params, c + 1);
					}
					stack += out;
				} else {
					stack += -getf(params, 0);
				}
				
			//} else if(verb == "/" || verb == "div") {
			} else if(verb == "/") {
				if(c > 1) {
					float out = getf(params, 0);
					--c;
					while(c--) {
						float newv = getf(params, c + 1);
						if(newv != 0)
							out /= newv;
						else {
							echo(">> Division by zero.");
							return [];
						}
					}
					stack += out;
				} else {
					float out = getf(params, 0);
					if(out != 0)
						stack += (1.0 / out);
					else {
						echo(">> Division by zero.");
						// stack += 0;
						return [];
					}
				}
			} else if(verb == "apply") {
				stack += stack_frame(prog, ix, parent, local_vars, return_mode, last_symbol);
				
				local_vars = "{}";
				ix = [NOWHERE];
				parent = count(stack) - 1;
				
				{
					string func = gets(params, 0);
					
					list arg_names = split(getjs(func, (list)"a"), " ");
					// bind args:
					integer an = count(arg_names);
					while(an--) {
						local_vars = setjs(local_vars, (list)gets(arg_names, an), gets(params, 1 + an));
					}
					
					prog = "[" + getjs(func, (list)"c") + "]";
					#ifdef GENERAL_DEBUG
					echo(">> applying function " + prog);
					#endif
				}
				
				descending = backtrack = FALSE;
				
				jump next;
				
			} else if(verb == "concat") {
				stack += concat(js2list(gets(params, 1)), gets(params, 0));
			
			} else if(verb == "split") {
				stack += list2js(JSON_ARRAY, split(gets(params, 1), gets(params, 0)));
			
			} else if(verb == "get") {
				stack += getjs(gets(params, 0), js2list(gets(params, 1)));
				
			} else if(verb == "index") {
				stack += index(js2list(gets(params, 0)), gets(params, 1));
				
			} else if(verb == "count") {
				stack += count(js2list(gets(params, 0)));
			
			} else if(verb == "put") {
				#ifdef GENERAL_DEBUG
				echo("Putting '" + gets(params, 2) + "' into '" + gets(params, 0) + "' at position: " + gets(params, 1));
				#endif
				stack += setjs(gets(params, 0), js2list(gets(params, 1)), gets(params, 2));
			
			} else if(verb == "char") {
				integer p = geti(params, 1);
				stack += substr(gets(params, 0), p, p);
			
			} else if(verb == "substr") {
				stack += substr(gets(params, 0), geti(params, 1), geti(params, 2));
			
			} else if(verb == "strpos") {
				stack += strpos(gets(params, 0), gets(params, 1));
				
			} else if(verb == "rand") {
				stack += llFrand(1);
				
			} else if(verb == "int") {
				stack += (integer)gets(params, 0);
			
			#ifdef ARES
			} else if(verb == "getd") {
				stack += getdb(gets(params, 0), gets(params, 1));
			} else if(verb == "setd") {
				setdb(gets(params, 0), gets(params, 1), gets(params, 2));
			} else if(verb == "deleted") {
				deletedb(gets(params, 0), gets(params, 1));
			} else if(substr(verb, 0, 0) == "@") {
				invoke(delstring(verb, 0, 0) + " " + (string)params, outs, NULL_KEY, user);
			}
			#endif
			
			#ifdef COMPANION
			} else if(verb == "external") {
				linked(LINK_ROOT, geti(params, 0), gets(params, 1), interrupt = llGenerateKey());
				// llSleep(0.25); // prevent self-activation
				interrupted_stack = stack;
				interrupted_frame = stack_frame(prog, ix, parent, local_vars, return_mode, last_symbol);
				// interrupted_program = prog;
				// interrupted_ix = ix;
				// echo("Paused execution.");
				return [];
			} else if(substr(verb, 0, 0) == "@") {
				start_task(EXECUTE, delstring(verb, 0, 0) + " " + (string)params, user);
			} else if(substr(verb, 0, 0) == "#") {
				start_task((integer)delstring(verb, 0, 0), (string)params, user);
			}
			#else
			else if(substr(verb, 0, 0) == "#") {
				llMessageLinked(LINK_THIS, (integer)delstring(verb, 0, 0), (string)params, user);
			}
			#endif
			else if(verb == JSON_INVALID) { // nil
				stack += "[]";
			} else if(verb == JSON_NULL) { // progn
				// echo(">> Null backtrack verb; params: " + concat(params, ", "));
				
				if(c)
					stack += sublist(params, LAST, LAST);
			} else {
				echo(">> unknown verb: " + verb);
			}
		} else {
			echo(">> unknown data type: " + type);
		}
		
		// result += getjs(prog, ix);
		
		descending = backtrack = FALSE;
		
		// echo(concat(ix, ">"));
	}
	
	// echo("Finished.");
	
	return stack;
}

string parse(list pq) {
	// match parens
	list opens; // indices of open parens
	integer tcount = count(pq);
	integer open_quote = NOWHERE;
	integer comment_start = NOWHERE;
	integer i;
	for(; i < tcount; ++i) {
		string t = gets(pq, i);
		if(~comment_start) {
			if(t == "\n") {
				pq = delrange(pq, comment_start, i);				
				tcount -= (i - comment_start + 1);
				i = comment_start;
				comment_start = NOWHERE;
			}
		} else if(~open_quote) {
			if(t == "\"") {
				string str;
				if(open_quote + 1 == i)
					str = "";
				else
					str = "\\\"" + concat(sublist(pq, open_quote + 1, i - 1), " ") + "\\\"";
				pq = alter(pq, [str], open_quote, i);
				i = open_quote;
				open_quote = NOWHERE;
			}
		} else {
			if(t == "") {
				pq = delitem(pq, i);
				--i;
				--tcount;
				// --i can't go in macro args; gets executed twice!
			} else if(t == "\"") {
				open_quote = i;
			} else if(t == "(") {
				opens += i;
			} else if(t == ";") {
				comment_start = i;
			} else if(t == "\n") {
				pq = delitem(pq, i);
				--i;
				--tcount;
			} else if(t == ")") {
				if(count(opens) == 0) {
					echo("++ Excess closing parens at " + (string)i + ".");
					return "";
				}
								
				integer L = geti(opens, LAST);
				opens = delitem(opens, LAST);
				string frag;
				if(L + 1 == i)
					frag = "[]";
				else
					frag = list2js(JSON_ARRAY, sublist(pq, L + 1, i - 1));
				if(jstype(frag, [0]) == JSON_ARRAY)
					frag = list2js(JSON_ARRAY, [JSON_NULL] + sublist(pq, L + 1, i - 1));
				pq = alter(pq, [frag], L, i);
				tcount = count(pq);
				i = L;
			}
		}
	}
	
	if(~open_quote) {
		echo("++ unclosed quote following: " + concat(sublist(pq, open_quote - 2, open_quote + 4), " "));
		return "";
	} else if(opens != []) {
		echo("++ imbalanced parens (" + (string)count(opens) + ").");
		return "";
	} else {
		// return json tree:
		
		/* #ifdef GENERAL_DEBUG
		echo("++ Parse results: " + list2js(JSON_ARRAY, pq));
		#endif */
		// return parsed;
		
		return list2js(JSON_ARRAY, pq);
	}
}

#ifndef ARES
default {
	state_entry() {
		#ifdef COMPANION
			list messages = [LISP_EXECUTE_FILE, LISP_EXECUTE_FUNC];
			list commands = ["lisp", "eval"];
			set_identity(MT_SERVICE, "interpreter for LSLisp", messages, commands);
			send_identity();
		#else
			echo((string)(llGetMemoryLimit() - llGetUsedMemory()) + " bytes available.");
		#endif
		
		//linked(LINK_THIS, LISP_EXECUTE_FILE, "ls_test", llGetOwner());
	}
	
	dataserver(key q, string m) {
		if(q == parse_q) {
			// llOwnerSay(".");
			if(m == EOF) {
				// llOwnerSay("-- Executing...");
				string prog = parse(parse_queue);
				parse_queue = [];
				list r = execute([stack_frame(prog, [], NOWHERE, "{}", 0, NOWHERE)]);
				
				if(interrupt) {
					// llOwnerSay("-- Interrupted!");
				} else if(r != []) {
					pipe_send(concat(r, " "), user);
				}
			} else {
				parse_queue += ["\n"] + tokenize(m);
				parse_q = llGetNotecardLine(filename, ++parse_n);
			}
		}
	}
	
	link_message(integer src, integer n, string m, key id) {
		#ifdef COMPANION
			// llOwnerSay("Incoming message from " + (string)src + ": " + (string)n + "; " + (string)m + "; " + string(id));
			if(n == EXECUTE || n == COMMAND) {
				list argv = split(m, " ");
				string cmd = gets(argv, 0);
				integer argc = count(argv);
				if(cmd == "lisp") {
					if(argc == 1 || gets(argv, 1) == "help") {
						list file_list;
						integer fi = llGetInventoryNumber(INVENTORY_NOTECARD);
						while(fi--) {
							string nc = llGetInventoryName(INVENTORY_NOTECARD, fi);
							if(substr(nc, 0, 2) == "ls_")
								file_list = substr(nc, 3, LAST) + file_list;
						}
						
						tell(id, 0, "lisp <filename>\n\nExecutes the notecard ls_<filename> using the LSLisp interpreter. See http://develop.nanite-systems.com/lisp for more information. Available cards: " + concat(file_list, ", "));
					} else {
						start_task(LISP_EXECUTE_FILE, "ls_" + concat(sublist(argv, 1, LAST), " "), id);
					}
				} else if(cmd == "eval") {
					if(argc == 1 || gets(argv, 1) == "help") {
						tell(id, 0, "eval <function>\n\nExecutes the provided source code directly using the LSLisp interpreter. See http://develop.nanite-systems.com/lisp for more information.");
					} else {
						start_task(LISP_EXECUTE_FUNC, concat(sublist(argv, 1, LAST), " "), id);
					}
				}
			} else if(n == PROBE_MODULES && (m == "" || m == llGetScriptName())) {
				send_identity();
			} else 
		#endif
		
		if(n == LISP_EXECUTE_FILE) {
			if(id)
				user = id;
			else
				user = llGetOwner();
			
			// program = "";
			parse_queue = v_names = v_values = interrupted_stack = [];
			interrupt = "";
			
			// llOwnerSay("-- Loading...");
			parse_q = llGetNotecardLine(filename = m, parse_n = 0);
		} else if(n == LISP_EXECUTE_FUNC) {
			if(id)
				user = id;
			else
				user = llGetOwner();
			
			// llOwnerSay("-- Evaluating...");
			list r = execute([stack_frame(parse(tokenize(m)), [], NOWHERE, "{}", 0, NOWHERE)]);
			if(interrupt) {
				// llOwnerSay("-- Interrupted!");
			} else if(r != []) {
				pipe_send(concat(r, " "), user);
			}
		} else if(interrupt) {
			if(id == interrupt) {
				interrupted_stack += m;
				// interrupt = ""; - now cleared within execute()
				
				list r = execute(interrupted_stack + interrupted_frame);
				if(interrupt) {
					// llOwnerSay("-- Interrupted!");
				} else if(r != []) {
					pipe_send(concat(r, " "), user);
				}
			}
		}
	}
}
#endif // ARES

