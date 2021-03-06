/*
   Optimized 36-point Inverse Modified Cosine Transform (IMDCT)
   Copyright 2003-2006 Atmel Corporation.

   Written by Ronny Pedersen, Atmel Norway

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

#define MAD_F(x) ((x + (1 << 13)) >> 14)

  .section  .text.imdct_avr32, "ax", @progbits

  .align  2
	.public	imdct36_avr32

/*
	void imdct36(mad_fixed_t const x[18], mad_fixed_t y[36])
	{
	mad_fixed_t tmp[18];
	int i;
*/
/* DCT-IV */
imdct36_avr32:
	pushm	r0-r7,r11,lr
	sub	sp, 4*18
/*
	{
	mad_fixed_t tmp2[18];
	int i;
*/
	/* scale[i] = 2 * cos(PI * (2 * i + 1) / (4 * 18)) */
/*
	static mad_fixed_t const scale[18] = {
	MAD_F(0x1ff833fa), MAD_F(0x1fb9ea93), MAD_F(0x1f3dd120),
	MAD_F(0x1e84d969), MAD_F(0x1d906bcf), MAD_F(0x1c62648b),
	MAD_F(0x1afd100f), MAD_F(0x1963268b), MAD_F(0x1797c6a4),
	MAD_F(0x159e6f5b), MAD_F(0x137af940), MAD_F(0x11318ef3),
	MAD_F(0x0ec6a507), MAD_F(0x0c3ef153), MAD_F(0x099f61c5),
	MAD_F(0x06ed12c5), MAD_F(0x042d4544), MAD_F(0x0165547c)
	};
*/

  /* scaling */

/*
	for (i = 0; i < 18; i += 3) {
		tmp2[i + 0] = mad_f_mul(x[i + 0], scale[i + 0]);
		tmp2[i + 1] = mad_f_mul(x[i + 1], scale[i + 1]);
		tmp2[i + 2] = mad_f_mul(x[i + 2], scale[i + 2]);
	  }
*/
	/* even input butterfly */

