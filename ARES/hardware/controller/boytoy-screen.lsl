#include <utils.lsl>
#include <objects.lsl>


#define B_A 79
#define B_B 80
#define B_C 81
#define B_D 82
#define SCREEN 10
#define SCREEN_2 11
#define SCREEN_3 12
#define SCREEN_CONE 9
#define TEXT_START 13
#define TEXT_COUNT 66
#define X_STEP (1.0/15.0)
#define BUTTON_B_WINDOW 1
#define ACTS_FLUSH 1024


#ifndef FX_TP_SOURCE
    #define FX_TP_SOURCE 4
#endif
#ifndef FX_TP_SOUND
    #define FX_TP_SOUND "c8cee78d-7116-8626-d779-7e13891a5df5"
#endif
#ifndef FX_TP_SOUND_VOL
    #define FX_TP_SOUND_VOL 0.5
#endif
#ifndef FX_BLOOM_HOLD
    #define FX_BLOOM_HOLD 0.7
#endif
#ifndef FX_SHOWER_DURATION
    #define FX_SHOWER_DURATION 1.8
#endif
#ifndef FX_PARTICLE_TEX
    #define FX_PARTICLE_TEX "7a0279e0-1e73-aa14-e387-e99e0a36b9a9"
#endif


integer screen_open = FALSE;
integer booted;
integer restore_menu_timer;
vector c1 = <0, 0.5, 1>;
vector c2 = <0, 1, 1>;
vector c3 = <1, 1, 0>;
vector c4 = <0, 0.75, 1>;
integer power_on;
key system;
integer CL;
integer muted;
integer button_b_waiting;
key button_b_user;
integer LL = -1;
list pbr_emissive_faces;
rotation text_rot;
rotation text_plane;

