/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//too much register pressure
//#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include M2S(INCLUDE_PATH/inc_vendor.h)
#include M2S(INCLUDE_PATH/inc_types.h)
#include M2S(INCLUDE_PATH/inc_platform.cl)
#include M2S(INCLUDE_PATH/inc_common.cl)
#include M2S(INCLUDE_PATH/inc_scalar.cl)
#endif

DECLSPEC u64 MurmurHash64A (const u8 *data, const u32 len)
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

  const u32 endpos = len - (len & 7);

  //printf("endpos = %d\n", endpos);

  // Loop over blocks of 8 bytes
  u32 i = 0;
  while (i != endpos) {
    u64x k = ((u64) data[i])
      | ((u64) data[i + 1] << 8)
      | ((u64) data[i + 2] << 16)
      | ((u64) data[i + 3] << 24)
      | ((u64) data[i + 4] << 32)
      | ((u64) data[i + 5] << 40)
      | ((u64) data[i + 6] << 48)
      | ((u64) data[i + 7] << 56);
  
    k *= M;
    k ^= k >> R;
    k *= M;

    hash ^= k;
    hash *= M;

    i += 8;
  }

  //printf("BEFORE_OVERFLOW = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  // Overflow

  const u32 overflow = len & 7;

  //printf("OVERFLOW = %d\n", overflow);

  //printf("data = %c%c%c%c%c%c%c%c%c%c\n", data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9]);

  //printf("i = %d\n", i);
  //printf("data[i] data[i + 1] = %08x%08x\n", data[i], data[i + 1]);

  switch (overflow) {
    case 7: hash ^= ((u64) data[i + 6]) << 48;
    case 6: hash ^= ((u64) data[i + 5]) << 40;
    case 5: hash ^= ((u64) data[i + 4]) << 32;
    case 4: hash ^= ((u64) data[i + 3]) << 24;
    case 3: hash ^= ((u64) data[i + 2]) << 16;
    case 2: hash ^= ((u64) data[i + 1]) << 8;
    case 1: hash ^= ((u64) data[i]);
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

  //printf("final hash = %08x%08x\n", h32_from_64(hash), l32_from_64(hash));

  return hash;
}



KERNEL_FQ void m90010_mxx (KERN_ATTR_BASIC ())
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

  u8 combined_buf[256] = {0};
  const u8 *comb_ptr = combined_buf;
  u32 offset = 0;

  // copy bytes from left buf
  GLOBAL_AS u8 *l_buf = (GLOBAL_AS u8*) pws[gid].i;
  
  for (u32 i = 0; i < pws[gid].pw_len; i++) {
    combined_buf[offset] = l_buf[i];
    offset++;
  }

  //printf("offset = %d\n", offset);

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    // copy bytes from right buf
    GLOBAL_AS u8 *r_buf = (GLOBAL_AS u8*) combs_buf[il_pos].i;
    for (u32 i = 0; i < combs_buf[il_pos].pw_len; i++) {
      combined_buf[offset + i] = r_buf[i];
    }

    const u32 total_len = pws[gid].pw_len + combs_buf[il_pos].pw_len;

    //const u32 *combined_ptr = (u32*) combined_buf;
    const u64 hash = MurmurHash64A (comb_ptr, total_len);

    const u32 r0 = l32_from_64 (hash);
    const u32 r1 = h32_from_64 (hash);
    const u32 z = 0;

    COMPARE_M_SCALAR (r0, r1, z, z);
  }
}

KERNEL_FQ void m90010_sxx (KERN_ATTR_BASIC ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);
  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

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

  u8 combined_buf[256] = {0};
  const u8 *comb_ptr = combined_buf;
  u32 offset = 0;

  // copy bytes from left buf
  GLOBAL_AS u8 *l_buf = (GLOBAL_AS u8*) pws[gid].i;
  
  for (u32 i = 0; i < pws[gid].pw_len; i++) {
    combined_buf[offset] = l_buf[i];
    offset++;
  }

  

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    // copy bytes from right buf
    GLOBAL_AS u8 *r_buf = (GLOBAL_AS u8*) combs_buf[il_pos].i;
    for (u32 i = 0; i < combs_buf[il_pos].pw_len; i++) {
      combined_buf[offset + i] = r_buf[i];
    }

    const u32 total_len = pws[gid].pw_len + combs_buf[il_pos].pw_len;

    //const u32 *combined_ptr = (u32*) combined_buf;
    const u64 hash = MurmurHash64A (comb_ptr, total_len);

    const u32 r0 = l32_from_64 (hash);
    const u32 r1 = h32_from_64 (hash);
    const u32 z = 0;

    COMPARE_S_SCALAR (r0, r1, z, z);
  }
}
