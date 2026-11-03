// svctl: control the native Split View divider via private SkyLight calls.
//   svctl collapse-other <wid>  shrink the tile that isn't <wid> to its app's
//                               minimum; prints the previous divider x
//   svctl divider <wid> <x>     move the divider of <wid>'s Split View to x
//   svctl info <wid>            prints "<dividerX> <layoutWidth> <spacing>",
//                               then the left and right apps' names, one per line
// If <wid> isn't in a two-tile Split View, the active space's is used; exit 1
// if there's none.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>

static void *SL;

// Finds the two-tile Split View containing window `wid`. If `wid` isn't in one
// (e.g. focus is on a transient popup), falls back to the active space's.
static NSDictionary *findSplit(int cid, uint32_t wid, uint64_t *space) {
  CFArrayRef (*copySpaces)(int) = dlsym(SL, "SLSCopyManagedDisplaySpaces");
  uint64_t (*activeSpace)(int) = dlsym(SL, "SLSGetActiveSpace");
  uint64_t active = activeSpace(cid);
  NSArray *displays = (__bridge_transfer NSArray *)copySpaces(cid);
  NSDictionary *fallback = nil;
  for (NSDictionary *d in displays) for (NSDictionary *s in d[@"Spaces"]) {
    NSArray *tiles = s[@"TileLayoutManager"][@"TileSpaces"];
    if (tiles.count != 2) continue;
    uint64_t sid = [s[@"ManagedSpaceID"] unsignedLongLongValue];
    for (NSDictionary *t in tiles) if ([t[@"TileWindowID"] unsignedIntValue] == wid) {
      *space = sid;
      return s[@"TileLayoutManager"];
    }
    if (sid == active) fallback = s;
  }
  if (fallback) *space = [fallback[@"ManagedSpaceID"] unsignedLongLongValue];
  return fallback[@"TileLayoutManager"];
}

int main(int argc, char **argv) { @autoreleasepool {
  if (argc < 3) { fprintf(stderr, "usage: svctl info <wid> | collapse-other <wid> | divider <wid> <x>\n"); return 2; }
  SL = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
  int (*mainCID)(void) = dlsym(SL, "SLSMainConnectionID");
  int cid = mainCID();
  uint32_t wid = (uint32_t)strtoul(argv[2], NULL, 10);
  uint64_t space = 0;
  NSDictionary *tlm = findSplit(cid, wid, &space);
  if (!tlm) { fprintf(stderr, "window %u is not in a two-tile Split View\n", wid); return 1; }

  NSArray *tiles = tlm[@"TileSpaces"];
  NSDictionary *left = tiles[0], *right = tiles[1];
  if ([left[@"TileRect"][@"X"] doubleValue] > [right[@"TileRect"][@"X"] doubleValue]) { NSDictionary *t = left; left = right; right = t; }
  double dividerX = [left[@"TileRect"][@"Width"] doubleValue];

  if (!strcmp(argv[1], "info")) {
    printf("%.0f %.0f %.0f\n%s\n%s\n", dividerX, [tlm[@"Layout Rect"][@"Width"] doubleValue],
           [tlm[@"Inter-Tile Spacing"][@"Width"] doubleValue],
           [left[@"appName"] UTF8String] ?: "?", [right[@"appName"] UTF8String] ?: "?");
  } else if (!strcmp(argv[1], "collapse-other")) {
    NSDictionary *other = ([left[@"TileWindowID"] unsignedIntValue] == wid) ? right : left;
    int (*sizeTile)(uint64_t, CGSize) = dlsym(SL, "SLSTileSpaceMoveSpacersForSize");
    int err = sizeTile([other[@"id64"] unsignedLongLongValue],
                       CGSizeMake(1, [other[@"TileRect"][@"Height"] doubleValue]));
    if (err) { fprintf(stderr, "SLSTileSpaceMoveSpacersForSize failed: %d\n", err); return 1; }
    printf("%.0f\n", dividerX);
  } else if (!strcmp(argv[1], "divider") && argc > 3) {
    long v = -1, h = -1; CGRect r;
    void (*spacersAt)(int, uint64_t, CGPoint, long *, long *, CGRect *) = dlsym(SL, "SLSSpaceGetSpacersAtPoint");
    spacersAt(cid, space, CGPointMake(dividerX + 6, 500), &v, &h, &r);
    if (v < 0) { fprintf(stderr, "divider not found\n"); return 1; }
    int (*moveSpacers)(int, uint64_t, long, long, CGPoint, int) = dlsym(SL, "SLSSpaceMoveSpacersToPoint");
    int err = moveSpacers(cid, space, v, h, CGPointMake(atof(argv[3]), 500), 0);
    if (err) { fprintf(stderr, "SLSSpaceMoveSpacersToPoint failed: %d\n", err); return 1; }
  } else {
    fprintf(stderr, "unknown command\n"); return 2;
  }
  return 0;
}}
