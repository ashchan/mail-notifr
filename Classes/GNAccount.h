//
//  GNAccount.h
//  Gmail Notifr
//
//  Created by James Chen on 1/25/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

@import Foundation;

extern NSString *const GNAccountKeychainServiceName;

@interface GNAccount : NSObject <NSCoding>

@property (copy) NSString *guid;
@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *browser;
@property (copy) NSString *sound;
@property (nonatomic, assign) NSInteger interval;
@property (assign) BOOL enabled;
@property (assign) BOOL growl;

- (id)initWithUsername:(NSString *)username
              interval:(NSInteger)interval
               enabled:(BOOL)enabled
                 growl:(BOOL)growl
                 sound:(NSString *)sound
               browser:(NSString *)browser;
- (NSString *)baseUrl;
- (void)save;

+ (GNAccount *)accountByUsername:(NSString *)username;
+ (GNAccount *)accountByMessageLink:(NSString *)link;
+ (NSString *)baseUrlForUsername:(NSString *)username;

@end