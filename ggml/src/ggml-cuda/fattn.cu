//
// Copyright (C) 2023-2024 The ggml authors
// Copyright (C) 2024 Iwan Kawrakow
// MIT license
// SPDX-License-Identifier: MIT
//

#include "common.cuh"
#include "fattn-common.cuh"
#include "fattn-tile-f16.cuh"
#include "fattn-tile-f32.cuh"
#include "fattn-vec-f16.cuh"
#include "fattn-vec-f32.cuh"
#include "fattn-wmma-f16.cuh"
#include "fattn.cuh"

#include <cstdint>

static void ggml_cuda_flash_attn_ext_wmma_f16(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    const ggml_tensor * KQV = dst;
    const ggml_tensor * Q   = dst->src[0];
    const ggml_tensor * V   = dst->src[2];

    if (Q->ne[0] != V->ne[0]) {
        if (!((Q->ne[0] == 192 && V->ne[0] == 128) || (Q->ne[0] == 576 && V->ne[0] == 512))) {
            fprintf(stderr, "======================= %s: Unhandled head size combination %d, %d\n", __func__, (int)Q->ne[0], (int)V->ne[0]);
            GGML_ABORT("fatal error");
        }
    }

    const int32_t precision = KQV->op_params[3];

    if (precision != GGML_PREC_DEFAULT) {
        if (Q->ne[1] <= 32 || Q->ne[0] > 128) {
            constexpr int cols_per_block = 16;
            switch (Q->ne[0]) {
                case 64:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 64, 64, cols_per_block, float>(ctx, dst);
                    break;
                case 80:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 80, 80, cols_per_block, float>(ctx, dst);
                    break;
                case 96:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 96, 96, cols_per_block, float>(ctx, dst);
                    break;
                case 112:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<112, 112, cols_per_block, float>(ctx, dst);
                    break;
                case 128:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<128, 128, cols_per_block, float>(ctx, dst);
                    break;
                case 256:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<256, 256, cols_per_block, float>(ctx, dst);
                    break;
                case 192:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<192, 128, cols_per_block, float>(ctx, dst);
                    break;
                default:
                    fprintf(stderr, "======================= %s: Unhandled head size %d\n", __func__, (int)Q->ne[0]);
                    GGML_ABORT("fatal error");
                    break;
            }
        } else {
            constexpr int cols_per_block = 32;
            switch (Q->ne[0]) {
                case 64:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 64, 64, cols_per_block, float>(ctx, dst);
                    break;
                case 80:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 80, 80, cols_per_block, float>(ctx, dst);
                    break;
                case 96:
                    ggml_cuda_flash_attn_ext_wmma_f16_case< 96, 96, cols_per_block, float>(ctx, dst);
                    break;
                case 112:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<112, 112, cols_per_block, float>(ctx, dst);
                    break;
                case 128:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<128, 128, cols_per_block, float>(ctx, dst);
                    break;
                case 192:
                    ggml_cuda_flash_attn_ext_wmma_f16_case<192, 128, cols_per_block, float>(ctx, dst);
                    break;
                // case 256:
                //     ggml_cuda_flash_attn_ext_wmma_f16_case<128, cols_per_block, float>(ctx, dst);
                //     break;
                default:
                    fprintf(stderr, "======================= %s: Unhandled head size %d\n", __func__, (int)Q->ne[0]);
                    GGML_ABORT("fatal error");
                    break;
            }
        }
        return;
    }

    if (Q->ne[1] <= 8 && Q->ne[0] % WARP_SIZE == 0) {
        constexpr int cols_per_block = 8;
        switch (Q->ne[0]) {
            case 64:
                ggml_cuda_flash_attn_ext_wmma_f16_case< 64, 64, cols_per_block, half>(ctx, dst);
                break;
            case 96:
                ggml_cuda_flash_attn_ext_wmma_f16_case< 96, 96, cols_per_block, half>(ctx, dst);
                break;
            case 128:
                ggml_cuda_flash_attn_ext_wmma_f16_case<128, 128, cols_per_block, half>(ctx, dst);
                break;
            case 192:
                ggml_cuda_flash_attn_ext_wmma_f16_case<192, 128, cols_per_block, half>(ctx, dst);
                break;
            case 256:
                ggml_cuda_flash_attn_ext_wmma_f16_case<256, 256, cols_per_block, half>(ctx, dst);
                break;
            default:
                fprintf(stderr, "======================= %s: Unhandled head size %d\n", __func__, (int)Q->ne[0]);
                GGML_ABORT("fatal error");
                break;
        }
        return;
    }

    if (Q->ne[1] <= 32) {
        constexpr int cols_per_block = 16;
        switch (Q->ne[0]) {
            case 64:
                ggml_cuda_flash_attn_ext_wmma_f16_case< 64, 64, cols_per_block, half>(ctx, dst);
                break;
            case 80:
                ggml_cuda_flash_attn_ext_wmma_f16_case< 80, 80, cols_per_block, half>(ctx, dst);
                break;
            case 96:
                ggml_cuda_flash_attn_ext_wmma_f16_case< 96, 96, cols_per_block, half>(ctx, dst);
                break;
            case 112:
                ggml_cuda_flash_attn_ext_wmma_f16_case<112, 112, cols_per_block, half>(ctx, dst);
                break;
            case 128:
                ggml_cuda_flash_attn_ext_wmma_f16_case<128, 128, cols_per_block, half>(ctx, dst);
                break;
            case 192:
                ggml_cuda_flash_attn_ext_wmma_f16_case<192, 128, cols_per_block, half>(ctx, dst);
                break;
            case 256:
                ggml_cuda_flash_attn_ext_wmma_f16_case<256, 256, cols_per_block, half>(ctx, dst);
                break;
            default:
                fprintf(stderr, "======================= %s: Unhandled head size %d\n", __func__, (int)Q->ne[0]);
                GGML_ABORT("fatal error");
                break;
        }
        return;
    }

    constexpr int cols_per_block = 32;
    switch (Q->ne[0]) {
        case 64:
            ggml_cuda_flash_attn_ext_wmma_f16_case< 64, 64, cols_per_block, half>(ctx, dst);
            break;
        case 80:
            ggml_cuda_flash_attn_ext_wmma_f16_case< 80, 80, cols_per_block, half>(ctx, dst);
            break;
        case 96:
            ggml_cuda_flash_attn_ext_wmma_f16_case< 96, 96, cols_per_block, half>(ctx, dst);
            break;
        case 112:
            ggml_cuda_flash_attn_ext_wmma_f16_case<112, 112, cols_per_block, half>(ctx, dst);
            break;
        case 128:
            ggml_cuda_flash_attn_ext_wmma_f16_case<128, 128, cols_per_block, half>(ctx, dst);
            break;
        case 192:
            ggml_cuda_flash_attn_ext_wmma_f16_case<192, 128, cols_per_block, half>(ctx, dst);
            break;
        case 256:
            ggml_cuda_flash_attn_ext_wmma_f16_case<256, 256, cols_per_block, half>(ctx, dst);
            break;
        default:
            fprintf(stderr, "======================= %s: Unhandled head size %d\n", __func__, (int)Q->ne[0]);
            GGML_ABORT("fatal error");
            break;
    }
}
#define FATTN_VEC_F16_CASE(D, type_K, type_V)                               \
    if (Q->ne[0] == (D) && K->type == (type_K) && V->type == (type_V)) {    \
        ggml_cuda_flash_attn_ext_vec_f16_case<D, D, type_K, type_V>(ctx, dst); \
        return;                                                             \
    }                                                                       \

