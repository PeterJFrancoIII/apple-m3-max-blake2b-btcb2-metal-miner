#include <metal_stdlib>
using namespace metal;

typedef ulong u64;

constant u64 IV[8] = {
    0x6a09e667f3bcc908UL, 0xbb67ae8584caa73bUL,
    0x3c6ef372fe94f82bUL, 0xa54ff53a5f1d36f1UL,
    0x510e527fade682d1UL, 0x9b05688c2b3e6c1fUL,
    0x1f83d9abfb41bd6bUL, 0x5be0cd19137e2179UL
};

constant uchar SIGMA[12][16] = {
    { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15},
    {14,10, 4, 8, 9,15,13, 6, 1,12, 0, 2,11, 7, 5, 3},
    {11, 8,12, 0, 5, 2,15,13,10,14, 3, 6, 7, 1, 9, 4},
    { 7, 9, 3, 1,13,12,11,14, 2, 6, 5,10, 4, 0,15, 8},
    { 9, 0, 5, 7, 2, 4,10,15,14, 1,11,12, 6, 8, 3,13},
    { 2,12, 6,10, 0,11, 8, 3, 4,13, 7, 5,15,14, 1, 9},
    {12, 5, 1,15,14,13, 4,10, 0, 7, 6, 3, 9, 2, 8,11},
    {13,11, 7,14,12, 1, 3, 9, 5, 0,15, 4, 8, 6, 2,10},
    { 6,15,14, 9,11, 3, 0, 8,12, 2,13, 7, 1, 4,10, 5},
    {10, 2, 8, 4, 7, 6, 1, 5,15,11, 9,14, 3,12,13, 0},
    { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15},
    {14,10, 4, 8, 9,15,13, 6, 1,12, 0, 2,11, 7, 5, 3}
};

inline u64 rotr64(u64 x, uint n) {
    return (x >> n) | (x << (64u - n));
}

inline void G(thread u64 &a, thread u64 &b, thread u64 &c, thread u64 &d,
              u64 x, u64 y) {
    a = a + b + x;
    d = rotr64(d ^ a, 32);
    c = c + d;
    b = rotr64(b ^ c, 24);
    a = a + b + y;
    d = rotr64(d ^ a, 16);
    c = c + d;
    b = rotr64(b ^ c, 63);
}

inline void blake2b256_80(thread const u64 m[16], thread u64 out[4]) {
    u64 h0 = IV[0] ^ 0x01010020UL; // digest=32, key=0, fanout=1, depth=1
    u64 h1 = IV[1], h2 = IV[2], h3 = IV[3];
    u64 h4 = IV[4], h5 = IV[5], h6 = IV[6], h7 = IV[7];

    u64 v0=h0, v1=h1, v2=h2, v3=h3, v4=h4, v5=h5, v6=h6, v7=h7;
    u64 v8=IV[0], v9=IV[1], v10=IV[2], v11=IV[3];
    u64 v12=IV[4] ^ 80UL, v13=IV[5], v14=IV[6] ^ ~0UL, v15=IV[7];

    for (uint r=0; r<12; ++r) {
        constant uchar *s = SIGMA[r];
        G(v0,v4,v8 ,v12,m[s[0]], m[s[1]]);
        G(v1,v5,v9 ,v13,m[s[2]], m[s[3]]);
        G(v2,v6,v10,v14,m[s[4]], m[s[5]]);
        G(v3,v7,v11,v15,m[s[6]], m[s[7]]);
        G(v0,v5,v10,v15,m[s[8]], m[s[9]]);
        G(v1,v6,v11,v12,m[s[10]],m[s[11]]);
        G(v2,v7,v8 ,v13,m[s[12]],m[s[13]]);
        G(v3,v4,v9 ,v14,m[s[14]],m[s[15]]);
    }

    out[0] = h0 ^ v0 ^ v8;
    out[1] = h1 ^ v1 ^ v9;
    out[2] = h2 ^ v2 ^ v10;
    out[3] = h3 ^ v3 ^ v11;
}

// BTCB2 / Sia-style 80-byte work layout:
// words 0..3: prevhash, word 4: nonce, word 5: ntime,
// words 6..9: work root, words 10..15: zero padding.
// `static_words` contains m0..m3 and m5..m9 packed as 9 u64 values:
// [m0,m1,m2,m3,m5,m6,m7,m8,m9].
kernel void m3b2_blake2b256(
    constant u64 *static_words [[buffer(0)]],
    constant u64 &nonce_base [[buffer(1)]],
    device u64 *digests [[buffer(2)]],
    uint gid [[thread_position_in_grid]])
{
    u64 m[16];
    m[0]=static_words[0]; m[1]=static_words[1]; m[2]=static_words[2]; m[3]=static_words[3];
    m[4]=nonce_base + (u64)gid;
    m[5]=static_words[4];
    m[6]=static_words[5]; m[7]=static_words[6]; m[8]=static_words[7]; m[9]=static_words[8];
    m[10]=0; m[11]=0; m[12]=0; m[13]=0; m[14]=0; m[15]=0;

    u64 out[4];
    blake2b256_80(m, out);
    const ulong o = (ulong)gid * 4UL;
    digests[o+0]=out[0]; digests[o+1]=out[1]; digests[o+2]=out[2]; digests[o+3]=out[3];
}
