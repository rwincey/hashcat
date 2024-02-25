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

DECLSPEC u64 wrapping_mul (u64 a, u64 b)
{
  return (a * b) % pow(2, 64);
}

DECLSPEC u64 MurmurHash64A (const u32 seed, PRIVATE_AS const u32 *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  u64 hash = seed ^ wrapping_mul(len, M);

  const u32 endpos = len - (len & 7);

  // Loop over blocks of 8
  if (endpos >= 8)
  {
    for (u32 i = 0; i < endpos; i += 8)
    {
      u64 k = data[i]
        | data[i + 1] << 8
        | data[i + 2] << 16
        | data[i + 3] << 24
        | data[i + 4] << 32
        | data[i + 5] << 40
        | data[i + 6] << 48
        | data[i + 7] << 56;

      k = wrapping_mul(k, M);
      k ^= k >> R;
      k = wrapping_mul(k, M);

      hash ^= k;
      hash = wrapping_mul(hash, M);
    }
  }

  // Overflow
  const u32 overflow = length & 7;

  if (overflow == 7)
  {
    hash ^= data[i + 6] << 48;
  }
  if (overflow >= 6)
  {
    hash ^= data[i + 5] << 40;
  }
  if (overflow >= 5)
  {
    hash ^= data[i + 4] << 32;
  }
  if (overflow >= 4)
  {
    hash ^= data[i + 3] << 24;
  }
  if (overflow >= 3)
  {
    hash ^= data[i + 2] << 16;
  }
  if (overflow >= 2)
  {
    hash ^= data[i + 1] << 8;
  }
  if (overflow >= 1)
  {
    hash ^= data[i];
  }
  if (overflow > 0)
  {
    hash = wrapping_mul(hash, M);
  }

  hash ^= hash >> R;
  hash = wrapping_mul(hash, M)
  hash ^= hash >> R;

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

  const u32 seed = salt_bufs[SALT_POS_HOST].salt_buf[0];

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u64x hash = MurmurHash64A (seed, w, out_len);

    const u32x r0 = (hash >> 32) & 0xffffffff;
    const u32x r1 = (hash) & 0xffffffff;
    const u32x r2 = 0;
    const u32x r3 = 0;

    COMPARE_M_SIMD (r0, r1, r2, r3);
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
    0,
    0,
    0
  };

  /**
   * seed
   */

  const u32 seed = salt_bufs[SALT_POS_HOST].salt_buf[0];

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u32x hash = MurmurHash64A (seed, w, out_len);

    const u32x r0 = (hash >> 32) & 0xffffffff;
    const u32x r1 = (hash) & 0xffffffff;
    const u32x r2 = 0;
    const u32x r3 = 0;

    COMPARE_S_SIMD (r0, r1, r2, r3);
  }
}

KERNEL_FQ void m90000_s08 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90000_s16 (KERN_ATTR_RULES ())
{
}
