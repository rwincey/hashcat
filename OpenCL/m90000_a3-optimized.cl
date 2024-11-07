/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include M2S(INCLUDE_PATH/inc_vendor.h)
#include M2S(INCLUDE_PATH/inc_types.h)
#include M2S(INCLUDE_PATH/inc_platform.cl)
#include M2S(INCLUDE_PATH/inc_common.cl)
#include M2S(INCLUDE_PATH/inc_simd.cl)
#endif


DECLSPEC u64x MurmurHash64A (const u64x seed, PRIVATE_AS const u32x *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  //Initialize hash
  u64x hash = seed ^ (len * M);

  printf("INITIAL = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  const u32 endpos = len - (len & 7);

  const u8 *data2 = (const u8*) data;

  printf("seed = %08x%08x\n", h32_from_64(seed), l32_from_64(seed));
  printf("data2 = %c%c%c%c%c%c%c%c\n", data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7]);
  printf("len = %d\n", len);

  
  // Loop over blocks of 8 bytes
  u32 i = 0;
  while (i != endpos) {
    u64x k = ((u64) data2[i])
      | ((u64) data2[i + 1] << 8)
      | ((u64) data2[i + 2] << 16)
      | ((u64) data2[i + 3] << 24)
      | ((u64) data2[i + 4] << 32)
      | ((u64) data2[i + 5] << 40)
      | ((u64) data2[i + 6] << 48)
      | ((u64) data2[i + 7] << 56);
  
    k *= M;
    k ^= k >> R;
    k *= M;

    hash ^= k;
    hash *= M;

    i += 8;
  }
  printf("BEFORE_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  // Overflow

  const u32 overflow = len & 7;

  printf("OVERFLOW = %d\n", overflow);

  switch (overflow) {
    case 7: hash ^= ((u64) data2[i + 6]) << 48;
    case 6: hash ^= ((u64) data2[i + 5]) << 40;
    case 5: hash ^= ((u64) data2[i + 4]) << 32;
    case 4: hash ^= ((u64) data2[i + 3]) << 24;
    case 3: hash ^= ((u64) data2[i + 2]) << 16;
    case 2: hash ^= ((u64) data2[i + 1]) << 8;
    case 1: hash ^= ((u64) data2[i]);
    hash *= M;
  }

  printf("AFTER_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  printf("hash = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  return hash;
}

DECLSPEC void m90000m (PRIVATE_AS const u32 *data, const u32 pw_len, KERN_ATTR_FUNC_VECTOR ())
{
  /**
   * modifiers are taken from args
   */

  /**
   * seed
   */

  const u32x seed_lo = salt_bufs[SALT_POS_HOST].salt_buf[0];
  const u32x seed_hi = salt_bufs[SALT_POS_HOST].salt_buf[1];
  const u64x seed = ((u64) seed_hi << 32) | ((u64) seed_lo);

  /**
   * base
   */

  u32x w[16];

  w[ 0] = data[ 0];
  w[ 1] = data[ 1];
  w[ 2] = data[ 2];
  w[ 3] = data[ 3];
  w[ 4] = data[ 4];
  w[ 5] = data[ 5];
  w[ 6] = data[ 6];
  w[ 7] = data[ 7];
  w[ 8] = data[ 8];
  w[ 9] = data[ 9];
  w[10] = data[10];
  w[11] = data[11];
  w[12] = data[12];
  w[13] = data[13];
  w[14] = data[14];
  w[15] = data[15];

  const u8 *data2 = (const u8*) data;
  //printf("w = %c%c%c%c%c%c%c%c\n", data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7]);

  /**
   * loop
   */

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0 = w0l | w0r;

    w[0] = w0;

    //printf("seed = %08x%08x\n", seed_hi, seed_lo);

    const u64x hash = MurmurHash64A (seed, w, pw_len);

    const u32x r0 = l32_from_64(hash);
    const u32x r1 = h32_from_64(hash);
    const u32x z = 0;

    printf("hash = %08x%08x\n", r1, r0);

    COMPARE_M_SIMD (r0, r1, z, z);
  }
}

DECLSPEC void m90000s (PRIVATE_AS const u32 *data, const u32 pw_len, KERN_ATTR_FUNC_VECTOR ())
{
  /**
   * modifiers are taken from args
   */

  /**
   * digest
   */
  
  printf("Hello world m90000s\n");

  const u32 search[4] =
  {
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R0],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R1],
    0,
    0
  };

  /**
   * seed
   */

  const u32x seed_lo = salt_bufs[SALT_POS_HOST].salt_buf[0];
  const u32x seed_hi = salt_bufs[SALT_POS_HOST].salt_buf[1];
  const u64x seed = ((u64) seed_hi << 32) | ((u64) seed_lo);

  /**
   * base
   */

  u32x w[16];

  w[ 0] = data[ 0];
  w[ 1] = data[ 1];
  w[ 2] = data[ 2];
  w[ 3] = data[ 3];
  w[ 4] = data[ 4];
  w[ 5] = data[ 5];
  w[ 6] = data[ 6];
  w[ 7] = data[ 7];
  w[ 8] = data[ 8];
  w[ 9] = data[ 9];
  w[10] = data[10];
  w[11] = data[11];
  w[12] = data[12];
  w[13] = data[13];
  w[14] = data[14];
  w[15] = data[15];

  /**
   * loop
   */

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0 = w0l | w0r;

    w[0] = w0;

    const u64x hash = MurmurHash64A (seed, w, pw_len);

    const u32x r0 = l32_from_64(hash);
    const u32x r1 = h32_from_64(hash);
    const u32x z = 0;

    //printf("r1 = %08x r0 = %08x\n", r1, r0);
    printf("hash = %08x%08x\n", r1, r0);

    COMPARE_S_SIMD (r0, r1, z, z);
  }
}

