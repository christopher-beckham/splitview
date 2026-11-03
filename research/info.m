// Read-only probe: list managed spaces and Split View tile info.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
typedef int CID;
static void *SL;
#define F(ret,name,...) ret (*name)(__VA_ARGS__) = dlsym(SL, #name)
int main(){ @autoreleasepool {
  SL = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
  F(CID, SLSMainConnectionID, void);
  F(CFArrayRef, SLSCopyManagedDisplaySpaces, CID);
  F(CFArrayRef, SLSSpaceCopyTileSpaces, CID, uint64_t);
  F(void, SLSSpaceGetSpacersAtPoint, CID, uint64_t, CGPoint, long*, long*, CGRect*);
  F(uint64_t, SLSGetActiveSpace, CID);
  CID cid = SLSMainConnectionID();
  printf("cid=%d active=%llu\n", cid, SLSGetActiveSpace(cid));
  NSArray *displays = (__bridge_transfer NSArray*)SLSCopyManagedDisplaySpaces(cid);
  CGRect b = CGDisplayBounds(CGMainDisplayID());
  printf("main display %.0fx%.0f\n", b.size.width, b.size.height);
  for (NSDictionary *d in displays) {
    printf("display %s\n", [d[@"Display Identifier"] UTF8String]);
    for (NSDictionary *s in d[@"Spaces"]) {
      uint64_t sid = [s[@"ManagedSpaceID"] unsignedLongLongValue];
      printf("  space %llu type=%s tileLayout=%s\n", sid, [[s[@"type"] description] UTF8String],
             s[@"TileLayoutManager"] ? "yes" : "no");
      NSArray *tiles = (__bridge_transfer NSArray*)SLSSpaceCopyTileSpaces(cid, sid);
      if (tiles.count) printf("    tile spaces: %s\n", [[tiles description] UTF8String]);
      if (s[@"TileLayoutManager"]) {
        printf("    TileLayoutManager: %s\n", [[s[@"TileLayoutManager"] description] UTF8String]);
        long v=-1,h=-1; CGRect r={0};
        SLSSpaceGetSpacersAtPoint(cid, sid, CGPointMake(1332, 500), &v, &h, &r);
        printf("    spacer@center v=%ld h=%ld rect=(%.0f,%.0f %.0fx%.0f)\n", v,h,r.origin.x,r.origin.y,r.size.width,r.size.height);
      }
    }
  }
}}
