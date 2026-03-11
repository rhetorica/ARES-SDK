
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2025–2026 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  API.H.LSL Header Component
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

#ifndef _ARES_WARRIOR_H_
#define _ARES_WARRIOR_H_

#define WARRIOR_VERSION "12.1.0"
#define WARRIOR_VERSION_TAGS "preview 1"

#define HIT_MARKER "b28c37f4-452b-5beb-6aef-fb7f0edbf508"

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define call_warrior(_outs, _user, _args) daemon_to_daemon(E_WARRIOR, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " warrior " + _args)
	#define call_chassis(_outs, _user, _args) daemon_to_daemon(E_CHASSIS, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " chassis " + _args)
#else
	#define call_warrior(_outs, _user, _args) e_call(C_WARRIOR, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " warrior " + _args)
	#define call_chassis(_outs, _user, _args) e_call(C_CHASSIS, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " chassis " + _args)
#endif

// ignore this damage type (-3):
#define DAMAGE_IGNORE 0xfffffffd

#define DAMAGE_PROJECTILE DAMAGE_TYPE_GENERIC
#define DAMAGE_CRASH DAMAGE_TYPE_IMPACT
#define DAMAGE_HEAT DAMAGE_TYPE_FIRE
#define DAMAGE_COLD DAMAGE_TYPE_COLD
// resurrection:
#define DAMAGE_TRUE_REPAIR DAMAGE_TYPE_REPAIR
// used for resynchronizing different integrity representations:
#define DAMAGE_SPECIAL 0xffffffe

#define VICE_SCALE [40, 20, 40, 60, 100, 100, 200, 600, 1000, 2500, 2800, 4000, 2000, 1600]

#define CRASH_RESISTANCE 4

#endif // _ARES_WARRIOR_H_
