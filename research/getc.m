#import <Foundation/Foundation.h>
#include <dlfcn.h>
int main(int c, char**v){ void*SL=dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",RTLD_NOW);
 int (*cidf)(void)=dlsym(SL,"SLSMainConnectionID");
 int (*get)(int,uint32_t,CGSize*,CGSize*,CGSize*)=dlsym(SL,"SLSPackagesGetWindowConstraints");
 for(int i=1;i<c;i++){ CGSize a={-1,-1},b={-1,-1},d={-1,-1}; int e=get(cidf(),atoi(v[i]),&a,&b,&d);
  printf("wid %s err=%d a=%.0fx%.0f b=%.0fx%.0f c=%.0fx%.0f\n",v[i],e,a.width,a.height,b.width,b.height,d.width,d.height);} }
