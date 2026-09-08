#import "FilterablePickerAppKit.h"

@interface FPAppKitFilteringMenu : NSMenu <NSMenuDelegate>
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu;
@end

@implementation FPAppKitFilteringMenu

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithTitle:title];
    if (self) {
        [super setDelegate:self];
    }
    return self;
}

- (void)setDelegate:(id<NSMenuDelegate>)delegate {
    // AppKit detects performSearchWithString:inMenu: on the NSMenu delegate.
    [super setDelegate:self];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self resetFilterInMenu:menu];
}

- (void)menuDidClose:(NSMenu *)menu {
    [self resetFilterInMenu:menu];
}

// AppKit owns the native filter field, focus, keyboard handling, layout, menu
// tracking, and dismissal. This callback only supplies substring matching.
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu {
    NSString *normalizedQuery = query ?: @"";
    for (NSMenuItem *item in menu.itemArray) {
        item.hidden = normalizedQuery.length > 0 &&
            [item.title localizedCaseInsensitiveContainsString:normalizedQuery] == NO;
    }
}

- (void)resetFilterInMenu:(NSMenu *)menu {
    for (NSMenuItem *item in menu.itemArray) {
        item.hidden = NO;
    }
}

@end

BOOL FPIsNativeMenuFilteringAvailable(void) {
    SEL capability = NSSelectorFromString(@"_delegateWantsDVTPerformSearchCall");
    return [NSMenu instancesRespondToSelector:capability];
}

NSMenu *FPCreateNativeFilteringMenu(NSString *title) {
    if (!FPIsNativeMenuFilteringAvailable()) {
        return nil;
    }
    return [[FPAppKitFilteringMenu alloc] initWithTitle:title];
}
