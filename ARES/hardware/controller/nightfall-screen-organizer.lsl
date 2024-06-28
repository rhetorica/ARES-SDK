#include <utils.lsl>
#include <objects.lsl>
#define TEXT_START 32
#define TEXT_COUNT 66

#define X_STEP (1.0/15.0)
#define Y_STEP (1.0/345.0)

#define X_BIAS -2.5
#define Y_BIAS -4.0

#define projection_magnitude 0.155

#define HORIZ_COMPONENT 0.00955
#define BARREL_COMPONENT 0.010
#define BARREL_COMPONENT_2 0.02
vector screen_origin = <0.0555, 0, -0.0618>;

default {
	state_entry() {
		integer i = 0;
		
		rotation post_R = llEuler2Rot(<0, PI_BY_TWO - (10 * DEG_TO_RAD), PI_BY_TWO + PI>);
		
		vector scale = <0, 5 * X_STEP, 3 * X_STEP> * projection_magnitude;
		
		while(i < TEXT_COUNT) {
			integer tx = i % 6;
			integer ty = i / 6;
            float x = (float)tx + X_BIAS;
            float dy = 10 - ty;
			
            if(ty == 1) {
                dy = 9.25;
            } else if(ty == 10) {
                dy = -0.25;
            } else if(ty == 0) {
                dy = 10.5;
            }
			
			float secondary_scale = 1.0;
			
            rotation R = llEuler2Rot(<0, BARREL_COMPONENT * -x * PI_BY_TWO, 0>);
			rotation R2 = llEuler2Rot(<0, BARREL_COMPONENT_2 * -x * PI_BY_TWO, 0>);
			setp(TEXT_START + i, [
                PRIM_SIZE, scale * secondary_scale,
                PRIM_POS_LOCAL, (<x * HORIZ_COMPONENT, (dy + Y_BIAS) * -Y_STEP, 0.025 * secondary_scale * secondary_scale> * secondary_scale - <0, 0, projection_magnitude * 0.55>) * R * post_R + screen_origin,
				// PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 128,
				PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_BLEND, 128,
                PRIM_ROT_LOCAL, llEuler2Rot(<PI_BY_TWO, 0, PI_BY_TWO>) * R2 * post_R
			]);
			++i;
		}
	}
}