flush_acts(list acts) {
    if(count(acts))
        setp(0, acts);
}
cache_pbr_emissive_faces() {
    pbr_emissive_faces = [];
    integer link = llGetNumberOfPrims();
    while(link) {
        string desc = gets(getp(link, [PRIM_DESC]), 0);
        if(llOrd(desc, 0) == 0x23) {
            list faces = split(delstring(desc, 0, 0), ",");
            integer i = count(faces);
            while(i--) {
                integer face = geti(faces, i);
                if(face == ALL_SIDES) {
                    integer side = llGetLinkNumberOfSides(link);
                    while(side--)
                        pbr_emissive_faces += [link, side];
                } else {
                    pbr_emissive_faces += [link, face];
                }
            }
        }
        --link;
    }
}
recolor_pbr_emissive() {
    vector color = llsRGB2Linear(c1 * (float)power_on);
    integer i = count(pbr_emissive_faces);
    while(i) {
        i -= 2;
        llSetLinkGLTFOverrides(
            geti(pbr_emissive_faces, i),
            geti(pbr_emissive_faces, i + 1),
            [OVERRIDE_GLTF_EMISSIVE_FACTOR, color]
        );
    }
}
send_command(key user, string cmdline) {
    if(system)
        tell(system, CL, "command " + (string)user + " " + (string)user + " " + cmdline);
    else {
        tell(llGetOwner(), CL, "ping");
        tell(user, 0, "Not yet connected to ARES. Please try again.");
    }
}
recolor_screen() {
    list acts = [
        PRIM_LINK_TARGET, SCREEN,
            PRIM_COLOR, ALL_SIDES, c4, 0.5,
        PRIM_LINK_TARGET, SCREEN_2,
            PRIM_COLOR, ALL_SIDES, c2, 1,
        PRIM_LINK_TARGET, SCREEN_3,
            PRIM_COLOR, ALL_SIDES, c2, 1,
        PRIM_LINK_TARGET, SCREEN_CONE,
            PRIM_COLOR, ALL_SIDES, c4, 0.0625
    ];
    integer pn = TEXT_START;
    while(pn < TEXT_START + TEXT_COUNT) {
        acts += [
            PRIM_LINK_TARGET, pn,
            PRIM_COLOR, ALL_SIDES, c2, 1
        ];
        ++pn;
        if(llGetFreeMemory() < ACTS_FLUSH) {
            flush_acts(acts);
            acts = [];
        }
    }
    flush_acts(acts);
}
screen_control(integer open) {
    list acts;
    
    if(open) {
        vector scale = <0, 5 * X_STEP, 3 * X_STEP>;
        integer pn = TEXT_START;
        vector screen_origin = <0.00000, -0.12748, 0.13781>;        
        setp(0, [
            PRIM_LINK_TARGET, SCREEN,
                PRIM_SIZE, <0.48000, 0.43979, 0.29782>,
                PRIM_POS_LOCAL, <-0.00000, -0.11470, 0.16081>,
                PRIM_ROT_LOCAL, <-0.00001, 0.04907, 0.99880, 0.00000>,
                PRIM_COLOR, ALL_SIDES, c4, 0.5,
            PRIM_LINK_TARGET, SCREEN_2,
                PRIM_SIZE, <0.28000, 0.06000, 0.09000>,
                PRIM_POS_LOCAL, <0.00000, -0.29178, 0.19020>,
                PRIM_ROT_LOCAL, <0.00000, 0.04907, 0.99880, 0.00000>,
                PRIM_COLOR, ALL_SIDES, c2, 1,
            PRIM_LINK_TARGET, SCREEN_3,
                PRIM_SIZE, <0.24000, 0.12, 0.06000>,
                PRIM_POS_LOCAL, <0.00000, 0.04835, 0.15801>,
                PRIM_ROT_LOCAL, <0.00000, 0.04907, 0.99880, 0.00000>,
                PRIM_COLOR, ALL_SIDES, c2, 1,
            PRIM_LINK_TARGET, SCREEN_CONE,
                PRIM_SIZE, <0.35000, 0.35000, 0.12500>,
                PRIM_POS_LOCAL, <-0.00000, -0.05045, 0.08679>,
                PRIM_ROT_LOCAL, <-0.04907, 0.00000, 0.00000, 0.99880>,
                PRIM_COLOR, ALL_SIDES, c4, 0.0625
        ]);        
        while(pn < TEXT_START + TEXT_COUNT) {
            integer tx = (pn - TEXT_START) % 6;
            integer ty = (pn - TEXT_START) / 6;
            float x = (float)tx - 2.5;
            float dy = 10 - ty;
            float secondary_scale = 1.0;
            if(dy == 9) {
                dy = 8.5;
                secondary_scale = 1.3;
            } else if(dy == 0) {
                dy = -0.25;
                secondary_scale = 1.1;
            } else if(dy == 10) {
                dy = 10.5;
                secondary_scale = 1.1;
            }
            float y = (float)(dy) - 5.5;
            vector local = <x * X_STEP, y * X_STEP / 3.5, 0.025 * secondary_scale * secondary_scale> * secondary_scale;
            acts += [
                PRIM_LINK_TARGET, pn,
                PRIM_SIZE, scale * secondary_scale,
                PRIM_POS_LOCAL, local * text_plane + screen_origin,
                PRIM_ROT_LOCAL, text_rot,
                PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 128,
                PRIM_COLOR, ALL_SIDES, c2, 1
            ];
            ++pn;
            if(llGetFreeMemory() < ACTS_FLUSH) {
                flush_acts(acts);
                acts = [];
            }
        }
        flush_acts(acts);
    } else {
        integer pn = TEXT_START;
        setp(0, [
            PRIM_LINK_TARGET, SCREEN,
                PRIM_SIZE, <0.02800, 0.02800, 0.03404>,
                PRIM_POS_LOCAL, <-0.00017, -0.06479, -0.00340>,
                PRIM_COLOR, ALL_SIDES, c4, 0.5,
            PRIM_LINK_TARGET, SCREEN_2,
                PRIM_SIZE, <0.02240, 0.01000, 0.01000>,
                PRIM_POS_LOCAL, <-0.00017, -0.07593, -0.00429>,
                PRIM_COLOR, ALL_SIDES, c2, 1,
            PRIM_LINK_TARGET, SCREEN_3,
                PRIM_SIZE, <0.01920, 0.01000, 0.01000>,
                PRIM_POS_LOCAL, <-0.00017, -0.05335, -0.00067>,
                PRIM_COLOR, ALL_SIDES, c2, 1,
            PRIM_LINK_TARGET, SCREEN_CONE,
                PRIM_SIZE, <0.02800, 0.02800, 0.01000>,
                PRIM_POS_LOCAL, <-0.00017, -0.07072, -0.00982>,
                PRIM_COLOR, ALL_SIDES, c4, 0.0625
        ]);
        while(pn < TEXT_START + TEXT_COUNT) {
            acts += [
                PRIM_LINK_TARGET, pn,
                PRIM_SIZE, ZV,
                PRIM_POS_LOCAL, ZV,
                PRIM_ROT_LOCAL, text_rot
            ];
            ++pn;
            if(llGetFreeMemory() < ACTS_FLUSH) {
                flush_acts(acts);
                acts = [];
            }
        }
        flush_acts(acts);
    }
    screen_open = open;
}
clearIdolFx() {
    llLinkParticleSystem(FX_TP_SOURCE, []);
}
playIdolBloom() {
    llLinkParticleSystem(FX_TP_SOURCE, [
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_BURST_RADIUS, 0.0,
        PSYS_SRC_ANGLE_BEGIN, 0.0,
        PSYS_SRC_ANGLE_END, 0.0,
        PSYS_PART_START_COLOR, c1,
        PSYS_PART_END_COLOR, c2,
        PSYS_PART_START_ALPHA, 0.15,
        PSYS_PART_END_ALPHA, 0.02,
        PSYS_PART_START_GLOW, 0.04,
        PSYS_PART_END_GLOW, 0.0,
        PSYS_PART_BLEND_FUNC_SOURCE, PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
        PSYS_PART_START_SCALE, <1.0, 1.0, 0.0>,
        PSYS_PART_END_SCALE, <2.4, 2.4, 0.0>,
        PSYS_SRC_TEXTURE, FX_PARTICLE_TEX,
        PSYS_SRC_MAX_AGE, FX_BLOOM_HOLD,
        PSYS_PART_MAX_AGE, FX_BLOOM_HOLD + 0.25,
        PSYS_SRC_BURST_RATE, 0.0,
        PSYS_SRC_BURST_PART_COUNT, 1,
        PSYS_SRC_ACCEL, <0.0, 0.0, 0.0>,
        PSYS_SRC_OMEGA, <0.0, 0.0, 0.5>,
        PSYS_SRC_BURST_SPEED_MIN, 0.0,
        PSYS_SRC_BURST_SPEED_MAX, 0.02,
        PSYS_PART_FLAGS,
            PSYS_PART_EMISSIVE_MASK |
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK
    ]);
}
playIdolShower() {
    llLinkParticleSystem(FX_TP_SOURCE, [
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_SRC_BURST_RADIUS, 0.95,
        PSYS_SRC_ANGLE_BEGIN, 0.0,
        PSYS_SRC_ANGLE_END, 0.7,
        PSYS_PART_START_COLOR, c1,
        PSYS_PART_END_COLOR, c2,
        PSYS_PART_START_ALPHA, 0.75,
        PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_GLOW, 0.08,
        PSYS_PART_END_GLOW, 0.0,
        PSYS_PART_BLEND_FUNC_SOURCE, PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
        PSYS_PART_START_SCALE, <0.03, 0.03, 0.0>,
        PSYS_PART_END_SCALE, <0.10, 0.10, 0.0>,
        PSYS_SRC_TEXTURE, FX_PARTICLE_TEX,
        PSYS_SRC_MAX_AGE, FX_SHOWER_DURATION,
        PSYS_PART_MAX_AGE, 1.5,
        PSYS_SRC_BURST_RATE, 0.10,
        PSYS_SRC_BURST_PART_COUNT, 8,
        PSYS_SRC_ACCEL, <0.0, 0.0, -1.4>,
        PSYS_SRC_OMEGA, <0.0, 0.0, 0.8>,
        PSYS_SRC_BURST_SPEED_MIN, 0.7,
        PSYS_SRC_BURST_SPEED_MAX, 1.35,
        PSYS_PART_FLAGS,
            PSYS_PART_EMISSIVE_MASK |
            PSYS_PART_FOLLOW_VELOCITY_MASK |
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK
    ]);
}
prepIdolTp() {
    restore_menu_timer = screen_open;
    button_b_waiting = FALSE;
    button_b_user = NULL_KEY;
    llSetTimerEvent(0);
    if(FX_TP_SOUND_VOL > 0.0)
        llLinkPlaySound(FX_TP_SOURCE, FX_TP_SOUND, FX_TP_SOUND_VOL, SOUND_PLAY);
}
handle_button(integer pi, key toucher) {
    if(pi == B_A) {
        if(power_on)
            send_command(toucher, "power off");
        else
            send_command(toucher, "power on");
    } else if(pi == B_B) {
        if(button_b_waiting) {
            button_b_waiting = FALSE;
            button_b_user = NULL_KEY;
            send_command(toucher, "input say =ddt reset");
            if(screen_open)
                llSetTimerEvent(15);
            else
                llSetTimerEvent(0);
        } else {
            button_b_waiting = TRUE;
            button_b_user = toucher;
            llSetTimerEvent(BUTTON_B_WINDOW);
        }
    } else if(pi == B_C) {
        send_command(toucher, "power motors toggle");
    } else if(pi == B_D) {
        muted = !muted;
        if(muted)
            send_command(toucher, "db hardware.controller.volume.master 0");
        else
            send_command(toucher, "db hardware.controller.volume.master 1");
        send_command(toucher, "device probe");
    }
}
apply_volume_master(string value) {
    muted = ((float)value == 0.0);
}
rebind_bus() {
    if(~LL)
        llListenRemove(LL);
    CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
    LL = llListen(CL, "", "", "");
}
query_volume_master() {
    if(system)
        tell(system, CL, "conf-get hardware.controller.volume.master");
}


