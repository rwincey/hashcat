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
#endif

DECLSPEC u64 MurmurHash64A (const u32 seed, PRIVATE_AS const u32 *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  //if ((gid == 0) && (lid == 0)) printf ("%016x\n", data);
  //printf ("%016llx\n", test);

  u64 hash = seed ^ (len * M);
  
  const u32 endpos = len - (len & 7);

  // Loop over blocks of 8
  u32 i = 0;
  if (endpos >= 8)
  {
    for (i = 0; i < endpos; i += 8)
    {
      u64 k = data[i]
        | data[i + 1] << 8
        | data[i + 2] << 16
        | data[i + 3] << 24
        | data[i + 4] << 32
        | data[i + 5] << 40
        | data[i + 6] << 48
        | data[i + 7] << 56;

      k *= M;
      k ^= k >> R;
      k *= M;

      hash ^= k;
      hash *= M;
    }
  }

  // Overflow
  const u32 overflow = len & 7;

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
    hash *= M;
  }

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  return hash;
}

KERNEL_FQ void m90000_mxx (KERN_ATTR_RULES ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  /**
   * base
   */

  COPY_PW (pws[gid]);
  u32 pw_buf0[4];
  u32 pw_buf1[4];

  //if ((gid == 0) && (lid == 0)) printf ("%08x\n", pw_buf0);

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

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    pw_t tmp = PASTE_PW;

    tmp.pw_len = apply_rules (rules_buf[il_pos].cmds, tmp.i, tmp.pw_len);

    u64x hash = MurmurHash64A (seed, tmp, tmp.pw_len);

    //if ((gid == 0) && (lid == 0)) printf ("%016llx\n", hash);

    const u32x r0 = (hash >> 32) & 0xffffffff;
    const u32x r1 = (hash) & 0xffffffff;
    const u32x r2 = 0;
    const u32x r3 = 0;

    COMPARE_M_SIMD (r0, r1, r2, r3);
  }
}

KERNEL_FQ void m90000_sxx (KERN_ATTR_RULES ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  /**
   * seed
   */

  const u32 seed = salt_bufs[SALT_POS_HOST].salt_buf[0];

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R0],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R1],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R2],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  COPY_PW (pws[gid]);

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    pw_t tmp = PASTE_PW;

    tmp.pw_len = apply_rules (rules_buf[il_pos].cmds, tmp.i, tmp.pw_len);

    u64x hash = MurmurHash64A (seed, tmp.i, tmp.pw_len);

    const u32 r0 = (hash >> 32) & 0xffffffff;
    const u32 r1 = (hash) & 0xffffffff;
    const u32 r2 = 0;
    const u32 r3 = 0;

    COMPARE_S_SCALAR (r0, r1, r2, r3);
  }
}
