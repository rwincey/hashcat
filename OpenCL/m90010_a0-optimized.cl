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
#include M2S(INCLUDE_PATH/inc_rp_optimized.h)
#include M2S(INCLUDE_PATH/inc_rp_optimized.cl)
#include M2S(INCLUDE_PATH/inc_simd.cl)
#endif

DECLSPEC u64 MurmurHash64A_round (PRIVATE_AS const u8 *data, u64 hash, const u32 cur_pos) {
  #define M 0xc6a4a7935bd1e995
  #define R 47

  u64 k = ((u64) data[cur_pos])
    | ((u64) data[cur_pos + 1] << 8)
    | ((u64) data[cur_pos + 2] << 16)
    | ((u64) data[cur_pos + 3] << 24)
    | ((u64) data[cur_pos + 4] << 32)
    | ((u64) data[cur_pos + 5] << 40)
    | ((u64) data[cur_pos + 6] << 48)
    | ((u64) data[cur_pos + 7] << 56);
  
  k *= M;
  k ^= k >> R;
  k *= M;

  hash ^= k;
  hash *= M;

  #undef M
  #undef R

  return hash;
}

DECLSPEC u64 MurmurHash64A_final (PRIVATE_AS const u8 *data, u64 hash, const u32 cur_pos, const u32 len) {
  #define M 0xc6a4a7935bd1e995
  #define R 47

  const u32 overflow = len & 7;

  switch (overflow) {
    case 7: hash ^= ((u64) data[cur_pos + 6]) << 48;
    case 6: hash ^= ((u64) data[cur_pos + 5]) << 40;
    case 5: hash ^= ((u64) data[cur_pos + 4]) << 32;
    case 4: hash ^= ((u64) data[cur_pos + 3]) << 24;
    case 3: hash ^= ((u64) data[cur_pos + 2]) << 16;
    case 2: hash ^= ((u64) data[cur_pos + 1]) << 8;
    case 1: hash ^= ((u64) data[cur_pos]);
    hash *= M;
  }

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  return hash;
}

DECLSPEC u64 MurmurHash64A (PRIVATE_AS const u32 *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  //Initialize hash
  u64 hash = 0 ^ (len * M);

  //const u64 INITIAL = hash;
  
  const u32 endpos = len - (len & 7);

  //const u32 nBlocks = len >> 3; // number of 8 byte blocks
  const u8 *data2 = (const u8*) data;

  //u64 MIDDLE_OF_BLOCK = 0;

  // Loop over blocks of 8 bytes
  u32 i = 0;
  while (i != endpos) {
    hash = MurmurHash64A_round(data2, hash, i);

    i += 8;
  }

  // Overflow

  //const u64 BEFORE_FINAL = hash;

  hash = MurmurHash64A_final (data2, hash, i, len);

  //const u64 AFTER_FINAL = hash;

  //printf("debug: %016lx:%016lx:%c%c%c%c%c%c%c%c%c%c len: %d INITIAL: %016lx MIDDLE_O_BLK: %016lx B4FINAL: %016lx overflow: %d AFTER_FINAL: %016lx\n", hash, seed, data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7], data2[8], data2[9], len, INITIAL, MIDDLE_OF_BLOCK, BEFORE_FINAL, overflow, AFTER_FINAL);
  //printf("data2 = %.2s, len = %d\n", data2[0], len);

  #undef M
  #undef R

  return hash;
}



KERNEL_FQ void m90000_m04 (KERN_ATTR_RULES ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);

  /**
   * base
   */

  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  u32 pw_buf0[4];
  u32 pw_buf1[4];

  pw_buf0[0] = pws[gid].i[0];
  pw_buf0[1] = pws[gid].i[1];
  pw_buf0[2] = pws[gid].i[2];
  pw_buf0[3] = pws[gid].i[3];
  pw_buf1[0] = pws[gid].i[4];
  pw_buf1[1] = pws[gid].i[5];
  pw_buf1[2] = pws[gid].i[6];
  pw_buf1[3] = pws[gid].i[7];

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * seed
   */

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u64x hash = MurmurHash64A (w, out_len);

    const u32x r0 = l32_from_64(hash);
    const u32x r1 = h32_from_64(hash);
    const u32x z = 0;

    COMPARE_M_SIMD (r0, r1, z, z);
  }
}

KERNEL_FQ void m90000_m08 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90000_m16 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90000_s04 (KERN_ATTR_RULES ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);

  /**
   * base
   */

  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  u32 pw_buf0[4];
  u32 pw_buf1[4];

  pw_buf0[0] = pws[gid].i[0];
  pw_buf0[1] = pws[gid].i[1];
  pw_buf0[2] = pws[gid].i[2];
  pw_buf0[3] = pws[gid].i[3];
  pw_buf1[0] = pws[gid].i[4];
  pw_buf1[1] = pws[gid].i[5];
  pw_buf1[2] = pws[gid].i[6];
  pw_buf1[3] = pws[gid].i[7];

  const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * digest
   */

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

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u64x hash = MurmurHash64A (w, out_len);

    const u32x r0 = l32_from_64(hash);
    const u32x r1 = h32_from_64(hash);
    const u32x z = 0;

    COMPARE_S_SIMD (r0, r1, z, z);
  }
}

KERNEL_FQ void m90000_s08 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90000_s16 (KERN_ATTR_RULES ())
{
}
