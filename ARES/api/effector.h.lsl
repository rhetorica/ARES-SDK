
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  EFFECTOR.H.LSL Header Component
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

// **** effector daemon ****

#ifndef _ARES_EFFECTOR_H_
#define _ARES_EFFECTOR_H_

/*
 * ARES RLV
 *
 * The main role of the effector daemon is in managing RLV restrictions and preventing them from conflicting, similar to an RLV relay. However, there are some slight differences from regular RLV:
 *
 *  - The '@' is stripped off.
 *  - To format _rule_values for restrictions (those rules ending in =n/y/add/rem), put '?' instead. This will be replaced with 'y' and 'n' as appropriate by the effector daemon.
 *  - If a rule's name starts with 'a:' then its contents will be treated as an animation from ring 2 (the daemon ring)
 *  - The new rule 'move=?' causes the system to intercept movement keys while active.
 *  - The rule 'recvchat=?' will also trigger 'recvemote=?' and cause the _input program to attempt to filter quoted text inside emotes.
 *
 * As of Alpha 1, only a few RLV rules can be applied multiple times. These are 'move=?', 'sendchat=?', 'recvemote=?', and 'recvchat=?'. Attempting to remove any other rule will release the restriction entirely, breaking other sources of the same restriction. This will be improved when the RLV relay program 'restraint' is finished in Alpha 3.
 *
 */

// effector_restrict(rule-name, rule-value): applies an RLV restriction (e.g. 'recvchat=?') with the specified rule name (see details at start of effector.h.lsl)
#define effector_restrict(_rule_name, _rule_value) e_call(C_EFFECTOR, E_SIGNAL_CREATE_RULE, _rule_name + " " + _rule_value)
// effector_release(rule-name): releases an RLV restriction (see details at start of effector.h.lsl); if the rule name ends in "*" then all rules matching the prefix will be removed, e.g. "power_*" to remove all rules starting with "power_"
#define effector_release(_rule_name) e_call(C_EFFECTOR, E_SIGNAL_DELETE_RULE, _rule_name)
// this just sticks "@" on the front:
#define effector_rlv(_rule) e_call(C_EFFECTOR, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " effector rlv " + _rule)
// teleports to region and (vector) position; if _external is TRUE, doesn't consume power or play fx
#define effector_teleport(_region, _position, _external) e_call(C_EFFECTOR, E_SIGNAL_CALL, NULL_KEY + " " + NULL_KEY + " effector teleport " + (string)(_external) + "|" + (string)avatar + "|" + (_region) + "|" + (string)(_position))

// tell the controller hardware to make noises:

// play_sound(): play a sound specified by UUID
// announce(): play an announcer voice sample, as defined in the LSD section 'announcer'

#define play_sound(_name) e_call(C_EFFECTOR, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " effector sound " + _name)
#define daemon_play_sound(_name) daemon_to_daemon(E_EFFECTOR, SIGNAL_CALL, (string)avatar + " " + (string)avatar + " effector sound " + _name)
#define announce(_announcement) e_call(C_EFFECTOR, E_SIGNAL_CALL, (string)avatar + " " + (string)avatar + " effector announce " + _announcement)
#define daemon_announce(_announcement) daemon_to_daemon(E_EFFECTOR, SIGNAL_CALL, (string)avatar + " " + (string)avatar + " effector announce " + _announcement)

#endif // _ARES_EFFECTOR_H_
