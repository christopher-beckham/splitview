// WRITE: move a Split View divider. usage: svmove <space> <vIdx> <hIdx> <x> [y]
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
int main(int argc, char **argv){ @autoreleasepool {
  if (argc < 5) { fprintf(stderr, "usage: svmove space v h x [y]\n"); return 2; }
  void *SL = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
  int (*SLSMainConnectionID)(void) = dlsym(SL, "SLSMainConnectionID");
  int (*SLSSpaceMoveSpacersToPoint)(int, uint64_t, long, long, CGPoint, int) = dlsym(SL, "SLSSpaceMoveSpacersToPoint");
  uint64_t space = strtoull(argv[1], NULL, 10);
  long v = atol(argv[2]), h = atol(argv[3]);
  CGPoint p = CGPointMake(atof(argv[4]), argc > 5 ? atof(argv[5]) : 500);
  int err = SLSSpaceMoveSpacersToPoint(SLSMainConnectionID(), space, v, h, p, 0);
  printf("SLSSpaceMoveSpacersToPoint(space=%llu v=%ld h=%ld x=%.0f) -> %d\n", space, v, h, p.x, err);
}}
