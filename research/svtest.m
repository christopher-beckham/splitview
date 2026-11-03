// WRITE tests for the alternative divider calls.
// svtest size <tileSpaceID> <w> <h>      -> SLSTileSpaceMoveSpacersForSize
// svtest client <space> <v> <h> <x>      -> SLSSpaceClientDrivenMoveSpacersToPoint
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
int main(int argc, char **argv){ @autoreleasepool {
  void *SL = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
  int (*SLSMainConnectionID)(void) = dlsym(SL, "SLSMainConnectionID");
  BOOL (*opsEnabled)(void) = dlsym(SL, "SLSWindowManagementClientOperationsEnabled");
  printf("client ops enabled: %d\n", opsEnabled ? opsEnabled() : -1);
  if (!strcmp(argv[1], "size")) {
    int (*f)(uint64_t, CGSize) = dlsym(SL, "SLSTileSpaceMoveSpacersForSize");
    int err = f(strtoull(argv[2], NULL, 10), CGSizeMake(atof(argv[3]), atof(argv[4])));
    printf("SLSTileSpaceMoveSpacersForSize -> %d\n", err);
  } else {
    int (*f)(int, long, uint64_t, long, long, CGPoint, int) = dlsym(SL, "SLSSpaceClientDrivenMoveSpacersToPoint");
    int err = f(SLSMainConnectionID(), 0, strtoull(argv[2], NULL, 10), atol(argv[3]), atol(argv[4]), CGPointMake(atof(argv[5]), 500), 0);
    printf("SLSSpaceClientDrivenMoveSpacersToPoint -> %d\n", err);
  }
}}
