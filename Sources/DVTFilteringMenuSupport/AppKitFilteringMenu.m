#import "DVTFilteringMenuSupport.h"

@interface AppKitFilteringMenu : NSMenu <NSMenuDelegate>
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu;
@end

@implementation AppKitFilteringMenu

- (instancetype)initWithTitle:(NSString *)title {
    SEL filteringCapability = NSSelectorFromString(@"_delegateWantsDVTPerformSearchCall");
    if (![NSMenu instancesRespondToSelector:filteringCapability]) {
        return nil;
    }

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

// This is the private callback used by AppKit's native menu-filtering UI.
// AppKit owns the search field and its first-responder behavior; the prototype
// only decides which menu items match the current query.
- (void)performSearchWithString:(nullable NSString *)query inMenu:(NSMenu *)menu {
    NSString *normalizedQuery = query ?: @"";
    for (NSMenuItem *item in menu.itemArray) {
        if (item.separatorItem || item.view != nil) {
            continue;
        }
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

NSMenu *CreateAppKitFilteringMenu(NSString *title) {
    return [[AppKitFilteringMenu alloc] initWithTitle:title];
}
