//
//  AppDelegate.m
//  GmailNotifrHelper
//
//  Created by James Chen on 2/3/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    for (int i = 4; i-- > 0;) {
        appPath = [appPath stringByDeletingLastPathComponent];
    }
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    [NSApp terminate:nil];
}

@end