/*
	for (i = 0; i < 9; i += 3) {
		tmp3[i + 0] = tmp2[i + 0] + tmp2[18 - (i + 0) - 1];
		tmp3[i + 1] = tmp2[i + 1] + tmp2[18 - (i + 1) - 1];
		tmp3[i + 2] = tmp2[i + 2] + tmp2[18 - (i + 2) - 1];
	  }
	for (i = 0; i < 9; i += 3) {
		tmp4[i + 0] = tmp2[i + 0] - tmp2[18 - (i + 0) - 1];
		tmp4[i + 1] = tmp2[i + 1] - tmp2[18 - (i + 1) - 1];
		tmp4[i + 2] = tmp2[i + 2] - tmp2[18 - (i + 2) - 1];
	  }
*/

	ld.d	r8, r12[0]				/*r8 = x[1], r9 = x[0]*/
	ld.d	r0, pc[scale_dctIV - .]			/*r0 = {scale[2], scale[3]}, r1 = { scale[0], scale[1] }*/
	ld.d	r2, r12[2*4]				/*r2 = x[3], r3 = x[2]*/
	ld.d	r4, pc[scale_dctIV - . + 14*2]		/*r4 = {scale[16], scale[17]}, r5 = { scale[14], scale[15] }*/
	mulsatrndwh.w	r9/*tmp2[0]*/, r9, r1:t		/*tmp2[0] = mad_f_mul(x[0], scale[0]) */
	ld.d	r6, r12[16*4]				/*r6 = x[17], r7 = x[16]*/
	mulsatrndwh.w	r8/*tmp2[1]*/, r8, r1:b		/*tmp2[1] = mad_f_mul(x[1], scale[1]) */
	mulsatrndwh.w	r3/*tmp2[2]*/, r3, r0:t		/*tmp2[2] = mad_f_mul(x[2], scale[2]) */
	mulsatrndwh.w	r2/*tmp2[3]*/, r2, r0:b		/*tmp2[3] = mad_f_mul(x[3], scale[3]) */
	ld.d	r0, r12[14*4]				/*r0 = x[15], r1 = x[14]*/
	mulsatrndwh.w	r7/*tmp2[16]*/, r7, r4:t	/*tmp2[16] = mad_f_mul(x[16], scale[16]) */
	mulsatrndwh.w	r6/*tmp2[17]*/, r6, r4:b	/*tmp2[17] = mad_f_mul(x[17], scale[17]) */
	mulsatrndwh.w	r1/*tmp2[14]*/, r1, r5:t	/*tmp2[14] = mad_f_mul(x[14], scale[14]) */
	mulsatrndwh.w	r0/*tmp2[15]*/, r0, r5:b	/*tmp2[15] = mad_f_mul(x[15], scale[15]) */

	ld.d	r4, r12[4*4]				/*r4 = x[5], r5 = x[4]*/

	sub		lr/*tmp4[0]*/, r9, r6
	add		r6/*tmp3[0]*/, r9, r6
	sub		r10/*tmp4[1]*/, r8, r7
	add		r7/*tmp3[1]*/, r8, r7
	sub		r9/*tmp4[2]*/, r3, r0
	add		r0/*tmp3[2]*/, r3, r0
	sub		r8/*tmp4[3]*/, r2, r1
	add		r1/*tmp3[3]*/, r2, r1

	ld.d	r2, pc[scale_dctIV - . + 4*2]		/*r2 = {scale[6], scale[7]}, r3 = { scale[4], scale[5] }*/

	stm		--sp, r8-r10, lr		/*sp[0] = tmp4[0],sp[1] = tmp4[1],
							  sp[2] = tmp4[2],sp[3] = tmp4[3] */

	/* Registers used:	r0 = tmp3[2], r1 = tmp3[3], r6 = tmp3[0], r7 = tmp3[1], r12 = x
	   Free	registers:	r2-r5, r8-r11, lr
	*/
	ld.d	r8, r12[6*4]				/*r8 = x[7], r9 = x[6]*/
	ld.d	r10, pc[scale_dctIV - . + 10*2]		/*r10 = {scale[12], scale[13]}, r11 = { scale[10], scale[11] }*/
	mulsatrndwh.w	r5/*tmp2[4]*/, r5, r3:t		/*tmp2[4] = mad_f_mul(x[4], scale[4]) */
	mulsatrndwh.w	r4/*tmp2[5]*/, r4, r3:b		/*tmp2[5] = mad_f_mul(x[5], scale[5]) */
	mulsatrndwh.w	r9/*tmp2[6]*/, r9, r2:t		/*tmp2[6] = mad_f_mul(x[6], scale[6]) */
	mulsatrndwh.w	r8/*tmp2[7]*/, r8, r2:b		/*tmp2[7] = mad_f_mul(x[7], scale[7]) */

	ld.d	r2, r12[12*4]				/*r2 = x[13], r3 = x[12]*/
	ld.w	lr, r12[11*4]				/*lr = x[11] */
	mulsatrndwh.w	r3/*tmp2[12]*/, r3, r10:t	/*tmp2[12] = mad_f_mul(x[12], scale[12]) */
	mulsatrndwh.w	r2/*tmp2[13]*/, r2, r10:b	/*tmp2[13] = mad_f_mul(x[13], scale[13]) */
	ld.w	r10, r12[10*4]				/*r10 = x[10] */
	mulsatrndwh.w	lr/*tmp2[11]*/, lr, r11:b	/*tmp2[11] = mad_f_mul(x[11], scale[11]) */
	mulsatrndwh.w	r10/*tmp2[10]*/, r10, r11:t	/*tmp2[10] = mad_f_mul(x[10], scale[10]) */

	sub	r11/*tmp4[4]*/, r5, r2
	add	r2/*tmp3[4]*/, r5, r2
	sub	r5/*tmp4[5]*/, r4, r3
	add	r3/*tmp3[5]*/, r4, r3
	sub	r4/*tmp4[6]*/, r9, lr
	add	lr/*tmp3[6]*/, r9, lr
	sub	r9/*tmp4[7]*/, r8, r10
	add	r10/*tmp3[7]*/, r8, r10
	lddpc	r8, scale_dctIV + 8*2			/*r8 = {scale[8], scale[9]} */

	stm	--sp, r4, r5, r9, r11			/*sp[0] = tmp4[4],sp[1] = tmp4[7],
							  sp[2] = tmp4[5],sp[3] = tmp4[6] */
	ld.d	r4, r12[8*4]				/*r4 = x[9], r5 = x[8]*/
	mulsatrndwh.w	r5/*tmp2[8]*/, r5, r8:t		/*tmp2[8] = mad_f_mul(x[8], scale[8]) */
	mulsatrndwh.w	r4/*tmp2[9]*/, r4, r8:b		/*tmp2[9] = mad_f_mul(x[9], scale[9]) */
	sub		r9/*tmp4[8]*/, r5, r4
	add		r5/*tmp3[8]*/, r5, r4

	st.w	--sp, r9				/* sp[0] = tmp4[8] */

	/* Registers used:

		r0=tmp3[2], r1=tmp3[3], r2=tmp3[4], r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r10=tmp3[7], lr=tmp3[6]
	   Free registers:
		r4, r8, r9, r11, r12
	*/


  /* SDCT-II */
/*

	{
	mad_fixed_t tmp3[9];
	int i;
*/
	/* scale[i] = 2 * cos(PI * (2 * i + 1) / (2 * 18)) */
