//
//  GNSecureTextField.m
//  Mail Notifr
//
//  Created by James Chen on 4/17/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import "GNSecureTextField.h"

@implementation GNSecureTextField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    NSUInteger flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    NSString *key = [event charactersIgnoringModifiers];
    if (flags == NSEventModifierFlagCommand && [key isEqualToString:@"v"]) {
        return [NSApp sendAction:@selector(paste:) to:[self.window firstResponder] from:self];
    }

    return NO;
}

@end
