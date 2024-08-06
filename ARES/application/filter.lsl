/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Text Filter Utilities (Standard Bundle)
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

list filters = [
	// filter		layer
	"censor",		0,
	"replace",		0,
	"slang",		0,
	"nonverbal",	1,
	"translate",	1,
	"stutter",		2,
	"serpentine",	2,
	"lisp",			3,
	"mumble",		4,
	"caps",			5,
	"rot13", 		5,
	"slow",			5,
	"bimbo",		6,
	"superscript",	6,
	"corrupted",	7,
	"glitch",		7
];

string f_censor(string message, string flags) {
	if(flags == "") {
		echo("No censor dictionary specified. See 'help censor'");
		return message;
	} else {
		list words = js2list(getdbl("filter", ["censor", flags]));
		// echo("Censor word list: " + (string)concat(words, ", "));
		integer wi = 0;
		integer wmax = count(words);
		string new_message = message;
		string search_space = llToLower(new_message);
		
		while(wi < wmax) {
			string word = gets(words, wi++);
			if(word == JSON_INVALID) {
				echo("Censor dictionary not found: " + flags + ". See 'help censor'");
				return message;
			}
			string replacement;
			integer ci;
			integer wlen = 0;
			while(~(ci = strpos(search_space, word))) {
				if(!wlen) {
					wlen = strlen(word) - 1;
					replacement = substr("********************************", 0, wlen);
				}
				new_message = llInsertString(delstring(new_message, ci, ci + wlen), ci, replacement);
				search_space = llInsertString(delstring(search_space, ci, ci + wlen), ci, replacement);
				
				// echo("Replaced " + word + " with " + replacement + ": " + new_message);
			}
			// new_message = replace(new_message, word, replacement);
		}
		return new_message;
	}
}

string f_replace(string message, string dictionary_name) {
	string dictionary = getdbl("filter", ["replace", dictionary_name]);
	if(dictionary == JSON_INVALID) {
		echo("[filter] warning: replacement dictionary " + dictionary_name + " does not exist. See 'help replace'");
		return message;
	}
	
	string out = "";
	integer limit = strlen(message);
	integer sentence_start = TRUE;
	string word;
	while(limit >= 0) { // one extra iteration ensures last word is emitted
		integer c = llOrd(message, 0);
		string cs = llChar(c);
		if(c == 0x27 /* ' */ || llToLower(cs) != llToUpper(cs)) {
			word += cs;
			// echo("word includes " + cs);
		} else {
			// echo("separator " + cs);
			integer c_len = strlen(word);
			if(c_len > 0) {
				while(llOrd(word, 0) == 0x27) { // '
					out += "'";
					word = delstring(word, 0, 0);
					c_len -= 1;
				}
				string suffix = "";
				while(llOrd(word, LAST) == 0x27) { // '
					suffix = "'" + suffix;
					word = delstring(word, LAST, LAST);
					c_len -= 1;
				}
				
				if(c_len > 0) {
					string replacement = word;
					string new;
					if((new = getjs(dictionary, [word])) != JSON_INVALID) {
						replacement = new; // exact capitalization match
					} else if((new = getjs(dictionary, [llToLower(word)])) != JSON_INVALID) {
						if(word == llToUpper(word) && !(c_len == 1 && sentence_start) && word != "I") {
							//echo(word + " is type 0");
							// word was entered in all caps and isn't just a one-letter word at the start of the sentence or "I"
							replacement = llToUpper(new);
						} else if(word == "I" && !sentence_start) {
							// echo(word + " is type 1");
							// avoid transferring first-letter capitalization from "I" in the middle of a sentence:
							replacement = new;
						} else if(substr(word, 0, 0) == llToUpper(substr(word, 0, 0))) {
							// echo(word + " is type 2");
							// word began with a capital letter (including "I" at the start of a sentence):
							replacement = llToUpper(substr(new, 0, 0)) + substr(new, 1, LAST);
						} else {
							// echo(word + " is type 3");
							replacement = new;
						}
					}
					// echo("emitting word " + replacement);
					out += replacement + suffix;
					/* if(sentence_start)
						echo("no longer sentence start after emitting " + replacement + " at position " + (string)i); */
					sentence_start = FALSE;
				} else {
					out += suffix;
				}
				word = "";
			}
			
			if(
				((c == 33 || c == 65 || c == 46) && llOrd(message, 1) == 32)  // ! ? . followed by space
			|| (c == 10)) { // line feed
				sentence_start = TRUE;
				// echo("Sentence start at position " + (string)i);
			}
			
			// echo("appending characters " + cs);
			out += cs;
		}
		
		message = delstring(message, 0, 0);
		--limit;
	}
	
	return out;
}

