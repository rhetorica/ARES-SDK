/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Identity System Module
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
#include <ARES/api/auth.h.lsl>
#define CLIENT_VERSION ARES_VERSION
#define CLIENT_VERSION_TAGS ARES_VERSION_TAGS

string authority;
string unit_name;
string unit_serial;
string model;
string gender;
list colors = [ONES, <1, 0, 0>, <0, 1, 0>, <1, 1, 0>];

string format_color(vector c) {
	string r = hex((integer)(c.x * 255));
	string g = hex((integer)(c.y * 255));
	string b = hex((integer)(c.z * 255));
	if(strlen(r) == 1) r = "0" + r;
	if(strlen(g) == 1) g = "0" + g;
	if(strlen(b) == 1) b = "0" + b;
	string hexcolor = "#" + r + g + b;
	list preset_pair = js2list(llLinksetDataRead("swatch"));
	integer hci = index(preset_pair, hexcolor);
	if(~hci) {
		return hexcolor + " (" + gets(preset_pair, hci - 1) + ")";
	} else {
		return hexcolor;
	}
}

vector parse_color(list argv) {
	// echo("parsing color " + concat(argv, " "));
	integer argc = count(argv);
	vector c;
	
	if(argc == 1) {
		string input = gets(argv, 0);
		string cand = getdbl("swatch", [input]);
		if(cand != JSON_INVALID)
			input = cand;
		
		if(substr(input, 0, 0) == "#" && strlen(input) == 7) {
			c = <(integer)("0x" + substr(input, 1, 2)),
				 (integer)("0x" + substr(input, 3, 4)),
				 (integer)("0x" + substr(input, 5, 6))> / 255.0;
		} else {
			c = <-1, -1, -1>;
		}
	} else if(count(argv) == 3) {
		c = <(float)gets(argv, 0),
			 (float)gets(argv, 1),
			 (float)gets(argv, 2)>;
		if(c.x > 1 || c.y > 1 || c.z > 1)
			c /= 255.0;
	}
	return c;
}