/*
	static mad_fixed_t const scale[9] = {
	MAD_F(0x1fe0d3b4), MAD_F(0x1ee8dd47), MAD_F(0x1d007930),
	MAD_F(0x1a367e59), MAD_F(0x16a09e66), MAD_F(0x125abcf8),
	MAD_F(0x0d8616bc), MAD_F(0x08483ee1), MAD_F(0x02c9fad7)
	};
*/
  /* divide the 18-point SDCT-II into two 9-point SDCT-IIs */


  /* fastdct */

/*
	{
	mad_fixed_t a0,  a1,  a2,  a3,  a4,  a5,  a6,  a7,  a8,  a9,  a10, a11, a12;
	mad_fixed_t a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25;
	mad_fixed_t m0,  m1,  m2,  m3,  m4,  m5,  m6,  m7;
*/
//	  enum {
//	    c0 =  MAD_F(0x1f838b8d),  /* 2 * cos( 1 * PI / 18) */
//	    c1 =  MAD_F(0x1bb67ae8),  /* 2 * cos( 3 * PI / 18) */
//	    c2 =  MAD_F(0x18836fa3),  /* 2 * cos( 4 * PI / 18) */
//	    c3 =  MAD_F(0x1491b752),  /* 2 * cos( 5 * PI / 18) */
//	    c4 =  MAD_F(0x0af1d43a),  /* 2 * cos( 7 * PI / 18) */
//	    c5 =  MAD_F(0x058e86a0),  /* 2 * cos( 8 * PI / 18) */
//	    c6 = -MAD_F(0x1e11f642)   /* 2 * cos(16 * PI / 18) */
//	  };

/*
	a2 = tmp3[6] + tmp3[2];
	a6 = tmp3[8] + tmp3[0];
	a11 = a2  - a6;
	m5 = mad_f_mul(a11, -c6) ;
	a4 = tmp3[1] + tmp3[7];

	a18 =     tmp3[4] + a4;
	a19 = -2 * tmp3[4] + a4;

	a0 = tmp3[3] + tmp3[5];

*/
	add	r11/*a4*/, r7, r10
	add	r12/*a18*/, r2, r11
	sub	r11/*a19*/, r11, r2<<1

	add	r4/*a2*/, lr, r0
	add	r8/*a6*/, r5, r6
	sub	r9/*a11*/, r4, r8

	st.d	--sp, r0	/* sp[0] = tmp3[3], sp1[1] = tmp3[2]*/

	mov	r2, MAD_F(0x1e11f642)
	mulsatrndwh.w	r9/*m5*/, r9, r2:b

	add	r2/*a0*/, r1, r3

	/* Registers used:

		r2=a0, r3=tmp3[5], r4=a2, r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r8=a6, r10=tmp3[7], r9=m5, r11=a19, r12=a18,lr=tmp3[6]
	   Free registers:
		r0, r1
	*/

/*
	a8  = a0  + a2;
	a12 = a8  + a6;
	a10 = a0  - a6;
	a9  = a0  - a2;
	m7 = mad_f_mul(a9,  -c2) ;
	m6 = mad_f_mul(a10, -c5) ;
*/

	add	r0/*a8*/, r2, r4
	add	r0/*a12*/, r8
	rsub	r8/*a10*/, r2
	sub	r2/*a9*/, r4
	mov	r1, -MAD_F(0x18836fa3)
	mulsatrndwh.w	r2/*m7*/, r2, r1:b
	mov	r1, -MAD_F(0x058e86a0)
	mulsatrndwh.w	r8/*m6*/, r8, r1:b

	/* Registers used:

		r0=a12, r2=m7, r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r8=m6, r10=tmp3[7], r9=m5, r11=a19, r12=a18,lr=tmp3[6]
	   Free registers:
		r1, r4
	*/


/*
	a21 = -a19 - (m5 << 1);
	tmp[ 8] = a21 - (m6 << 1);

	a20 = a19 - (m5 << 1);
	tmp[ 4] = (m7 << 1)  + a20;
	a22 = -a19 + (m6 << 1);
	tmp[16] = a22 + (m7 << 1);
	tmp[ 0] = a18 + a12;
	tmp[12] = a12 - 2 * a18;
*/
	add	r1/*a21*/, r11, r9 << 1
	neg	r1
	sub	r1/*tmp[8]*/, r1, r8 << 1
	stdsp	sp[4*11/*tmp3[..] on the stack*/ + 8*4], r1
	sub	r4/*a20*/, r11, r9 << 1
	add	r4/*tmp[4]*/, r4, r2 << 1
	stdsp	sp[4*11/*tmp3[..] on the stack*/ + 4*4], r4
	neg	r11
	add	r1/*a22*/, r11, r8 << 1
	add	r1/*tmp[16]*/, r1, r2 << 1
	stdsp	sp[4*11/*tmp3[..] on the stack*/ + 16*4], r1
	add	r4, r12, r0
	sub	r1, r0, r12 << 1
	stdsp	sp[4*11/*tmp3[..] on the stack*/ + 0*4], r4
	stdsp	sp[4*11/*tmp3[..] on the stack*/ + 12*4], r1

	ld.d	r0, sp++

	/* Registers used:

		r0 = tmp3[2], r1 = tmp3[3], r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r10=tmp3[7], r11=a19, lr=tmp3[6]
	   Free registers:
		r2,r4,r8,r9,r12
	*/