string f_slang(string message, string flags) {
	if(flags == "") {
		echo("Warning: no slang table specified; see 'help slang'.");
		return message;
	}
	
	string dictionary = getdbl("filter", ["slang", flags]);
	if(dictionary == JSON_INVALID) {
		echo("Warning: slang table " + flags + " does not exist; see 'help slang'.");
		return message;
	}
	
	list prefixes = js2list(getjs(dictionary, ["pre"])); integer pc = count(prefixes);
	list infixes = js2list(getjs(dictionary, ["mid"])); integer ic = count(infixes);
	list suffixes = js2list(getjs(dictionary, ["post"])); integer sc = count(suffixes);
	
	list sentences = llParseStringKeepNulls(message + " ", [], [". ", "? ", "! "]);
	// echo(concat(sentences, "|"));
	integer si = count(sentences);
	while(si--) {
		string sentence = gets(sentences, si);
		if(strlen(sentence) > 2) {
			list words = splitnulls(sentence, " ");
			integer wc = count(words);
			if(wc > 1) {
				string prefix = gets(prefixes, (integer)llFrand(pc));
				string suffix = gets(suffixes, (integer)llFrand(sc)) + " ";
				string infix = gets(infixes, (integer)llFrand(ic));
				integer wi = (integer)llFrand(wc);
				words = alter(words, [llToLower(gets(words, 0))], 0, 0);
				words = [prefix] + llListInsertList(words, [infix], wi) + [suffix];
			}
			
			sentences = alter(sentences, [concat(words, " ")], si, si + 1);
		}
	}
	return llStringTrim(concat(sentences, ""), STRING_TRIM);
}

/*
string transfer_capitals(string source, string dest) {
	string result;
	integer ci = 0;
	integer cimax = strlen(source);
	integer d = strlen(dest);
	integer c;
	while(ci < cimax) {
		integer a = llOrd(source, ci);
		integer b = llOrd(dest, ci);
		if(a < 0x80 && b < 0x80) { // if ASCII, work with integers
			if(a > 0x40 && a < 0x5b) {
				++c;
				if(b > 0x60 && b < 0x7b) {
					result += llChar(b - 0x20);
				} else {
					result += llChar(b);
				}
			} else {
				result += llChar(b);
			}
		} else { // otherwise fall back to llToUpper()/llToLower()
			string ac = llChar(a);
			string bc = llChar(b);
			string caps = llToUpper(ac);
			string small = llToLower(ac);
			if(caps != small && ac == caps) {
				++c;
				result += llToUpper(bc);
			} else {
				result += bc;
			}
		}
		++ci;
	}
	
	// deal with extended words:
	if(d > cimax) {
		if(c == cimax && c > 1)
			result += llToUpper(substr(dest, cimax, d));
		else
			result += substr(dest, cimax, d);
	}
	
	// yield:
	return result;
} */

