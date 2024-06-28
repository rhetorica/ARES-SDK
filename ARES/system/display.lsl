/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Display System Module
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
#include <ARES/api/interface.consts.h.lsl>

#define call_interface(_outs, _user, _msg) \
			system(SIGNAL_CALL, E_INTERFACE + E_PROGRAM_NUMBER \
				+ (string)_outs + " " + (string)_user + " interface " + (_msg));

#define CLIENT_VERSION ARES_VERSION
#define CLIENT_VERSION_TAGS ARES_VERSION_TAGS

integer power_on = TRUE;

string fixed_warning_texture;
integer fixed_warning_mode = 1;
string devices_texture;
float device_scale;
integer device_mode = 1;
integer device_wires = 1;
vector devices_offset = <0, -860, 0>;

string sound_heat_alarm = "5db9d9d6-6eda-485e-6436-e97dfdc1983c";
string sound_shield_alarm = "348fcd3d-7993-54fb-720c-c5ebc42de505";
integer heat_alarm;
integer shield_alarm;

integer color_slot;

vector color = <1, 1, 1>;
vector color_bad = <1, 0.25, 0>;

integer screen_height = 1008;
integer screen_height_mlook = 1027;

float sound_volume = 1;

float pixel_scale;

vector fixed_warning_offset = <0, 768, 384>;
list active_warnings = [0, 0, 0, 0, 0, 0, 0];

integer in_mlook = FALSE;
integer old_in_mlook;
integer devices_in_mlook = NOWHERE;
integer old_devices_in_mlook;

integer config_visible;
integer config_target;
string config_parameter = "(uninitialized)";
vector config_value;
vector config_backup;