/*
	a5 = tmp3[1] - tmp3[7];
	a7 = tmp3[8] - tmp3[0];
	a3 = tmp3[6] - tmp3[2];
	a1 = tmp3[3] - tmp3[5];
	a13 = a1  - a3;
	a14 = a13 + a7;
	m3 = mad_f_mul(a14, -c1) ;
	m4 = mad_f_mul(a5,  -c1) ;
	tmp[ 6] = m3 << 1;
*/
	sub	r7/*a5*/, r10
	sub	r2/*a7*/, r5, r6
	sub	r4/*a3*/, lr, r0
	sub	r8/*a1*/, r1, r3
	sub	r9/*a13*/, r8, r4
	add	r12/*a14*/, r9, r2
	mov	r0, -MAD_F(0x1bb67ae8)
	mulsatrndwh.w	r12/*m3*/, r12, r0:b
	mulsatrndwh.w	r7/*m4*/, r7, r0:b
	lsl	r12, 1
	stdsp	sp[4*9/*tmp3[..] on the stack*/ + 6*4], r12

	/* Registers used:
		r2 = a7, r4 = a3, r7 = m4, r8 = a1, r12 = m3

	   Free registers:
		r0, r1, r3, r5, r6, r10, r9, r11, lr
	*/


/*
	a15 = a3  + a7;
	m2 = mad_f_mul(a15, -c4) ;
	a17 = a1  + a3;
	m0 = mad_f_mul(a17, -c3) ;
	a23 = (m4 << 1)  + (m2 << 1);
	tmp[14] = a23 + (m0 << 1); */
	add	r0/*a15*/, r4, r2
	mov	r1, -MAD_F(0x0af1d43a)
	mulsatrndwh.w	r0/*m2*/, r0, r1:b
	mov	r3, -MAD_F(0x1491b752)
	add	r5/*a17*/, r8, r4
	mulsatrndwh.w	r5/*m0*/, r5, r3:b
	lsl	r7, 1
	add	r6/*a23*/, r7, r0 << 1
	add	r6/*tmp[14]*/, r6, r5 << 1
	stdsp	sp[4*9/*tmp3[..] on the stack*/ + 14*4], r6

	/* Registers used:
		r0 = m2, r2 = a7, r5 = m0, r7 = m4, r8 = a1

	   Free registers:
		r1, r3, r4, r6, r10, r9, r11, lr
	*/

