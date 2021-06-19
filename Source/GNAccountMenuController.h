//
//  GNAccountMenuController.h
//  Mail Notifr
//
//  Created by James Chen on 3/23/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

@import Cocoa;

@class Account;
@class GNChecker;

@interface GNAccountMenuController : NSObject

@property (copy, readonly) NSString *guid;
@property (assign) BOOL singleMode;

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem GNAccount:(Account *)account;
- (void)attachAtIndex:(NSInteger)index actionTarget:(id)target;
- (void)detach;
- (void)updateWithChecker:(GNChecker *)checker;
- (void)updateStatus;

@end
