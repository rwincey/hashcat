/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

#ifndef INC_HASH_MD6_H
#define INC_HASH_MD6_H

/* for standard word size */

#define RL00 loop_body(10,11, 0)
#define RL01 loop_body( 5,24, 1)
#define RL02 loop_body(13, 9, 2)
#define RL03 loop_body(10,16, 3)
#define RL04 loop_body(11,15, 4)
#define RL05 loop_body(12, 9, 5)
#define RL06 loop_body( 2,27, 6)
#define RL07 loop_body( 7,15, 7)
#define RL08 loop_body(14, 6, 8)
#define RL09 loop_body(15, 2, 9)
#define RL10 loop_body( 7,29,10)
#define RL11 loop_body(13, 8,11)
#define RL12 loop_body(11,15,12)
#define RL13 loop_body( 7, 5,13)
#define RL14 loop_body( 6,31,14)
#define RL15 loop_body(12, 9,15)

/*
CONSTANT_VK u64 MD6_S0 = 0x0123456789abcdefUL;
CONSTANT_VK u64 MD6_Smask = 0x7311c2812425cfa0UL;
*/

/* n == 89 */

#define  t0   17     /* index for linear feedback */
#define  t1   18     /* index for first input to first and */
#define  t2   21     /* index for second input to first and */
#define  t3   31     /* index for first input to second and */
#define  t4   67     /* index for second input to second and */
#define  t5   89     /* last tap */

/* w == 64, standard version

CONSTANT_VK u64 MD6_Q[15] =
{
  0x7311c2812425cfa0UL,
  0x6432286434aac8e7UL,
  0xb60450e9ef68b7c1UL,
  0xe8fb23908d9f06f1UL,
  0xdd2e76cba691e5bfUL,
  0x0cd0d63b2c30bc41UL,
  0x1f8ccf6823058f8aUL,
  0x54e5ed5b88e3775dUL,
  0x4ad12aae0a6d6031UL,
  0x3e7f16bb88222e0dUL,
  0x8af8671d3fb50c2cUL,
  0x995ad1178bd25c31UL,
  0xc878c1dd04c4b633UL,
  0x3b72066c7a1552acUL,
  0x0d6f3522631effcbUL
};
*/

#define md6_w 64
#define md6_n 89            /* size of compression input block, in words  */
#define md6_c 16            /* size of compression output, in words       */
#define md6_q 15            /* # Q words in compression block (>=0)       */
#define md6_k  8            /* # key words per compression block (>=0)    */
#define md6_b 64            /* # data words per compression block (>0)    */

#define md6_default_L   64  /* large so that MD6 is fully hierarchical */

#define MD6_256_ROUNDS 104  // default value
#define MD6_256_DLEN   256  // digest len

/* hc optimized values

CONSTANT_VK u64 MD6_256_DEFAULT_NODEID = 0x0100000000000000UL; // ell = 1, i = 0
CONSTANT_VK u64 MD6_Vs = 0x0068401000000000UL;
CONSTANT_VK u64 MD6_Ve = 0x0000000000000100UL;
*/

#endif // INC_HASH_MD6_H
