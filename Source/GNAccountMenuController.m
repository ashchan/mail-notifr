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

static const NSInteger kTopSeparatorMenuItemTag      = 10001;
static const NSInteger kBottomSeparatorMenuItemTag   = 10002;
static const NSInteger kAboveMessagesMenuItemTag     = 10003;

@interface GNAccountMenuController ()

@property (weak) NSStatusItem *statusItem;
@property (strong) GNAccount *account;
@property (strong) NSMenuItem *checkMenuItem;
@property (strong) NSMenuItem *enableAccountMenuItem;

@end

@implementation GNAccountMenuController {
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem GNAccount:(GNAccount *)account {
    if (self = [super init]) {
        _statusItem     = statusItem;
        _account        = account;
    }
    return self;
}

- (NSString *)guid {
    return self.account.guid;
}

- (void)attachAtIndex:(NSInteger)index actionTarget:(id)target {
    NSMenuItem *openInboxItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Inbox", nil) action:@selector(openInbox:) keyEquivalent:@""];
    [openInboxItem setRepresentedObject:self.guid];
    [openInboxItem setTarget:target];
    [openInboxItem setEnabled:YES];

    self.checkMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Check", nil) action:@selector(checkAccount:) keyEquivalent:@""];
    [self.checkMenuItem setRepresentedObject:self.guid];
    [self.checkMenuItem setTarget:target];
    [self.checkMenuItem setEnabled:self.account.enabled];
    self.checkMenuItem.hidden = self.singleMode;

    self.enableAccountMenuItem = [[NSMenuItem alloc] initWithTitle:self.account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil)
                                                            action:@selector(toggleAccount:)
                                                     keyEquivalent:@""];
    [self.enableAccountMenuItem setRepresentedObject:self.guid];
    [self.enableAccountMenuItem setTarget:target];
    [self.enableAccountMenuItem setEnabled:YES];

    if (self.singleMode) {
        NSUInteger indexForTopSeparator = [self indexForMenuItemWithTag:kTopSeparatorMenuItemTag];
        [self.statusItem.menu insertItem:openInboxItem atIndex:++indexForTopSeparator];
        [self.statusItem.menu insertItem:self.checkMenuItem atIndex:++indexForTopSeparator];
        NSMenuItem *separator = [NSMenuItem separatorItem];
        separator.tag = kAboveMessagesMenuItemTag;
        [self.statusItem.menu insertItem:separator atIndex:++indexForTopSeparator];
        [self.statusItem.menu insertItem:self.enableAccountMenuItem atIndex:++indexForTopSeparator];
    } else {
        NSMenu *accountMenu = [[NSMenu alloc] initWithTitle:self.guid];
        [accountMenu setAutoenablesItems:NO];

        [accountMenu addItem:openInboxItem];
        [accountMenu addItem:self.checkMenuItem];
        NSMenuItem *separator = [NSMenuItem separatorItem];
        separator.tag = kAboveMessagesMenuItemTag;
        [accountMenu addItem:separator];
        [accountMenu addItem:self.enableAccountMenuItem];

        NSMenuItem *accountItem = [[NSMenuItem alloc] init];
        [accountItem setTitle:self.account.username];
        [accountItem setRepresentedObject:self.guid];
        [accountItem setSubmenu:accountMenu];
        [accountItem setTarget:target];
        [accountItem setAction:@selector(openInbox:)];

        [self addAccountMenuItem:accountItem atIndex:index];
    }
}

- (void)detach {
    if (self.singleMode) {
        NSUInteger indexForTopSeparator = [self indexForMenuItemWithTag:kTopSeparatorMenuItemTag];
        NSUInteger indexForBottomSeparator = [self indexForMenuItemWithTag:kBottomSeparatorMenuItemTag];
        NSInteger numbersOfItemsToRemove = indexForBottomSeparator - indexForTopSeparator - 1;
        for (; numbersOfItemsToRemove-- > 0;) {
            [self.statusItem.menu removeItemAtIndex:indexForTopSeparator + 1];
        }
    } else {
        [self.statusItem.menu removeItem:[self menuItem]];
    }
}

- (void)updateStatus {
    self.enableAccountMenuItem.title = self.account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil);
    self.checkMenuItem.enabled = self.account.enabled;
}

