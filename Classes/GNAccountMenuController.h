//
//  GNAccountMenuController.h
//  Mail Notifr
//
//  Created by James Chen on 3/23/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GNAccount;
@class GNChecker;

@interface GNAccountMenuController : NSObject

@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, assign) NSUInteger index;

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem GNAccount:(GNAccount *)account;
- (void)attachAtIndex:(NSInteger *)index actionTarget:(id)target;
- (void)detach;
- (void)updateWithChecker:(GNChecker *)checker;
- (void)updateStatus;

@end
