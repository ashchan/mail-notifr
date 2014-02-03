//
//  main.m
//  GmailNotifrHelper
//
//  Created by James Chen on 2/3/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [NSApplication sharedApplication].delegate = delegate;
    [NSApp run];
}
