/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2025 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  TESI Storage Tank
 *
 *  This program is covered under the terms of the ARES Software Copyright
 *  License, Section 3 (ASCL-iii). It may be redistributed or used as the
 *  basis of commercial, closed-source products so long as steps are taken
 *  to ensure proper attribution as defined in the text of the license.
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


#include <utils.lsl>
#include <objects.lsl>

// Uncomment this line only to use cylindroidal capacity:
#define capacity_formula(size) PI * (size.x * size.y) * 0.25 * size.z * 1000

// Uncomment this line only to use cuboid capacity:
// #define capacity_formula(size) (size.x * size.y * size.z) * 1000

// Uncomment this line only to use a fixed capacity (100 L, regardless of size):
// #define capacity_formula(size) 100

#define LC -9999969
integer UIL;
integer UIC;
key user;

vector color;
float capacity;
float volume;
list substances;
list ratios;

list available_destinations;
list destination_names;
key destination;

float to_withdraw;
float to_deposit;

string majority_liquid_summary = "(empty)";

#define format_liquid_percentage(xxratio) (substr((string)((xxratio) * 100.0), 0, 5) + "%")
#define format_volume_L(xxliters) (substr((string)((xxliters)), 0, 4))

float old_volume;

update() {
    if(volume > old_volume) {
        if(volume < 0.001) {
            llTriggerSound("3fa7274c-3baa-305a-7467-ab3683e84f6c", 1);
        } else {
            llTriggerSound("9af2f0f0-ff90-89c8-872f-f9e36eab2b42", 1);
        }
    } else if(old_volume > volume) {
        llTriggerSound("51937596-dfcd-8843-b289-26b56162e3e0", 1);
    }
    old_volume = volume;
    // renormalize substances here:
    integer si = count(substances);
    float sr_total;
    while(si--) {
        sr_total += getf(ratios, si);
    }
    si = count(substances);
    while(si--) {
        ratios = alter(ratios, [getf(ratios, si) / sr_total], si, si);
    }
    
    float apparent_volume = volume / capacity;
    if(apparent_volume < 0.01) {
        setp(1, [
            PRIM_COLOR, ALL_SIDES, color, 0
        ]);
    } else {
        setp(1, [
            PRIM_COLOR, ALL_SIDES, color, 0.45,
            PRIM_SLICE, <0, apparent_volume, 0> // will bottom out at 0.02
        ]);
    }
    
    if(volume == 0) {
        majority_liquid_summary = "(empty)";
        ratios = substances = [];
    } else {
        list m_liquid_summary = [];
        float benchmark_ratio = 0;
        integer s = count(substances);
        while(s--) {
            string sn = gets(substances, s);
            float sr = getf(ratios, s);
            if(sr > benchmark_ratio * 1.05) {
                benchmark_ratio = sr;
            }
        }
        
        float ratio_counted;
        
        s = count(substances);
        while(s--) {
            string sn = gets(substances, s);
            float sr = getf(ratios, s);
            if(sr > benchmark_ratio * 0.9) {
                m_liquid_summary += sn + " (" + format_liquid_percentage(sr) + ")";
                ratio_counted += sr;
            }
        }
        
        float cr = 1.0 - ratio_counted;
        if(cr > 0)
            m_liquid_summary += "contaminants: " + format_liquid_percentage(cr);
        
        majority_liquid_summary = concat(m_liquid_summary, ", ");
    }
}

integer menu_action;

prompt(key user) {
    llListenRemove(UIL);
    UIL = llListen(UIC = (integer)llFrand(12345) - 6900000, "", "", "");
    menu_action = 0;
    llDialog(user, "Fluid Storage\n\nStatus: " + (string)format_volume_L(volume) + "/" + format_volume_L(capacity) + " L\nContents: " + majority_liquid_summary, ["deposit", "withdraw", "dump", "rename"], UIC);
}

