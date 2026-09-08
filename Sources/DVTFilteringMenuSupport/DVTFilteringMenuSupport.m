#import "DVTFilteringMenuSupport.h"

@interface NSMenu (DVTFilteringMenuInitializer)
- (instancetype)initWithTitle:(NSString *)title
         initiallyShowsSearch:(BOOL)initiallyShowsSearch;
@end

NSMenu *CreateDVTFilteringMenu(
    Class menuClass,
    NSString *title,
    BOOL initiallyShowsSearch
) {
    return [[menuClass alloc] initWithTitle:title
                      initiallyShowsSearch:initiallyShowsSearch];
}
