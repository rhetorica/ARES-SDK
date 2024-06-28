
#ifndef QKEYS
#define QKEYS

/*

   ***********************************************************
   *                                                         *
   *    NANITE SYSTEMS ADVANCED TACTICAL OPERATING SYSTEM    *
   *                                                         *
   *                     QKEYS COMPONENT                     *
   *                                                         *
   *  Copyright, (C) Nanite Systems Corp., 1984, 1985, 2018  *
   *                                                         *
   *     Copyright, (C) University of Michigan 1977-1981     *
   *                                                         *
   ***********************************************************
   
   NOTICE: UNAUTHORIZED DISTRIBUTION, COPYING, MODIFICATION,
   OR REVERSE ENGINEERING OF PROPRIETARY NANITE SYSTEMS
   MILITARY CONTROL CODE IS A FEDERAL OFFENSE. THIS CODE IS
   CONFIDENTIAL.
   
   PRODUCED UNDER CONTRACT TO THE GOVERNMENT OF THE TERRAN
   REPUBLIC OR ONE OF ITS DEPENDENT POLITIES.
   
   IDV:				F0960303D0002
   VENDOR DUNS:     005128988
   
*/

rotation k2q(key k) {
	string kt = (string)llParseStringKeepNulls(k, ["-"], []);
	/*integer e0 = (integer)("0x" & llGetSubString(kt, 0, 1)) - 126;
	integer m0 = (integer)("0x" & llGetSubString(kt, 2, 7));
	integer e1 = (integer)("0x" & llGetSubString(kt, 8, 9)) - 126;
	integer m1 = (integer)("0x" & llGetSubString(kt, 10, 15));
	integer e2 = (integer)("0x" & llGetSubString(kt, 16, 17)) - 126;
	integer m2 = (integer)("0x" & llGetSubString(kt, 18, 23));
	integer e3 = (integer)("0x" & llGetSubString(kt, 24, 25)) - 126;
	integer m3 = (integer)("0x" & llGetSubString(kt, 26, 31));
	
	return <(float)m0 * llPow(2, e0),
	        (float)m1 * llPow(2, e1),
			(float)m2 * llPow(2, e2),
			(float)m3 * llPow(2, e3)>; */
	
	return <
		iuf((integer)llGetSubString(kt,  0,  7)),
		iuf((integer)llGetSubString(kt,  8, 15)),
		iuf((integer)llGetSubString(kt, 16, 23)),
		iuf((integer)llGetSubString(kt, 24, 31))
	>;
}

key q2k(rotation q) {
	return llInsertString(llInsertString(
		i2h(fui(q.x)) + "-"
		+ i2h(fui(q.y)) + "-"
		+ i2h(fui(q.z))
		+ i2h(fui(q.s)),
	21, "-"), 12, "-");
}

// Strife Onizuka's Float-Union-Integer implementation
integer fui(float a)//Mono Safe, LSO Safe, Doubles Unsupported, LSLEditor Unsafe
{//union float to integer
    integer b = 0x80000000 & ~llSubStringIndex(llList2CSV([a]), "-");//the sign
    if((a)){//is it nonzero?
        if((a = llFabs(a)) < 2.3509887016445750159374730744445e-38)//Denormalized range check & last stride of normalized range
            return b | (integer)(a / 1.4012984643248170709237295832899e-45);//the math overlaps; saves cpu time.
        if(a > 3.4028234663852885981170418348452e+38)//Round up to infinity
            return b | 0x7F800000;//Positive or negative infinity
        if(a > 1.4012984643248170709237295832899e-45){//It should at this point, except if it's NaN
            integer c = ~-llFloor(llLog(a) * 1.4426950408889634073599246810019);//extremes will error towards extremes. following yuch corrects it
            return b | (0x7FFFFF & (integer)(a * (0x1000000 >> c))) | ((126 + (c = ((integer)a - (3 <= (a *= llPow(2, -c))))) + c) * 0x800000);
        }//the previous requires a lot of unwinding to understand it.
        return b | 0x7FC00000;//NaN time! We have no way to tell NaN's apart so lets just choose one.
    }//Mono does not support indeterminates so I'm not going to worry about them.
    return b;//for grins, detect the sign on zero. it's not pretty but it works.
}

