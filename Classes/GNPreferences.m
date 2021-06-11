//
// GNPreferences.rb
// Gmail Notifr
//
// Created by James Chan on 11/7/08.
// Copyright (c) 2008 ashchan.com. All rights reserved.
//

#import "GNPreferences.h"
#import "GNAccount.h"
#import "Mail_Notifr-Swift.h"

NSString *const PrefsToolbarItemAccounts                = @"prefsToolbarItemAccounts";
NSString *const PrefsToolbarItemSettings                = @"prefsToolbarItemSettings";
NSString *const PrefsToolbarItemInfo                    = @"prefsToolbarItemInfo";
NSString *const GNPreferencesSelection                  = @"PreferencesSelection";
NSString *const GNShowUnreadCountChangedNotification    = @"GNShowUnreadCountChangedNotification";
NSString *const GNAccountAddedNotification              = @"GNAccountAddedNotification";
NSString *const GNAccountRemovedNotification            = @"GNAccountRemovedNotification";
NSString *const GNAccountChangedNotification            = @"GNAccountChangedNotification";
NSString *const GNAccountsReorderedNotification         = @"GNAccountsReorderedNotification";

static NSString *const kDefaultsKeyAccounts                     = @"Accounts";
static NSString *const kDefaultsKeyShowUnreadCount              = @"ShowUnreadCount";
static NSString *const kDefaultsKeyAutoCheckAfterInboxInterval  = @"AutoCheckAfterInboxInterval";

// a simple wrapper for preferences values
@implementation GNPreferences {
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
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ kDefaultsKeyShowUnreadCount: @(YES), GNPreferencesSelection: PrefsToolbarItemAccounts }];
}

- (id)init {
    if (self = [super init]) {
        _accounts = [[NSMutableArray alloc] init];
        NSArray *archivedAccounts = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsKeyAccounts];
        for (id data in archivedAccounts) {
            [_accounts addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        }

        self.showUnreadCount = [[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyShowUnreadCount];

        // This is a hidden setting which can only be set from the Terminal or similar:
        //     defaults write com.ashchan.GmailNotifr AutoCheckAfterInboxInterval -float 30.0
        // The below property will be 0 if the key did not exist in the user defaults.
        self.autoCheckAfterInboxInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kDefaultsKeyAutoCheckAfterInboxInterval];
    }

    return self;
}

- (BOOL)allAccountsDisabled {
    for (GNAccount *account in self.accounts) {
        if (account.enabled) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)showUnreadCount {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyShowUnreadCount];
}

- (void)setShowUnreadCount:(BOOL)val {
    [[NSUserDefaults standardUserDefaults] setBool:val forKey:kDefaultsKeyShowUnreadCount];
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
    [GNAccount setPasswordWithAccount:account password:NULL];
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
    [[NSUserDefaults standardUserDefaults] setObject:archivedAccounts forKey:kDefaultsKeyAccounts];
    [[NSUserDefaults standardUserDefaults] synchronize];

    for (id account in _accounts) {
        [GNAccount setPasswordWithAccount:account password:[account password]];
    }
}

@end
