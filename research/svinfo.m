// Read-only: for each Split View space, print tiles and the divider between them.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
int main(){ @autoreleasepool {
  void *SL = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
  int (*SLSMainConnectionID)(void) = dlsym(SL, "SLSMainConnectionID");
  CFArrayRef (*SLSCopyManagedDisplaySpaces)(int) = dlsym(SL, "SLSCopyManagedDisplaySpaces");
  uint64_t (*SLSGetActiveSpace)(int) = dlsym(SL, "SLSGetActiveSpace");
  void (*SLSSpaceGetSpacersAtPoint)(int, uint64_t, CGPoint, long*, long*, CGRect*) = dlsym(SL, "SLSSpaceGetSpacersAtPoint");
  int cid = SLSMainConnectionID();
  printf("active space %llu\n", SLSGetActiveSpace(cid));
  NSArray *displays = (__bridge_transfer NSArray*)SLSCopyManagedDisplaySpaces(cid);
  int found = 0;
  for (NSDictionary *d in displays) for (NSDictionary *s in d[@"Spaces"]) {
    NSDictionary *tlm = s[@"TileLayoutManager"]; if (!tlm) continue;
    found = 1;
    uint64_t sid = [s[@"ManagedSpaceID"] unsignedLongLongValue];
    printf("split space %llu\n", sid);
    double right0 = 0;
    for (NSDictionary *t in tlm[@"TileSpaces"]) {
      NSDictionary *r = t[@"TileRect"], *mn = t[@"SizeConstraints"][@"Min"];
      double x = [r[@"X"] doubleValue], w = [r[@"Width"] doubleValue];
      printf("  tile %s id64=%s wid=%s x=%.0f w=%.0f min=%sx%s\n", [t[@"appName"] UTF8String],
             [[t[@"id64"] description] UTF8String], [[t[@"TileWindowID"] description] UTF8String],
             x, w, [[mn[@"Width"] description] UTF8String], [[mn[@"Height"] description] UTF8String]);
      if (x == 0) right0 = w;
    }
    long v=-1,h=-1; CGRect rc={0};
    SLSSpaceGetSpacersAtPoint(cid, sid, CGPointMake(right0 + 6, 500), &v, &h, &rc);
    printf("  divider v=%ld h=%ld rect=(%.0f,%.0f %.0fx%.0f)\n", v, h, rc.origin.x, rc.origin.y, rc.size.width, rc.size.height);
  }
  if (!found) printf("no Split View spaces right now\n");
}}