float iuf(integer a) { //union integer to float
    if(0x7F800000 & ~a)
        return llPow(2, (a | !a) + 0xffffff6a) * (((!!(a = (0xff & (a >> 23)))) * 0x800000) | (a & 0x7fffff)) * (1 | (a >> 31));
    return (!(a & 0x7FFFFF)) * (float)"inf" * ((a >> 31) | 1);
}

// int2hexdword, also by Strife Onizuka
string i2h (integer I) {
	integer A = (I >> 2) & 0x3C000000;//not an unsigned rshift
	integer B = (I & 0x0F000000) >>  4;
	integer C = (I & 0x00F00000) >>  6;
	integer D = (I & 0x000F0000) >>  8;
	integer E = (I & 0x0000F000) << 14;
	integer F = (I & 0x00000F00) << 12;
	integer G = (I & 0x000000F0) << 10;
	integer H = (I & 0x0000000F) <<  8;

	return llGetSubString(
		   llInsertString(
			   llIntegerToBase64(
				   A + B + C + D + 0xD34D3400
				   - (0xF8000000 * (A / 0x28000000))//lowercase=0x90000000, uppercase=0xF8000000
				   - (0x03E00000 * (B / 0x00A00000))//lowercase=0x02400000, uppercase=0x03E00000
				   - (0x000F8000 * (C / 0x00028000))//lowercase=0x00090000, uppercase=0x000F8000
				   - (0x00003E00 * (D / 0x00000A00))//lowercase=0x00002400, uppercase=0x00003E00
			   ),
			   4,
			   llIntegerToBase64(
				   E + F + G + H + 0xD34D3400
				   - (0xF8000000 * (E / 0x28000000))//lowercase=0x90000000, uppercase=0xF8000000
				   - (0x03E00000 * (F / 0x00A00000))//lowercase=0x02400000, uppercase=0x03E00000
				   - (0x000F8000 * (G / 0x00028000))//lowercase=0x00090000, uppercase=0x000F8000
				   - (0x00003E00 * (H / 0x00000A00))//lowercase=0x00002400, uppercase=0x00003E00
			   )
		   ),
		   0,
		   7
	   );
}

// Copyright (C) 2009 Adam Wozniak and Doran Zemlja
// Released into the public domain.
// Free for anyone to use for any purpose they like.
//
// deep voodoo base 4096 key compression
//
// It produces fixed length encodings of 11 characters.
 
string compress_key(key k) {
	string s = llToLower((string)llParseString2List((string)k, ["-"], []) + "0");
	string ret;
	integer i;

	string A;
	string B;
	string C;
	// string D;

	while(i < 32) {
		A = llGetSubString(s, i, i);
		++i;
		B = llGetSubString(s, i, i);
		++i;
		C = llGetSubString(s, i, i);
		++i;

		/*if(A == "0") {
			A = "e";
			D = "8";
		} else if(A == "d") {
			A = "e";
			D = "9";
		} else if(A == "f") {
			A = "e";
			D = "a";
		} else
			D = "b";

		ret += "%e" + A + "%" + D + B + "%b" + C;*/
		
		if(A == "0")
			ret += "%ee%8";
		else if(A == "d")
			ret += "%ee%9";
		else if(A == "f")
			ret += "%ee%a";
		else
			ret += "%e" + A + "%b";
		
		ret += B + "%b" + C;
	}
	
	return llUnescapeURL(ret);
}
 