position_all(integer only_devices) {
	in_mlook = TRUE && (llGetAgentInfo(avatar) & AGENT_MOUSELOOK);
	if(in_mlook) {
		pixel_scale = 1.0 / screen_height_mlook;
	} else {
		pixel_scale = 1.0 / screen_height;
	}
	
	/* DEVICES */
	#define MAX_DEVICES 16
	// string devices = llLinksetDataRead("device");
	string device_icons = getdbl("display", ["devices", "icon"]);
	
	list device_names = jskeys(llLinksetDataRead("device"));
	integer di;
	
	list device_names_local;
	list device_names_remote;
	
	integer dmax = count(device_names);
	while(di < dmax) {
		string device = gets(device_names, di);
		integer remote = (integer)getdbl("device", [device, "r"]);
		if(remote)
			device_names_remote += device;
		else
			device_names_local += device;
		
		++di;
	}
	
	device_names = device_names_local + device_names_remote;
	di = 0;
	
	list updates;
	/*string s_interface = llLinksetDataRead("interface");
	
	float screen_height = (float)getjs(s_interface, ["height"]);
	if(screen_height == 0) screen_height = 1008;
	
	if(llGetAgentInfo(avatar) & AGENT_MOUSELOOK) {
		screen_height = (float)getjs(s_interface, ["height-mlook"]);
		if(screen_height == 0) screen_height = 1027;
	} */
	
	vector scaled_devices_offset = devices_offset * pixel_scale;
	float scale_module = 16.0 * pixel_scale * device_scale;
	
	old_devices_in_mlook = devices_in_mlook;
	devices_in_mlook = (llGetAgentInfo(avatar) & AGENT_MOUSELOOK) && TRUE;
	
	float line_texture_rotation = 0;
	vector device_main_axis = <0, 0, 1>;
	vector device_cross_axis = <0, -1, 0>;
	vector line_size = <8, 1, 0>;
	if(device_mode == 2) {
		device_main_axis = <0, -1, 0>;
		device_cross_axis = <0, 0, -1>;
		line_size = <1, 8, 0>;
		line_texture_rotation = -PI_BY_TWO;
	}
	
	if(old_devices_in_mlook != devices_in_mlook) {				
		di = 0;
		while(di < MAX_DEVICES) {
			updates += [
				PRIM_LINK_TARGET, DEVICE_ICON_BASE + di + MAX_DEVICES,
					PRIM_POS_LOCAL, scaled_devices_offset
						+ device_cross_axis * 0.25
						+ device_main_axis * (di * scale_module),
					PRIM_ROTATION, INVISIBLE,
					PRIM_COLOR, ALL_SIDES, color, 0,
				PRIM_LINK_TARGET, DEVICE_ICON_BASE + di,
					PRIM_POS_LOCAL, scaled_devices_offset
						+ device_cross_axis * 0.125
						+ device_main_axis * (di * scale_module),
					PRIM_ROTATION, INVISIBLE,
					PRIM_COLOR, ALL_SIDES, color, 0
			];
			++di;
		}
		
		setp(0, updates);
		updates = [];
		llSleep(0.25);
	}
	
	di = 0;
	string texk = devices_texture;
	while(di < MAX_DEVICES) {
		string device = gets(device_names, di);
		string device_info = getdbl("device", [device]);
		if(device != "") {
			integer remote = (integer)getjs(device_info, ["r"]);
			
			if(device_wires)
				updates += [
					PRIM_LINK_TARGET, DEVICE_ICON_BASE + di + MAX_DEVICES,
						// PRIM_TEXTURE, 0, texk, <1.0, 0.125, 0>, <0, -0.4375 + 0.125 * remote, 0>, 0,
						PRIM_TEXTURE, 0, texk, <1.0, 0.125, 0>, <0, -0.3125 - 0.125 * remote, 0>, line_texture_rotation,
						PRIM_SIZE, line_size * scale_module,
						PRIM_ROTATION, VISIBLE,
						PRIM_POS_LOCAL, scaled_devices_offset
							+ device_cross_axis * 4.5 * scale_module
							+ device_main_axis * (di * scale_module),
						PRIM_COLOR, ALL_SIDES, color, 1
				];
			
			updates += [
				PRIM_LINK_TARGET, DEVICE_ICON_BASE + di,
					PRIM_SIZE, <scale_module, scale_module, 0>,
					PRIM_ROTATION, VISIBLE,
					PRIM_POS_LOCAL, scaled_devices_offset 
						+ device_cross_axis * 0
						+ device_main_axis * (di * scale_module),
					PRIM_DESC, device,
					PRIM_COLOR, ALL_SIDES, color, 1
			];
			
			string icon = getjs(device_info, ["i"]);
			if(icon != JSON_INVALID) {
				updates += [
					PRIM_TEXTURE, 0, icon, <1, 1, 0>, ZV, 0
				];
			} else {
				icon = getjs(device_icons, [device]);
				
				if(strlen(icon) == 36) {
					updates += [
						PRIM_TEXTURE, 0, icon, <1, 1, 0>, ZV, 0
					];
				} else {
					if(icon == JSON_INVALID)
						icon = "40";
					
					float iconx = -0.46875 + (float)(llOrd(icon, 0) - 48) * 0.0625;
					float icony = 0.46875 - (float)(llOrd(icon, 1) - 48) * 0.0625;
					updates += [
						PRIM_TEXTURE, 0, texk, <0.0625, 0.0625, 0>, <iconx, icony, 0>, 0
					];
				}
			}
		} else {
			updates += [
				PRIM_LINK_TARGET, DEVICE_ICON_BASE + di,
					PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, ZV, ZV, 0,
					PRIM_POS_LOCAL, scaled_devices_offset
						+ device_cross_axis * 0.125
						+ device_main_axis * (di * scale_module),
					PRIM_ROTATION, INVISIBLE,
					PRIM_DESC, "",
				PRIM_LINK_TARGET, DEVICE_ICON_BASE + di + MAX_DEVICES,
					PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, ZV, ZV, 0,
					PRIM_POS_LOCAL, scaled_devices_offset
						+ device_cross_axis * 0.25
						+ device_main_axis * (di * scale_module),
					PRIM_ROTATION, INVISIBLE
			];
		}
		
		setp(0, updates);
		updates = [];
		++di;
	}
	setp(0, updates);
	
		
	if(only_devices) // allow device updates without refreshing whole UI
		return;
	
	if(fixed_warning_mode == 1) {
		setp(FIXED_WARNING_LIST, [
			// PRIM_TEXTURE, ALL_SIDES, FIXED_MSGS_TEX, <1, 0.03125, 0>, <0, 0.015625 + (float)(1) * 0.03125, 0>, PI_BY_TWO,
			//PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ONES, ZV, 0,
			//PRIM_ROTATION, llEuler2Rot(<0, 0, -PI_BY_TWO>) * VISIBLE,
			//PRIM_ROTATION, INVISIBLE_FWL,
			
			PRIM_POS_LOCAL, (fixed_warning_offset - <0, 0, 64>) * pixel_scale,
			PRIM_SIZE, <128, 128, 0> * pixel_scale
		]);
	
		if(sum(active_warnings) > 0 && power_on)
			setp(FIXED_WARNING_LIST, [
				PRIM_ROTATION, VISIBLE_FWL
			]);
		else
			setp(FIXED_WARNING_LIST, [
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0,
				PRIM_ROTATION, INVISIBLE_FWL
			]);
	} else if(fixed_warning_mode == 2) {
		setp(FIXED_WARNING_LIST, [
			// PRIM_TEXTURE, ALL_SIDES, FIXED_MSGS_TEX, <1, 0.03125, 0>, <0, 0.015625 + (float)(1) * 0.03125, 0>, PI_BY_TWO,
			//PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ONES, ZV, 0,
			//PRIM_ROTATION, llEuler2Rot(<0, 0, -PI_BY_TWO>) * VISIBLE,
			//PRIM_ROTATION, INVISIBLE_FWL,
			
			PRIM_POS_LOCAL, fixed_warning_offset * pixel_scale,
			PRIM_SIZE, <128, 16, 0> * pixel_scale
		]);
		
		if(sum(active_warnings) > 0 && power_on)
			setp(FIXED_WARNING_LIST, [
				PRIM_ROTATION, VISIBLE
			]);
		else
			setp(FIXED_WARNING_LIST, [
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0,
				PRIM_ROTATION, INVISIBLE
			]);
	}
	
	if(config_visible) {
		setp(CONFIG_CONTROLS, [
			PRIM_ROTATION, VISIBLE,
			PRIM_COLOR, ALL_SIDES, color, 1,
			PRIM_TEXT, "configuring: " + config_parameter + "\n" + (string)config_value + "\n ", color, 1,
			PRIM_SIZE, <256, 32, 0> * pixel_scale,
			PRIM_POSITION, <-5, 0, 0>,
			PRIM_TEXTURE, 0, MOVER_TEX, <0.125, 1, 0>, <-0.4375, 0, 0>, 0,
			PRIM_TEXTURE, 1, MOVER_TEX, <0.125, 1, 0>, <-0.3125, 0, 0>, 0,
			PRIM_TEXTURE, 2, MOVER_TEX, <0.125, 1, 0>, <-0.1875, 0, 0>, 0,
			PRIM_TEXTURE, 3, MOVER_TEX, <0.125, 1, 0>, <-0.0625, 0, 0>, 0,
			PRIM_TEXTURE, 4, MOVER_TEX, <0.125, 1, 0>, < 0.0625, 0, 0>, 0,
			PRIM_TEXTURE, 5, MOVER_TEX, <0.125, 1, 0>, < 0.1875, 0, 0>, 0,
			PRIM_TEXTURE, 6, MOVER_TEX, <0.125, 1, 0>, < 0.3125, 0, 0>, 0,
			PRIM_TEXTURE, 7, MOVER_TEX, <0.125, 1, 0>, < 0.4375, 0, 0>, 0
		]);
	}
}