- (void)updateWithChecker:(GNChecker *)checker {
    NSMenu *menu = self.singleMode ? [self.statusItem menu] : [[self menuItem] submenu];
    NSUInteger indexForInsert = self.singleMode ? [self indexForMenuItemWithTag:kAboveMessagesMenuItemTag] : [self indexForSubMenuItemWithTag:kAboveMessagesMenuItemTag];
    if (!self.singleMode) {
        [[self menuItem] setTitle:self.account.username];
    }

    [self removeMessagesMenuItems];

    if (self.account.enabled) {
        if ([checker hasConnectionError] || [checker hasUserError]) {
            NSString *title = [checker hasConnectionError] ? NSLocalizedString(@"Connection Error", nil) : NSLocalizedString(@"Username/password Wrong", nil);
            NSMenuItem *errorItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
            [errorItem setEnabled:NO];
            [menu insertItem:errorItem atIndex:++indexForInsert];
            [menu insertItem:[NSMenuItem separatorItem] atIndex:++indexForInsert];
            if (!self.singleMode) {
                [[self menuItem] setImage:[NSImage imageNamed:@"error"]];
            }
        } else {
            // messages list
            for (NSDictionary *message in [checker messages]) {
                NSMenuItem *messageItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@", message[@"author"], message[@"subject"]]
                                                                     action:@selector(openMessage:)
                                                              keyEquivalent:@""];
                [messageItem setToolTip:message[@"summary"]];
                [messageItem setEnabled:YES];
                [messageItem setRepresentedObject:message[@"link"]];
                [messageItem setTarget:self.enableAccountMenuItem.target];
                [menu insertItem:messageItem atIndex:++indexForInsert];
            }
            if ([checker messageCount] > 0) {
                [menu insertItem:[NSMenuItem separatorItem] atIndex:++indexForInsert];
            }

            if (!self.singleMode) {
                [[self menuItem] setImage:nil];
                [[self menuItem] setTitle:[NSString stringWithFormat:@"%@ (%lu)", self.account.username, [checker messageCount]]];
            }
        }

        // recent check timestamp
        NSString *timestampTitle = [[NSLocalizedString(@"Last Checked:", nil) stringByAppendingString:@" "] stringByAppendingString:checker.lastCheckedAt];
        NSMenuItem *lastCheckedMenuItem = [[NSMenuItem alloc] initWithTitle:timestampTitle action:nil keyEquivalent:@""];
        lastCheckedMenuItem.enabled = NO;
        [menu insertItem:lastCheckedMenuItem atIndex:++indexForInsert];
    }

    [menu insertItem:self.enableAccountMenuItem atIndex:++indexForInsert];
}

- (void)removeMessagesMenuItems {
    if (self.singleMode) {
        NSUInteger indexForMessagesSeparator = [self indexForMenuItemWithTag:kAboveMessagesMenuItemTag];
        NSUInteger indexForBottomSeparator = [self indexForMenuItemWithTag:kBottomSeparatorMenuItemTag];
        NSInteger numbersOfItemsToRemove = indexForBottomSeparator - indexForMessagesSeparator - 1;
        for (; numbersOfItemsToRemove-- > 0;) {
            [self.statusItem.menu removeItemAtIndex:indexForMessagesSeparator + 1];
        }
    } else {
        NSUInteger indexForMessagesSeparator = [self indexForSubMenuItemWithTag:kAboveMessagesMenuItemTag];
        NSInteger numbersOfItemsToRemove = [[[[self menuItem] submenu] itemArray] count] - indexForMessagesSeparator - 1;
        for (; numbersOfItemsToRemove-- > 0;) {
            [[[self menuItem] submenu] removeItemAtIndex:indexForMessagesSeparator + 1];
        }
    }
}

- (void)addAccountMenuItem:(NSMenuItem *)item atIndex:(NSUInteger)index {
    [self.statusItem.menu insertItem:item atIndex:[self accountMenuItemPos] + index];
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

- (NSUInteger)indexForMenuItemWithTag:(NSUInteger)tag {
    for (NSUInteger idx = 0; idx < [[self.statusItem.menu itemArray] count]; ++idx) {
        if (tag == ((NSMenuItem *)[self.statusItem.menu itemArray][idx]).tag) {
            return idx;
        }
    }
    NSAssert(FALSE, @"Should find menu item for tag");
    return NSNotFound;
}

- (NSUInteger)accountMenuItemPos {
    return [self indexForMenuItemWithTag:kTopSeparatorMenuItemTag] + 1;
}

- (NSUInteger)indexForSubMenuItemWithTag:(NSUInteger)tag {
    for (NSUInteger idx = 0; idx < [[[[self menuItem] submenu] itemArray] count]; ++idx) {
        if (tag == ((NSMenuItem *)[[[self menuItem] submenu] itemArray][idx]).tag) {
            return idx;
        }
    }
    NSAssert(FALSE, @"Should find sub menu item for tag");
    return NSNotFound;
}

#pragma clang diagnostic pop

@end
