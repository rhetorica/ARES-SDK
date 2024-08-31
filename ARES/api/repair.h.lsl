
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  REPAIR.H.LSL Header Component
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

#ifndef _ARES_REPAIR_H_
#define _ARES_REPAIR_H_

// **** repair daemon ****

/* Standard community damage types proposed by Nexii Malthus: https://wiki.secondlife.com/wiki/Category:LSL_Combat2
*/

// Healing (organics only):
#define DAMAGE_TYPE_MEDICAL 100
// Healing (machines only):
#define DAMAGE_TYPE_REPAIR 101
#define DAMAGE_TYPE_EXPLOSIVE 102
#define DAMAGE_TYPE_CRUSHING 103
#define DAMAGE_TYPE_ANTI_ARMOR 104
// Organics only:
#define DAMAGE_TYPE_SUFFOCATION 105

/* deal_damage(): deal ATOS damge to the unit
		_type: one of: "projectile", "crash", "heat", "cold", "special"
		_amount: number of HP to remove; multiply by 4 for projectile and crash damage; may be affected by shields
		_source: the UUID of the object causing the damage
	
	negative numbers apply repair
	
	use "special" damage if you want to bypass defenses
	
	if DQD or OOC mode is enabled, the unit's integrity number will not change, but other consequences like masochistic arousal and shield damage may still occur
*/
#define deal_damage(_amount, _type, _source) e_call(C_REPAIR, E_SIGNAL_CALL, (string)_source + " " + (string)_source + " repair inflict " + (_type) + " " + (string)(_amount));

#endif // _ARES_REPAIR_H_