main(integer src, integer n, string m, key outs, key ins, key user) {
	@restart_main;
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		
		string action = gets(argv, 1);
		
		if(argc == 1 || action == "help") {
			msg = "Usage: " + PROGRAM_NAME + " <action> ...\nConfigures and assists the interface daemon.\n\n    show: Turns on all UI elements\n    reconfigure: Refreshes the UI\n    devices: Refreshes just the display of devices\n    c[onfig] on: Turns on the UI mover.\n    c[onfig] off: Turns off the UI mover.\n    c[onfig] <database entry>: Causes the UI mover to operate on the specified vector.\n\nUnrecognized actions will be forwarded to the interface daemon.";
		} else if(action == "show") {
			setp(LINK_ALL_CHILDREN, [
				PRIM_ROTATION, VISIBLE,
			PRIM_LINK_TARGET, FIXED_WARNING_LIST,
				PRIM_ROTATION, VISIBLE_FWL
			]);
		} else if(action == "reconfigure") {
			call_interface(outs, user, concat(delitem(argv, 0), " "));
			jump reconfigure;
		} else if(action == "devices") {
			position_all(TRUE);
		} else if(action == "config" || action == "c") {
			string arg2 = gets(argv, 2);
			if(arg2 == "none" || arg2 == "off" || arg2 == "done") {
				config_visible = FALSE;
				unhook_events([EVENT_TOUCH]);
				setp(CONFIG_CONTROLS, [
					PRIM_TEXT, "", ZV, 0,
					PRIM_POSITION, OFFSCREEN,
					PRIM_ROTATION, INVISIBLE,
					PRIM_SIZE, ZV,
					PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, ZV, ZV, 0
				]);
			} else {
				if(config_parameter != "(uninitialized)") {
					list keyname = split(config_parameter, ".");
					string hive = gets(keyname, 0);
					keyname = delitem(keyname, 0);
					setdbl(hive, keyname, (string)config_value);
				}
				
				config_parameter = arg2;
				
				if(config_parameter != "(uninitialized)") {
					list keyname = split(config_parameter, ".");
					string hive = gets(keyname, 0);
					keyname = delitem(keyname, 0);
					config_backup = config_value = (vector)getdbl(hive, keyname);
				}
				if(!config_visible) {
					hook_events([EVENT_TOUCH]);
					config_visible = TRUE;
					echo("UI mover active. Press the ⭯ button to see changes, or type '@display config done' to close.");
				}
				position_all(FALSE);
			}
		} else {
			call_interface(outs, user, concat(delitem(argv, 0), " "));
		}
		
		if(msg != "") {
			print(outs, user, msg);
		}
	} else if(n == SIGNAL_EVENT) {
		// echo(m);
		// cannot access warning texture - pls fix
		integer e = (integer)m;
		if(e == EVENT_TOUCH) {
			if(!config_visible) {
				unhook_events([EVENT_TOUCH]);
			} else {
				list args = split(m, " ");
				if((integer)gets(args, 2) == CONFIG_CONTROLS) {
					integer button = (integer)gets(args, 3);
					
					vector current_value = config_value;
					
					integer SPEED = 4;
					
					if(button == 0) {
						invoke("_menu start mover", DAEMON, NULL_KEY, avatar);
						return;
					} else if(button == 1) { // Left = +Y
						config_value.y += SPEED;
					} else if(button == 2) { // Up = +Z
						config_value.z += SPEED;
					} else if(button == 3) { // Down = -Z
						config_value.z -= SPEED;
					} else if(button == 4) { // Right = -Y
						config_value.y -= SPEED;
					} else if(button == 5) { // Away = +X
						config_value.x += SPEED * 128;
					} else if(button == 6) { // Back = -X
						config_value.x -= SPEED * 128;
					} else if(button == 7) {
						interface_sound("go");
						m = PROGRAM_NAME + " reconfigure";
						n = SIGNAL_INVOKE;
						jump restart_main;
					}
					
					interface_sound("act");
					
					if(config_parameter != "(uninitialized)" && config_value != current_value) {
						list keyname = split(config_parameter, ".");
						string hive = gets(keyname, 0);
						keyname = delitem(keyname, 0);
						setdbl(hive, keyname, (string)config_value);
						
						setp(CONFIG_CONTROLS, [
							PRIM_TEXT, "configuring: " + config_parameter + "\n" + (string)config_value + "\n ", color, 1
						]);
					}
				}
			}
		} else if(e == EVENT_INTERFACE) {
			power_on = (integer)getdbl("status", ["on"]);
			position_all(FALSE);
		} else if(e == EVENT_WARNING) {
			list argv = split(m, " ");
			integer slot = (integer)gets(argv, 1);
			integer msg = (integer)gets(argv, 2);
			
			// 0x00b <slot> <number> (0 = clear)
			
			// echo(m);
			
			if(slot < 0 || slot > 7 || msg < 0 || msg > 32) return;
			
			integer old_warning = geti(active_warnings, slot);
			active_warnings = alter(active_warnings, [msg], slot, slot);
			
			string announcements = "{"
				+ "\"1\":\"error-malfunction\","
				+ "\"3\":\"repair-1\","
				+ "\"4\":\"dqd-1\","
				+ "\"5\":\"dqd-1\","
				+ "\"7\":\"heat-1\","
				+ "\"8\":\"heat-0\","
				+ "\"9\":\"heat-1\","
				+ "\"10\":\"pressure-1\","
				+ "\"11\":\"pressure-0\","
				+ "\"13\":\"cryolube-025\","
				+ "\"15\":\"nav-1\","
				+ "\"16\":\"follow-1\","
				+ "\"25\":\"battery-020\","
				+ "\"26\":\"charging-1\"}";
			
			string deactivate_announcements = "{"
				+ "\"3\":\"repair-0\","
				+ "\"4\":\"dqd-0\","
				+ "\"5\":\"dqd-0\","
				+ "\"15\":\"nav-0\","
				+ "\"16\":\"follow-0\","
				+ "\"26\":\"charging-0\"}";
			
			string announcement = getjs(announcements, [(string)msg]);
			if(announcement == JSON_INVALID)
				announcement = getjs(deactivate_announcements, [(string)old_warning]);
			
			if(announcement != JSON_INVALID)
				system(SIGNAL_CALL, E_EFFECTOR + E_PROGRAM_NUMBER + NULL_KEY + " " + NULL_KEY + " effector announce " + announcement);
			
			if(slot == 2 && msg == 9) { // DUMP HEAT!
				heat_alarm = 1;
				sound_volume = (float)getdbl("interface", ["sound", "volume"]);
				llLinkPlaySound(HEAT_GAUGE, sound_heat_alarm, sound_volume, SOUND_LOOP);
				setp(FIXED_WARNING_LIST, [
					PRIM_COLOR, slot, color_bad, 1
				]);
			} else if(slot == 2 && heat_alarm) {
				heat_alarm = 0;
				setp(FIXED_WARNING_LIST, [
					PRIM_COLOR, slot, color, 1
				]);
			}
			
			if(msg == 0) {
				setp(FIXED_WARNING_LIST, [
					PRIM_TEXTURE, slot, TEXTURE_TRANSPARENT, ONES, ZV, 0
				]);
			} else if(fixed_warning_mode == 2) {
				setp(FIXED_WARNING_LIST, [
					PRIM_TEXTURE, slot, fixed_warning_texture, <1, 0.03125, 0>, <0, 0.515625 - (float)msg * 0.03125, 0>, 0
				]);
			} else if(fixed_warning_mode == 1) {
				setp(FIXED_WARNING_LIST, [
					PRIM_TEXTURE, slot, fixed_warning_texture, <1, 0.03125, 0>, <0, 0.515625 - (float)msg * 0.03125, 0>, PI_BY_TWO
				]);
			}
			
			if(fixed_warning_mode == 2) {
				if(sum(active_warnings))
					setp(FIXED_WARNING_LIST, [
						PRIM_ROTATION, VISIBLE
					]);
				else
					setp(FIXED_WARNING_LIST, [
						PRIM_ROTATION, INVISIBLE
					]);			
			} else if(fixed_warning_mode == 1) {
				if(sum(active_warnings))
					setp(FIXED_WARNING_LIST, [
						PRIM_ROTATION, VISIBLE_FWL
					]);
				else
					setp(FIXED_WARNING_LIST, [
						PRIM_ROTATION, INVISIBLE_FWL
					]);
			}
			
			if(!heat_alarm)
				llLinkStopSound(HEAT_GAUGE);
		}
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		hook_events([EVENT_INTERFACE, EVENT_WARNING]);
		unhook_events([EVENT_TOUCH]);
		llLinkStopSound(HEAT_GAUGE);
		jump reconfigure;
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
	jump end;
	@reconfigure;
	{
		string s_interface = llLinksetDataRead("interface");
		
		screen_height = (integer)getjs(s_interface, ["height"]);
		if(!screen_height) screen_height = 1008;
		
		screen_height_mlook = (integer)getjs(s_interface, ["height-mlook"]);
		if(!screen_height_mlook) screen_height_mlook = 1027;
		
		color_slot = (integer)getjs(s_interface, ["color"]);
	}
	
	if(color_slot == 0)
		color = ONES;
	else
		color = str2vec(getdbl("id", ["color", color_slot - 1]));
	
	integer cbi = 2;
	if(color_slot - 1== 2)
		cbi = 3;
	color_bad = str2vec(getdbl("id", ["color", cbi]));
	
	{
		string s_display = llLinksetDataRead("display");
		fixed_warning_offset = (vector)getjs(s_display, ["warning", "offset"]);
		fixed_warning_texture = getjs(s_display, ["warning", "texture"]);
		fixed_warning_mode = (integer)getjs(s_display, ["warning", "mode"]);
		
		devices_texture = getjs(s_display, ["devices", "texture"]);
		devices_offset = (vector)getjs(s_display, ["devices", "offset"]);
		device_scale = (float)getjs(s_display, ["devices", "scale"]);
		if(device_scale <= 0)
			device_scale = 1;
		
		device_mode = (integer)getjs(s_display, ["devices", "mode"]);
		device_wires = (integer)getjs(s_display, ["devices", "wires"]);
	}
	
	position_all(FALSE);
	@end;
}

#include <ARES/program>
