/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  Power Management Program
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

#define C_PUBLIC 0xff676981

integer EPS_active = 0;
integer power_on = 1;
integer max_state;
integer power_state;
integer forbidden_state;
string power_systems;
string power_system_names = "{}";
float power_draw = 0;

string notify_cmds = "{}";

key cmd_outs;
key cmd_user;

apply_state(integer update, integer report_state) {
	// key ek = llGenerateKey();
	// task_begin(ek, "apply");
	string s_status = llLinksetDataRead("status");

	power_draw = 0;
	integer psi = 0;
	string ps;
	list enabled_systems;
	list masked_systems;
	list disabled_systems;
	list forbidden_systems;
	
	notify_cmds = "{}";
	
	while((ps = getjs(power_systems, [(string)psi])) != JSON_INVALID) {
		integer system_forbidden = (forbidden_state & (1 << psi)) != FALSE;
		integer system_enabled = (((power_state & (1 << psi)) != FALSE) && power_on);
		integer raw_se = system_enabled;
		
		string psname = getjs(ps, ["name"]);
		
		// echo("system #" + (string)psi + " (" + (string)(1 << psi) + ") '" + psname + "'");
		
		if(system_forbidden) {
			system_enabled = FALSE;
			// echo("...is forbidden");
		} else if(system_enabled) {
			// echo("...is enabled");
			
			list psreqs = js2list(getjs(ps, ["req"]));
			integer psri = count(psreqs);
			while(psri--) {
				integer psreq = geti(psreqs, psri);
				system_enabled = (system_enabled && (power_state & (1 << psreq)) && !(forbidden_state & (1 << psreq)));
				if(!system_enabled) {
					// echo("...but inhibited due to inavailability of system " + (string)psreq);
					jump brk;
				}
			}
			@brk;
		} /*else {
			echo("...is disabled");
		}*/
		
		if(report_state) {
			if(system_forbidden)
				forbidden_systems += psname;
			else if(system_enabled)
				enabled_systems += psname;
			else if(raw_se)
				masked_systems += psname;
			else
				disabled_systems += psname;
		}
		
		string sys_enabled_char = gets(["n", "y"], system_enabled);
		
		if(update) {
			string sys_notify = getjs(ps, ["notify"]);
			if(sys_notify != JSON_INVALID) {
				sys_notify = replace(sys_notify, "?", sys_enabled_char);
				list argv = splitnulls(sys_notify, " ");
				string cmd = gets(argv, 0);
				
				string cmdl = getjs(notify_cmds, [cmd]);
				if(cmdl == JSON_INVALID)
					notify_cmds = setjs(notify_cmds, [cmd], "[]");
					
				notify_cmds = setjs(notify_cmds, [cmd, JSON_APPEND], concat(delitem(argv, 0), " "));
			}
			
			string sys_rlv = getjs(ps, ["rlv"]);
			if(sys_rlv != JSON_INVALID) {
				// sys_rlv = replace(sys_rlv, "?", sys_enabled_char);
				if(sys_enabled_char == "y")
					effector_release("power_" + psname);
				else
					effector_restrict("power_" + psname, sys_rlv);
				//echo("@" + sys_rlv);
			}
		}
		
		float sys_draw = (float)getjs(ps, ["draw"]);
		if(sys_draw != 0 && system_enabled) {
			power_draw += sys_draw;
		}
		
		++psi;
	}
	
	if(update) {
		list notify_acts = js2list(notify_cmds);
		integer ni = count(notify_acts);
		while(ni) {
			ni -= 2;
			string nc = gets(notify_acts, ni);
			list np = js2list(gets(notify_acts, ni + 1));
			string cmdline = concat([nc] + np, " ");
			if(nc == PROGRAM_NAME)
				main(0, SIGNAL_NOTIFY, cmdline, avatar, NULL_KEY, avatar);
			else
				notify_program(cmdline, avatar, NULL_KEY, avatar);
		}
	}

	if(report_state) {
		string s = concat(jskeys(power_system_names), ", ");
		string e = concat(enabled_systems, ", ");
		string m = concat(masked_systems, ", ");
		string d = concat(disabled_systems, ", ");
		string f = concat(forbidden_systems, ", ");
		
		integer sl = strlen(s);
		
		if(s == "") {
			s = "None detected. Database maintenance is required.";
		} else {
			if(e == "") e = "(none)"; else if(sl == strlen(e)) e = "(all)";
			if(m == "") m = "(none)"; else if(sl == strlen(m)) m = "(all)";
			if(d == "") d = "(none)"; else if(sl == strlen(d)) d = "(all)";
		}
	
		print(cmd_outs, cmd_user, "[" + PROGRAM_NAME + "] system status\n"
		+ "\nsupported subsystems: " + s
		+ "\nonline: " + e
		+ "\ndisabled explicitly: " + d
		+ "\ndisabled due to policy or hardware limitations: " + f
		+ "\ndisabled due to unmet dependencies: " + m
		+ "\n\nsubsystem draw: " + (string)((integer)power_draw) + " W");
	}
	
	if(update) {
		s_status = setjs(setjs(setjs(setjs(s_status,
			["state"], (string)power_state),
			["forbidden"], (string)forbidden_state),
			["draw"], (string)power_draw),
			["on"], (string)power_on);
		llLinksetDataWrite("status", s_status);
		
		e_call(C_STATUS, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " status update");
		llSleep(0.25);
		e_call(C_THERMAL, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " thermal update");
	}
	
	// task_end(ek);
}

