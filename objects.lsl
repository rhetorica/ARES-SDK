
#ifndef _OBJECTS_LSL_
#define _OBJECTS_LSL_

/*

   ***********************************************************
   *                                                         *
   *    NANITE SYSTEMS ADVANCED TACTICAL OPERATING SYSTEM    *
   *                                                         *
   *                    OBJECTS COMPONENT                    *
   *                                                         *
   *        Copyright, (C) Nanite Systems Corp., 2021        *
   *                                                         *
   ***********************************************************
   
   THE SOURCE CODE FOR THIS LIBRARY COMPONENT IS PROVIDED TO
   NANITE SYSTEMS CUSTOMERS FOR DEVELOPMENT OF COMPATIBLE
   SOFTWARE.
   
   BY USING THIS CODE, YOU AGREE NOT TO MODIFY OR DISTRIBUTE
   IT FOR COMMERCIAL GAIN, EXCEPT IN A COMPILED PRODUCT. YOU
   MAY PROVIDE THE SOURCE CODE OF THIS FILE FOR FREE OR
   INCLUDED WITH YOUR OWN DEVELOPMENT PACKAGE AS LONG AS THIS
   NOTICE IS INCLUDED AND THE REST OF THE FILE IS UNMODIFIED.
   
   INTERACTIONS WITH OTHER COMPONENTS OF THE OPERATING SYSTEM
   ARE SUBJECT TO THE APPROPRIATE END-USER LICENSE AGREEMENT
   (EULA).
   
   IDV:				F0960303D0002
   VENDOR DUNS:     005128988
   
*/

#ifndef ZR
	#define ZR ZERO_ROTATION
#endif

#ifndef ZV
	#define ZV ZERO_VECTOR
#endif

#ifndef ONES
	#define ONES <1, 1, 1>
#endif

#ifndef setp
	#define setp llSetLinkPrimitiveParamsFast
#endif

#ifndef getp
	#define getp llGetLinkPrimitiveParams
#endif

#ifndef geto
	#define geto llGetObjectDetails
#endif

#ifndef object_pos
	#define object_pos(__object) llList2Vector(llGetObjectDetails(__object, [OBJECT_POS]), 0)
#endif

#define OVER_1024 0.0009765625
#define OVER_512 0.001953125
#define OVER_256 0.00390625

#endif // _OBJECTS_LSL_
