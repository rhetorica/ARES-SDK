
#ifndef _VARIATYPE_H_
#define _VARIATYPE_H_

/* =========================================================================
 *
 *             Nanite Systems Applied Research Execution System
 *  
 *            Copyright (c) 2022–2023 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  VariaType text engine
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

// define this to prevent positioning (for pre-positioned labels):
// #define VT_NO_POSITIONING

// otherwise use this:
#ifndef VT_NO_POSITIONING
#ifndef PIXEL_SCALE
#define PIXEL_SCALE
float pixel_scale;
#endif
#endif

#define PSYCHIC_INSTABILITY 1
#define IGNEOUS_EXTRUSIVE 2
#define MURKY_TRUTH 3
#define CLOCK_SKEW 4

#if VT_FONT == PSYCHIC_INSTABILITY
// Psychic Instability
list FONT = [TEXTURE_TRANSPARENT, "fa2be25b-b84e-ae3a-39b7-be9159562538", "9586e45b-81d7-30af-7fef-944456ad2a4c", "95c1288d-b624-3ba0-98e1-766c4976cb4c",
	TEXTURE_TRANSPARENT, "f2616b27-bba8-33af-0d38-b83706dc32ce", "3e1225be-2c07-160d-e047-0b27aed9a80c", "5bcccd5f-3b07-1a78-0086-f1c78d5d9e6a"];
	
#define FONT_charwidths "21111111111111111111111111111111111222211122121122222222221122222222222221222332222222232221112212222212211213222212122322211121"

#elif VT_FONT == IGNEOUS_EXTRUSIVE
// Igneous Extrusive
list FONT = [TEXTURE_TRANSPARENT, "62974d79-964a-5f6f-da7a-fa71d0729fbf", "3e775d1a-47b7-987d-950e-76d86dba4d65", "ff7b660d-4404-041f-34ec-29c99fe2299d",
			  TEXTURE_TRANSPARENT, "8ad2c9e1-f8d6-744b-daef-5dbe06e07477", "29d05527-9dff-2595-6d43-179558027cfa", "a251039a-3fdf-70c1-9664-14ef2a0e4558"];

#define FONT_charwidths "21111111111111111111111111111111111222211122121122222222221122222222222221222332222222232221112212222212211213222212122322211121"

#elif VT_FONT == MURKY_TRUTH
// Murky Truth
list FONT = [TEXTURE_TRANSPARENT, "b17c85ad-dbb4-5e08-0bcd-f9bcc911958d", "63d0b7da-3ed9-4eb2-6878-317d4b810f16", "266f9977-0a97-f4b2-0dd8-58b54b6a6858",
			 TEXTURE_TRANSPARENT, "2edab492-6ddc-5c9f-3bbc-e2ee1cb4d5f0", "d1fad11b-97fd-de31-2dbe-aad04a3b51ab", "fc1fd1b3-f691-3e16-a0d5-5415375e4d6e"];

// Murky Truth uses a different character width table from PI and IX. The capital N is only 2 cells wide instead of 3.
#define FONT_charwidths "21111111111111111111111111111111111222211122121122222222221122222222222221222322222222232221112212222212211213222212122322211121"

#elif VT_FONT == CLOCK_SKEW || !defined(VT_FONT)
// Clock Skew
list FONT = ["8dcd4a48-2d37-4909-9f78-f7a9eb4ef903", "66f0c644-a340-9772-f870-9b30051db9d9", "57b9b8a5-ccb1-72e0-2429-916d25ace382", "d8903765-b390-4707-0397-18d558fcdfa5",
			 "8dcd4a48-2d37-4909-9f78-f7a9eb4ef903", "ad63bb36-f8e1-074a-24a2-40fcd1ea8baa", "bd83ac93-51c8-6515-c98f-33ca21c6516a", "251c5c6f-14c2-cd25-6e91-e9c08e06a677"];

// Clock Skew's characters use 2 cells for r, f, t, /, \, {, and }, and 3 cells for @
string FONT_charwidths = "21111111111111111111111111111111111222211122121222222222221122223222222221222322222222232221212212222222211213222222222322221221";
#endif

// with VT_NO_POSITIONING: variatype(text, start_prim, prim_limit)
// otherwise: variatype(text, start_prim, prim_limit, origin) and remember to set pixel_scale

// if using positioning, Riders 8 Face vert/horiz prims are expected;
// other shapes will require adaptation

// send all setp commands twice? (helps against packet loss)
integer DOUBLE_PRINT;

variatype(string text, integer start_prim, integer prim_limit
#ifndef VT_NO_POSITIONING
, vector origin
#endif
#ifdef VT_COLOR
, vector color
#endif
) {
	text += " ";
	integer c = 0; // character
	integer f = 0; // face
	integer p = 0; // pixel
	integer prim;
	integer face;
	integer cmax = strlen(text) + 1;
	integer fmax = prim_limit << 3;
	list acts;
	while(c < cmax && f < fmax) {
		integer c0 = llOrd(text, c);
		if(c0 == 0x09) {
			f = (f + 8);
			f -= f % 8;
			
			c += 1;
			p = 0;
			c0 = llOrd(text, c);
		}
		integer c1 = llOrd(text, c + 1);
		integer p0 = (integer)substr(FONT_charwidths, c0, c0) << 2;
		integer p1 = (integer)substr(FONT_charwidths, c1, c1) << 2;
		integer si = (c0 >> 5) + 4 * (c1 >> 6);
		string section = gets(FONT, si);
		// echo("c=" + (string)c + " printed (" + llChar(c0) + llChar(c1) + "), width " + (string)(p0 + p1) + " column offset " + (string)p);
		
		prim = start_prim + (f >> 3);
		face = f & 7;
		
		if(!face) {
			if(llGetFreeMemory() < 4092) {
				setp(0, acts);
				if(DOUBLE_PRINT) {
					llSleep(0.01);
					setp(0, acts);
				}
				acts = [];
			}
		
			acts += [
				PRIM_LINK_TARGET, prim,
				#ifndef VT_NO_POSITIONING
				PRIM_SIZE, <64, 16, 0> * pixel_scale,
				PRIM_POSITION, (origin - <0, 64 * (f >> 3), 0>) * pixel_scale,
				#ifdef VISIBLE
				PRIM_ROTATION, VISIBLE,
				#endif
				#endif
				#ifdef VT_COLOR
				PRIM_COLOR, ALL_SIDES, color, 1,
				#endif
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0
			];
		}
		
		acts += [
			PRIM_TEXTURE, face, section,
				<0.0078125, 0.015625, 0>,
				<(float)(c0 & 31) / 32.0 - 0.5 + ((4.0 + p) / 1024.0),
				 0.5 - (float)(c1 & 63) / 64.0 - 0.0078125, 0>, 0
		];
		++f;
		
		integer w = p0 + p1;
		if(p == 0) {
			if(w == 8) {
				c += 2;
			} else if(p0 == 4) {
				c += 1;
				p = 4;
			} else if(p0 == 8) {
				c += 1;
			} else if(p0 == 12) {
				p = 8;
			}
		} else if(p == 4) { // p0 == 8 or p0 == 12
			if(p0 == 8) {
				if(p1 == 4) {
					c += 2;
					p = 0;
				} else
					c += 1;
			} else if(p0 == 12) {
				c += 1;
				p = 0;
			}
		} else if(p == 8) { // p0 == 12
			if(p1 == 4) {
				c += 2;
				p = 0;
			} else {
				c += 1;
				p = 4;
			}
		}
		
		if(c1 == 0x09) {
			p = 0;
			f = (f + 8);
			f -= f % 8;
		}
	}
	
	if(face < 7) {
		while(face < 8) {
			acts += [
				PRIM_TEXTURE, face++, TEXTURE_TRANSPARENT, ZV, ZV, 0
			];
		}
	}
	
	integer last_prim = start_prim + prim_limit - 1;
	if(prim < last_prim) {
		while(prim < last_prim) {
			++prim;
			acts += [
				PRIM_LINK_TARGET, prim,
				#ifndef VT_NO_POSITIONING
				PRIM_POSITION, (origin - <0, 64 * (prim - start_prim), 0>) * pixel_scale,
				#endif
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, ZV, ZV, 0
			];
		}
	}
	setp(0, acts);
	if(DOUBLE_PRINT) {
		llSleep(0.01);
		setp(0, acts);
	}
}

#endif // _VARIATYPE_H_
