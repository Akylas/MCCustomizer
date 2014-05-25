#import <Preferences/Preferences.h>

@interface MCCustomizerListController: PSListController {
}
@end
@interface MCCustomizerLockscreenController: PSListController {
}
@end
@interface MCCustomizerControlCenterController: PSListController {
}
@end

@implementation MCCustomizerListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"MCCustomizer" target:self] retain];
	}
	return _specifiers;
}

- (void)donate:(id)param
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7KMVX7A7XCN4G"]];
}
@end

@implementation MCCustomizerLockscreenController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Lockscreen" target:self] retain];
    }
    return _specifiers;
}
@end

@implementation MCCustomizerControlCenterController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"ControlCenter" target:self] retain];
    }
    return _specifiers;
}
@end

// vim:ft=objc
