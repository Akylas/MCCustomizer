#import <Preferences/Preferences.h>
#define TAG @"MCCustomizer"
#define Log(x, ...) NSLog(@"[%@] " x, TAG, ##__VA_ARGS__)

static NSBundle* getBundle() {
    return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/MCCustomizer.bundle"];
}

@interface PSTableCell()
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
@end

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

- (void)donate
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7KMVX7A7XCN4G"]];
}

- (void)twitter {

    NSString * _user = @"farfromrefuge";

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:_user]]];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:_user]]];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:_user]]];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:_user]]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:_user]]];
    }
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

@interface BannerCell : PSTableCell {
    UIImageView *_imageView;
}
@end
 
@implementation BannerCell
- (id)initWithSpecifier:(PSSpecifier *)specifier
{
        self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"headerCell" specifier:specifier];
        if (self) {
            _imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[getBundle() pathForResource:@"banner" ofType:@"png"]]];
            [self addSubview:_imageView];
            [_imageView release];
        }
        return self;
}
 
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
    // Return a custom cell height.
    return 100.0f;
}
@end

// vim:ft=objc