#define FATTN_VEC_F16_CASE_DKDV(Dk, Dv, type_K, type_V)                               \
    if (Q->ne[0] == (Dk) && V->ne[0] == Dv && K->type == (type_K) && V->type == (type_V)) {    \
        ggml_cuda_flash_attn_ext_vec_f16_case<Dk, Dv, type_K, type_V>(ctx, dst); \
        return;                                                             \
    }                                                                       \

static void ggml_cuda_flash_attn_ext_vec_f16(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    ggml_tensor * Q = dst->src[0];
    ggml_tensor * K = dst->src[1];
    ggml_tensor * V = dst->src[2];

#ifdef GGML_CUDA_FA_ALL_QUANTS
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_F16 )

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q4_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q4_1)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q5_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q5_1)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q8_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16,  GGML_TYPE_F16)

    FATTN_VEC_F16_CASE(256, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(256, GGML_TYPE_Q8_0,GGML_TYPE_Q8_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_IQ4_NL, GGML_TYPE_IQ4_NL)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0,   GGML_TYPE_IQ4_NL)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q6_0,   GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q6_0,   GGML_TYPE_Q6_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0,   GGML_TYPE_Q6_0)

    FATTN_VEC_F16_CASE_DKDV(192, 128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE_DKDV(192, 128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)
#else
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)

    FATTN_VEC_F16_CASE( 64, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(256, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE(256, GGML_TYPE_Q8_0,GGML_TYPE_Q8_0)

    FATTN_VEC_F16_CASE(128, GGML_TYPE_IQ4_NL, GGML_TYPE_IQ4_NL)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0,   GGML_TYPE_IQ4_NL)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q6_0,   GGML_TYPE_Q5_0)
    FATTN_VEC_F16_CASE(128, GGML_TYPE_Q8_0,   GGML_TYPE_Q6_0)

    FATTN_VEC_F16_CASE_DKDV(192, 128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F16_CASE_DKDV(192, 128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)

#endif // GGML_CUDA_FA_ALL_QUANTS

    on_no_fattn_vec_case(Q->ne[0], V->ne[0]);
}