/*
	a16 = a1  - a7;
	m1 = mad_f_mul(a16, -c0) ;
	a24 = (m4 << 1)  - (m2 << 1);
	tmp[10] = a24 - (m1 << 1);

	a25 = (m4 << 1)  + (m1 << 1);
	tmp[ 2] = (m0 << 1)  - a25;
*/
	sub	r3/*a16*/, r8, r2
	mov	r4,  -MAD_F(0x1f838b8d)
	mulsatrndwh.w	r3/*m1*/, r3, r4:b
	sub	r1/*a24*/, r7, r0 << 1
	sub	r1/*tmp[10]*/, r1, r3 << 1
	stdsp	sp[4*9/*tmp3[..] on the stack*/ + 10*4], r1
	add	r7/*a25*/, r7, r3 << 1
	sub	r7, r7, r5 << 1
	neg	r7
	stdsp	sp[4*9/*tmp3[..] on the stack*/ + 2*4], r7




  /* output to every other slot for convenience */

  /*} */
  /* End fastdct */

  /* odd input butterfly and scaling */


	/*  On the stack:
		sp[0] = tmp4[8], sp[1] = tmp4[4],sp[2] = tmp4[7], sp[3] = tmp4[5],sp[4] = tmp4[6]
		sp[5] = tmp4[0], sp[6] = tmp4[1],sp[7] = tmp4[2],sp[8] = tmp4[3]
	*/

  /*
	  tmp3[0] = mad_f_mul(tmp4[0], scale[0]);
	  tmp3[1] = mad_f_mul(tmp4[1], scale[1]) << 1;
	  tmp3[2] = mad_f_mul(tmp4[2], scale[2]);
	  tmp3[3] = mad_f_mul(tmp4[3], scale[3]) << 1;
	  tmp3[4] = mad_f_mul(tmp4[4], scale[4]);
	  tmp3[5] = mad_f_mul(tmp4[5], scale[5]);
	  tmp3[6] = mad_f_mul(tmp4[6], scale[6]) << 1;
	  tmp3[7] = mad_f_mul(tmp4[7], scale[7]);
	  tmp3[8] = mad_f_mul(tmp4[8], scale[8]) << 1;
  */
	/* Registers used:
		r1 = tmp4[3], r2 = tmp4[2], r3 = tmp4[1], r4 = tmp4[0], r7 = tmp4[6]
		r10 = tmp4[5], r11 = tmp4[7], r12 = tmp4[4], lr = tmp4[8]

	   Free registers:
		r0, r5, r6, r8, r9
	*/
	ld.d	r8, pc[ scale_sdctII - . + 4*2]	/* r8 = { scale[6], scale[7] }, r9 = { scale[4], scale[5]} */
	ldm	sp++, r1, r2, r3, r4, r7, r10, r11, r12, lr
	mov	r5, MAD_F(0x02c9fad7)		/* r3 = scale[8] */
	mulsatrndwh.w	r5/*tmp3[8]*/, lr, r5:b
	mulsatrndwh.w	lr/*tmp3[6]*/, r7, r8:t
	ld.d	r6, pc[ scale_sdctII - . + 0*2]	/* r6 = { scale[2], scale[3] }, r7 = { scale[0], scale[1]} */
	lsl	lr, 1
	lsl	r5, 1
	mulsatrndwh.w	r0/*tmp3[2]*/, r2, r6:t
	mulsatrndwh.w	r1/*tmp3[3]*/, r1, r6:b
	mulsatrndwh.w	r6/*tmp3[0]*/, r4, r7:t
	mulsatrndwh.w	r7/*tmp3[1]*/, r3, r7:b
	mulsatrndwh.w	r3/*tmp3[5]*/, r10, r9:b
	mulsatrndwh.w	r2/*tmp3[4]*/, r12, r9:t
	mulsatrndwh.w	r9/*tmp3[7]*/, r11, r8:b
	lsl	r1, 1
	lsl	r7, 1


  /* fastdct */

/*
	{
	mad_fixed_t a0,  a1,  a2,  a3,  a4,  a5,  a6,  a7,  a8,  a9,  a10, a11, a12;
	mad_fixed_t a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25;
	mad_fixed_t m0,  m1,  m2,  m3,  m4,  m5,  m6,  m7;
*/
//	  enum {
//	    c0 =  MAD_F(0x1f838b8d),  /* 2 * cos( 1 * PI / 18) */
//	    c1 =  MAD_F(0x1bb67ae8),  /* 2 * cos( 3 * PI / 18) */
//	    c2 =  MAD_F(0x18836fa3),  /* 2 * cos( 4 * PI / 18) */
//	    c3 =  MAD_F(0x1491b752),  /* 2 * cos( 5 * PI / 18) */
//	    c4 =  MAD_F(0x0af1d43a),  /* 2 * cos( 7 * PI / 18) */
//	    c5 =  MAD_F(0x058e86a0),  /* 2 * cos( 8 * PI / 18) */
//	    c6 = -MAD_F(0x1e11f642)   /* 2 * cos(16 * PI / 18) */
//	  };

	/* Registers used:

		r0=tmp3[2], r1=tmp3[3], r2=tmp3[4], r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r9=tmp3[7], lr=tmp3[6]
	   Free registers:
		r4, r8, r10, r11, r12
	*/

/*
	a2 = tmp3[6] + (tmp3[2] << 1);
	a6 = tmp3[8] + (tmp3[0] << 1);
	a11 = a2 - a6;
	m5 = mad_f_mul(a11, c6) ;
	a4 = tmp3[1] + (tmp3[7] << 1);

	a18 =     (tmp3[4] << 1) + a4;
	a19 = -2 * (tmp3[4] << 1) + a4;

	a0 = tmp3[3] + (tmp3[5] << 1);

*/
	add	r11/*a4*/, r7, r9 << 1
	add	r12/*a18*/, r11, r2 << 1
	sub	r11/*a19*/, r11, r2 << 2

	add	r4/*a2*/, lr, r0 << 1
	add	r8/*a6*/, r5, r6 << 1
	sub	r10/*a11*/, r4, r8

	st.d	--sp, r0	/* sp[0] = tmp3[3], sp1[1] = tmp3[2]*/

	mov	r2, -MAD_F(0x1e11f642)
	mulsatrndwh.w	r10/*m5*/, r10, r2:b

	add	r2/*a0*/, r1, r3 << 1

	/* Registers used:

		r2=a0, r3=tmp3[5], r4=a2, r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r8=a6, r9=tmp3[7], r10=m5, r11=a19, r12=a18,lr=tmp3[6]
	   Free registers:
		r0, r1
	*/

