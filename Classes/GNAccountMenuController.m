//
//  GNAccountMenuController.m
//  Mail Notifr
//
//  Created by James Chen on 3/23/14.
//  Copyright (c) 2014 ashchan.com. All rights reserved.
//

#import "GNAccountMenuController.h"
#import "GNAccount.h"
#import "GNChecker.h"

static const NSUInteger kAccountMenuItemPos           = 2;
static const NSUInteger kCheckMenuItemPos             = 1;
static const NSUInteger kEnableMenuItemPos            = 2;
static const NSUInteger kDefaultAccountSubmenuCount   = 4;

@interface GNAccountMenuController ()

@property (nonatomic, weak) NSStatusItem *statusItem;
@property (nonatomic, strong) GNAccount *account;

@end

@implementation GNAccountMenuController {
    NSImage *_errorIcon;
}

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem GNAccount:(GNAccount *)account {
    if (self = [super init]) {
        _statusItem     = statusItem;
        _account        = account;
        _errorIcon      = [NSImage imageNamed:@"error"];
    }
    return self;
}

- (NSString *)guid {
    return self.account.guid;
}

- (void)attachAtIndex:(NSInteger *)index actionTarget:(id)target {
    NSMenu *accountMenu = [[NSMenu alloc] initWithTitle:self.guid];
    [accountMenu setAutoenablesItems:NO];

    NSMenuItem *openInboxItem = [accountMenu addItemWithTitle:NSLocalizedString(@"Open Inbox", nil) action:@selector(openInbox:) keyEquivalent:@""];
    [openInboxItem setTarget:target];
    [openInboxItem setEnabled:YES];

    NSMenuItem *checkItem = [accountMenu addItemWithTitle:NSLocalizedString(@"Check", nil) action:@selector(checkAccount:) keyEquivalent:@""];
    [checkItem setTarget:target];
    [checkItem setEnabled:self.account.enabled];

    NSMenuItem *enableAccountItem = [accountMenu addItemWithTitle:self.account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil)
                                                           action:@selector(toggleAccount:)
                                                    keyEquivalent:@""];
    [enableAccountItem setTarget:target];
    [enableAccountItem setEnabled:YES];

    [accountMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *accountItem = [[NSMenuItem alloc] init];
    [accountItem setTitle:self.account.username];
    [accountItem setSubmenu:accountMenu];
    [accountItem setTarget:target];
    [accountItem setAction:@selector(openInbox:)];

    [self addAccountMenuItem:accountItem atIndex:index];
}

- (void)detach {
    [self.statusItem.menu removeItem:[self menuItem]];
}

- (void)updateStatus {
    NSMenu *menu = [[self menuItem] submenu];
    [menu itemAtIndex:kEnableMenuItemPos].title = self.account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil);
    [menu itemAtIndex:kCheckMenuItemPos].enabled = self.account.enabled;
}

- (void)updateWithChecker:(GNChecker *)checker {
    NSMenuItem *menuItem = [self menuItem];
    [menuItem setTitle:self.account.username];

    NSUInteger count = [[[menuItem submenu] itemArray] count];
    if (count > kDefaultAccountSubmenuCount) {
        for (NSUInteger i = count - 1; i >= kDefaultAccountSubmenuCount; i--) {
            [[menuItem submenu] removeItemAtIndex:i];
        }
    }

    if (self.account.enabled) {
        if ([checker hasConnectionError] || [checker hasUserError]) {
            NSString *title = [checker hasConnectionError] ? NSLocalizedString(@"Connection Error", nil) : NSLocalizedString(@"Username/password Wrong", nil);
            NSMenuItem *errorItem = [[menuItem submenu] addItemWithTitle:title action:nil keyEquivalent:@""];
            [errorItem setEnabled:NO];
            [menuItem setImage:_errorIcon];
        } else {
            // messages list
            for (NSDictionary *message in [checker messages]) {
                NSMenuItem *messageItem = [[menuItem submenu] addItemWithTitle:[NSString stringWithFormat:@"%@: %@", message[@"author"], message[@"subject"]]
                                                                        action:@selector(openMessage:)
                                                                 keyEquivalent:@""];
                [messageItem setToolTip:message[@"summary"]];
                [messageItem setEnabled:YES];
                [messageItem setRepresentedObject:message[@"link"]];
                [messageItem setTarget:self];
            }

            [menuItem setImage:nil];
            [menuItem setTitle:[NSString stringWithFormat:@"%@ (%lu)", self.account.username, [checker messageCount]]];
        }
 
        if ([checker messageCount] > 0) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        }

        // recent check timestamp
        NSString *timestampTitle = [[NSLocalizedString(@"Last Checked:", nil) stringByAppendingString:@" "] stringByAppendingString:checker.lastCheckedAt];
        [[[menuItem submenu] addItemWithTitle:timestampTitle action:nil keyEquivalent:@""] setEnabled:NO];
    }
}

- (void)addAccountMenuItem:(NSMenuItem *)item atIndex:(NSUInteger)index {
    [self.statusItem.menu insertItem:item atIndex:kAccountMenuItemPos + index];
}

- (NSMenuItem *)menuItem {
    return [self menuItemForGuid:self.guid];
}

- (NSMenuItem *)menuItemForGuid:(NSString *)guid {
    for (NSMenuItem *item in [self.statusItem.menu itemArray]) {
        if ([[[item submenu] title] isEqualToString:guid]) {
            return item;
        }
    }

    return nil;
}

@end