#define FATTN_VEC_F32_CASE(D, type_K, type_V)                               \
    if (Q->ne[0] == (D) && K->type == (type_K) && V->type == (type_V)) {    \
        ggml_cuda_flash_attn_ext_vec_f32_case<D, D, type_K, type_V>(ctx, dst); \
        return;                                                             \
    }                                                                       \

#define FATTN_VEC_F32_CASE_DKDV(Dk, Dv, type_K, type_V)                               \
    if (Q->ne[0] == (Dk) && V->ne[0] == Dv && K->type == (type_K) && V->type == (type_V)) {    \
        ggml_cuda_flash_attn_ext_vec_f32_case<Dk, Dv, type_K, type_V>(ctx, dst); \
        return;                                                             \
    }                                                                       \

static void ggml_cuda_flash_attn_ext_vec_f32(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    ggml_tensor * Q = dst->src[0];
    ggml_tensor * K = dst->src[1];
    ggml_tensor * V = dst->src[2];

#ifdef GGML_CUDA_FA_ALL_QUANTS
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_F16)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q4_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q4_0)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q4_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q4_1)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q5_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q5_0)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q5_1)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q5_1)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_Q8_0)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_1, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_0, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q5_1, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16,  GGML_TYPE_F16)

    FATTN_VEC_F32_CASE(256, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(256, GGML_TYPE_Q8_0,GGML_TYPE_Q8_0)

    FATTN_VEC_F32_CASE_DKDV(192, 128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE_DKDV(192, 128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)
#else
    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q4_0, GGML_TYPE_Q4_0)

    FATTN_VEC_F32_CASE(128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)

    FATTN_VEC_F32_CASE( 64, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(256, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE(256, GGML_TYPE_Q8_0,GGML_TYPE_Q8_0)

    FATTN_VEC_F32_CASE_DKDV(192, 128, GGML_TYPE_F16, GGML_TYPE_F16)
    FATTN_VEC_F32_CASE_DKDV(192, 128, GGML_TYPE_Q8_0, GGML_TYPE_Q8_0)
#endif // GGML_CUDA_FA_ALL_QUANTS

    on_no_fattn_vec_case(Q->ne[0], V->ne[0]);
}

void ggml_cuda_flash_attn_ext(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    const ggml_tensor * KQV = dst;
    const ggml_tensor * Q   = dst->src[0];

    ggml_cuda_set_device(ctx.device);
    const int cc = ggml_cuda_info().devices[ggml_cuda_get_device()].cc;
    const int32_t precision = KQV->op_params[3];

    // On AMD the tile kernels perform poorly, use the vec kernel instead:
    if (cc >= CC_OFFSET_AMD) {
        if (precision == GGML_PREC_DEFAULT && fast_fp16_available(cc)) {
            ggml_cuda_flash_attn_ext_vec_f16(ctx, dst);
        } else {
            ggml_cuda_flash_attn_ext_vec_f32(ctx, dst);
        }
        return;
    }

    if (!fast_fp16_available(cc)) {
        if (Q->ne[1] <= 8) {
            ggml_cuda_flash_attn_ext_vec_f32(ctx, dst);
        } else {
            ggml_cuda_flash_attn_ext_tile_f32(ctx, dst);
        }
        return;
    }

    if (!fp16_mma_available(cc)) {
        if (Q->ne[1] <= 8) {
            ggml_cuda_flash_attn_ext_vec_f16(ctx, dst);
        } else {
            ggml_cuda_flash_attn_ext_tile_f16(ctx, dst);
        }
        return;
    }

    if (Q->ne[1] == 1 && Q->ne[0] % (2*WARP_SIZE) == 0) {
        if (precision == GGML_PREC_DEFAULT) {
            ggml_cuda_flash_attn_ext_vec_f16(ctx, dst);
            return;
        } else if(Q->ne[0] <= 128) {
            ggml_cuda_flash_attn_ext_vec_f32(ctx, dst);
            return;
        }
    }

    ggml_cuda_flash_attn_ext_wmma_f16(ctx, dst);
}