/*
	a8  = a0  + a2;
	a12 = a8  + a6;
	a10 = a0  - a6;
	a9  = a0  - a2;
	m7 = mad_f_mul(a9,  -c2) ;
	m6 = mad_f_mul(a10, -c5) ;
*/

	add	r0/*a8*/, r2, r4
	add	r0/*a12*/, r8
	rsub	r8/*a10*/, r2
	sub	r2/*a9*/, r4
	mov	r1, -MAD_F(0x18836fa3)
	mulsatrndwh.w	r2/*m7*/, r2, r1:b
	mov	r1, -MAD_F(0x058e86a0)
	mulsatrndwh.w	r8/*m6*/, r8, r1:b

	/* Registers used:

		r0=a12, r2=m7, r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r8=m6, r9=tmp3[7], r10=m5, r11=a19, r12=a18,lr=tmp3[6]
	   Free registers:
		r1, r4
	*/


/*
	a21 = -a19 + (m5 << 1);
	tmp[ 9] = a21 - (m6 << 1);

	a20 = -(-a19 - (m5 << 1));
	tmp[ 5] = (m7 << 1)  + a20;
	a22 = -a19 + (m6 << 1);
	tmp[17] = a22 + (m7 << 1);
	tmp[ 1] = a18 + a12;
	tmp[13] = a12 - 2 * a18;
*/
	sub	r1/*a21*/, r11, r10 << 1
	neg	r1
	sub	r1/*tmp[9]*/, r1, r8 << 1
	stdsp	sp[4*2/*tmp3[..] on the stack*/ + 9*4], r1
	add	r4/*a20*/, r11, r10 << 1
	add	r4/*tmp[5]*/, r4, r2 << 1
	stdsp	sp[4*2/*tmp3[..] on the stack*/ + 5*4], r4
	neg	r11
	add	r1/*a22*/, r11, r8 << 1
	add	r1/*tmp[17]*/, r1, r2 << 1
	stdsp	sp[4*2/*tmp3[..] on the stack*/ + 17*4], r1
	add	r4, r12, r0
	sub	r1, r0, r12 << 1
	stdsp	sp[4*2/*tmp3[..] on the stack*/ + 1*4], r4
	stdsp	sp[4*2/*tmp3[..] on the stack*/ + 13*4], r1

	ld.d	r0, sp++

	/* Registers used:

		r0 = tmp3[2], r1 = tmp3[3], r3=tmp3[5], r5=tmp3[8], r6 = tmp3[0],
		r7 = tmp3[1], r9=tmp3[7], r11=a19, lr=tmp3[6]
	   Free registers:
		r2,r4,r8,r10,r12
	*/

/*
	a5 = tmp3[1] - (tmp3[7] << 1);
	a7 = tmp3[8] - (tmp3[0] << 1);
	a3 = tmp3[6] - (tmp3[2] << 1);
	a1 = tmp3[3] - (tmp3[5] << 1);
	a13 = a1  - a3;
	a14 = a13 + a7;
	m3 = mad_f_mul(a14, -c1) ;
	m4 = mad_f_mul(a5,  -c1) ;
	tmp[ 7] = m3 << 1;
*/
	sub	r7/*a5*/, r7, r9 << 1
	sub	r2/*a7*/, r5, r6 << 1
	sub	r4/*a3*/, lr, r0 << 1
	sub	r8/*a1*/, r1, r3 << 1
	sub	r10/*a13*/, r8, r4
	add	r12/*a14*/, r10, r2
	mov	r0, -MAD_F(0x1bb67ae8)
	mulsatrndwh.w	r12/*m3*/, r12, r0:b
	mulsatrndwh.w	r7/*m4*/, r7, r0:b
	lsl	r12, 1
	stdsp	sp[7*4], r12

	/* Registers used:
		r2 = a7, r4 = a3, r7 = m4, r8 = a1, r12 = m3

	   Free registers:
		r0, r1, r3, r5, r6, r9, r10, r11, lr
	*/


/*
	a15 = a3  + a7;
	m2 = mad_f_mul(a15, -c4) ;
	a17 = a1  + a3;
	m0 = mad_f_mul(a17, -c3) ;
	a23 = (m4 << 1)  + (m2 << 1);
	tmp[15] = a23 + (m0 << 1); */
	add	r0/*a15*/, r4, r2
	mov	r1, -MAD_F(0x0af1d43a)
	mulsatrndwh.w	r0/*m2*/, r0, r1:b
	mov	r3, -MAD_F(0x1491b752)
	add	r5/*a17*/, r8, r4
	mulsatrndwh.w	r5/*m0*/, r5, r3:b
	lsl	r7, 1
	add	r6/*a23*/, r7, r0 << 1
	add	r6/*tmp[15]*/, r6, r5 << 1
	stdsp	sp[15*4], r6

	/* Registers used:
		r0 = m2, r2 = a7, r5 = m0, r7 = m4, r8 = a1

	   Free registers:
		r1, r3, r4, r6, r9, r10, r11, lr
	*/

