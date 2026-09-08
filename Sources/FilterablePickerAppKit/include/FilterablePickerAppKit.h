#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

BOOL FPIsNativeMenuFilteringAvailable(void);
NSMenu * _Nullable FPCreateNativeFilteringMenu(NSString *title);

NS_ASSUME_NONNULL_END
