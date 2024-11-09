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
#include M2S(INCLUDE_PATH/inc_rp.h)
#include M2S(INCLUDE_PATH/inc_rp.cl)
#include M2S(INCLUDE_PATH/inc_scalar.cl)
#endif

DECLSPEC u64 MurmurHash64A (PRIVATE_AS const u32 *data, const u32 len)
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

  //u64 test = hl32_to_64 (0x0a16869e, 0xcb107f54);
  //printf("hl32_to_64 test = %08x%08x\n", h32_from_64(test), l32_from_64(test));

  //printf("AFTER_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  //printf("hash = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  return hash;
}

KERNEL_FQ void m90010_mxx (KERN_ATTR_RULES ())
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

  COPY_PW (pws[gid]);

  //if ((gid == 0) && (lid == 0)) printf ("%016lx\n", pw_buf0);
  //printf("Hello world\n");

  /**
   * salt
   */

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    pw_t tmp = PASTE_PW;

    tmp.pw_len = apply_rules (rules_buf[il_pos].cmds, tmp.i, tmp.pw_len);

    //if ((gid == 0) && (lid == 0) && (il_pos == 0)) printf ("tmp.i = %08x, tmp.pw_len = %x\n", *tmp.i, tmp.pw_len);

    u64 hash = MurmurHash64A (tmp.i, tmp.pw_len);

    //if ((gid == 0) && (lid == 0)) printf ("hash = %lu\n", hash);

    //if (il_pos == 0) printf("tmp.i = %lu, tmp.pw_len = %lu\n", tmp.i, tmp.pw_len);
    //if (il_pos == 0) printf("seed = %llu\n", seed);

    const u32 r0 = l32_from_64(hash);
    const u32 r1 = h32_from_64(hash);
    const u32 z = 0;

    COMPARE_M_SCALAR (r0, r1, z, z);
  }
}

KERNEL_FQ void m90010_sxx (KERN_ATTR_RULES ())
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

  /**
   * salt
   */

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
   * base
   */

  COPY_PW (pws[gid]);

  //printf ("%016lx\n", seed);
  //printf("Hello world\n");

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    pw_t tmp = PASTE_PW;

    tmp.pw_len = apply_rules (rules_buf[il_pos].cmds, tmp.i, tmp.pw_len);

    u64 hash = MurmurHash64A (tmp.i, tmp.pw_len);

    const u32 r0 = l32_from_64 (hash);
    const u32 r1 = h32_from_64 (hash);
    const u32 z = 0;

    COMPARE_S_SCALAR (r0, r1, z, z);
  }
}