/*
	a16 = a1  - a7;
	m1 = mad_f_mul(a16, -c0) ;
	a24 = (m4 << 1)  - (m2 << 1);
	tmp[11] = a24 - (m1 << 1);

	a25 = (m4 << 1)  + (m1 << 1);
	tmp[ 3] = (m0 << 1)  - a25;
*/
	sub	r3/*a16*/, r8, r2
	mov	r4,  -MAD_F(0x1f838b8d)
	mulsatrndwh.w	r3/*m1*/, r3, r4:b
	sub	r1/*a24*/, r7, r0 << 1
	sub	r1/*tmp[11]*/, r1, r3 << 1
	stdsp	sp[11*4], r1
	add	r7/*a25*/, r7, r3 << 1
	sub	r7, r7, r5 << 1
	neg	r7
	lddsp	r12, sp[4*18+4]	/* Get y from stack */
	stdsp	sp[3*4], r7


  /* output to every other slot for convenience */

  /* End fastdct */

  /* output accumulation */

/*	for (i = 3; i < 18; i += 8) {
	  tmp[i + 0] -= tmp[(i + 0) - 2];
	  tmp[i + 2] -= tmp[(i + 2) - 2];
	  tmp[i + 4] -= tmp[(i + 4) - 2];
	  tmp[i + 6] -= tmp[(i + 6) - 2];
	}
	}
*/

/* End  SDCT-II */



  /* scale reduction and output accumulation */

/*
	for (i = 1; i < 17; i += 4) {
	  tmp[i + 0] = tmp[i + 0]  - tmp[(i + 0) - 1];
	  tmp[i + 1] = tmp[i + 1]  - tmp[(i + 1) - 1];
	  tmp[i + 2] = tmp[i + 2]  - tmp[(i + 2) - 1];
	  tmp[i + 3] = tmp[i + 3]  - tmp[(i + 3) - 1];
	}
	tmp[17] = tmp[17] - tmp[16];
	}
*/
/* End  DCT-IV */


  /* convert 18-point DCT-IV to 36-point IMDCT */