integer target_menu_page;
target_menu(integer page) {
    if(page >= count(available_destinations) * 9)
        page = 0;
    list items = sublist(destination_names, 0 + page * 9, 8 + page * 9);
    while(count(items) < 9)
        items += [" "];
    
    items = sublist(items, 6, 8) + sublist(items, 3, 5) + sublist(items, 0, 2);
    
    string msg;
    if(menu_action == 1)
        msg = "Deposit fluid from where?";
    else
        msg = "Withdraw fluid into where?";
    
    llDialog(user, msg, [" ", "next", "cancel"] + items, UIC);
    target_menu_page = page;
}

default {
    state_entry() {
        llListen(LC, "", "", "");
        vector internal_s = getv(getp(1, [PRIM_SIZE]), 0);
        capacity = capacity_formula(internal_s);
    }

    touch_start(integer n) {
        llWhisper(LC, "query status");
        destination_names = [];
        available_destinations = [];
        prompt(user = llDetectedKey(0));
    }
    
    changed(integer w) {
        if(w & CHANGED_SCALE) {
            vector internal_s = getv(getp(1, [PRIM_SIZE]), 0);
            float new_capacity = capacity_formula(internal_s);
            if(new_capacity != capacity) {
                echo("Capacity changed. New limit: " + format_volume_L(new_capacity) + " L.");
                if(new_capacity < volume) {
                    float difference = volume - new_capacity;
                    echo("Lost " + format_volume_L(difference) + " L of liquid.");
                    volume = new_capacity;
                }
                capacity = new_capacity;
            }
        }
    }
    
    listen(integer c, string n, key id, string m) {
        if(c == UIC) {
            if(menu_action == 0) {
                if(m == "deposit") {
                    menu_action = 1;
                    target_menu(0);
                } else if(m == "withdraw") {
                    menu_action = 2;
                    target_menu(0);
                } else if(m == "dump") {
                    volume = 0;
                    update();
                    prompt(id);
                } else if(m == "rename") {
                    menu_action = 3;
                    llTextBox(user, "Change name to what?\n(ASCII only)", UIC);
                }
            } else if(menu_action == 1) { // target deposit
                if(m == "next") {
                    target_menu(++target_menu_page);
                } else if(m == "cancel") {
                    prompt(id);
                } else if(m == " ") {
                    target_menu(target_menu_page);
                } else {
                    destination = getk(available_destinations, index(destination_names, m));
                    menu_action = 4;
                    llTextBox(user, "Deposit how much? (blank = all, 0 = cancel)", UIC);
                }
            } else if(menu_action == 2) { // target withdrawal
                if(m == "next") {
                    target_menu(++target_menu_page);
                } else if(m == "cancel") {
                    prompt(id);
                } else if(m == " ") {
                    target_menu(target_menu_page);
                } else {
                    destination = getk(available_destinations, index(destination_names, m));
                    menu_action = 5;
                    llTextBox(user, "Withdraw how much? (blank = all, 0 = cancel)", UIC);
                }
            } else if(menu_action == 3) { // rename
                llSetObjectName(m);
                prompt(id);
            } else if(menu_action == 4) { // enact deposit
                if(m == "") {
                    prompt(id);
                } else if(m == "0") {
                    to_deposit = 16777216; // largest possible prim
                }
                
                to_deposit = (float)m;
                
                if(to_deposit + volume > capacity) {
                    to_deposit = capacity - volume;
                    tell(id, 0, "Depositing only the " + format_volume_L(to_deposit) + " L that will fit.");
                }
                tell(destination, LC, "query fluids");
            } else if(menu_action == 5) { // enact withdrawal
                if(m == "") {
                    prompt(id);
                } else if(m == "0") {
                    to_withdraw = 16777216; // largest possible prim
                }
                
                to_withdraw = (float)m;
                
                if(to_withdraw > volume) {
                    to_withdraw = volume;
                    tell(id, 0, "Withdrawing only the " + format_volume_L(to_withdraw) + " L available.");
                }
                integer s = count(substances);
                while(s--) {
                    float fv = getf(ratios, s) * to_withdraw;
                    string fn = gets(substances, s);
                    tell(destination, LC, "deposit " + (string)fv + " " + fn + " " + (string)color.x + " " + (string)color.y + " " + (string)color.z);
                    tell(user, 0, "Giving " + format_volume_L(fv) + " L of " + fn);
                }
                volume -= to_withdraw;
                update();
            }
        } else if(c == LC) {            
            list ms = split(m, " ");
            string cmd = gets(ms, 0);
            if(cmd == "status") {
                    available_destinations += id;
                    if(strlen(n) > 24) {
                        n = substr(n, 0, 20) + "…";
                    }
                    
                    if(contains(destination_names, n))
                        n = n + " " + (string)((integer)llFrand(999));
                    
                    destination_names += n;
                // tell(user, 0, n + " has " + format_volume_L((float)gets(ms, 4)) + "/" + format_volume_L((float)gets(ms, 5)) + " L");
                
            } else if(cmd == "fluids") {
                // tell(user, 0, "Fluid report for " + n + ": " + m);
                vector new_color = <(float)gets(ms, 1), (float)gets(ms, 2), (float)gets(ms, 3)>;
                list fluids = sublist(ms, 4, LAST);
                integer fi = count(fluids);
                float available_liquid;
                while(fi) {
                    fi -= 2;
                    available_liquid += (float)gets(fluids, fi + 1);
                }
                
                if(available_liquid < to_deposit) {
                    to_deposit = available_liquid;
                    if(available_liquid > 0)
                        tell(user, 0, n + " only has " + format_volume_L(to_withdraw) + " L available; taking all of it.");
                }
                
                if(available_liquid == 0) {
                    tell(user, 0, n + " has no fluid to deposit.");
                    return;
                }
                
                tell(id, LC, "withdraw " + (string)to_deposit);
                
                float new_volume = volume + to_deposit;
                
                fi = count(fluids);
                while(fi) {
                    fi -= 2;
                    string fn = gets(fluids, fi);
                    float fv = (float)gets(fluids, fi + 1) / available_liquid * to_deposit;
                    tell(user, 0, "Taking " + format_volume_L(fv) + " L of " + fn);
                    float n_sr = fv;
                    if(volume > 0)
                        n_sr /= volume;
                    integer si = index(substances, fn);
                    if(~si) {
                        ratios = alter(ratios, [getf(ratios, si) + n_sr], si, si);
                    } else {
                        substances += fn;
                        ratios += n_sr;
                    }
                }
                
                volume = new_volume;
                
                update();
                
            } else if(m == "query status") {
                tell(id, LC, concat([
                    "status",
                    0, // arousal
                    0, // orgasm threshold
                    0, // plateau
                    (string)volume,
                    (string)capacity,
                    0, // sensitivity
                    (string)color.x,
                    (string)color.y,
                    (string)color.z
                ], " "));
            } else if(m == "query fluids") {
                list fluids;
                integer si = count(substances);
                if(si == 0) {
                    fluids = ["lubricant", 0];
                } else while(si--) {
                    fluids += [gets(substances, si), getf(ratios, si) * volume];
                }
                tell(id, LC, concat([
                    "fluids",
                    (string)color.x,
                    (string)color.y,
                    (string)color.z
                ] + fluids, " "));
            } else if(cmd == "withdraw") {
                volume = volume - (float)gets(ms, 1);
                if(volume < 0)
                    volume = 0;
                update();
            } else if(cmd == "deposit") {
                float to_accept = (float)gets(ms, 1);
                if(to_accept + volume > capacity)
                    to_accept = capacity - volume;
                
                string sn = gets(ms, 2);
                vector new_color = <(float)gets(ms, 3), (float)gets(ms, 4), (float)gets(ms, 5)>;
                float new_volume = to_accept + volume;
                
                if(to_accept > 0) {
                    integer si = index(substances, sn);
                    if(~si) {
                        ratios = alter(ratios, [getf(ratios, si) + (to_accept / volume)], si, si);
                    } else {
                        substances += sn;
                        if(volume > 0)
                            ratios += to_accept / volume;
                        else
                            ratios += to_accept;
                    }
                    color = (color * (volume / new_volume)) + (new_color * (to_accept / new_volume));
                    volume = new_volume;
                    update();
                }
            }
        }
    }
}
