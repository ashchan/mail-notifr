//
// GNPreferences.rb
// Gmail Notifr
//
// Created by James Chan on 11/7/08.
// Copyright (c) 2008 ashchan.com. All rights reserved.
//

#import "GNPreferences.h"
#import "NSApplication+LoginItems.h"
#import "SSKeychain.h"
#import "GNAccount.h"

NSString *const PrefsToolbarItemAccounts                = @"prefsToolbarItemAccounts";
NSString *const PrefsToolbarItemSettings                = @"prefsToolbarItemSettings";
NSString *const GNPreferencesSelection                  = @"PreferencesSelection";
NSString *const GNShowUnreadCountChangedNotification    = @"GNShowUnreadCountChangedNotification";
NSString *const GNAccountAddedNotification              = @"GNAccountAddedNotification";
NSString *const GNAccountRemovedNotification            = @"GNAccountRemovedNotification";
NSString *const GNAccountChangedNotification            = @"GNAccountChangedNotification";
NSString *const GNAccountsReorderedNotification         = @"GNAccountsReorderedNotification";

NSString *const DefaultsKeyAccounts         = @"Accounts";
NSString *const DefaultsKeyShowUnreadCount  = @"ShowUnreadCount";

// a simple wrapper for preferences values
@implementation GNPreferences

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

        self.autoLaunch = [self inLoginItems];
        self.showUnreadCount = [[NSUserDefaults standardUserDefaults] boolForKey:DefaultsKeyShowUnreadCount];
    }

    return self;
}

- (BOOL)autoLaunch {
    return [self inLoginItems];
}

- (void)setAutoLaunch:(BOOL)val {
    if (val != [self inLoginItems]) {
        if (val) {
            [NSApp addToLoginItems];
        } else {
            [NSApp removeFromLoginItems];
        }
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

    // save accounts to default keychain
    for (id account in _accounts) {
        [SSKeychain setPassword:[account password] forService:KeychainServiceName account:[account username]];
    }
}

#pragma mark - Private Methods

- (BOOL)inLoginItems {
    return [NSApp isInLoginItems];
}

@end