string last_nonverbal_flags = "m o o";
string f_nonverbal(string message, string flags) {
	if(flags == "")
		flags = last_nonverbal_flags;
	else
		last_nonverbal_flags = flags;
	
	list parts = split(llToLower(flags), " ");
	string prefix = gets(parts, 0); integer prelen = strlen(prefix);
	string infix = gets(parts, 1); integer inlen = strlen(infix);
	string suffix = gets(parts, 2); integer suflen = strlen(suffix);
	
	string out;
	
	integer fmax = strlen(message);
	integer fi = 0;
	string word;
	while(fi < fmax) {
		string char = substr(message, fi, fi);
		if(llToUpper(char) != llToLower(char)) {
			word += char;
		} else {
			if(word) {
				integer wmax = strlen(word);
				integer wi = 0;
				string raword;
				if(wmax <= prelen + inlen + suflen) {
					raword = prefix + infix + suffix;
				} else {
					raword = prefix;
					integer jl = wmax - prelen - suflen;
					while(jl > 0) {
						raword += infix;
						jl -= inlen;
					}
					raword += suffix;
				}
				if(llToUpper(word) == word)
					raword = llToUpper(raword);
				else if(llToLower(word) != word)
					raword = llToUpper(substr(raword, 0, 0)) + substr(word, 1, LAST);
				/* else
					word = raword; */
				// word = transfer_capitals(word, raword);
				
				out += raword;
				word = raword = "";
			}
			out += char;
		}
		++fi;
	}
	
	return out;
}

#define TRANSLATION_URL "http://mymemory.translated.net/api/get?q=" + llEscapeURL(message) + "&langpair=" + replace(flags, ":", "|") + "&de=" + (string)avatar + "@lsl.secondlife.com"
key translate_pipe;
list translation_queue; 

f_translate(string message, string flags, key outs, key ins, key user, integer rc) {
	if(flags == "") {
		echo("Cannot translate; no translation language pair set: " + message + ". See 'help translate'");
		print(outs, user, message);
		// resolve_io(rc, outs, ins);
		resolve_i(rc, ins);
		return;
	}

	key handle = llGenerateKey();
	translation_queue += [message, flags, handle, outs, ins, user, rc];
	
	if(translate_pipe) {		
		#ifdef DEBUG
		echo("sending message " + message + " for translation immediately");
		#endif
		http_get(TRANSLATION_URL, translate_pipe, handle);
	} else {		
		#ifdef DEBUG
		echo("opening translation pipe");
		#endif
		translate_pipe = llGenerateKey();
		pipe_open(["p:" + (string)translate_pipe + " notify " + PROGRAM_NAME + " translation"]);
	}
}

/* string match_case(string question, string answer) {
    if(llToLower(answer) == answer) {
        return llToLower(question);
    } else {
        return llToUpper(question);
    }
} */

string f_stutter(string message, string flags) {
	float stutter_level = (float)flags;
	if(flags == "" || stutter_level == 0)
		return message;
	
	list tokens = [" "] + llParseString2List(message, [], [" ", "a", "e", "i", "o", "u", "y", "A", "E", "I", "O", "U", "Y"]) + [" "];
    integer tc = count(tokens);
    integer ti = tc - 1;
    while(ti--) {
        if(gets(tokens, ti) == " ") {
            string nt = gets(tokens, ti + 1);
            string nt2 = gets(tokens, ti + 2);
            if(llFrand(100) <= stutter_level) {
                string pnt = substr(nt, 0, 0);
                if(llToLower(pnt) != llToUpper(pnt)) {
					string ntx;
					if(llToLower(nt2) == nt2)
						ntx = llToLower(nt);
					else
						ntx = llToUpper(nt);
					
                    if(~strpos("aeiouy", llToLower(nt))) { // starting with a vowel
                        nt += "-" + ntx;
                        if(llFrand(100) <= stutter_level) {
                            nt += "-" + ntx;
                            if(llFrand(100) <= stutter_level) {
                                nt += "-" + ntx;
                            }
                        }
                        tokens = alter(tokens, [nt], ti + 1, ti + 1);
                    } else if(nt2 != " ") { // consonants before a vowel
                        if(llFrand(100) < 50) // extend consonants only
                            nt2 = "-" + nt;
                        
                        nt += nt2 + "-" + ntx;
                        if(llFrand(100) <= stutter_level) {
                            nt += nt2 + "-" + ntx;
                            if(llFrand(100) <= stutter_level) {
                                nt += nt2 + "-" + ntx;
                            }
                        }
                        tokens = alter(tokens, [nt], ti + 1, ti + 1);
                    }
                }
            }
        }
    }
    
    return substr(concat(tokens, ""), 1, -2);
}