key uncompress_key(string s) {
   integer i;
   string ret;
   string A;
   string B;
   string C;
   string D;
 
   s = llToLower(llEscapeURL(s));
   for(i = 0; i < 99; i += 9) {
      A = llGetSubString(s,i+2,i+2);
      B = llGetSubString(s,i+5,i+5);
      C = llGetSubString(s,i+8,i+8);
      D = llGetSubString(s,i+4,i+4);
 
      if(D == "8") {
         A = "0";
      } else if(D == "9") {
         A = "d";
      } else if(D == "a") {
         A = "f";
      }
      ret += A + B + C;
   }
   
   return (key)(llGetSubString(ret, 0, 7) + "-" +
      llGetSubString(ret, 8,11) + "-" +
      llGetSubString(ret,12,15) + "-" +
      llGetSubString(ret,16,19) + "-" +
      llGetSubString(ret,20,31));
}

/*
 encode/decode 8 for compact keys
 minimum weight of 3774-4338 bytes with 1 invocation of each function
 rhet0rica, August 9, 2021
 encodes keys into exactly 8 chars weighing 24 bytes on average
 using the new llChar() and llOrd() built-ins
*/

string encode_8(key k) {
    string o;
    string in = llDumpList2String(llParseString2List(k, ["-"], []), "");
    integer ri = 8;
    while(ri--) {
        integer cn = (integer)("0x" + substr(in, ri << 2, (ri << 2) + 3));
        string c = llChar(cn);
        if(llOrd(c, 0) != cn || cn < 256)
            o += llChar(cn + 0x10000);
        else
            o += c;
    }
    return o;
}

key decode_8(string s) {
    string o;
    integer ri = 8;
    while(ri--) {
        integer c = llOrd(s, ri) & 0x0ffff;
        integer rii = 4;
        string word;
        while(rii--) {
            integer cn = (c >> (rii << 2)) & 0x0f;
            if(cn < 10)
                word += llChar(cn + 0x30);
            else
                word += llChar(cn + 0x57);
        }
        o += word;
    }
    return (key)(
        substr(o, 0, 7) + "-" +
        substr(o, 8, 11) + "-" +
        substr(o, 12, 15) + "-" +
        substr(o, 16, 19) + "-" +
        substr(o, 20, 31)
    );
}

/*
	encode/decode 22 for compact keys
	weight of 3778-4392 bytes with 1 invocation of each function
	rhet0rica, August 13, 2022
	encodes keys into 16 chars weighing up to 32 bytes
	special NULL and EMPTY values for NULL_KEY and ""
	less likely than encode_8 to break mono serialization (!) on uplifted regions
	uses llChar() and llOrd()
*/

string encode_22(key u) {
    if(u == "")
        return "EMPTY";
    if(u == NULL_KEY)
        return "NULL";
    
    /*string unhyphenated = substr(u, 0, 7) + substr(u, 9, 12)
                      + substr(u, 14, 17) + substr(u, 19, 22)
                      + substr(u, 24, 35);*/
	
	string unhyphenated = llDumpList2String(llParseString2List(u, ["-"], []), "");
    
    string outs;
    
    integer cc = 16;
    while(cc--) {
        integer icc = cc << 1;
        integer code = (integer)("0x" + substr(unhyphenated, icc, icc + 1));
        if(code < 35 || code > 126) code += 0x100;
        outs = llChar(code) + outs;
    }
    
    return outs;
}

key decode_22(string c) {
    if(c == "EMPTY")
        return "";
    if(c == "NULL")
        return NULL_KEY;
    
    string prec;
    integer cc = 16;
    while(cc--) {
        integer bits = llOrd(c, cc);
        integer low = bits & 0xf;
        integer high = (bits & 0xf0) >> 4;
        #define decode_22_lookup "0123456789abcdef"
        prec = substr(decode_22_lookup, high, high) + substr(decode_22_lookup, low, low) + prec;
        #undef decode_22_lookup
    }
     
	// inexplicably, leaving this concatenation here is better for memory than putting it in the return line:
	key hyphenated = (key)(substr(prec, 0, 7) + "-" + substr(prec, 8, 11) + "-"
               + substr(prec, 12, 15) + "-" + substr(prec, 16, 19) + "-"
               + substr(prec, 20, 31));
    
    return hyphenated;
}

#endif // QKEYS
