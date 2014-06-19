#import <libactivator/libactivator.h>

@protocol EventActivatorDelegate
-(void)didUpdateEvent:(NSString *)event;
@end


@interface EventActivator : LAEventSettingsController
@property(nonatomic, weak,   readwrite) NSObject<EventActivatorDelegate> *delegate;
@property(nonatomic, retain) NSString* eventName;
@end