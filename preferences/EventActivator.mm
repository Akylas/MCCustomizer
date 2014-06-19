#import "EventActivator.h"

@interface LAEventSettingsController ()
- (void)updateHeader;
@end

@implementation EventActivator
@synthesize eventName;
- (id)initWithModes:(NSArray *)modes eventName:(NSString *)_eventName
{   

    if (self =[super initWithModes:modes eventName:_eventName]) {
        self.eventName = _eventName;
    }
     
    // superObject.navigationItem.title = @"TerminalActivator";
    
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // LAEvent *event = [[LAEvent alloc] initWithName:self.eventName];
    
    // [LASharedActivator unassignEvent:event];
}

- (void)updateHeader
{
    [super updateHeader];
    if (self.delegate) {
        [self.delegate didUpdateEvent:self.eventName];
    }

    // LAEvent *event = [[[LAEvent alloc] initWithName:@"kr.iolate.terminalactivator.event"] autorelease];

    // NSString* listenerName = [LASharedActivator assignedListenerNameForEvent:event];
    
    // NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfFile:SettingPath];

    // if (listenerName) {
    //     [dic setObject:[NSString stringWithFormat:@"libactivator.%@", listenerName] forKey:num];
    // }else
    // {
    //     listenerName = @"";
    //     [dic setObject:@"" forKey:num];
    // }
    // [dic writeToFile:SettingPath atomically:NO];
    // [dic release];
    
    // [[NotificationsListViewController sharedInstance] loadSetting];
    // [[[NotificationsListViewController sharedInstance] tableView] reloadData];

    // CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("kr.iolate.terminalactivator.reloadsetting"), NULL, NULL, true);

}

- (void)setRootController:(id)fp8
{
    //for iOS4
    return;
}

@end