string f_serpentine(string message, string flags) {
	if(flags == "") flags = "100";
	float serpentine_strength = 0.01 * (float)flags;
	
	if(serpentine_strength > 0.0) {
        integer i = 0;
        integer j = 0;
        while(i < strlen(message)) {
            string e = substr(message, i, i);
            string f = substr(message, i, i + 1);
            if(f == "ci" || f == "CI" || f == "CE" || f == "ce") {
                e = e + e;
                j = 1;
            } else if(f == "SH") {
                e = f;
            } else if(f == "sh" || f == "Sh") {
                e = "sh";
            } else if(e == "s" || e == "z" || e == "S" || e == "Z" || e == "ß") {
                e = e + e;
                j = 1;
            } else
                e = "";
                
            if(llFrand(1.0) < serpentine_strength && e != "") {
                message = substr(message, 0, i) + e + substr(message, i + 1, LAST);
                ++i;
                if(j) {
                    j = 0;
                    ++i;
                }
            } else {
                ++i;
            }
        }
    }
    
    return message;
}

string f_lisp(string message, string flags) {
	if(flags == "") flags = "100";
	float lisp_strength = 0.01 * (float)flags;

	integer i = 0;
    integer j = 0;
    while(i <= strlen(message) - 1) {
        string e = substr(message, i, i);
        string f = substr(message, i, i+1);
        string g = substr(message, i+1, i+1);
        if(g == "") g = e;        
                
        j = 1;
        if(e == "s" || e == "z" || e == "ß") {
            e = "th";
            j = 0;
        } else if(f == "ci" || f == "ce" || f == "sh" || f == "cc" || f == "zh") {
            e = "th";
        } else if(f == "Ci" || f == "Ce" || f == "Sh" || f == "Cc" || f == "Zh" || (llToLower(g) == g && ( e == "S" || e == "Z"))) {
            e = "Th";
        } else if(f == "CI" || f == "CE" || f == "SH" || f == "CC" || f == "ZH" || e == "S" || e == "Z") {
            e = "TH";
        } else {
            e = "";
            j = 0;
        }
                
        if(llFrand(1.0) < lisp_strength && e != "") {
            if(strlen(message) == 1)
                message = e;
            else if(i == strlen(message) - 1)
                message = substr(message, 0, i - 1) + e;
            else if(i > 0)
                message = substr(message, 0, i - 1) + e + substr(message, i + 1, -1);
            else
                message = e + substr(message, i + 1, -1);
            
            ++i;
            if(j) {
                i += j;
            }
        } else {
            ++i;
        }
    }
    
    return message;
}

// based on fp_gagvox from the NS Ballgag

list orig_4 = ["tion", "tial"];
list repl_4 = ["fhion", "fho"];

list orig_3 = ["sch"];
list repl_3 = ["fh"];

list orig_2 = ["ss", "ci", "th", "sh", "ge", "ch"];
list repl_2 = ["ffh", "fi", "w", "hw", "wye", "tfh"];

list orig_1 = ["s", "l", "t", "r", "p", "b", "j", "z"];
list repl_1 = ["fh", "w", "ht", "w", "k", "w", "dh", "v"];

#define MIXED 0
#define LOWER 1
#define UPPER 2

