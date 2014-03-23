//
//  GNChecker.h
//  Gmail Notifr
//
//  Created by James Chen on 1/26/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const GNCheckingAccountNotification;
extern NSString *const GNAccountMenuUpdateNotification;

@class GNAccount;

@interface GNChecker : NSObject

@property (nonatomic, copy) NSString *lastCheckedAt;

- (id)initWithAccount:(GNAccount *)account;
- (BOOL)isForAccount:(GNAccount *)account;
- (BOOL)isForGuid:(NSString *)guid;
- (NSArray *)messages;
- (NSUInteger)messageCount;
- (void)checkAfterInterval:(NSInteger)interval;
- (void)reset;
- (void)cleanupAndQuit;
- (BOOL)hasUserError;
- (BOOL)hasConnectionError;

@end