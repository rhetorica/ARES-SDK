
/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *               Copyright (c) 2023 Nanite Systems Corporation              
 *  
 * =========================================================================
 *
 *  AUTH.H.LSL Header Component
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

#ifndef _ARES_AUTH_H_
#define _ARES_AUTH_H_

#include <utils.lsl>

#define ALLOWED TRUE
#define DENIED FALSE
#define PENDING NOWHERE

#define SEC_NEVER 0
#define SEC_ALWAYS 1
#define SEC_CONSENT 2
#define SEC_USER 3
#define SEC_MANAGER 4
#define SEC_OWNER 5
#define SEC_SELF 6

/*
	sec_check() return values:
		ALLOWED (1) on access granted,
		DENIED (0) on access denied, or
		PENDING (-1) if a consent prompt was generated
		
	if sec_check() returns PENDING, the program should abruptly halt
	
	one of deny_cmd or retry_cmd is executed after the unit denies or grants consent, preserving the original user and outs
	
	if you implement a structure like...
	
		if (check == ALLOWED) { // do the task here ... } else if (check == DENIED) { // print error message here ... }
	
	...in your program, then you can pass the original command as both deny_cmd and retry_cmd, e.g. sec_check(user, "manage", outs, m, m)
	
	almost all of the permissions are customizable; the default ones are:
		menu: access the menus
		local: send commands in local chat
		remote: send commands using a remote access device
		yank: force the unit to teleport
		arouse: trigger TESI events
		chat: send chat as the unit
		manage: adjust unit settings
		identity: adjust unit's name etc.
		add-user: add a registered user at rank 3
		add-manager: promote a registered user to rank 4
		add-owner: promote a registered user to rank 5
		demote-self: lower own user rank
		demote-manager: lower rank of a manager (rank 4)
		demote-owner: lower rank of an owner (rank 5)
		run-away: clear all users
		safeword: restore the unit's autonomy
		database: alter database entries directly
			(the db program requires rank 5 to affect the 'security' section or run a load)
	
		owner: this is a special permission that just checks the owner rank (used for configuring security settings)
	
	the standard interpretations of the security levels are:
		0: no one may do this
		1: everyone may do this except for the banned
		2: consent must be given to do this
		3: authorized users of rank 3 or higher (all) may do this
		4: authorized users of rank 4 or higher (managers) may do this
		5: authorized users of rank 5 or higher (owners) may do this
		6: only the unit may do this
*/ 	

// #define SEC_DEBUG

integer sec_check(key user, string permission, key outs, string deny_cmd, string retry_cmd) {
	string sec_section = llLinksetDataRead("security");
	integer req = (integer)getjs(sec_section, ["rule", permission]);
	#ifdef SEC_DEBUG
		echo("[sec_check]\nrequired access: " + (string)req
		+ "\nuser rank: " + getjs(sec_section, ["user", user])
		+ "\nuser guest? " + getjs(sec_section, ["guest", user])
		+ "\nuser ban? " + getjs(sec_section, ["ban", user])
		);
	#endif
	if(req == SEC_SELF && user == avatar)
		return ALLOWED;
	
	string ban = getjs(sec_section, ["ban", user]);
	string guest = getjs(sec_section, ["guest", user]);
	integer rank = (integer)getjs(sec_section, ["user", user]);
	if(permission == "owner")
		return (rank == SEC_OWNER);
	
	if(ban != JSON_INVALID && ((integer)ban == 1 || (integer)ban > llGetUnixTime()))
		return DENIED;
	else if(rank >= req && req > SEC_NEVER)
		return ALLOWED;
	else if(req == SEC_CONSENT) {
		if(guest != JSON_INVALID && ((integer)guest == 1 || (integer)guest > llGetUnixTime()))
			return ALLOWED;
		else {
			notify_program("_security consent "
				+ jsarray([retry_cmd, deny_cmd]),
				outs,
				NULL_KEY,
				user
			);
			return PENDING;
		}
	} else if(req == SEC_ALWAYS)
		return ALLOWED;
	else
		return DENIED;
}

#endif // _ARES_AUTH_H_