KERNEL_FQ void m90000_m04 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */
  
  //printf("Hello world m90000_m04\n");
  

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = 0;
  w[ 5] = 0;
  w[ 6] = 0;
  w[ 7] = 0;
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = 0;
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len & 63;
  //printf("pws[gid].pw_len = %d\n", pws[gid].pw_len);

  /**
   * main
   */

  m90000m (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}

KERNEL_FQ void m90000_m08 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */
  
  printf("Hello world m90000_m08\n");

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = 0;
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * main
   */

  m90000m (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}

KERNEL_FQ void m90000_m16 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = pws[gid].i[ 8];
  w[ 9] = pws[gid].i[ 9];
  w[10] = pws[gid].i[10];
  w[11] = pws[gid].i[11];
  w[12] = pws[gid].i[12];
  w[13] = pws[gid].i[13];
  w[14] = pws[gid].i[14];
  w[15] = pws[gid].i[15];

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * main
   */

  m90000m (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}

KERNEL_FQ void m90000_s04 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = 0;
  w[ 5] = 0;
  w[ 6] = 0;
  w[ 7] = 0;
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = 0;
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * main
   */

  m90000s (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}

KERNEL_FQ void m90000_s08 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = 0;
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * main
   */

  m90000s (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}

KERNEL_FQ void m90000_s16 (KERN_ATTR_VECTOR ())
{
  /**
   * base
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = pws[gid].i[ 8];
  w[ 9] = pws[gid].i[ 9];
  w[10] = pws[gid].i[10];
  w[11] = pws[gid].i[11];
  w[12] = pws[gid].i[12];
  w[13] = pws[gid].i[13];
  w[14] = pws[gid].i[14];
  w[15] = pws[gid].i[15];

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * main
   */

  m90000s (w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_extra0_buf, d_extra1_buf, d_extra2_buf, d_extra3_buf, kernel_param, gid, lid, lsz);
}
