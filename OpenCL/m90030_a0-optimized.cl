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

DECLSPEC u32 MurmurHash64A_32 (PRIVATE_AS const u32 *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  //Initialize hash
  u64 hash = 0 ^ (len * M);

  //printf("len = %d\n", len);
  //printf("INITIAL = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  // 2 for each u64 block
  const u32 num_blocks = (len / 8) * 2;

  //printf("num_blocks = %d\n", num_blocks);

  // Loop over blocks of 8 bytes
  u32 i = 0;
  while (i < num_blocks) {
    u64 k = hl32_to_64 (data[i + 1], data[i]);

    k *= M;
    k ^= k >> R;
    k *= M;

    hash ^= k;
    hash *= M;

    i += 2;
  }

  //printf("BEFORE_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  // Overflow

  const u32 overflow = len & 7;

  //printf("OVERFLOW = %d\n", overflow);

  //printf("data = %08x%08x%08x%08x%08x%08x%08x%08x%08x%08x\n", data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9]);

  //printf("i = %d\n", i);
  //printf("data[i] data[i + 1] = %08x%08x\n", data[i], data[i + 1]);

  // can we turn this into a single xor

  if ((overflow > 0) &&  (overflow <= 4)) {
    //printf("Overflow case 1\n");
    hash ^= hl32_to_64 (data[i + 1], data[i]);
    hash *= M;
  }

  else if (overflow > 4) {
    //printf("Overflow case 2\n");
    //printf("tmp = %08x%08x\n", h32_from_64(tmp), l32_from_64(tmp));
    hash ^= hl32_to_64 (data[i + 1], data[i]);
    hash *= M;
  }

  //printf("AFTER_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  //printf("hash = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  return (u32) (hash >> 32);
}



KERNEL_FQ void m90030_m04 (KERN_ATTR_RULES ())
{
  //printf("Hello world m90030_m04\n");
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

  // max pw len of 32
  const u32 pw_len = (pws[gid].pw_len > 32) ? 32 : pws[gid].pw_len;

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u32x hash = MurmurHash64A_32 (w, out_len);

    //printf("hash = %08x\n", hash);

    const u32x z = 0;

    COMPARE_M_SIMD (hash, z, z, z);
  }
}

KERNEL_FQ void m90030_m08 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90030_m16 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90030_s04 (KERN_ATTR_RULES ())
{
  //printf("Hello world m90030_s04\n");
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

  // max pw len of 32
  const u32 pw_len = (pws[gid].pw_len > 32) ? 32 : pws[gid].pw_len;

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
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    u32x w[16] = { 0 };

    const u32x out_len = apply_rules_vect_optimized (pw_buf0, pw_buf1, pw_len, rules_buf, il_pos, w + 0, w + 4);

    u32x hash = MurmurHash64A_32 (w, out_len);

    const u32x z = 0;

    COMPARE_S_SIMD (hash, z, z, z);
  }
}

KERNEL_FQ void m90030_s08 (KERN_ATTR_RULES ())
{
}

KERNEL_FQ void m90030_s16 (KERN_ATTR_RULES ())
{
}