apply_EPS(integer EPS_on) {
	string change_char = gets(["n", "y"], EPS_on);
	
	if(!power_on) {
		effector_rlv(replace(getdbl("power", ["EPS", "rlv"]), "?", change_char));
	
		list EPS_notify = js2list(getdbl("power", ["EPS", "notify"]));
		integer En = count(EPS_notify);
		while(En--) {
			notify_program(replace(gets(EPS_notify, En), "?", change_char), avatar, NULL_KEY, avatar);
		}
	}
	llSleep(0.5);
}

integer wifi_state;
integer locomotion_state;
integer lidar_state;
integer base_state;
integer hud_state;
integer video_state;
integer optics_state;
integer motors_state;

integer has_motors = TRUE;
integer can_move = TRUE;
integer can_unsit = TRUE;

integer video_in_lidar_mode;
integer no_signal_mode;
integer no_video_mode;
integer EPS_mode;

integer overlay_active;

#define ZAP_CHANNEL 0x5a415021
key zap_user;
key zap_outs;
integer zap_spend_total;
key zap_pipe = "00005a41-5020-4520-414c-4c2031393839";
integer zap_amount;

integer rebooting;

main(integer src, integer n, string m, key outs, key ins, key user) {
	@restart_main;
	key instance = llGenerateKey();
	// task_begin(instance, (string)n);
	if(n == SIGNAL_TIMER) {
		if(m == "zap-finish") {
			pipe_close(zap_pipe);
			set_timer("zap-finish", 0);
			
			string msg;
			
			if(zap_spend_total == 0)
				msg = PROGRAM_NAME + " zap: No targets in range.";
			else if(zap_spend_total != zap_amount)
				msg = PROGRAM_NAME + " zap: Disbursed " + (string)zap_spend_total + " kJ total.";
			if(msg != "")
				print(zap_outs, zap_user, msg);
			
			task_end("zap");
		} else {
			echo("[_power] Performing scheduled power " + m + " task...");
			set_timer(m, 0);
			n = SIGNAL_INVOKE;
			m = PROGRAM_NAME + " " + m;
			user = outs = avatar;
			ins = NULL_KEY;
			jump restart_main;
		}
	} else if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		string msg;
		integer argc = count(argv);
		// echo("[_power] executing: " + m);
		cmd_outs = outs;
		cmd_user = user;
		// echo((string)argc);
		if(argc == 1) {
			apply_state(0, 1);
			e_call(C_STATUS, E_SIGNAL_CALL, (string)outs + " " + (string)user + " status power");
			llSleep(0.022);
			e_call(C_THERMAL, E_SIGNAL_CALL, (string)outs + " " + (string)user + " thermal power");
		} else {
			string sys = gets(argv, 1);
			string act = gets(argv, 2);
			
			string pss;
			string ann;
			
			if(sys == "drainprotect") {
				list opt_de = ["disabled", "enabled"];
				list opt_standard = ["off", "on", "toggle"];
			
				integer result = (integer)getdbl("status", ["drainprotect"]);
				if(contains(opt_standard, act)) {
					setdbl("status", ["drainprotect"],
						(string)(result = geti([0, 1, !result],
						index(opt_standard, act)))
					);
					msg = "DrainProtect™ is now " + gets(opt_de, result) + ".";
					e_call(C_STATUS, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " status update");
					
				} else {
					msg = "DrainProtect™ is " + gets(opt_de, result) + ".";
				}
				
				if(result)
					msg += " The unit will be protected from unauthorized attempts to extract power.";
					
			} else if(sys == "menu") {
				list schemes = jskeys(getdbl("power", ["profile"]));
				list scheme_buttons = [];
				integer sci = count(schemes);
				while(sci--) {
					string scheme = gets(schemes, sci);
					string sb = jsarray([
						scheme,
						0,
						"power load " + scheme
					]);
					scheme_buttons = sb + scheme_buttons;
				}
				setdbl("m:profile", ["d"], jsarray(scheme_buttons));
			} else if(sys == "zap") {
				task_begin("zap", "");
				if(act == "reply") {
					string buffer;
					pipe_read(ins, buffer);
					if(llVecDist(llGetPos(), object_pos(user)) < 20) {
						zap_spend_total += zap_amount;
						io_tell(user, C_PUBLIC, "charge " + (string)zap_amount);
						e_call(C_STATUS, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " charge " + (string)(1000 * -zap_amount));
						print(zap_outs, zap_user, PROGRAM_NAME + " zap: Sent " + (string)zap_amount + " kJ to " + llKey2Name(user));
					}
					set_timer("zap-finish", 2);
				} else {
					zap_user = user;
					zap_outs = outs;
					zap_amount = llAbs((integer)act);
					if(zap_amount == 0)
						zap_amount = 240;
					else if(zap_amount > 720) {
						zap_amount = 720;
						print(outs, user, "Notice: zapping is capped at 720 kJ");
					}
					
					zap_spend_total = 0;
					
					pipe_open("p:" + (string)zap_pipe + " from " + (string)ZAP_CHANNEL + " " + NULL_KEY + " power zap reply");
					set_timer("zap-finish", 2);
				}
			} else if(sys == "cancel") {
				set_timer("on", 0);
				set_timer("off", 0);
				set_timer("cycle", 0);
				set_timer("reboot", 0);
				msg = "Scheduled tasks cleared.";
			} else if(sys == "on" || sys == "off" || sys == "cycle" || sys == "reboot") {
				integer delay = (integer)act;
				if(delay > 0) {
					if(delay < 10)
						delay = 10;
					msg = "[_power] Scheduled power " + llToUpper(sys) + " to occur in " + format_time(delay) + "; abort with 'power cancel'";
					if(user != avatar) {
						echo(msg);
					}
					print(outs, user, msg);
					set_timer(sys, delay);
					return;
				}
			
				integer viable = FALSE; // desired power change is possible
				integer new_state = (sys == "on");
				
				if(!new_state && sys != "off") {
					if(!power_on) {
						new_state = 1;
						sys = "on";
					} else {
						rebooting = 1;
						sys = "off";
					}
				}
				
				float integrity = (float)getdbl("repair", ["integrity"]);
				
				if(integrity == 0) {
					viable = 0;
					msg = "Repairs are required to restore power control.";
					rebooting = 0;
				} else if(new_state == power_on) {
					viable = 0;
					msg = "Cannot power " + sys + ": already " + sys + ".";
				} else if(new_state == 1) {
					float capacity = (float)getdbl("status", ["capacity"]);
					float charge = (float)getdbl("status", ["charge"]);
					if(capacity == 0) {
						msg = "Cannot power on: no battery is installed.";
						viable = 0;
					} else if(charge == 0) {
						msg = "Cannot power on: battery is empty.";
						viable = 0;
					} else {
						viable = 1;
					}
				} else {
					viable = 1;
				}
				
				if(viable) {
					setdbl("status", ["on"], (string)new_state);
					// power_on = new_state;
					n = SIGNAL_NOTIFY;
					m = "power system " + sys;
					jump restart_main;
					
					// main(src, SIGNAL_NOTIFY, "power system " + sys, outs, ins, user);
					// apply_state(1, 0);
					// the SIGNAL_NOTIFY should take care of applying state and status update
				}
				/*power_on = (sys == "on");
				
				
				apply_state(TRUE, FALSE);*/
			} else if(sys == "load") {
				if(act == "") {
					string pplist = concat(jskeys(getdbl("power", ["profile"])), ", ");
					if(pplist == "")
						pplist = "(none)";
					msg = "Available power profiles: " + pplist;
				} else {
					string power_profile = getdbl("power", ["profile", act]);
					if(power_profile == JSON_INVALID) {
						msg = "No power profile: " + act;
					} else {
						setdbl("m:profile", ["f"], act);
						power_state = (integer)power_profile;
						ann = "subsystem-profile";
						msg = "Power profile '" + act + "' loaded.";
						apply_state(1, 0);
					}
				}
			} else if(sys == "delete") {
				if(act != "") {
					string power_profile = getdbl("power", ["profile", act]);
					if(power_profile == JSON_INVALID) {
						msg = "No power profile: " + act;
					} else {
						deletedbl("power", ["profile", act]);
						msg = "Deleted power profile '" + act + "'";
					}
				} else {
					msg = "To delete a power profile, please specify a name.";
				}
			} else if(sys == "save") {
				if(act != "") {
					setdbl("power", ["profile", act], (string)power_state);
					msg = "Power profile '" + act + "' saved.";
				} else {
					msg = "To save a power profile, please specify a name.";
				}
			} else if(sys == "all") {
				if(act == "toggle" || act == "") {
					integer old_power_state = power_state;
					power_state = ~power_state & max_state;
					if(old_power_state < power_state)
						ann = "subsystem-1";
					else
						ann = "subsystem-0";
				} else if(act == "off") {
					power_state = 0;
					ann = "subsystem-0";
				} else if(act == "on") {
					power_state = max_state;
					ann = "subsystem-1";
				}
				
				apply_state(1, 0);
			} else if((pss = getjs(power_system_names, [sys])) != JSON_INVALID) {
				integer system_forbidden = (forbidden_state & (1 << (integer)pss)) != FALSE;
			
				integer mask = 1 << (integer)pss;
				// echo("Power state starts at " + (string)power_state);
				
				if(act == "toggle" || act == "") {
					integer new_power_state = power_state ^ mask;
					if(new_power_state > power_state)
						ann = "subsystem-1";
					else
						ann = "subsystem-0";
					
					power_state = new_power_state;
				} else if(act == "on") {
					power_state = power_state | mask;
					ann = "subsystem-1";
				} else if(act == "off") {
					power_state = power_state & ~(mask);
					ann = "subsystem-0";
				}
				
				if(system_forbidden) {
					ann = "critical-error";
					msg = "power operation failed: " + sys + " is unavailable due to hardware or policy limitations";
				}
				
				// echo("Changing " + pss + " #?# " + (string)mask + " -> " + (string)power_state);
				
				apply_state(1, 0);
			} else {
				msg = "no subsystem: " + sys;
			}
			
			if(ann)
				announce(ann);
		}
		
		if(msg != "") {
			print(outs, user, msg);
		}
		
	} else if(n == SIGNAL_NOTIFY) {
		float integrity = (float)getdbl("repair", ["integrity"]);
		list argv = delitem(splitnulls(m, " "), 0);
		// echo("power notify: " + (string)ins + " " + (string)user + " | " + concat(argv, ".."));
		string cmd1 = gets(argv, 0);
		integer ci = count(argv);
		if(cmd1 == "pipe" && ins == zap_pipe) {
			io_tell(NULL_KEY, C_PUBLIC, "ping " + (string)ZAP_CHANNEL);
		} else while(ci > 0) {
			ci -= 2;
			string cmd = gets(argv, ci);
			string status = gets(argv, ci + 1);
			// echo("POWER notify: " + cmd + " " + status);
			
			if(cmd == "forbidden") {
				// change in forbidden rules
				forbidden_state = (integer)getdbl("status", ["forbidden"]);
				apply_state(1, 0);
			} else if(cmd == "charged") {
				// integer charge_bootable = (status == "y");
				// no code required here - will occur automatically
				
			} else if(cmd == "wifi") {
				// block non-attached devices
				wifi_state = (status == "y");
				setdbl("status", ["remote-device"], (string)wifi_state);
				e_call(C_HARDWARE, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " hardware reconfigure");
			} else if(cmd == "locomotion") {
				// block unsit if already sitting, tell effector daemon to take controls
				locomotion_state = (status == "y");
			} else if(cmd == "lidar") {
				lidar_state = (status == "y");
			} else if(cmd == "base") {
				base_state = (status == "y");
			} else if(cmd == "hud") {
				hud_state = (status == "y");
			} else if(cmd == "motors") {
				motors_state = (status == "y");
			} else if(cmd == "video") {
				video_state = (status == "y");
			} else if(cmd == "optics") {
				optics_state = (status == "y");
			} else if(cmd == "notify") {
				// redeliver cached notify messages:
				string nc = getjs(notify_cmds, [status]);
				if(nc != JSON_INVALID) {
					list np = js2list(nc);
					string cmdline = concat([status] + np, " ");
					if(status == PROGRAM_NAME)
						main(src, SIGNAL_NOTIFY, cmdline, avatar, NULL_KEY, avatar);
					else
						notify_program(cmdline, avatar, NULL_KEY, avatar);
				}
			} else if(cmd == "system") {
				integer new_power_on = (status == "on");
				if(new_power_on != power_on) {
					power_on = new_power_on;
					if(EPS_active && power_on)
						apply_EPS(FALSE);
					apply_state(TRUE, FALSE);
					
					if(power_on) {
						effector_release("a:shutdown");
						echo("[_power] System initialized.");
						announce("power-on");
						string boot_chime = getdbl("id", ["chime", "boot"]);
						if(boot_chime != JSON_INVALID)
							llTriggerSound(boot_chime, 1);
					} else {
						string anim = "s_shutdown";
						if(integrity > 0) {
							echo("[_power] System shutdown complete. Type '@on' to boot.");
							
							announce("power-off");
							string halt_chime = getdbl("id", ["chime", "halt"]);
							if(halt_chime != JSON_INVALID)
								llTriggerSound(halt_chime, 1);
						} else {
							anim = "s_dead";
							echo("[_power] System offline due to damage.");
						}
						
						effector_restrict("a:shutdown", anim);
					}
					
					notify_program("security power", outs, NULL_KEY, user);
					if(llGetInventoryType("dispatch") == INVENTORY_SCRIPT) {
						notify_program("dispatch power", outs, NULL_KEY, user);
					}
					
					llSleep(0.5);
					
					e_call(C_INTERFACE, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " interface reconfigure");
					if(rebooting) {
						llSleep(1);
						rebooting = 0;
						echo("[_power] Rebooting...");
						
						/*m = PROGRAM_NAME + " on";
						n = SIGNAL_INVOKE;
						jump restart_main;*/
						// invoke("_power on", outs, NULL_KEY, user);
						// must finish shutdown first
						set_timer("on", 1);
					}
				}
			} else if(cmd == "aux") {
				if(rebooting) {
					echo("[_power] Not entering EPS; reboot in progress");
				} else {
					integer new_EPS_on = (status == "on");
					if(new_EPS_on != EPS_active) {
						if(power_on && new_EPS_on) {
							EPS_active = FALSE;
							echo("[_power] Not entering EPS; power is on.");
						} else {
							EPS_active = new_EPS_on;
							apply_EPS(EPS_active);
							/* if(!power_on)
								echo("[_power] Auxiliary power now " + status + "."); */
						}
					}
				}
			}
		}
		
		if(!motors_state && has_motors) {
			has_motors = FALSE;
			effector_restrict("a:motors", "s_frozen");
		} else if(motors_state && !has_motors) {
			has_motors = TRUE;
			effector_release("a:motors");
		}
		
		if(lidar_state && !optics_state && video_state && !video_in_lidar_mode) {
			effector_restrict(
				"power_lidar", "setsphere=?||setsphere_mode:0=force,setsphere_param:0/0/0/0=force,setsphere_distmin:0=force,setsphere_distmax:10=force,setsphere_distextend:3=force,setsphere_valuemin:0.0=force,setsphere_valuemax:1=force"
			);
			effector_restrict(
					"power_lidar-2", "setenv_daytime:-1=force,setenv=?,setenv_daytime:-1=force||setenv_ambient:2/2/2=force,setenv_bluedensity:1/1/1=force,setenv_bluehorizon:1/1/1=force,setenv_scenegamma:2=force,setenv_hazedensity:1=force,setenv_hazehorizon:0=force,setenv_maxaltitude:4000=force,setenv_densitymultiplier:2=force,setenv_distancemultiplier:2000=force,setenv_starbrightness:0=force"
			);
			video_in_lidar_mode = TRUE;
		} else if(video_in_lidar_mode) {
			effector_release("power_lidar");
			effector_release("power_lidar-2");
			llSleep(0.2);
			echo("@setenv=n,setenv_reset=force,setenv=y");
			video_in_lidar_mode = FALSE;
		}
		
		/*
		   "No Video" and "No Signal" modes interact in a tricky manner because they both use setoverlay
			
			Overlay priorities:
				dead, no rez
				dead, will rez
				EPS active
				no battery
				empty battery
				no EPS (bootable)
				no video
				no signal
		*/
		
		#define AUX_POWER_OVERLAY "27262ded-a1fa-a5ed-3fb9-5870e67794b1"
		#define REALLY_DEAD_OVERLAY "cc377084-0058-f385-e19e-bd23f33df085"
		#define WILL_RECLAIM_OVERLAY "b54ada0c-342d-3851-a4e9-e85661a96d76"
		#define NO_BATTERY_OVERLAY "fc6c3a3a-f9ee-5301-7563-07d6b023770d"
		#define EMPTY_BATTERY_OVERLAY "b35df830-9cab-d5f8-4007-e21223db886a"
		#define BOOTABLE_OVERLAY "d5a932db-2526-e949-e23f-30c9aeea0811"
		// #define NO_VIDEO_OVERLAY "c15ea705-570d-ee99-10ba-ee2d978033aa"
		#define NO_VIDEO_OVERLAY "e8a40fce-1f34-9cfd-953e-9e31b2b4dc7c"
		#define NO_SIGNAL_OVERLAY "e9c6ad2b-879c-4472-58a9-03ae64ad5b7d"
		
		string overlay;
		
		if(EPS_active && !power_on) {
			overlay = AUX_POWER_OVERLAY;
		} else if(!power_on) {
			integer can_reclaim = (integer)getdbl("repair", ["reclamation"]);
			float battery_charge = (float)getdbl("status", ["charge"]);
			float battery_capacity = (float)getdbl("status", ["capacity"]);
			
			if(integrity == 0) {
				if(can_reclaim)
					overlay = WILL_RECLAIM_OVERLAY;
				else
					overlay = REALLY_DEAD_OVERLAY;
			} else if(battery_capacity > 0) {
				if(battery_charge > 0) {
					overlay = BOOTABLE_OVERLAY;
				} else {
					overlay = EMPTY_BATTERY_OVERLAY;
				}
			} else {
				overlay = NO_BATTERY_OVERLAY;
			}
		
		} else if(!video_state && !no_video_mode) {
			
			overlay = NO_VIDEO_OVERLAY;
			no_video_mode = TRUE;
			no_signal_mode = FALSE;
		} else if(video_state && !(lidar_state || optics_state) && !no_signal_mode) {
			// overlay = "97614d75-2bcb-e2e5-6df8-8fe5cf0b1988";
			
			overlay = NO_SIGNAL_OVERLAY;
			no_video_mode = FALSE;
			no_signal_mode = TRUE;
		} else if(no_video_mode && video_state) {
			no_signal_mode = FALSE;
			no_video_mode = FALSE;
		}
		
		if(no_signal_mode && (optics_state || lidar_state)) {
			no_signal_mode = FALSE;
		}
		
		if(overlay_active) { // is active
			if(power_on && !(no_video_mode || no_signal_mode)) { // but we don't need it
				overlay_active = FALSE;
				effector_release("power_overlay");
			} else if(overlay != "") { // we changed it
				// echo("[_power] RLV overlay " + overlay + " applied during notify " + m);
				// echo("subsystem states: " + (string)power_state + ", " + getdbl("status", ["state"]));
				effector_restrict("power_overlay", "setoverlay=?,setoverlay_alpha:1=force,setoverlay_tint:1/1/1=force,setoverlay_texture:" + overlay + "=force");
			}
		} else if(overlay != "") { // isn't active but we need to apply it
			overlay_active = TRUE;
			effector_restrict("power_overlay", "setoverlay=?,setoverlay_alpha:1=force,setoverlay_tint:1/1/1=force,setoverlay_texture:" + overlay + "=force");
		} // else isn't active and we don't need it
		
		if(locomotion_state && !can_move) {
			effector_release("power_movement");
			can_move = TRUE;
			if(!can_unsit) {
				effector_release("power_unsit");
				can_unsit = TRUE;
			}
		} else if(!locomotion_state && can_move) {
			effector_restrict("power_movement", "move=?"); // special pseudo-RLV command
			can_move = FALSE;
			if(llGetAgentInfo(avatar) & AGENT_SITTING) {
				can_unsit = FALSE;
				effector_restrict("power_unsit", "unsit=?");
				// TODO: when implementing handles, they need a way to re-enable can_unsit
			}
		}
		
	} else if(n == SIGNAL_INIT) {
		#ifdef DEBUG
			echo("[" + PROGRAM_NAME + "] init event");
		#endif
		// hook_events([EVENT_TELEPORT, EVENT_ON_REZ, EVENT_REGION_CHANGE]);
		hook_events([EVENT_ON_REZ]);
		
		string s_status = llLinksetDataRead("status");
		string s_power = llLinksetDataRead("power");
		power_on = (integer)getjs(s_status, ["on"]);
		forbidden_state = (integer)getjs(s_status, ["forbidden"]);
		power_state = (integer)getjs(s_status, ["state"]);
		power_draw = (float)getjs(s_status, ["draw"]);
		power_systems = getjs(s_power, ["system"]);
		
		integer psi = 0;
		string ps = "";
		while((ps = getjs(power_systems, [(string)psi])) != JSON_INVALID) {
			string psname = getjs(ps, ["name"]);
			power_system_names = setjs(power_system_names, [psname], (string)psi);
			++psi;
		}
		
		max_state = (1 << psi) - 1;
		#ifdef DEBUG
		echo("[" + PROGRAM_NAME + "] (DEBUG) available subsystems: " + (string)psi);
		#endif
		
		apply_state(1, 0);
	} else if(n == SIGNAL_EVENT) {
		integer e = (integer)m;
		if(e == EVENT_ON_REZ) {
			notify_program("security power", avatar, NULL_KEY, avatar);
		}
	/*} else if(n == SIGNAL_EVENT) {
		// handles events EVENT_ON_REZ, EVENT_TELEPORT
		// both cause FTL resets
		// tell status daemon about it
		integer e = (integer)m;
		if(e == EVENT_TELEPORT || e == EVENT_ON_REZ || e == EVENT_REGION_CHANGE) {
			e_call(C_STATUS, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " status teleport");
		}
		// echo("[" + PROGRAM_NAME + "] unimplemented event " + m);
		// apply_state();
		*/
		// the above is just too slow
	} else if(n == SIGNAL_UNKNOWN_SCRIPT) {
		echo("[" + PROGRAM_NAME + "] failed to run '" + m + "' (kernel could not find the program specified)");
	} else {
		echo("[" + PROGRAM_NAME + "] unimplemented signal " + (string)n + ": " + m);
	}
	// task_end(instance);
}

#include <ARES/program>