default {
    state_entry() {
        if(booted) {
            clearIdolFx();
            rebind_bus();
            if(restore_menu_timer && screen_open)
                llSetTimerEvent(15);
            else
                llSetTimerEvent(0);
            restore_menu_timer = FALSE;
            return;
        }
        booted = TRUE;
        rebind_bus();
        text_plane = <-0.04907, 0.00000, 0.00000, 0.99880>;
        text_rot = <-0.52392, 0.52395, 0.47486, 0.47486>;
        llSetLinkTextureAnim(SCREEN_CONE, ANIM_ON | SMOOTH | LOOP | PING_PONG, ALL_SIDES, 0, 0, 0, 1, 100);
        llSetMemoryLimit(0x10000);
        cache_pbr_emissive_faces();
        clearIdolFx();
        #ifdef TEST_SCREEN
            power_on = 1;
            recolor_pbr_emissive();
            screen_control(TRUE);
            linked(LINK_THIS, 0, "menu-start", "");
            llSetTimerEvent(15);
        #else
            recolor_pbr_emissive();
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
        #endif
        echo((string)llGetUsedMemory() + " bytes used; " + (string)llGetFreeMemory() + " free.");
    }
    on_rez(integer n) {
        system = NULL_KEY;
        rebind_bus();
    }
    touch_start(integer n) {
        while(n--) {
            key toucher = llDetectedKey(n);
            integer pi = llDetectedLinkNumber(n);
            if(pi == B_A || pi == B_B || pi == B_C || pi == B_D) {
                handle_button(pi, toucher);
            } else {
                string part = llGetLinkName(pi);
                if(part == "text" && power_on) {
                    linked(LINK_THIS, pi, "touch-screen", toucher);
                    if(screen_open)
                        llSetTimerEvent(15);
                } else if(part != "screen" && part != "cone" && part != "screen 1" && part != "screen 2") {
                    if((power_on && screen_open) || !power_on)
                        linked(LINK_THIS, 0, "menu-request", toucher);
                    else
                        linked(LINK_THIS, 0, "menu-start", toucher);
                }
            }
        }
    }
    timer() {
        if(button_b_waiting) {
            button_b_waiting = FALSE;
            send_command(button_b_user, "exec service baseband restart");
            button_b_user = NULL_KEY;
            if(screen_open)
                llSetTimerEvent(15);
            else
                llSetTimerEvent(0);
            return;
        }
        if(screen_open) {
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
        }
        llSetTimerEvent(0);
    }
    listen(integer c, string n, key id, string m) {
        if(c != CL)
            return;
        if(llGetOwnerKey(id) != llGetOwner())
            return;
        list argv = split(m, " ");
        if(gets(argv, 0) != "conf")
            return;
        if(gets(argv, 1) != "hardware.controller.volume.master")
            return;
        apply_volume_master(concat(delrange(argv, 0, 1), " "));
    }
    link_message(integer s, integer n, string m, key id) {
        if(m == "on") {
            power_on = 1;
            recolor_pbr_emissive();
            system = id;
            rebind_bus();
            query_volume_master();
        } else if(m == "off") {
            power_on = 0;
            recolor_pbr_emissive();
            system = id;
            CL = 105 - (integer)("0x" + substr(llGetOwner(), 29, 35));
            button_b_waiting = FALSE;
            button_b_user = NULL_KEY;
            clearIdolFx();
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
            llSetTimerEvent(0);
        } else if(m == "menu-open") {
            if(!screen_open)
                screen_control(TRUE);
            llSetTimerEvent(15);
        } else if(m == "menu-close") {
            button_b_waiting = FALSE;
            button_b_user = NULL_KEY;
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
            llSetTimerEvent(0);
        } else if(m == "add-confirm") {
            system = id;
            rebind_bus();
            query_volume_master();
        } else if(m == "tp") {
            prepIdolTp();
            state idol_bloom;
        } else {
            list argv = split(m, " ");
            string cmd = gets(argv, 0);
            if(cmd == "color") {
                c1 = (vector)concat(delitem(argv, 0), " ");
                recolor_pbr_emissive();
            } else if(cmd == "color-2") {
                c2 = (vector)concat(delitem(argv, 0), " ");
                if(screen_open)
                    recolor_screen();
            } else if(cmd == "color-3") {
                c3 = (vector)concat(delitem(argv, 0), " ");
            } else if(cmd == "color-4") {
                c4 = (vector)concat(delitem(argv, 0), " ");
                if(screen_open)
                    recolor_screen();
            }
        }
    }
}



