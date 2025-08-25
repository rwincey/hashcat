/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include M2S(INCLUDE_PATH/inc_vendor.h)
#include M2S(INCLUDE_PATH/inc_types.h)
#include M2S(INCLUDE_PATH/inc_platform.cl)
#include M2S(INCLUDE_PATH/inc_common.cl)
#include M2S(INCLUDE_PATH/inc_simd.cl)
#include M2S(INCLUDE_PATH/inc_hash_sha256.cl)
#endif

#define COMPARE_S M2S(INCLUDE_PATH/inc_comp_single.cl)
#define COMPARE_M M2S(INCLUDE_PATH/inc_comp_multi.cl)

typedef struct shiro1_sha256_tmp
{
  u32 dgst[8];

} shiro1_sha256_tmp_t;

KERNEL_FQ KERNEL_FA void m12175_init (KERN_ATTR_TMPS (shiro1_sha256_tmp_t))
{
  const u32 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  sha256_ctx_t ctx;

  sha256_init (&ctx);

  sha256_update_global_swap (&ctx, salt_bufs[SALT_POS_HOST].salt_buf, salt_bufs[SALT_POS_HOST].salt_len);

  sha256_update_global_swap (&ctx, pws[gid].i, pws[gid].pw_len);

  sha256_final (&ctx);

  tmps[gid].dgst[ 0] = ctx.h[0];
  tmps[gid].dgst[ 1] = ctx.h[1];
  tmps[gid].dgst[ 2] = ctx.h[2];
  tmps[gid].dgst[ 3] = ctx.h[3];
  tmps[gid].dgst[ 4] = ctx.h[4];
  tmps[gid].dgst[ 5] = ctx.h[5];
  tmps[gid].dgst[ 6] = ctx.h[6];
  tmps[gid].dgst[ 7] = ctx.h[7];
}

KERNEL_FQ KERNEL_FA void m12175_loop(KERN_ATTR_TMPS (shiro1_sha256_tmp_t))
{
  const u32 gid = get_global_id(0);

  if (gid >= GID_CNT) return;

  u32 w0[4];
  u32 w1[4];
  u32 w2[4];
  u32 w3[4];
  u32 w4[4];
  u32 w5[4];
  u32 w6[4];
  u32 w7[4];

  w0[0] = tmps[gid].dgst[ 0];
  w0[1] = tmps[gid].dgst[ 1];
  w0[2] = tmps[gid].dgst[ 2];
  w0[3] = tmps[gid].dgst[ 3];
  w1[0] = tmps[gid].dgst[ 4];
  w1[1] = tmps[gid].dgst[ 5];
  w1[2] = tmps[gid].dgst[ 6];
  w1[3] = tmps[gid].dgst[ 7];
  w2[0] = 0x80000000;
  w2[1] = 0;
  w2[2] = 0;
  w2[3] = 0;
  w3[0] = 0;
  w3[1] = 0;
  w3[2] = 0;
  w3[3] = 32 * 8;
  w4[0] = 0;
  w4[1] = 0;
  w4[2] = 0;
  w4[3] = 0;
  w5[0] = 0;
  w5[1] = 0;
  w5[2] = 0;
  w5[3] = 0;
  w6[0] = 0;
  w6[1] = 0;
  w6[2] = 0;
  w6[3] = 0;
  w7[0] = 0;
  w7[1] = 0;
  w7[2] = 0;
  w7[3] = 0;

  for (u32 i = 0; i < LOOP_CNT; i++)
  {
    u32 dgst[8];

    dgst[0] = SHA256M_A;
    dgst[1] = SHA256M_B;
    dgst[2] = SHA256M_C;
    dgst[3] = SHA256M_D;
    dgst[4] = SHA256M_E;
    dgst[5] = SHA256M_F;
    dgst[6] = SHA256M_G;
    dgst[7] = SHA256M_H;

    sha256_transform (w0, w1, w2, w3, w4, w5, w6, w7, dgst);

    w0[0] = dgst[0];
    w0[1] = dgst[1];
    w0[2] = dgst[2];
    w0[3] = dgst[3];
    w1[0] = dgst[4];
    w1[1] = dgst[5];
    w1[2] = dgst[6];
    w1[3] = dgst[7];
  }

  tmps[gid].dgst[ 0] = w0[0];
  tmps[gid].dgst[ 1] = w0[1];
  tmps[gid].dgst[ 2] = w0[2];
  tmps[gid].dgst[ 3] = w0[3];
  tmps[gid].dgst[ 4] = w1[0];
  tmps[gid].dgst[ 5] = w1[1];
  tmps[gid].dgst[ 6] = w1[2];
  tmps[gid].dgst[ 7] = w1[3];
}

KERNEL_FQ KERNEL_FA void m12175_comp (KERN_ATTR_TMPS (shiro1_sha256_tmp_t))
{
  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  const u64 lid = get_local_id (0);

  const u32 r0 = tmps[gid].dgst[1];
  const u32 r1 = tmps[gid].dgst[0];
  const u32 r2 = tmps[gid].dgst[3];
  const u32 r3 = tmps[gid].dgst[2];

  #define il_pos 0

  #ifdef KERNEL_STATIC
  #include COMPARE_M
  #endif
}
