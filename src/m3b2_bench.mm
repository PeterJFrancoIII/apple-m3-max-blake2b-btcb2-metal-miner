#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <chrono>
#include <cstdio>
#include <cstdlib>

int main(int argc, char **argv) {
    @autoreleasepool {
        const char *libPath = (argc > 1) ? argv[1] : "build/m3b2.metallib";
        const NSUInteger threads = (argc > 2) ? strtoull(argv[2], nullptr, 10) : (1u << 20);

        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { std::fprintf(stderr, "No Metal device found.\n"); return 1; }

        NSError *err = nil;
        NSString *path = [NSString stringWithUTF8String:libPath];
        id<MTLLibrary> library = [device newLibraryWithFile:path error:&err];
        if (!library) {
            std::fprintf(stderr, "Failed to load %s: %s\n", libPath,
                         err ? [[err localizedDescription] UTF8String] : "unknown error");
            return 1;
        }

        id<MTLFunction> fn = [library newFunctionWithName:@"m3b2_blake2b256"];
        if (!fn) { std::fprintf(stderr, "Kernel m3b2_blake2b256 not found.\n"); return 1; }

        id<MTLComputePipelineState> pso = [device newComputePipelineStateWithFunction:fn error:&err];
        if (!pso) {
            std::fprintf(stderr, "Pipeline creation failed: %s\n",
                         err ? [[err localizedDescription] UTF8String] : "unknown error");
            return 1;
        }

        // Synthetic fixed 80-byte BTCB2/Sia-style work header words.
        // Replace with real job words in an integrating miner.
        uint64_t staticWords[9] = {
            0x0123456789abcdefULL, 0xfedcba9876543210ULL,
            0x0011223344556677ULL, 0x8899aabbccddeeffULL,
            0x0000000000000000ULL,
            0x1020304050607080ULL, 0x90a0b0c0d0e0f000ULL,
            0x1122334455667788ULL, 0x99aabbccddeeff00ULL
        };
        uint64_t nonceBase = 0;

        id<MTLBuffer> staticBuf = [device newBufferWithBytes:staticWords
                                                     length:sizeof(staticWords)
                                                    options:MTLResourceStorageModeShared];
        id<MTLBuffer> nonceBuf = [device newBufferWithBytes:&nonceBase
                                                    length:sizeof(nonceBase)
                                                   options:MTLResourceStorageModeShared];
        id<MTLBuffer> outBuf = [device newBufferWithLength:threads * 4 * sizeof(uint64_t)
                                                  options:MTLResourceStorageModeShared];

        id<MTLCommandQueue> queue = [device newCommandQueue];
        id<MTLCommandBuffer> cb = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cb computeCommandEncoder];
        [enc setComputePipelineState:pso];
        [enc setBuffer:staticBuf offset:0 atIndex:0];
        [enc setBuffer:nonceBuf offset:0 atIndex:1];
        [enc setBuffer:outBuf offset:0 atIndex:2];

        const NSUInteger tg = 64;
        MTLSize grid = MTLSizeMake(threads, 1, 1);
        MTLSize group = MTLSizeMake(tg, 1, 1);

        auto t0 = std::chrono::steady_clock::now();
        [enc dispatchThreads:grid threadsPerThreadgroup:group];
        [enc endEncoding];
        [cb commit];
        [cb waitUntilCompleted];
        auto t1 = std::chrono::steady_clock::now();

        if (cb.status != MTLCommandBufferStatusCompleted) {
            std::fprintf(stderr, "Command buffer failed.\n");
            return 1;
        }

        const double sec = std::chrono::duration<double>(t1 - t0).count();
        const double mh = (double)threads / 1.0e6;
        std::printf("Device: %s\n", [[device name] UTF8String]);
        std::printf("Threads/hashes: %llu\n", (unsigned long long)threads);
        std::printf("Elapsed: %.6f s\n", sec);
        std::printf("Throughput: %.2f MH/s\n", mh / sec);

        const uint64_t *out = static_cast<const uint64_t *>([outBuf contents]);
        std::printf("First digest (LE words): %016llx %016llx %016llx %016llx\n",
                    (unsigned long long)out[0], (unsigned long long)out[1],
                    (unsigned long long)out[2], (unsigned long long)out[3]);
    }
    return 0;
}
