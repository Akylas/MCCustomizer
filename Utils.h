#import <libactivator/libactivator.h>

inline NSBundle* getBundle() {
    return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/MCCustomizer.bundle"];
}

inline UIImage* getBundleImage(NSString* name) {
    return [UIImage imageWithContentsOfFile:[getBundle() pathForResource:name ofType:@"png"]];
}

inline UIImage* getActivatorEventImage(NSArray* listeners) {
    if ([listeners count] == 0) {
        return nil;
    }
    if ([listeners count] == 1) {
        return [LASharedActivator smallIconForListenerName:[listeners objectAtIndex:0]];
    }

    UIImage *result;
    BOOL first = YES;
    CGFloat x = 0;
    CGFloat decale = 3.0f;
    int count = MIN([listeners count], 3);
    for (int i = 0; i < count; ++i)
    {
        NSString* oneName = [listeners objectAtIndex:([listeners count] - 1 - i)];
        UIImage* image = [LASharedActivator smallIconForListenerName:oneName];
        if (first) {
            first = NO;
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width + (count-1)*decale, image.size.height + (count-1)*decale), NO, 0);
        }
        if (image) {
            [image drawAtPoint:CGPointMake(x, x)];
        }

        x += decale;
    }
    // grab context
    result = UIGraphicsGetImageFromCurrentImageContext();

    // end context
    UIGraphicsEndImageContext();
    return result;
}


inline NSString* getActivatorDisplayName(NSArray* listeners) {
    if ([listeners count] == 0) {
        return @"Action unassigned";
    }
    NSString *displayName = nil;
    for(NSString* oneName in listeners) {
        id<LAListener> listener = [LASharedActivator listenerForName:oneName];
        NSString *listenerName = [listener activator:[LAActivator sharedInstance] requiresLocalizedTitleForListenerName:oneName];
        if (displayName == nil) {
            displayName = listenerName;
        }
        else {
            displayName = [displayName stringByAppendingFormat:@",%@", listenerName];
        }
    }
    return displayName;
}
