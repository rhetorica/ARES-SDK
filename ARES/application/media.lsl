/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  media Utility
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
#define CLIENT_VERSION "0.3.0"
#define CLIENT_VERSION_TAGS "beta"

#define S_PLAY 0x01
#define S_STOP 0x02
#define S_LOOP 0x04
#define S_INT 0x08
#define S_EXT 0x10
#define S_PRELOAD 0x20

#define SILENCE "475b270a-8dc0-2b53-210d-32d4dc6ebc7c"

integer playing;
float volume = 1.0;
integer venue = 0;

list anim_start_queue;
list anim_stop_queue;

string perms_thread;

main(integer src, integer n, string m, key outs, key ins, key user) {
	if(n == SIGNAL_INVOKE) {
		list argv = split(m, " ");
		integer argc = count(argv);
		string msg = "";
		integer action = 0;
		
		if(argc == 1) {
			msg = gets(argv, 0) + " [-i|internal] [-x|external] [-v|vol|volume 0.0-1.0] [-n|link|prim <link #>] [-p|play|-l|loop|preload|trigger <sound>] [-p|play <animation>] [-d|duration|-s|sleep|-w|wait <seconds>] [stop] [stop <animation>] [freeze] [unfreeze] [-q 0|1]\n\nControls media playback.\n\ninternal/external: select audio channel\nvolume: set sound volume\nlink/prim: set prim number for sound playback (internal only, not compatible with -q)\nplay/loop/trigger: play sound name (loop only supported for internal mode)\nduration/sleep/wait: pause for <seconds>\nstop: end current sound playback\n-q: toggle sound queueing for internal audio (not compatible with -n)\n\nFor best results, set channel and volume before sound playback command, and add sleep afterward. Multiple commands are allowed.\n\nFuture versions will add a HUD widget for interacting with sound, images, and animations.";
		} else {
			integer C_LIGHT_BUS = 105 - (integer)("0x" + substr(avatar, 29, 35));
			integer link_number = LINK_THIS;
			
			integer argi = 1;
			while(argi < argc) {
				string arg = gets(argv, argi);
				
				if(arg == "-q") {
					++argi;
					integer enable_queueing = (integer)gets(argv, argi);
					llSetSoundQueueing(enable_queueing);
					
				} else if(arg == "-n" || arg == "link" || arg == "prim") {
					++argi;
					link_number = (integer)gets(argv, argi);
				} else if(arg == "play" || arg == "-p" || arg == "loop" || arg == "-l" || arg == "preload") {
					++argi;
					string fname = gets(argv, argi);
					integer ftype = llGetInventoryType(fname);
					integer do_sound = 0;
					integer do_animation = 0;
					integer loop = (arg == "loop" || arg == "-l");
					integer preload = (arg == "preload");
					string fuuid = llGetInventoryKey(fname);
					if(ftype == INVENTORY_NONE) {
						if(validate_key(fname)) {
							do_sound = 1;
							fuuid = fname;
						} else {
							msg = "no file '" + fname + "'";
						}
					} else if(ftype == INVENTORY_SOUND) {
						do_sound = 1;
					} else if(ftype == INVENTORY_ANIMATION) {
						do_animation = 1;
					} else {
						msg = fname + ": wrong file type";
					}
					
					if(do_sound) {
						if(preload) {
							llPreloadSound(fname);
						} else if(venue == S_INT) {
							if(loop) {
								// llLoopSound(fname, volume);
								llLinkPlaySound(link_number, fname, volume, SOUND_LOOP);
							} else {
								// llPlaySound(fname, volume);
								llLinkPlaySound(link_number, fname, volume, SOUND_PLAY);
							}
						} else if(venue == S_EXT) {
							if(fuuid) {
								if(loop) {
									msg = "external sound playback does not support loop";
								} else {
									key controller = getdbl("device", ["controller", "id"]);
									if(controller != JSON_INVALID) {
										io_tell(controller, C_LIGHT_BUS, "fx s " + fuuid + " " + (string)volume);
									} else {
										msg = "no device available for external sound playback";
									}
								}
							} else {
								msg = "cannot get UUID of '" + fname + "' for external playback; insufficient inventory permissions";
							}
						}
					} else if(do_animation) {
						if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
							llStartAnimation(fname);
						} else {
							anim_start_queue += fname;
							llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
							if(perms_thread == "") {
								task_begin(perms_thread = llGenerateKey(), "");
							}
						}
					}
				} else if(arg == "trigger") {
					string fname = gets(argv, argi);
					integer ftype = llGetInventoryType(fname);
					integer do_sound = 0;
					if(ftype == INVENTORY_NONE) {
						if(validate_key(fname)) {
							do_sound = 1;
						} else {
							msg = "no file '" + fname + "'";
						}
					} else if(ftype == INVENTORY_SOUND) {
						do_sound = 1;
					} else {
						msg = fname + ": wrong file type";
					}
					
					if(do_sound)
						// llTriggerSound(fname, volume);
						llLinkPlaySound(link_number, fname, volume, SOUND_TRIGGER);
				} else if(arg == "-i" || arg == "internal") {
					venue = S_INT;
				} else if(arg == "-x" || arg == "external") {
					venue = S_EXT;
				} else if(arg == "freeze") {
					effector_restrict("mfreeze", "move=?");
				} else if(arg == "unfreeze") {
					effector_release("mfreeze");
				} else if(arg == "-s" || arg == "sleep" || arg == "-w" || arg == "wait" || arg == "-d" || arg == "duration") {
					++argi;
					float length = (float)gets(argv, argi);
					llSleep(argi);
				} else if(arg == "stop") {
					action = S_STOP;
					string fname = gets(argv, argi + 1);
					if(llGetInventoryType(fname) == INVENTORY_ANIMATION) {
						++argi;
						if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
							llStopAnimation(fname);
						} else {
							anim_stop_queue += fname;
							llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
							if(perms_thread == "") {
								task_begin(perms_thread = llGenerateKey(), "");
							}
						}
					} else if(venue == S_INT) {
						// llStopSound();
						llLinkStopSound(link_number);
					} else if(venue == S_EXT) {
						key controller = getdbl("device", ["controller", "id"]);
						if(controller != JSON_INVALID) {
							io_tell(controller, C_LIGHT_BUS, "fx s " + SILENCE + " 0");
						} else {
							msg = "no device available for external sound playback";
						}
					}
				} else if(arg == "-v" || arg == "volume" || arg == "vol") {
					++argi;
					volume = (float)gets(argv, argi);
					if(venue == S_INT)
						llAdjustSoundVolume(volume);
				} else {
					msg = PROGRAM_NAME + ": unexpected parameter '" + arg + "'; see 'help media' for usage";
				}
				
				++argi;
			}
		}
		
		if(msg != "") {
			print(outs, user, PROGRAM_NAME + ": " + msg);
		}
		
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

#define EXT_EVENT_HANDLER "ARES/application/media.event.lsl"
#include <ARES/program>
