
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  STATUS.H.LSL Header Component
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

#ifndef _ARES_STATUS_H_
#define _ARES_STATUS_H_

/* status daemon: power loads & updates

   1. create a power load with:
   
   setdbl("chassis", ["load", device + "__" + load_name], (string)wattage);
   
   where 'device' should be 'system' or the address of a connected device, and load_name is a single-word lower-case description of why power is being used
	
   2. trigger the status daemon to reload the status section with:
   
   (from a program) e_call(C_STATUS, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " status update");
   
   (from a daemon) daemon_to_daemon(E_DAEMON, SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " status update");

   3. when finished, delete the power load:
   
   deletedbl("chassis", ["load", device + "__" + load_name]);
   
   4. repeat step 2
   
*/

#if defined(RING_NUMBER) && RING_NUMBER <= R_DAEMON
	#define call_status(_outs, _user, _args) daemon_to_daemon(E_STATUS, SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " status " + _args)
#else
	#define call_status(_outs, _user, _args) e_call(C_STATUS, E_SIGNAL_CALL, (string)(_outs) + " " + (string)(_user) + " status " + _args)
#endif

// create/modify or remove a power load:
#define set_power_load(_device, _load_name, _wattage) setdbl("chassis", ["load", _device + "__" + _load_name], (string)_wattage)
#define delete_power_load(_device, _load_name) { if(getdbl("chassis", ["load", _device + "__" + _load_name]) != JSON_INVALID) deletedbl("chassis", ["load", _device + "__" + _load_name]); }
// (remember to trigger a status update afterward, as described in the comment above)

#define status_update() call_status(NULL_KEY, NULL_KEY, "update");

#endif // _ARES_STATUS_H_
