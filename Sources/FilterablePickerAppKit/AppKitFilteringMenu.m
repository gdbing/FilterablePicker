#import "FilterablePickerAppKit.h"

// AppKit treats any menu class whose name contains "FilteringMenu" as a legacy
// DVTFilteringMenu and logs a Carbon menu warning, so avoid that in the name.
@interface FPSearchableMenu : NSMenu <NSMenuDelegate>
- (void)menu:(NSMenu *)menu performSearchWithString:(nullable NSString *)query;
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu;
@end

@implementation FPSearchableMenu

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithTitle:title];
    if (self) {
        [super setDelegate:self];
    }
    return self;
}

- (void)setDelegate:(id<NSMenuDelegate>)delegate {
    // AppKit detects the search callbacks on the NSMenu delegate.
    [super setDelegate:self];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self resetFilterInMenu:menu];
}

- (void)menuDidClose:(NSMenu *)menu {
    [self resetFilterInMenu:menu];
}

// AppKit owns the native filter field, focus, keyboard handling, layout, menu
// tracking, and dismissal. These callbacks only supply substring matching.
- (void)menu:(NSMenu *)menu performSearchWithString:(nullable NSString *)query {
    [self filterMenu:menu withQuery:query];
}

// Legacy DVTFilteringMenu callback, used where AppKit lacks the delegate
// callback above. AppKit prefers the delegate callback when both exist.
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu {
    [self filterMenu:menu withQuery:query];
}

- (void)filterMenu:(NSMenu *)menu withQuery:(nullable NSString *)query {
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
    return [NSMenu instancesRespondToSelector:NSSelectorFromString(@"_delegateWantsPerformSearchCall")] ||
        [NSMenu instancesRespondToSelector:NSSelectorFromString(@"_delegateWantsDVTPerformSearchCall")];
}

NSMenu *FPCreateNativeFilteringMenu(NSString *title) {
    if (!FPIsNativeMenuFilteringAvailable()) {
        return nil;
    }
    return [[FPSearchableMenu alloc] initWithTitle:title];
}
