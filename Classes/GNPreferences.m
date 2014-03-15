//
// GNPreferences.rb
// Gmail Notifr
//
// Created by James Chan on 11/7/08.
// Copyright (c) 2008 ashchan.com. All rights reserved.
//

#import "GNPreferences.h"
#import <SSKeychain.h>
#import <StartAtLoginController.h>
#import "GNAccount.h"

NSString *const PrefsToolbarItemAccounts                = @"prefsToolbarItemAccounts";
NSString *const PrefsToolbarItemSettings                = @"prefsToolbarItemSettings";
NSString *const GNPreferencesSelection                  = @"PreferencesSelection";
NSString *const GNShowUnreadCountChangedNotification    = @"GNShowUnreadCountChangedNotification";
NSString *const GNAccountAddedNotification              = @"GNAccountAddedNotification";
NSString *const GNAccountRemovedNotification            = @"GNAccountRemovedNotification";
NSString *const GNAccountChangedNotification            = @"GNAccountChangedNotification";
NSString *const GNAccountsReorderedNotification         = @"GNAccountsReorderedNotification";

NSString *const DefaultsKeyAccounts                     = @"Accounts";
NSString *const DefaultsKeyShowUnreadCount              = @"ShowUnreadCount";
NSString *const DefaultsKeyAutoCheckAfterInboxInterval  = @"AutoCheckAfterInboxInterval";

// a simple wrapper for preferences values
@implementation GNPreferences {
    StartAtLoginController *_startAtLoginController;
}

+ (GNPreferences *)sharedInstance {
    static GNPreferences *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GNPreferences alloc] init];
    });
    return instance;
}

+ (void)setupDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ DefaultsKeyShowUnreadCount: @(YES), GNPreferencesSelection: PrefsToolbarItemAccounts }];
}

- (id)init {
    if (self = [super init]) {
        _accounts = [[NSMutableArray alloc] init];
        NSArray *archivedAccounts = [[NSUserDefaults standardUserDefaults] objectForKey:DefaultsKeyAccounts];
        for (id data in archivedAccounts) {
            [_accounts addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        }

        _startAtLoginController = [[StartAtLoginController alloc] initWithIdentifier:@"com.ashchan.GmailNotifrHelper"];

        self.showUnreadCount = [[NSUserDefaults standardUserDefaults] boolForKey:DefaultsKeyShowUnreadCount];

        // This is a hidden setting which can only be set from the Terminal or similar:
        //     defaults write com.ashchan.GmailNotifr AutoCheckAfterInboxInterval -float 30.0
        // The below property will be 0 if the key did not exist in the user defaults.
        self.autoCheckAfterInboxInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:DefaultsKeyAutoCheckAfterInboxInterval];
    }

    return self;
}

- (BOOL)autoLaunch {
    return [_startAtLoginController startAtLogin];
}

- (void)setAutoLaunch:(BOOL)val {
    if (val != self.autoLaunch) {
        _startAtLoginController.startAtLogin = val;
    }
}

- (BOOL)showUnreadCount {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DefaultsKeyShowUnreadCount];
}

- (void)setShowUnreadCount:(BOOL)val {
    [[NSUserDefaults standardUserDefaults] setBool:val forKey:DefaultsKeyShowUnreadCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNShowUnreadCountChangedNotification object:self];
}

- (void)addAccount:(id)account {
    [_accounts addObject:account];
    [self writeBack];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNAccountAddedNotification object:self userInfo:@{@"guid": [account guid]}];
}

- (void)removeAccount:(id)account {
    NSString *guid = [[account guid] copy];
    [SSKeychain deletePasswordForService:KeychainServiceName account:[account username]];
    [_accounts removeObject:account];
    [self writeBack];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNAccountRemovedNotification object:self userInfo:@{@"guid": guid}];
}

- (void)saveAccount:(id)account {
    [self writeBack];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNAccountChangedNotification object:self userInfo:@{@"guid": [account guid]}];
}

- (void)moveAccountFromRow:(NSUInteger)row toRow:(NSUInteger)newRow {
    if (row < newRow) {
        [_accounts insertObject:_accounts[row] atIndex:newRow];
        [_accounts removeObjectAtIndex:row];
    } else {
        GNAccount *account = _accounts[row];
        [_accounts removeObjectAtIndex:row];
        [_accounts insertObject:account atIndex:newRow];
    }
    [self writeBack];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNAccountsReorderedNotification object:nil];
}

- (void)writeBack {
    NSMutableArray *archivedAccounts = [[NSMutableArray alloc] initWithCapacity:[_accounts count]];
    for (id account in _accounts) {
        [archivedAccounts addObject:[NSKeyedArchiver archivedDataWithRootObject:account]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:archivedAccounts forKey:DefaultsKeyAccounts];
    [[NSUserDefaults standardUserDefaults] synchronize];

    for (id account in _accounts) {
        [SSKeychain setPassword:[account password] forService:KeychainServiceName account:[account username]];
    }
}

@end