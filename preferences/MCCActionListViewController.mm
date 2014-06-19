#import <libactivator/libactivator.h>
#import "MCCActionListViewController.h"
#import "../MCCTweakController.h"
#import "../Utils.h"



@interface MCCActionListViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    NSMutableOrderedSet *_enabled;
    NSMutableOrderedSet *_disabled;
}

@end

@implementation MCCActionListViewController
@synthesize prefPrefix;
#define PRE_FORMAT_STRING(val) [NSString stringWithFormat:@"%@%@", self.prefPrefix, [NSString stringWithUTF8String:#val]]

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    
    return self;
}

-(NSArray*)compatibleModes
{
    return @[@"lockscreen", @"springboard", @"application"];
}

- (void)popupViewWillDisappear {
    [super popupViewWillDisappear];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setAllowsSelectionDuringEditing:YES];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}


-(int)getMaxCurrentIndex {
    __block int result = -1;
    [_enabled enumerateObjectsUsingBlock:^(NSString* value, NSUInteger idx, BOOL *stop) {        
        if (value) {
            int current = [[[value componentsSeparatedByString:@"."] lastObject] intValue];
            result = MAX(current, result);
        }
    }];
    [_disabled enumerateObjectsUsingBlock:^(NSString* value, NSUInteger idx, BOOL *stop) {        
        if (value) {
            int current = [[[value componentsSeparatedByString:@"."] lastObject] intValue];
            result = MAX(current, result);
        }
    }];
    return result+1;
}


- (void)loadView {
    self.title = PRE_FORMAT_STRING(Actions);
    //  Load settings plist
    NSDictionary * prefs = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];
    _enabled = [NSMutableOrderedSet orderedSetWithArray:prefs[PRE_FORMAT_STRING(EnabledSections)]];

    _disabled = [NSMutableOrderedSet orderedSetWithArray:prefs[PRE_FORMAT_STRING(DisabledSections)]];

    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame style:UITableViewStyleGrouped];
    
    tableView.dataSource = self;
    tableView.delegate = self;
    
    self.view = tableView;
}

- (UITableView *)tableView {
    return (UITableView *)self.view;
}

- (void)syncPrefs:(BOOL)notify {

    NSMutableDictionary * prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];    
    if (_enabled) {
        prefs[PRE_FORMAT_STRING(EnabledSections)] = _enabled.array;
    }
    else {
        [prefs removeObjectForKey:PRE_FORMAT_STRING(EnabledSections)];
    }
    
    if (_disabled.count) {
        prefs[PRE_FORMAT_STRING(DisabledSections)] = _disabled.array;
    }
    else {
        [prefs removeObjectForKey:PRE_FORMAT_STRING(DisabledSections)];
    }
    
    [prefs writeToFile:PREFERENCES_PATH atomically:YES];
    
    if (notify) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PREFERENCES_CHANGED_NOTIFICATION),  NULL, NULL, true);
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        return 1;
    }
    
    NSUInteger num = 0;
    if (section == 0) {
        num = _enabled.count;
    }
    else {
        num = _disabled.count;
    }
    
    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enabled Actions";
    }
    else if (section == 1) {
        return @"Disabled Actions";
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    if (indexPath.section == 2) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize: [cell.textLabel.font pointSize]];
        cell.textLabel.text = @"Add New Shortcut";
    }
    else if ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)) {
        NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        LAEvent *event = [[LAEvent alloc] initWithName:ID];

        NSString* listenerName = [LASharedActivator assignedListenerNameForEvent:event];

        NSArray* listeners = [listenerName componentsSeparatedByString:@";"];
        cell.imageView.image = getActivatorEventImage(listeners);
        cell.textLabel.text = getActivatorDisplayName(listeners);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        return UITableViewCellEditingStyleNone;
    }
    else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section < 2);
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count));
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sourceID ;
    if (indexPath.section == 2) {
        sourceID = [NSString stringWithFormat:@"com.akylas.mccustomizer.action.%@.%d", self.prefPrefix, [self getMaxCurrentIndex]];
        int count = [_enabled count];
        [self.tableView beginUpdates];
        [_enabled addObject:sourceID];
        NSIndexPath *add = [NSIndexPath indexPathForRow:count inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[add] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [self syncPrefs:YES];
    }
    else if ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        sourceID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        
    }
    EventActivator *vc = [[EventActivator alloc] initWithModes:[self compatibleModes] eventName:sourceID];
    vc.delegate = self;
    [self pushController:vc];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section > 1) {
        return sourceIndexPath;
    }
    else if ((proposedDestinationIndexPath.section == 0 && !_enabled.count) || (proposedDestinationIndexPath.section == 1 && !_disabled.count)) {
        return [NSIndexPath indexPathForRow:0 inSection:proposedDestinationIndexPath.section];
    }
    else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {

    BOOL clearRow = ((destinationIndexPath.section == 0 && !_enabled.count) || (destinationIndexPath.section == 1 && !_disabled.count));
    
    if (sourceIndexPath.section == 0) {
        NSString *sourceID = _enabled[sourceIndexPath.row];
        
        [_enabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 0) {
            [_enabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_disabled insertObject:sourceID atIndex:(clearRow ? 0 : destinationIndexPath.row)];
        }
    }
    else if (sourceIndexPath.section == 1) {
        NSString *sourceID = _disabled[sourceIndexPath.row];
        
        [_disabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 1) {
            [_disabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_enabled insertObject:sourceID atIndex:(clearRow ? 0 : destinationIndexPath.row)];
        }
    }

    [self syncPrefs:YES];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableOrderedSet* set = nil;
        if (indexPath.section == 0) {
            set = _enabled;
        }
        else if (indexPath.section == 1) {
            set = _disabled;
        }
        if (!set) return;
        NSString *sourceID = set[indexPath.row];
        for (NSString* mode in [self compatibleModes]) {
            LAEvent *event = [LAEvent eventWithName:sourceID mode:mode];
            [[LAActivator sharedInstance] unassignEvent:event];
        }
        
        [self.tableView beginUpdates];
        [set removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];

        [self syncPrefs:YES];
    }    
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        // you might disable other widgets here... (optional)
    } else {
        // re-enable disabled widgets (optional)
    }
}

-(void)didUpdateEvent:(NSString *)eventName
{
    [self.tableView reloadData];
    [self syncPrefs:YES];
}

@end