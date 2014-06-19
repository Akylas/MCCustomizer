#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Preferences/PSViewController.h"
#import "EventActivator.h"

@interface MCCActionListViewController : PSViewController <EventActivatorDelegate>
@property(nonatomic, readwrite, assign) NSString* prefPrefix;
@end