state idol_bloom {
    state_entry() {
        playIdolBloom();
        llSetTimerEvent(FX_BLOOM_HOLD);
    }
    timer() {
        state idol_shower;
    }
    link_message(integer s, integer n, string m, key id) {
        if(m == "off") {
            power_on = 0;
            recolor_pbr_emissive();
            system = id;
            clearIdolFx();
            llSetTimerEvent(0);
            restore_menu_timer = FALSE;
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
            state default;
        } else if(m == "tp") {
            prepIdolTp();
            state idol_bloom;
        } else {
            list argv = split(m, " ");
            string cmd = gets(argv, 0);
            if(cmd == "color")
                c1 = (vector)concat(delitem(argv, 0), " ");
            else if(cmd == "color-2")
                c2 = (vector)concat(delitem(argv, 0), " ");
        }
    }
}
state idol_shower {
    state_entry() {
        playIdolShower();
        llSetTimerEvent(FX_SHOWER_DURATION);
    }
    timer() {
        clearIdolFx();
        llSetTimerEvent(0);
        state default;
    }
    link_message(integer s, integer n, string m, key id) {
        if(m == "off") {
            power_on = 0;
            recolor_pbr_emissive();
            system = id;
            clearIdolFx();
            llSetTimerEvent(0);
            restore_menu_timer = FALSE;
            screen_control(FALSE);
            linked(LINK_THIS, 0, "menu-end", "");
            state default;
        } else if(m == "tp") {
            prepIdolTp();
            state idol_bloom;
        } else {
            list argv = split(m, " ");
            string cmd = gets(argv, 0);
            if(cmd == "color")
                c1 = (vector)concat(delitem(argv, 0), " ");
            else if(cmd == "color-2")
                c2 = (vector)concat(delitem(argv, 0), " ");
        }
    }
}