string f_mumble(string message, string flags) {
    integer i = 0;
    integer L = strlen(message);
    message = message + " ";
    
    list out_tokens;
    
    while(i < L) {
        string src_4 = substr(message, i, i + 3);
        string src_3 = substr(message, i, i + 2);
        string src_2 = substr(message, i, i + 1);
        string src_1 = substr(message, i, i + 0);
        
        integer case = MIXED;
        
        if(llToLower(src_2) == src_2)
            case = LOWER;
        else if(llToUpper(src_2) == src_2)
            case = UPPER;
        
        integer i4 = index(orig_4, llToLower(src_4));
        integer i3 = index(orig_3, llToLower(src_3));
        integer i2 = index(orig_2, llToLower(src_2));
        integer i1 = index(orig_1, llToLower(src_1));
        integer ll = 0;
        
        string out_token;
        
        if(~i4) {
            out_token = gets(repl_4, i4);
            i += 4;
        } else if(~i3) {
            out_token = gets(repl_3, i3);
            i += 3;
        } else if(~i2) {
            out_token = gets(repl_2, i2);
            i += 2;
        } else if(~i1) {
            out_token = gets(repl_1, i1);
            i += 1;
            if(llToUpper(src_1) == src_1 && strlen(out_token) == 1) {
                ll = 1;
                out_token = llToUpper(out_token);
            }
        } else {
            out_token = src_1;
            i += 1;
            ll = 1;
        }
        
        if(ll || case == LOWER)
            out_tokens += out_token;
        else if(case == UPPER)
            out_tokens += llToUpper(out_token);
        else if(case == MIXED)
            out_tokens += llToUpper(substr(out_token, 0, 0)) + substr(out_token, 1, -1);
    }
    
    return concat(out_tokens, "");
}

string f_caps(string message, string flags) {
	return llToUpper(message);
}

string f_rot13(string message, string flags) {
	string out;
	integer fmax = strlen(message);
	integer fi;
	while(fi < fmax) {
		integer c = llOrd(message, fi++);
		if(c > 0x40 && c < 0x5b) { // after @ and before [
			c -= 13;
			if(c < 0x41)
				c += 26;
		} else if(c > 0x60 && c < 0x7b) { // after ` and before {
			c -= 13;
			if(c < 0x61)
				c += 26;
		}
		out += llChar(c);
	}
	return out;
}

string f_slow(string message, string flags) {
	// echo("FLAGS = " + flags);
	return replace(message, " ", substr("                ", 0, llAbs((integer)flags)));
}

string f_bimbo(string message, string flags) {
	string intake = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	string replacement = "αв¢∂єƒﻭнιנкℓмησρ۹яѕтυνωχуչαв¢∂єƒﻭнιנкℓмησρ۹яѕтυνωχуչ";
	string output = "";
	integer imax = strlen(message);
	integer i;
	while(i < imax) {
		string c = substr(message, i, i);
		integer j = strpos(intake, c);
		if(~j) {
			// echo(c + " is letter #" + (string)j + " and maps to " + substr(replacement, j, j));
			output += substr(replacement, j, j);
		} else {
			// echo(c + " is not a letter");
			output += c;
		}
		++i;
	}
	return output;
}

string f_superscript(string message, string flags) {
	string intake = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-=~";
	string replacement = "ᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾ۹ᴿˢᵀᵁⱽᵂˣʸᶻᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖ۹ʳˢᵗᵘᵛʷˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁼˜";
	string output = "";
	integer imax = strlen(message);
	integer i;
	while(i < imax) {
		string c = substr(message, i, i);
		integer j = strpos(intake, c);
		if(~j) {
			// echo(c + " is letter #" + (string)j + " and maps to " + substr(replacement, j, j));
			output += substr(replacement, j, j);
		} else {
			// echo(c + " is not a letter");
			output += c;
		}
		++i;
	}
	return output;
}

list ft_dropout_chars = ["░", "▒", "▓", "█"];

string f_corrupted(string message, string flags) {
	float dropout_strength = 0.01 * (float)flags;
	if(dropout_strength == 0)
		return message;
	
    integer imax = strlen(message);
    string oo;
    
    integer i = 0;
    for(; i < imax; ++i) {
        string c = substr(message, i, i);
        if(llFrand(1) < dropout_strength && llToUpper(c) != llToLower(c)) {
            oo += gets(ft_dropout_chars, (integer)llFrand(4));
        } else
            oo += substr(message, i, i);
    }
    
    return oo;
}

