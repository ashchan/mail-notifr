//
//  GNAccountDetailController.h
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GNAccount;

@interface GNAccountDetailController : NSWindowController

- (id)initWithAccount:(GNAccount *)account;

+ (void)editAccount:(GNAccount *)account onWindow:(NSWindow *)window;

@end
