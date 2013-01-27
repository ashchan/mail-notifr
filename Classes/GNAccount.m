//
//  GNAccount.rb
//  Gmail Notifr
//
// Created by James Chan on 1/3/09.
// Copyright (c) 2009 ashchan.com. All rights reserved.
//

// a normal gmail account, or a google hosted email account

#include "GNAccount.h"
#include "SSKeychain.h"
#include "GNSound.h"
#include "GNBrowser.h"
#include "GNPreferences.h"

@implementation GNAccount

const NSInteger MIN_INTERVAL        = 1;
const NSInteger MAX_INTERVAL        = 900;
const NSInteger DEFAULT_INTERVAL    = 30;

NSString *const KeychainServiceName = @"GmailNotifr";

- (id)initWithUsername:(NSString *)username
              interval:(NSInteger)interval
               enabled:(BOOL)enabled
                 growl:(BOOL)growl
                 sound:(NSString *)sound
               browser:(NSString *)browser {
    if (self = [super init]) {
        self.username   = [username copy];
        self.interval   = MAX(interval, DEFAULT_INTERVAL);
        self.enabled    = enabled;
        self.growl      = growl;
        if (sound) {
            self.sound  = [sound copy];
        } else {
            self.sound  = [SoundNone copy];
        }
        if (browser) {
            self.browser = [browser copy];
        } else {
            self.browser = [DefaultBrowserIdentifier copy];
        }

        [self fetchPassword];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.guid       = [coder decodeObjectForKey:@"guid"];
        self.username   = [coder decodeObjectForKey:@"username"];
        self.interval   = [[coder decodeObjectForKey:@"interval"] integerValue];
        self.enabled    = [[coder decodeObjectForKey:@"enabled"] boolValue];
        self.sound      = [coder decodeObjectForKey:@"sound"];
        self.growl      = [[coder decodeObjectForKey:@"growl"] boolValue];
        self.browser    = [coder decodeObjectForKey:@"browser"];

        [self fetchPassword];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.guid forKey:@"guid"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:@(self.interval) forKey:@"interval"];
    [coder encodeObject:@(self.enabled) forKey:@"enabled"];
    [coder encodeObject:self.sound forKey:@"sound"];
    [coder encodeObject:@(self.growl) forKey:@"growl"];
    [coder encodeObject:self.browser forKey:@"browser"];
}

- (void)setInterval:(NSInteger)val {
    _interval = val <= MAX_INTERVAL && val >= MIN_INTERVAL ? val : DEFAULT_INTERVAL;
}

- (NSString *)baseUrl {
    return [self.class baseUrlForUsername:self.username];
}

- (void)save {
    if ([self isPersisted]) {
        [[GNPreferences sharedInstance] saveAccount:self];
    } else {
        // self.guid = `uuidgen`.strip
        self.guid = [self generateUUID];
        [[GNPreferences sharedInstance] addAccount:self];
    }
}

+ (GNAccount *)accountByUsername:(NSString *)username {
    for (GNAccount *account in [[GNPreferences sharedInstance] accounts]) {
        if ([account.username isEqualToString:username]) {
            return account;
        }
    }
    return nil;
}

+ (GNAccount *)accountByMessageLink:(NSString *)link {
    NSString *queryString = [link componentsSeparatedByString:@"?"][1];
    for (NSString *param in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        if ([keyValue[0] isEqualToString:@"account_id"]) {
            for (GNAccount *account in [[GNPreferences sharedInstance] accounts]) {
                if ([@[keyValue[1], [keyValue[1] componentsSeparatedByString:@"@"][0]] containsObject:account.username]) {
                    return account;
                }
            }
        }
    }
    return nil;
}

+ (NSString *)baseUrlForUsername:(NSString *)username {
    NSString *accountName = [username stringByAppendingString:([username rangeOfString:@"@"].length > 0 ? @"" : @"@gmail.com")];
    return [@"https://mail.google.com/mail/b/" stringByAppendingString:accountName];
}

#pragma mark - Private Methods

- (void)fetchPassword {
    self.password = [SSKeychain passwordForService:KeychainServiceName account:self.username];
    if (!self.password) {
        self.password = @"";
    }
}

- (BOOL)isPersisted {
    return self.guid != nil;
}

- (NSString *)generateUUID {
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}

@end
