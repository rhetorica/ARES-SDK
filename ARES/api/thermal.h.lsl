
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *               Copyright (c) 2025 Nanite Systems Corporation              
 *  
 * =========================================================================
 *
 *  THERMAL.H.LSL Header Component
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

#ifndef _ARES_THERMAL_H_
#define _ARES_THERMAL_H_

#include <utils.lsl>

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define call_thermal(_outs, _user, _args) daemon_to_daemon(E_THERMAL, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " thermal " + _args)
#else
	#define call_thermal(_outs, _user, _args) e_call(C_THERMAL, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " thermal " + _args)
#endif

#define DEFAULT_TEMP 298.15
#define FREEZING 273.15
#define DEFAULT_PRESSURE 101.325

#define DANGEROUS_PRESSURE 400
#define POWER_HEAT_RATE 0.12
#define POWER_HEAT_EXP 0.6
#define FAN_POWER 45
#define LIQUID_EXCHANGE_POWER 10
#define PASSIVE_EXCHANGE_POWER 5
#define FAN_ACCELERATION 0.25
#define FAN_DECELERATION 0.05
#define FAN_ACTIVATION_THRESHOLD 312.15
#define FAN_TARGET_TEMP 310.15
#define FAN_DEACTIVATION_THRESHOLD 308.15
#define OVERHEAT_AT 373.15
#define QUITE_COLD 263.15
#define POWER_GAIN_HEAT_FACTOR 0.0025
#define MIN_FAN_SPEED 0.0
#define QUITE_HOT 348.15

// the void of teleportation is now fairly chilly:
#define COLD_TELEPORT 283.15

// unit adjusts to environmental temperature changes at this rate:
#define WARM_UP_STEP 1.0

integer temp_units = 1; // 0 = K, 1 = C, 2 = F
// #define format_temperature(KELVIN) gets([format_float((KELVIN - FREEZING), 2) + "° C", format_float((KELVIN - FREEZING) * 1.8 + 32, 2) + "° F", format_float(KELVIN, 2) + " K"], temp_units)

string format_temperature(float kelvin) {
	if(temp_units == 2) {
		return format_float(kelvin, 2) + " K";
	} else if(temp_units) {
		return format_float((kelvin - FREEZING) * 1.8 + 32, 2) + "° F";
	} else {
		return format_float((kelvin - FREEZING), 2) + "° C";
	}
}


#endif // _ARES_THERMAL_H_