make_callsign(string prefix) {
	string callsign;
	integer lc = llOrd(prefix, LAST);
	if(prefix == JSON_INVALID)
		callsign = unit_name;
	else if(lc == 0x2f || lc == 0x2e || lc == 0x2d || lc == 0x5f || prefix == "") // / . - _
		callsign = prefix + unit_name;
	else
		callsign = prefix + " " + unit_name;
	
	if(strlen_byte(callsign) != strlen(callsign))
		echo("Warning: new callsign is not a valid object name (contains Unicode)");
	
	setdbl("id", ["callsign"], callsign);
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg;
		if(argc == 1) {
			string vendor = getdbl("id", ["vendor"]);
			if(vendor == JSON_INVALID || vendor == "")
				vendor = "Nanite Systems Corporation";
			
			model = getdbl("id", ["model"]);
			if(model == JSON_INVALID || model == "")
				model = "(unknown)";
			
			string s_kernel = llLinksetDataRead("kernel");
			
			// about:
			msg = "About ARES\nARES (Psyche/CX) " + model + " System\n";
			
			string kernel_version = getjs(s_kernel, ["version"]);
			string kernel_version_tags = getjs(s_kernel, ["version-tags"]);
			
			string package_version = getdbl("pkg", ["version", "ARES"]);
			
			if(package_version != JSON_INVALID)
				msg += "\nOS version: " + package_version;
			
			if(kernel_version != package_version) {
				if(kernel_version_tags != JSON_INVALID && kernel_version_tags != "")
					kernel_version = kernel_version + " " + kernel_version_tags;
				
				msg += "\nKernel version: " + kernel_version;
			}
			
			if(package_version != CLIENT_VERSION)
				msg += 
					"\nid version: " + CLIENT_VERSION				
					#ifdef CLIENT_VERSION_TAGS
						+ " " + CLIENT_VERSION_TAGS + " (_id compiled " + __DATE__ + ")"
					#else
						+ "\nid compiled: " + __DATE__
					#endif
				;
			
			msg += "\n\nUnit name: " + unit_name + "\nVendor: " + vendor;
			
			
			if(authority != "(none)")
				msg += "\nSupervising authority: " + authority;
			
			integer ci = 4;
			while(ci--)
				colors = alter(colors, [str2vec(getdbl("id", ["color", ci]))], ci, ci);
			
			msg += 
				"\nSerial number: " + unit_serial +
				"\nModel: " + model +
				"\nColors:" +
				"\n    " + format_color(getv(colors, 0)) +
				"\n    " + format_color(getv(colors, 1)) +
				"\n    " + format_color(getv(colors, 2)) +
				"\n    " + format_color(getv(colors, 3)) +
				"\n\nType 'security' for user information or 'device' for devices information."
			;
			
		} else {
			integer check = sec_check(user, "identity", outs, m, m);
			if(check == DENIED) {
				print(outs, user, "You are not authorized to modify this unit's identity settings.");
				return;
			} else if(check != ALLOWED) {
				return;
			}
		
			integer trigger_color_update = 0;
			string action = gets(argv, 1);
			if(action == "regen" || action == "regenerate") {
				integer mantissa = (integer)("0x" + substr(llGetOwner(), 29, 35)) % 1000000;
				string serial = getdbl("id", ["model"]);
				if(~strpos(serial, "oXq")) {
					#define letter_map "0123456789ABabcdefghijklmnopqrstuvwxyz."
					
					integer part = 3;
					string name;
					while(part--) {
						integer tangle;
						
						if(part == 0) {
							tangle = (integer)("0x" + substr(avatar, 2, 3))
									   ^ (integer)("0x" + substr(avatar, 31, 33));
						} else if(part == 2) {
							tangle = (integer)("0x" + substr(avatar, 5, 7))
									   ^ (integer)("0x" + substr(avatar, 25, 30));
						} else if(part == 1) {
							tangle = (integer)("0x" + substr(avatar, 9, 10) + substr(avatar, 14, 15))
									   ^ (integer)("0x" + substr(avatar, 27, 31));
						}
						
						if(tangle < 0)
							tangle = -tangle;
						
						string frag = "";
						
						while(tangle > 0) {
							integer a;
							if(part % 2 == 0) {
								if(strlen(frag) % 2) {
									a = tangle % 5;
									frag += substr("aeiou", a, a);
									tangle /= 6;
								} else {
									a = tangle % 21;
									frag += substr("bcdfghklmnpqrstvwxyzj", a, a);
									tangle /= 23;
								}
							} else {
								a = tangle % 10;
								tangle /= 16;
								frag += substr(letter_map, a, a);
							}
						}
						
						name += frag;
						
						if(part)
							name += ".";
					}
					
					serial = name;
				} else {
					string mantissa_s = substr((string)mantissa, 0, 1) + "-" + substr((string)mantissa, 2, 5);
					if(~strpos(serial, "-")) {
						serial += "-" + mantissa_s;
					} else {
						serial += " " + mantissa_s;
					}
				}
				
				setdbl("id", ["serial"], unit_serial = serial);
				make_callsign(getdbl("id", ["prefix"]));
			} else if(action == "font") {
				list font_names = jskeys(llLinksetDataRead("font"));
				if(argc == 2) {
					msg = "Current variatype font: " + getdbl("interface", ["font"]) +
						"\nAvailable fonts: " + concat(font_names, ", ");
				} else {
					string font_name = gets(argv, 2);
					if(contains(font_names, font_name)) {
						setdbl("interface", ["font"], font_name);
						msg = "Set variatype font to " + font_name + ".";
						e_call(C_VARIATYPE, E_SIGNAL_CALL, (string)outs + " " + (string)user + " variatype reconfigure");
					} else {
						msg = "Unknown font '" + font_name + "'; available fonts: " + concat(font_names, ", ");
					}
				}
			} else if(action == "interface") {
				string setting = gets(argv, 2);
				list keyname = split(setting, ".");
				string current_value = getdbl("interface", keyname);
				if(argc > 2) {
					string new_value = gets(argv, 3);
					if(new_value == "toggle") {
						if(current_value == "0")
							new_value = "1";
						else
							new_value = "0";
					}
					
					if(current_value != new_value) {
						current_value = new_value;
						setdbl("interface", keyname, current_value);
						if(setting == "font") {
							e_call(C_VARIATYPE, E_SIGNAL_CALL, (string)outs + " " + (string)user + " variatype reconfigure");
						} else {
							e_call(C_INTERFACE, E_SIGNAL_CALL, (string)outs + " " + (string)user + " interface reconfigure");
						}
					}
				}
				msg = "Interface setting " + setting + ": " + current_value;
			
			} else if(action == "volume") {
				float vol = (float)getdbl("interface", ["sound", "volume"]);
				
				if(argc == 3) {
					string new_vol = gets(argv, 2);
					if(new_vol == "off" || new_vol == "mute") {
						vol = 0;
					} else if((string)((integer)new_vol) == new_vol) {
						vol = 0.01 * (float)new_vol;
					} else if(new_vol == "up") {
						vol += 0.1;
					} else if(new_vol == "down") {
						vol -= 0.1;
					} else if(new_vol == "cycle") {
						vol += 0.1;
						if(vol > 1.0)
							vol = 0;
					}
				}
				
				if(vol < 0.0)
					vol = 0.0;
				else if(vol > 1.0)
					vol = 1.0;
				
				string vf = (string)((integer)(100 * vol)) + "%";
				
				setdbl("interface", ["sound", "volume"], (string)vol);
				setdbl("interface", ["sound", "vf"], vf);
				msg = "Interface volume: " + vf;
				interface_sound("test");
					
			} else if(action == "menu") {
				list schemes = jskeys(getdbl("id", ["scheme"]));
				list scheme_buttons = [];
				integer sci = count(schemes);
				while(sci--) {
					string scheme = gets(schemes, sci);
					string sb = jsarray([
						scheme,
						0,
						"id color load " + scheme
					]);
					scheme_buttons = sb + scheme_buttons;
				}
				setdbl("m:color", ["d"], jsarray(scheme_buttons));
			} else if(action == "name") {
				if(argc == 2) {
					msg = "Unit name: " + unit_name;
				} else {
					unit_name = concat(delrange(argv, 0, 1), " ");
					if(unit_name == "none") {
						deletedbl("id", ["name"]);
						msg = "Name cleared.";
						unit_name = "(none)";
						setdbl("id", ["callsign"], unit_serial);
					} else {
						setdbl("id", ["name"], unit_name);
						msg = "Name set.";
						string prefix = getdbl("id", ["prefix"]);
						make_callsign(prefix);
					}
				}
			} else if(action == "authority") {
				if(argc == 2) {
					msg = "Supervising authority: " + authority;
				} else {
					authority = concat(delrange(argv, 0, 1), " ");
					if(authority == "none") {
						deletedbl("id", ["authority"]);
						msg = "Authority cleared.";
						authority = "(none)";
					} else {
						setdbl("id", ["authority"], authority);
						msg = "Authority set.";
					}
				}
			} else if(action == "chime") {
				// id chime load <scheme>
				// id chime save <scheme>
				// id chime delete <scheme>
				// id chime boot none|<uuid>
				// id chime halt none|<uuid>
				string verb = gets(argv, 2);
				string value = gets(argv, 3);
				if(verb == "load" && value != "") {
					string scheme = getdbl("chime", [value]);
					if(scheme != JSON_INVALID) {
						string bc;
						setdbl("id", ["chime", "boot"], bc = getjs(scheme, [0]));
						setdbl("id", ["chime", "halt"], getjs(scheme, [1]));
						msg = "Chime scheme '" + value + "' applied.";
						play_sound(bc);
						setdbl("m:chime", ["f"], value);
					} else {
						msg = "There is no chime scheme named '" + value + "'";
					}
				} else if(verb == "save" && value != "") {
					string bc = getdbl("id", ["chime", "boot"]);
					string hc = getdbl("id", ["chime", "halt"]);
					setdbl("chime", [value], jsarray([bc, hc]));
				} else if(verb == "delete" && value != "") {
					string scheme = getdbl("chime", [value]);
					if(scheme != JSON_INVALID) {
						deletedbl("chime", [value]);
						msg = "Deleted chime scheme '" + value + "'";
					} else {
						msg = "There is no chime scheme named '" + value + "'";
					}
				} else if((verb == "boot" || verb == "halt") && value != "") {
					string old = getdbl("id", ["chime", verb]);
					if(value == "clear") {
						if(old != JSON_INVALID)
							value = JSON_DELETE;
						else
							jump nah;
					} else if(old == value)
						jump nah;
					
					setdbl("id", ["chime", verb], value);
					msg = "Chime set.";
					jump yah;
					@nah;
					msg = "No change.";
					@yah;
				} else {
					string bc = getdbl("id", ["chime", "boot"]); if(bc == JSON_INVALID) bc = "(none)";
					string hc = getdbl("id", ["chime", "halt"]); if(hc == JSON_INVALID) hc = "(none)";
					string schemes = concat(jskeys(getdbl("chime", [])), ", ");
					if(schemes == "") schemes = "(none; please reload default database)";
					
					msg = "Current chime settings\n\nBoot: " + bc +
						"\nHalt: " + hc +
						"\nAvailable schemes: " + schemes;
				}
			} else if(action == "color") {
				integer ci = 4;
				while(ci--)
					colors = alter(colors, [str2vec(getdbl("id", ["color", ci]))], ci, ci);
				
				if(argc == 2) {
					string schemes = getdbl("id", ["scheme"]);
					if(schemes == JSON_INVALID)
						schemes = "(none)";
					else
						schemes = concat(jskeys(schemes), ", ");
					
					msg = "Current colors:\n    " + format_color(getv(colors, 0)) +
						"\n    " + format_color(getv(colors, 1)) +
						"\n    " + format_color(getv(colors, 2)) +
						"\n    " + format_color(getv(colors, 3)) +
						"\nAvailable swatches:" +
						"\n    " + concat(jskeys(llLinksetDataRead("swatch")), ", ") +
						"\nAvailable schemes:" +
						"\n    " + schemes;
				} else {
					integer affect = -1; // affect all
					string keyword = gets(argv, 2);
					argv = delrange(argv, 0, 2);
					
					list slot_names = ["a", "b", "c", "d", "primary", "secondary", "tertiary", "quartenary", "p", "s", "t", "q"];
					integer si = index(slot_names, keyword);
					if(~si) {
						affect = si & 0x03; // % 4
						keyword = gets(argv, 0);
					} else if(keyword == "all" || keyword == "*") {
						si = 0;
					} else if(keyword == "swatch") {
						affect = 5;
						keyword = gets(argv, 0);
					}
					
					integer action; // 1: set, 2: save scheme, 3: load scheme, 4: delete scheme
					
					list actions = [0, "set", "save", "load", "delete"];
					integer ai = index(actions, keyword);
					if(~ai) {
						action = ai;
						if(~si)
							argv = delitem(argv, 0);
					} else {
						action = 1; // mode: set
					}
					
					vector c;
					if(argc = count(argv)) { // update argc
						if(affect == 5) {
							if(keyword == "delete") {
								string name = gets(argv, 1);
								if(getdbl("swatch", [name]) != JSON_INVALID) {
									deletedbl("swatch", [name]);
									msg = "Deleted swatch " + name;
								} else {
									msg = "No swatch: " + name;
								}
							} else {
								c = parse_color(delitem(argv, 0));
								if(c == <-1, -1, -1>) {
									msg = "Unknown color code: " + concat(argv, " ") + ". See 'help id' for more information.";
									jump error;
								}
								
								string hex = substr(format_color(c), 0, 6);
								setdbl("swatch", [keyword], hex);
							}
						} else if(action == 1) { // set
							c = parse_color(argv);
							if(c == <-1, -1, -1>) {
								msg = "Unknown color code: " + concat(argv, " ") + ". See 'help id' for more information.";
								jump error;
							}
							
							if(~affect) {
								colors = alter(colors, [c], affect, affect);
							} else {
								colors = [c, c, c, c];
							}
							
							vector ca = getv(colors, 0);
							vector cb = getv(colors, 1);
							vector cc = getv(colors, 2);
							vector cd = getv(colors, 3);
							
							setdbl("id", ["color"], jsarray([
								vec2str(ca),
								vec2str(cb),
								vec2str(cc),
								vec2str(cd)
							]));
							
							trigger_color_update = 1;
							msg = "Color updated.";
							
						} else if(action == 2) { // save <scheme_name>
							string scheme_name = concat(argv, " ");
							
							vector ca = getv(colors, 0);
							vector cb = getv(colors, 1);
							vector cc = getv(colors, 2);
							vector cd = getv(colors, 3);
							
							setdbl("id", ["scheme", scheme_name], jsarray([
								vec2str(ca),
								vec2str(cb),
								vec2str(cc),
								vec2str(cd)
							]));
							
							msg = "Color scheme '" + scheme_name + "' saved.";
						} else if(action == 3) { // load <scheme_name>
							string scheme_name = concat(argv, " ");
							string colorlist = getdbl("id", ["scheme", scheme_name]);
							if(colorlist != JSON_INVALID) {
								setdbl("id", ["color"], colorlist);
								setdbl("m:color", ["f"], scheme_name);
								
								integer ci = 4;
								while(ci--) {
									colors = alter(colors, [str2vec(getjs(colorlist, [ci]))], ci, ci);
								}
								
								trigger_color_update = 1;
								msg = "Color scheme '" + scheme_name + "' loaded.";
							} else {
								msg = "No color scheme: '" + scheme_name + "'";
							}
						} else if(action == 4) { // delete <scheme_name>
							string scheme_name = concat(argv, " ");
							string colorlist = getdbl("id", ["scheme", scheme_name]);
							if(colorlist != JSON_INVALID) {
								setdbl("id", ["scheme", scheme_name], JSON_DELETE);
								msg = "Color scheme '" + scheme_name + "' deleted.";
							} else {
								msg = "No color scheme: '" + scheme_name + "'";
							}
						}
					
						@error;
					} else {
						msg = "Missing arguments: id color " + keyword;
					}
				}
			} else if(action == "gender") {
				string s_gender = getdbl("id", ["gender"]);
				if(argc == 2) {
					msg = "Gender status:\n\nMental gender (self-reported pronouns): " + getjs(s_gender, ["mental"]) +
						"\nPhysical gender (pronouns used in descriptions): " + getjs(s_gender, ["physical"]) +
						"\nVoice gender (chat tone/speech markers): " + getjs(s_gender, ["voice"]) +
						"\n\nSee 'help gender' for instructions on how to configure.";
				} else {
					string tfield = gets(argv, 2);
					string gfield = gets(argv, 3);
					integer gender = NOWHERE;
					integer topic = NOWHERE;
					
					list pronoun_options = [
						"neuter,they,them,their,theirs,themself",
						"female,she,her,her,hers,herself",
						"male,he,him,his,his,himself",
						"inanimate,it,it,its,its,itself"
					];
										
					topic = llListFindList(["all", "mental", "physical", "voice"], [tfield]);
					if(!~topic)
						topic = strpos("*mpv", tfield);
					
					gender = llListFindList(["neuter", "female", "male", "inanimate", "custom"], [gfield]);
					if(!~gender)
						gender = strpos("nfmic", gfield);
					
					if(!~topic || !~gender) {
						msg = "Unknown gender command: " + tfield + " " + gfield + ". Please check the manual and try again.";
					} else {					
						if(topic != 3) { // anything but voice
							string pronoun_source;
							
							if(gender == 4) {
								// custom
								pronoun_source = gets(argv, 4);
							} else {
								pronoun_source = gets(pronoun_options, gender);
							}
							
							list pronouns = split(pronoun_source, ",");
							string pronoun_obj = jsobject([
								"adj", gets(pronouns, 0),
								"sub", gets(pronouns, 1),
								"obj", gets(pronouns, 2),
								"gen", gets(pronouns, 3),
								"pos", gets(pronouns, 4),
								"refl", gets(pronouns, 5)
							]);
							
							if(topic == 0) {
								if(gender > 2)
									gender = 0;
								
								setdbl("id", ["gender", "voice"], substr("nfm", gender, gender));
							}
							
							if(topic == 0 || topic == 1) {
								setdbl("env", ["pm"], pronoun_obj);
								setdbl("id", ["gender", "mental"], jsarray(pronouns));
							}
							
							if(topic == 0 || topic == 2) {
								setdbl("env", ["pp"], pronoun_obj);
								setdbl("id", ["gender", "physical"], jsarray(pronouns));
							}
							
							msg = "Gender set.";
							
						} else { // voice
							if(gender > 2)
								gender = 0;
							
							setdbl("id", ["gender", "voice"], substr("nfm", gender, gender));
							
							msg = "Voice gender set.";
						}
					}
				}
				
			} else {
				msg = PROGRAM_NAME + ": Unrecognized action '" + action + "'; see 'help id' for a list of valid actions";
			}
			
			if(trigger_color_update) {
				e_call(C_INTERFACE, E_SIGNAL_CALL, (string)outs + " " + (string)user + " interface color");
				e_call(C_VARIATYPE, E_SIGNAL_CALL, (string)outs + " " + (string)user + " variatype color");
				e_call(C_HARDWARE, E_SIGNAL_CALL, (string)NULL_KEY + " " + (string)NULL_KEY + " hardware color");
				// no keys = tell device to send update to all devices
				e_call(C_REPAIR, E_SIGNAL_CALL, (string)outs + " " + (string)user + " repair color");
				e_call(C_STATUS, E_SIGNAL_CALL, (string)outs + " " + (string)user + " status color");
			}
		}
		
		if(msg != "")
			print(outs, user, msg);
	} else if(n == SIGNAL_INIT) {
		string id_section = llLinksetDataRead("id");
		unit_name = getjs(id_section, ["name"]);
		unit_serial = getjs(id_section, ["serial"]);
		if(unit_serial == JSON_INVALID || unit_serial == "")
			unit_serial = "NS-100-00-0001";
		if(unit_name == JSON_INVALID || unit_name == "")
			unit_name = unit_serial;
		
		if(strlen_byte(unit_name) != strlen(unit_name))
			echo("Warning: unit name is invalid (contains Unicode)");
		
		authority = getjs(id_section, ["authority"]);
		if(authority == JSON_INVALID || authority == "")
			authority = "(none)";
		model = getjs(id_section, ["model"]);
		if(model == JSON_INVALID || model == "")
			model = "(unknown)";
		gender = getjs(id_section, ["gender"]);
		integer ci = 4;
		while(ci--)
			colors = alter(colors, [str2vec(getjs(id_section, ["color", ci]))], ci, ci);
	/* // obsolete/niche:
	} else if(n == SIGNAL_TERMINATE) {
		echo("[" + PROGRAM_NAME + "] dying as ordered");
		exit(); */
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unhandled: signal " + (string)n + ": " + m);
	}
}

#include <ARES/program>
