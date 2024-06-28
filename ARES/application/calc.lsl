/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Calculator Utility
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

#define PUSH(_list, _item) _list += (list)(_item)
#define SHIFT(_list) gets(_list, 0); _list = delitem(_list, 0)
#define POP(_list) gets(_list, LAST); _list = delitem(_list, LAST)
#define UNSHIFT(_list, _item) _list = (list)(_item) + _list

#define SYMBOLS ["<<", ">>", "+", "-", "**", "*", "/", "%", "^", "~", "&&", "||", "&", "|", "(", ")"]

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		llSetMemoryLimit(0x10000);
		llScriptProfiler(amm_profiling = PROFILE_SCRIPT_MEMORY);
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg;
		if(argc == 1) {
			msg = "Usage: " + PROGRAM_NAME + " [-x|-d|-e] <calculation>\n    -x: Return result in hexadecimal\n    (input hex values as 0xff)\n    -d: Decode from ARES base64\n    -e: Encode to ARES base64\n    -r [[<min>] <max>]: generate a random integer between <min> (or 0) and (<max> - 1); if no bounds are specified, generates a random float between 0.0 and 1.0\n\nSupported symbols: " + concat(SYMBOLS, ", ");
		} else {
			integer hex_output;
			integer ARES_decode;
			integer ARES_encode;
			string first = gets(argv, 1);
			if(first == "-r") {
				if(argc == 2)
					msg = (string)llFrand(1.0);
				else if(argc == 3)
					msg = (string)((integer)llFrand((float)gets(argv, 2)));
				else if(argc == 4)
					msg = (string)((integer)(llFrand((float)gets(argv, 3) - (float)gets(argv, 2))) + (integer)gets(argv, 2));
				
				jump error;
			} else if(first == "-x") {
				hex_output = 1;
				argv = delitem(argv, 1);
				#ifdef DEBUG
				echo("hexadecimal output enabled if result is integer");
				#endif
			} else if(first == "-d") {
				ARES_decode = 1;
				string t0 = gets(argv, 2);
				argv = alter(argv, [ares_decode(t0)], 1, 2);
			} else if(first == "-e") {
				ARES_encode = 1;
				argv = delitem(argv, 1);
			}
			list tokens = llParseString2List(concat(delitem(argv, 0), " "), [" "], sublist(SYMBOLS, 0, 7));
			// n.b. there is a hard limit of 8 separators
			integer ti = 0;
			integer imax = count(tokens);
			list symbol_block_2 = sublist(SYMBOLS, 8, 15);
			while(ti < imax) {
				list tr = llParseString2List(gets(tokens, ti), [], symbol_block_2);
				tokens = alter(tokens, tr, ti, ti);
				integer tri = count(tr);
				if(tri) {
					ti += tri;
					imax += tri - 1;
				} else {
					++ti;
				}
			}
			
			#ifdef DEBUG
			echo("Initial tokens: " + concat(tokens, ", "));
			#endif
			
			#define SYMBOL_TEXT 0
			#define SYMBOL_CLASS 1
			
			#define C_IS_ATOM 0x001
			#define C_INTEGER 0x03
			#define C_FLOAT 0x05
			
			#define C_OPEN_PAREN 0x0400
			#define C_CLOSE_PAREN 0x0600
			
			#define C_IS_OPERATOR 0x1000
			#define C_IS_UNARY 0x0010
			
			#define C_UNARY 0x1710
			// C_UNARY consists of unary - ~
			#define C_EXP 0x1600
			// C_EXP consists of ** << >>
			#define C_MUL 0x1500
			// C_MUL consists of * / %
			#define C_SUM 0x1400
			// C_SUM consists of + -
			#define C_BIT 0x1300
			// C_BIT consists of ^ & |
			#define C_NOT 0x1210
			// C_NOT consists of unary !
			#define C_BOOL 0x1100
			// C_BOOL consists of && ||
			
			tokens = ["("] + tokens + [")"];
			imax += 2;
			
			// each token is represented as a doublet: [text,class]
			list stack = [];
			
			list parse;
			
			integer i = 0;
			
			#define T_OPEN_PAREN "[\"\",64]"
			
			while(i < imax) {
				string token_text = SHIFT(tokens);
				integer first = llOrd(token_text, 0);
				
				string top = gets(stack, LAST);
				string top_text;
				integer top_class;
				if(top != "") {
					top_class = (integer)getjs(top, [SYMBOL_CLASS]);
					top_text = getjs(top, [SYMBOL_TEXT]);
				} else {
					top_class = NOWHERE;
					top_text = "?";
				}
				
				integer token_class;
				
				if(first == 0x30 || first == 0x2e || (float)token_text != 0) { // '0' or '.'
					if(~strpos(token_text, "."))
						token_class = C_FLOAT;
					else if(~strpos(token_text, "x"))
						token_class = C_INTEGER;
					else if(~strpos(token_text, "e"))
						token_class = C_FLOAT;
					else
						token_class = C_INTEGER;
					
				} else if(token_text == "(") {
					token_text = "";
					token_class = C_OPEN_PAREN;
				} else if(contains(SYMBOLS, token_text)) {
					if(token_text == "-") {
						if(top_class == C_OPEN_PAREN && ((integer)getjs(gets(parse, LAST), [SYMBOL_CLASS]) & C_IS_ATOM)) {
							token_class = C_SUM;
							#ifdef DEBUG
							echo("interpreted - as first subtraction in pg");
							#endif
						} else if(top_class == C_OPEN_PAREN) {
							token_class = C_UNARY;
							#ifdef DEBUG
							echo("interpreted - as negative at start of pg");
							#endif
						} else if(top_class & C_IS_OPERATOR) {
							token_class = C_UNARY;
							#ifdef DEBUG
							echo("interpreted - as negative after op " + top_text);
							#endif
						} else {
							token_class = C_SUM;
							#ifdef DEBUG
							echo("interpreted - as base case subtraction");
							#endif
						}
					} else if(token_text == "~")
						token_class = C_UNARY;
					else if(token_text == "**" || token_text == "<<" || token_text == ">>")
						token_class = C_EXP;
					else if(token_text == "*" || token_text == "/" || token_text == "%")
						token_class = C_MUL;
					else if(token_text == "+")
						token_class = C_SUM;
					else if(token_text == "^" || token_text == "&" || token_text == "|")
						token_class = C_BIT;
					else if(token_text == "!")
						token_class = C_NOT;
					else if(token_text == "&&" || token_text == "||")
						token_class = C_BOOL;
					else if(token_text == ")")
						token_class = C_CLOSE_PAREN;
					
				} else {
					msg = "Unknown symbol: " + token_text;
					jump error;
				}
				
				string token = jsarray([token_text, token_class]);
				
				#ifdef DEBUG
				echo("evaluating token " + token + " and stack " + concat(stack, " · "));
				#endif
				
				if(token_class & C_IS_ATOM) {
					// numeric atom
					#ifdef DEBUG
					echo("top when evaluating atom " + token_text + ": " + (string)top_class);
					#endif
					if(top_class & C_IS_ATOM) {
						msg = "Bad syntax: two consecutive atoms " + top_text + " " + token_text;
						jump error;
					} else if(top_class == C_OPEN_PAREN || top_class == 0) {
						PUSH(parse, token);
						#ifdef DEBUG
						echo("emitted first token of paren group: " + token);
						#endif
					} else {
						PUSH(stack, token);
						#ifdef DEBUG
						echo("stacked " + token);
						#endif
					}
				} else if(token_class == C_OPEN_PAREN) {
					PUSH(stack, token);
					#ifdef DEBUG
					echo("stacked open paren");
					#endif
				} else { // must be an operator or C_CLOSE_PAREN
					string second = gets(stack, -2);
					integer second_class = (integer)getjs(second, [SYMBOL_CLASS]);
					/*
						possibilities for an operator (using /):
						input        stack       current parse   correct action			final parse
						1/2          (           1               stack / 2              1 2 /
						(1+2)/3      (           1 2 +           stack / 3              1 2 + 3 /
						1**3/2       ( ** 3      1               emit 3 **, stack / 2   1 3 ** 2 /
						1+2/3        ( + 2       1               stack / 3              1 2 3 / +
						1+2/3**4	 ( + 2       1               stack / 3              1 2 3 4 ** / +
						1+2/3/4                                                         1 2 3 / 4 / +
						1+2/3+4                                                         1 2 3 / 4 + +
						1*2/3*4                                                         1 2 * 3 / 4 *
						1%2/3        ( % 2       1               emit 2 %, stack / 3    1 2 % 3 /
						1+(1+2/3)**3 ( + ( + 2   1 1 			 stack / 3              1 1 2 3 / + + 3 **
						
						shift leftovers
					*/
					
					if(token_class & C_IS_OPERATOR) {
						if(second_class & C_IS_OPERATOR) {
							// emit [top, second] only if second_class is at least token_class
							if(second_class >= token_class && top_class != C_OPEN_PAREN) {
								PUSH(parse, top);
								PUSH(parse, second);
								#ifdef DEBUG
								echo("precedence decision: emitted " + top + " and " + second + " instead of " + token);
								#endif
								stack = delrange(stack, -2, -1);
							}
						}
						
						// convert unary operators into binary operators:
						if(token_class & C_IS_UNARY) {
							PUSH(stack, top = jsarray([top_text = "0", top_class = C_INTEGER]));
						}
						
						PUSH(stack, token);
					}
				}
				
				++i;
				if(token_class == C_CLOSE_PAREN || i == imax) {
					string arg;
					string a2;
					while(count(stack) && (i == imax || arg != T_OPEN_PAREN)) {
						arg = POP(stack);
						if((integer)getjs(arg, [SYMBOL_CLASS]) & C_IS_ATOM) {
							a2 = arg;
							arg = POP(stack);
							
							string a3 = gets(stack, LAST);
							if((integer)getjs(a3, [SYMBOL_CLASS]) & C_IS_ATOM) {
								POP(stack);
								PUSH(parse, a3);
								#ifdef DEBUG
								echo("consume a3 " + a3);
								#endif
							}
							
							if((integer)getjs(a2, [SYMBOL_CLASS]) != C_OPEN_PAREN) {
								PUSH(parse, a2);
								#ifdef DEBUG
								echo("a2 emit " + a2);
								#endif
							}
							#ifdef DEBUG
							else {
								echo("a2 no emit paren");
							}
							#endif
						}
						if((integer)getjs(arg, [SYMBOL_CLASS]) != C_OPEN_PAREN) {
							PUSH(parse, arg);
							#ifdef DEBUG
							echo("arg emit " + arg);
							#endif
						}
						#ifdef DEBUG
						else {
							echo("arg no emit paren");
						}
						#endif
					}
					#ifdef DEBUG
					echo("drainage stopped on " + arg);
					#endif
				}
			}
			
			#ifdef DEBUG
			echo("Final parse: " + concat(parse, " · "));
			#endif
			
			list execution_stack;
			
			while(count(parse)) {
				string token = SHIFT(parse);
				string text = getjs(token, [SYMBOL_TEXT]);
				integer class = (integer)getjs(token, [SYMBOL_CLASS]);
				if(class & C_IS_ATOM) {
					PUSH(execution_stack, token);
				} else if(class & C_IS_OPERATOR) {
					string right = POP(execution_stack);
					string left = POP(execution_stack);
					string left_text = getjs(left, [SYMBOL_TEXT]);
					string right_text = getjs(right, [SYMBOL_TEXT]);
					integer li = (integer)left_text;
					integer ri = (integer)right_text;
					float lf = (float)left_text;
					float rf = (float)right_text;
					integer left_is_float = (llFabs(lf - (float)li) > 0.0001) || ~strpos(left_text, ".");
					integer right_is_float = (llFabs(rf - (float)ri) > 0.0001) || ~strpos(right_text, ".");
					integer have_floats = left_is_float || right_is_float;

					string result_text;
					integer result_type = C_INTEGER;
					
					if(have_floats)
						result_type = C_FLOAT;
					
					if(text == "<<") {
						result_text = (string)(li << ri);
					} else if(text == ">>") {
						result_text = (string)(li >> ri);
					} else if(text == "+") {
						if(have_floats)
							result_text = (string)(lf + rf);
						else
							result_text = (string)(li + ri);
					} else if(text == "-") {
						if(have_floats)
							result_text = (string)(lf - rf);
						else
							result_text = (string)(li - ri);
					} else if(text == "**") {
						if(have_floats)
							result_text = (string)llPow(lf, rf);
						else
							result_text = (string)llPow(li, ri);
					} else if(text == "*") {
						if(have_floats)
							result_text = (string)(lf * rf);
						else
							result_text = (string)(li * ri);
					} else if(text == "/") {
						if(have_floats)
							result_text = (string)(lf / rf);
						else
							result_text = (string)(li / ri);
					} else if(text == "%") {
						result_text = (string)(li % ri);
					} else if(text == "^") {
						result_text = (string)(li ^ ri);
					} else if(text == "~") {
						result_text = (string)(~ri);
					} else if(text == "&&") {
						result_text = (string)(li && ri);
					} else if(text == "||") {
						result_text = (string)(li || ri);
					} else if(text == "&") {
						result_text = (string)(li & ri);
					} else if(text == "|") {
						result_text = (string)(li | ri);
					} else {
						msg = "Unknown operator " + text;
						jump error;
					}
					
					PUSH(execution_stack, jsarray([result_text, result_type]));
				} else {
					msg = "Parse invalid: found token " + token + " in execution stack";
					jump error;
				}
			}
			
			if(count(execution_stack) != 1) {
				msg = "Error: multiple results: " + concat(execution_stack, " · ");
			} else {
				string final_output = gets(execution_stack, 0);
				integer final_class = (integer)getjs(final_output, [SYMBOL_CLASS]);
				string final_text = getjs(final_output, [SYMBOL_TEXT]);
				/* #ifdef DEBUG
				echo("hex output? " + (string)hex_output + "; final class = " + (string)final_class);
				#endif*/
				if(substr(final_text, 0, 1) == "0x")
					final_text = (string)((integer)final_text);
				
				if(hex_output && final_class == C_INTEGER) {
					msg = "0x" + hex((integer)final_text);
				} else if(ARES_encode && final_class == C_INTEGER) {
					integer v = (integer)final_text;
					msg = ares_encode(v);
				} else {
					msg = final_text;
				}
			}
		}
		
		@error;
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
