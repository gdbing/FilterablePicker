#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Calls Xcode's private `-initWithTitle:initiallyShowsSearch:` initializer.
/// This exists only to make the comparison prototype possible.
NSMenu * _Nullable CreateDVTFilteringMenu(
    Class menuClass,
    NSString *title,
    BOOL initiallyShowsSearch
);

/// Creates a normal AppKit menu whose delegate supplies matches to AppKit's
/// private native menu-filtering UI.
/// This exists only to make the comparison prototype possible.
NSMenu * _Nullable CreateAppKitFilteringMenu(NSString *title);

NS_ASSUME_NONNULL_END