#define GLITCH_MULTIPLIER 1
string f_glitch(string message, string flags) {
	if(flags == "") flags = "10";
	float glitch_level = 0.01 * (float)flags;

	list junkchars = ["̆","̎","̾","͋","̚","͠","͢","̨","̴","̶","̷","̡","̜","̼","̖","̞","̤","̰","͌","̂"];

    if(glitch_level > 0.009) {
		integer k = strlen(message);
		integer j = strlen_byte(message);
        integer i = (integer)((float)k * glitch_level * GLITCH_MULTIPLIER);
		// llOwnerSay("Adding " + (string)i + " glitches to string of " + (string)strlen(message) + " characters.");		
        while(i > 0 && j < 1022) {
			string a = gets(junkchars, (integer)llFrand(20));
			string b = gets(junkchars, (integer)llFrand(20));
			
            message = llInsertString(llInsertString(
				message,
				(integer)(llFrand((k) - 1)) + 1, a),
				(integer)(llFrand((k += 2) - 3)) + 1, b);
			
			j += strlen_byte(a + b);
			// llOwnerSay(">>" + message);
            --i;
        }
    }
    
    return message;
}

list activated_filters = [];

key session;

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		#ifdef DEBUG
		echo("[" + PROGRAM_NAME + "] signal " + (string)n + " from " + (string)src + ": " + m + " ("+(string)outs+":"+(string)ins+":"+(string)user +")");
		#endif
		list argv = split(m, " ");
		integer argc = count(argv);
		if(argc == 1) {
			print(outs, user, "[" + PROGRAM_NAME + "] see 'help " + PROGRAM_NAME + "'");
		} else {
			string filter = gets(argv, 1);
			string action = gets(argv, 2);
			
			if(filter == "install" || filter == "remove") {
				string fconf = getdbl("vox", ["filter"]);
				
				integer fi = count(filters);
				string msg;
				
				if(filter == "install")
					msg = "Installed " ;
				else
					msg = "Removed ";
				
				if(fi > 2)
					msg += (string)(fi / 2) + " filters";
				else
					msg += "1 filter";
				
				while(fi >= 0) {
					fi -= 2;
					string fn = gets(filters, fi);
					integer layer = geti(filters, fi + 1);
					
					if(filter == "install")
						fconf = setjs(fconf, [fn], jsarray([PROGRAM_NAME + " " + fn, layer]));
					else if(getjs(fconf, [fn]) != JSON_INVALID)
						fconf = setjs(fconf, [fn], JSON_DELETE);
				}
				
				setdbl("vox", ["filter"], fconf);
				
				print(outs, user, "[" + PROGRAM_NAME + "] " + msg);
				
			} else if(action == "activate" || action == "deactivate") {
				integer new_status = (action == "activate");
				integer fi = index(filters, filter);
				string msg;
				
				if(~fi) {
					integer current_status = index(activated_filters, filter);
					if(new_status && !~current_status) {
						if(activated_filters == []) {
							task_begin(session = llGenerateKey(), "");
						}
						activated_filters += filter;
					} else if(~current_status && !new_status) {
						activated_filters = delitem(activated_filters, current_status);
						if(activated_filters == []) {
							task_end(session);
						}
						
						if(filter == "translate" && translate_pipe != "") {
							pipe_close(translate_pipe);
							translate_pipe = "";
						}
					}
				} else {
					echo("[" + PROGRAM_NAME + "] No filter to " + action + ": " + filter);
				}
			} else {
				// calling syntax: echo msg | filter <filter> <flags>
				
				string flags = concat(delrange(argv, 0, 1), " ");
			
				string message;
				pipe_read(ins, message);
				
				// echo(" -- filter in: " + message + " (from pipe " + (string)ins + ")");
				
				if(filter == "translate") {
					f_translate(message, flags, outs, ins, user, _resolved);
					_resolved = 0;
					// message = f_translate(message, flags);
				} else {
					if(filter == "censor") {
						message = f_censor(message, flags);
					} else if(filter == "replace") {
						message = f_replace(message, flags);
					} else if(filter == "nonverbal") {
						message = f_nonverbal(message, flags);
					} else if(filter == "rot13") {
						message = f_rot13(message, flags);
					} else if(filter == "glitch") {
						message = f_glitch(message, flags);
					} else if(filter == "corrupted") {
						message = f_corrupted(message, flags);
					} else if(filter == "stutter") {
						message = f_stutter(message, flags);
					} else if(filter == "serpentine") {
						message = f_serpentine(message, flags);
					} else if(filter == "lisp") {
						message = f_lisp(message, flags);
					} else if(filter == "mumble") {
						message = f_mumble(message, flags);
					} else if(filter == "caps") {
						message = f_caps(message, flags);
					} else if(filter == "bimbo") {
						message = f_bimbo(message, flags);
					} else if(filter == "superscript") {
						message = f_superscript(message, flags);
					} else if(filter == "slang") {
						message = f_slang(message, flags);
					} else if(filter == "slow") {
						message = f_slow(message, flags);
					} else {
						echo("[" + PROGRAM_NAME + "] Filter '" + filter + "' unrecognized.");
						#ifdef DEBUG
						echo("argv 1 " + gets(argv, 1));
						echo("message '" + m + "'");
						echo("argc " + (string)count(argv));
						#endif
					}
					
					// echo(" -- filter out: " + message + " (to pipe " + (string)outs + ")");
					print(outs, user, message);
				}
			}
		}
	} else if(n == SIGNAL_NOTIFY) {
		list argv = split(m, " ");
		string action = gets(argv, 1);
		
		// translation_queue: [0: message, 1: flags, 2: handle, 3: outs, 4: ins, 5: user, 6: rc];
		
		if(action == "pipe" && ins == translate_pipe) {
			string message = gets(translation_queue, 0);
			string flags = gets(translation_queue, 1);
			key handle = gets(translation_queue, 2);
			#ifdef DEBUG
			echo("got translation pipe; running " + TRANSLATION_URL);
			#endif
			http_get(TRANSLATION_URL, translate_pipe, handle);
		} else if(action == "translation") {
			string buffer;
			pipe_read(ins, buffer);
			integer hi = index(translation_queue, user);
			if(~hi) {
				integer mi = hi - 2;
				// resolve_io(geti(translation_queue, mi + 6), gets(translation_queue, mi + 3), gets(translation_queue, mi + 4));
				resolve_i(geti(translation_queue, mi + 6), gets(translation_queue, mi + 4));
				
				buffer = getjs(buffer, ["responseData"]);
				#ifdef DEBUG
				echo("received translation server response data: " + buffer);
				#endif
				
				integer jj;
				if(~(jj = strpos(buffer, "\\u"))) {
					string remainder = substr(buffer, jj, -1);
					integer o = strpos(remainder, "\"");
					
					while(~jj) {
						integer code = (integer)("0x" + substr(buffer, jj + 2, jj + 5));
						buffer = llInsertString(delstring(buffer, jj, jj + 5), jj, llChar(code));
						
						jj = strpos(buffer, "\\u");
					}
				}
				
				string message = getjs(buffer, ["translatedText"]);
				
				print(gets(translation_queue, mi + 3), gets(translation_queue, mi + 5), message);
				translation_queue = delrange(translation_queue, mi, mi + 6);
			}
			#ifdef DEBUG
			else
				echo("got translation unexpectedly: " + buffer);
			#endif
			
			if(!count(translation_queue)) {
				pipe_close(translate_pipe);
				translate_pipe = "";
			}
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		list active_filters = jskeys(getdbl("vox", ["active"]));
		integer ai = count(active_filters);
		
		while(ai--) {
			string filter = gets(active_filters, ai);
			integer fi = index(filters, filter);
		
			if(~fi) {
				if(activated_filters == []) {
					task_begin(session = llGenerateKey(), "");
				}
				activated_filters += filter;
			}
		}
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
