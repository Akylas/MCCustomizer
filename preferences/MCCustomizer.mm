#import <Preferences/PSTableCell.h>
#import "Preferences/PSListController.h"
#import <Preferences/PSSpecifier.h>
#import "MCCActionListViewController.h"
#import <libactivator/libactivator.h>
#import "../Utils.h"
#import "../MCCTweakController.h"
#define TAG @"MCCustomizer"


@interface MCCListController: PSListController {
}
@end


@interface PSTableCell()
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
@end

@interface MCCustomizerListController: MCCListController {
}
@end
@interface MCCustomizerLockscreenController: MCCListController {
}
@end
@interface MCCustomizerControlCenterController: MCCListController {
}
@end

@interface MCCustomizerLSActionListViewController: MCCActionListViewController {
}
@end

@interface MCCustomizerCCActionListViewController: MCCActionListViewController {
}
@end

@implementation MCCListController
-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];
    if (!exampleTweakSettings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return exampleTweakSettings[specifier.properties[@"key"]];
}
 
-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:PREFERENCES_PATH atomically:YES];
    // NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end

@implementation MCCustomizerLSActionListViewController
- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.prefPrefix = @"ls";
    }
    
    return self;
}
@end

@implementation MCCustomizerCCActionListViewController
- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.prefPrefix = @"cc";
    }
    
    return self;
}
@end

@implementation MCCustomizerListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"MCCustomizer" target:self];
	}
	return _specifiers;
}

- (void)donate
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7KMVX7A7XCN4G"]];
}

- (void)twitter:(PSSpecifier *)specifier {
    NSString *_user = [specifier.properties objectForKey:@"twitterId"];
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
        _specifiers = [self loadSpecifiersFromPlistName:@"Lockscreen" target:self];
    }
    return _specifiers;
}
@end

@implementation MCCustomizerControlCenterController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ControlCenter" target:self];
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
            _imageView = [[UIImageView alloc] initWithImage:getBundleImage(@"banner")];
            _imageView.backgroundColor = [UIColor redColor];
            _imageView.frame = self.bounds;
            _imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |    
                              UIViewAutoresizingFlexibleHeight);
            _imageView.contentMode = UIViewContentModeScaleAspectFill;
            [self addSubview:_imageView];
        }
        return self;
}
 
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
    // Return a custom cell height.
    return arg1 / 3.2f;
}
@end

// vim:ft=objc
