//
//  PrefsInfoViewController.m
//  Mail Notifr
//
//  Created by James Chen on 10/8/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import "PrefsInfoViewController.h"

@interface PrefsInfoViewController ()

@end

@implementation PrefsInfoViewController

- (id)init {
    if (self = [super initWithNibName:@"PreferencesInfo" bundle:nil]) {
    }

    return self;
}

- (NSString *)title {
    return NSLocalizedString(@"Info", nil);
}

- (NSString *)identifier {
    return PrefsToolbarItemInfo;
}

- (NSImage *)image {
    return [NSImage imageNamed:NSImageNameInfo];
}

@end
