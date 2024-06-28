/* =========================================================================
 *
 *           Nanite Systems Advanced Research Encapsulation System
 *  
 *            Copyright (c) 2022–2024 Nanite Systems Corporation
 *  
 * =========================================================================
 *
 *  saver Utility - Event Handlers
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


	timer() {
		list acts;
		
		if(current_saver == "stars") {
			float cycle = 0;
			float now = llGetTime() * 0.2;
			float t = now - llFloor(now);
			integer n = STARS_LAYERS;
			while(n--) {
				float i = (float)n / STARS_LAYERS;
				float scale = t + i;
				if(scale > 1.0) {
					scale -= 1.0;
				}
				
				float o = (1 - scale * scale * scale) * (scale * scale - 0.05) * 4.25;
				if(o > 1)
					o = 1;
				else if(o < 0)
					o = 0;
				
				acts += [
					PRIM_LINK_TARGET, SS_FG + n,
					//PRIM_SIZE, ONES * (2 + scale * 4.0),
					PRIM_SIZE, ONES * (1.0 / (1.01 - scale)),
					PRIM_POSITION, <-5, 0, 0>,
					PRIM_COLOR, 0, ONES, o,
					PRIM_ROTATION,
						// llEuler2Rot(<0, 0, scale * TWO_PI>) *
						VISIBLE,
					PRIM_TEXTURE, 0, STARS_TEX, ONES, ZV, n * n
				];
			}
		} else if(current_saver == "bounce") {
			integer usable_width = screen_width - 256;
			integer usable_height = screen_height - 128;
			// float now = llGetAndResetTime();
			bounce_pos += bounce_dir * BOUNCE_SPEED;
			
			if(bounce_pos.y <= usable_width * -0.5
			|| bounce_pos.y >= usable_width * 0.5) {
				bounce_dir.y = -bounce_dir.y;
			}
			
			if(bounce_pos.z <= usable_height * -0.5
			|| bounce_pos.z >= usable_height * 0.5) {
				bounce_dir.z = -bounce_dir.z;
			}
			
			acts += [
				PRIM_LINK_TARGET, SS_FG,
				PRIM_SIZE, <256, 128, 0> * pixel_scale,
				PRIM_POSITION, <-5, 0, 0> + bounce_pos * pixel_scale,
				PRIM_TEXTURE, 0, model_badge, ONES, ZV, 0,
				PRIM_ROTATION, VISIBLE,
				PRIM_COLOR, 0, <1, 0, 0> * llEuler2Rot(<0, 0, llGetTime()> * PI) * 0.5 + ONES * 0.5, 1
			];
		} else if(current_saver == "toasters") {
			integer n = TOASTERS;
			while(n--) {
				vector tp = getv(toaster_pos, n);
				tp += <0, 2, -1> * (n + MIN_TOAST_SPEED);
				
				integer visible = 1;
				if(tp.y >= screen_width * 0.5 + 64
				|| tp.z <= screen_height * -0.5 - 64) {
					tp.y = screen_width * 0.25 - llFloor(llFrand(screen_width * 2));
					tp.z = screen_height * 0.5 + 128;
					visible = 0;
					integer is_toast = llFrand(1.5) > 1;
					if(!is_toast)
						llSetLinkTextureAnim(SS_FG + n, ANIM_ON | LOOP | PING_PONG, ALL_SIDES, 4, 4, 0, 4, 16);
					else
						llSetLinkTextureAnim(SS_FG + n, ANIM_ON | LOOP | PING_PONG, ALL_SIDES, 4, 4, 4, 1, 16);
				} else if(tp.y < (screen_width * -0.5 - 64)
					   || tp.z > (screen_height * 0.5 + 64)) {
					visible = 0;
				}
				
				acts += [
					PRIM_LINK_TARGET, SS_FG + n,
					PRIM_SIZE, <64, 64, 0> * pixel_scale,
					PRIM_TEXTURE, 0, TOASTER_TEX, <0.25, 0.25, 0>, <-.375, .375, 0>, 0,
					PRIM_POSITION, tp * pixel_scale - <5, 0, 0>,
					PRIM_ROTATION, VISIBLE,
					PRIM_COLOR, 0, ONES, visible
				];
				
				toaster_pos = alter(toaster_pos, [tp], n, n);
			}
		} else {
			echo(current_saver);
		}
		
		setp(0, acts);
	}
	