/*
	for (i =  0; i <  9; i += 3) {
	  y[i + 0] =  tmp[9 + (i + 0)];
	  y[i + 1] =  tmp[9 + (i + 1)];
	  y[i + 2] =  tmp[9 + (i + 2)];
	}
	for (i =  9; i < 27; i += 3) {
	  y[i + 0] = -tmp[36 - (9 + (i + 0)) - 1];
	  y[i + 1] = -tmp[36 - (9 + (i + 1)) - 1];
	  y[i + 2] = -tmp[36 - (9 + (i + 2)) - 1];
	}
	for (i = 27; i < 36; i += 3) {
	  y[i + 0] = -tmp[(i + 0) - 27];
	  y[i + 1] = -tmp[(i + 1) - 27];
	  y[i + 2] = -tmp[(i + 2) - 27];
	}
	}
*/

	/* Registers used:
		r0 = tmp[8], r1 = tmp[7], r2 = tmp[6], r3 = tmp[5], r4 = tmp[4]
		r5 = tmp[3], r6 = tmp[2], r7 = tmp[1], r8 = tmp[0], r12 = y

	   Free registers:
		r9, r10, r11, lr
	*/

	ldm	sp++, r0-r8	/* Get tmp[0]-tmp[8] from stack */
	sub	r5, r7		/* tmp[3] -= tmp[1]*/
	sub	r3, r5		/* tmp[5] -= tmp[3]*/
	sub	r1, r3		/* tmp[7] -= tmp[5]*/

	sub	r7, r8		/* tmp[1] -= tmp[0]*/
	sub	r6, r7		/* tmp[2] -= tmp[1]*/
	sub	r5, r6		/* tmp[3] -= tmp[2]*/
	neg	r8
	st.w	r12[26*4], r8	/* y[26] = -tmp[0] */
	st.w	r12[27*4], r8	/* y[27] = -tmp[0] */
	neg	r7
	neg	r6
	st.w	r12[25*4], r7	/* y[25] = -tmp[1] */
	st.w	r12[24*4], r6	/* y[24] = -tmp[2] */
	st.d	r12[28*4], r6	/* y[28] = -tmp[1], y[29] = -tmp[2]*/

	sub	r4, r5		/* tmp[4] -= tmp[3]*/
	sub	r3, r4		/* tmp[5] -= tmp[4]*/
	neg	r5
	neg	r4
	st.w	r12[23*4], r5	/* y[23] = -tmp[3] */
	st.w	r12[22*4], r4	/* y[22] = -tmp[4] */
	st.d	r12[30*4], r4	/* y[30] = -tmp[3], y[31] = -tmp[4]*/

	ldm	sp++, r4-r11,lr	/* Get tmp[9]-tmp[17] from stack */

	sub	r2, r3		/* tmp[6] -= tmp[5]*/

	sub	lr, r1		/* tmp[9] -= tmp[7]*/
	sub	r10, lr		/* tmp[11] -= tmp[9]*/
	sub	r8, r10		/* tmp[13] -= tmp[11]*/
	sub	r6, r8		/* tmp[15] -= tmp[13]*/
	sub	r4, r6		/* tmp[17] -= tmp[15]*/

	sub	r1, r2		/* tmp[7] -= tmp[6]*/
	sub	r0, r1		/* tmp[8] -= tmp[7]*/
	neg	r3
	neg	r2
	st.w	r12[21*4], r3	/* y[21] = -tmp[5] */
	st.w	r12[20*4], r2	/* y[20] = -tmp[6] */
	st.d	r12[32*4], r2	/* y[32] = -tmp[5], y[33] = -tmp[6]*/

	sub	lr, r0		/* tmp[9] -= tmp[8]*/
	sub	r11, lr		/* tmp[10] -= tmp[9]*/
	neg	r1
	neg	r0
	st.w	r12[19*4], r1	/* y[19] = -tmp[7] */
	st.w	r12[18*4], r0	/* y[18] = -tmp[8] */
	st.d	r12[34*4], r0	/* y[34] = -tmp[7], y[35] = -tmp[8]*/

	sub	r10, r11	/* tmp[11] -= tmp[10]*/
	sub	r9, r10		/* tmp[12] -= tmp[11]*/

	st.w	r12[0*4], lr	/* y[0] = tmp[9]*/
	neg	lr
	st.w	r12[17*4], lr	/* y[17] = -tmp[9]*/
	st.d	r12[1*4], r10	/* y[1] = tmp[10], y[2] = tmp[11] */
	neg	r11
	neg	r10
	st.w	r12[16*4], r11	/* y[16] = -tmp[10] */
	st.w	r12[15*4], r10	/* y[15] = -tmp[11] */


	sub	r8, r9		/* tmp[13] -= tmp[12]*/
	sub	r7, r8		/* tmp[14] -= tmp[13]*/
	st.d	r12[3*4], r8	/* y[3] = tmp[12], y[4] = tmp[13] */
	neg	r9
	neg	r8
	st.w	r12[14*4], r9	/* y[14] = -tmp[12] */
	st.w	r12[13*4], r8	/* y[13] = -tmp[13] */

	sub	r6, r7		/* tmp[15] -= tmp[14]*/
	sub	r5, r6		/* tmp[16] -= tmp[15]*/
	sub	r4, r5		/* tmp[17] -= tmp[16]*/

	st.d	r12[5*4], r6	/* y[5] = tmp[14], y[6] = tmp[15] */
	neg	r7
	neg	r6
	st.w	r12[12*4], r7	/* y[12] = -tmp[14] */
	st.w	r12[11*4], r6	/* y[11] = -tmp[15] */

	st.d	r12[7*4], r4	/* y[7] = tmp[16], y[8] = tmp[17] */
	neg	r5
	neg	r4
	st.w	r12[10*4], r5	/* y[10] = -tmp[16] */
	st.w	r12[9*4], r4	/* y[9] = -tmp[17] */

	popm	r0-r7,r11,pc

	.align	2
scale_dctIV:
	.short	MAD_F(0x1ff833fa), MAD_F(0x1fb9ea93), MAD_F(0x1f3dd120)
	.short	MAD_F(0x1e84d969), MAD_F(0x1d906bcf), MAD_F(0x1c62648b)
	.short	MAD_F(0x1afd100f), MAD_F(0x1963268b), MAD_F(0x1797c6a4)
	.short	MAD_F(0x159e6f5b), MAD_F(0x137af940), MAD_F(0x11318ef3)
	.short	MAD_F(0x0ec6a507), MAD_F(0x0c3ef153), MAD_F(0x099f61c5)
	.short	MAD_F(0x06ed12c5), MAD_F(0x042d4544), MAD_F(0x0165547c)

	.align	2
scale_sdctII:
	.short	MAD_F(0x1fe0d3b4), MAD_F(0x1ee8dd47), MAD_F(0x1d007930)
	.short	MAD_F(0x1a367e59), MAD_F(0x16a09e66), MAD_F(0x125abcf8)
	.short	MAD_F(0x0d8616bc), MAD_F(0x08483ee1), MAD_F(0x02c9fad7)
