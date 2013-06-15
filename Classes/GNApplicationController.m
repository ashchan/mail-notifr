//
//  GNApplicationController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import "GNApplicationController.h"
#import "GNPreferences.h"
#import <Growl/GrowlApplicationBridge.h>
#import "GNAccount.h"
#import "GNBrowser.h"
#import "GNChecker.h"
#import "GNPreferencesController.h"

@interface GNApplicationController () <GrowlApplicationBridgeDelegate>

@property (strong) IBOutlet NSMenu *menu;

@property (weak) IBOutlet NSMenuItem *menuItemCheckAll;
@property (weak) IBOutlet NSMenuItem *menuItemPreferences;
@property (weak) IBOutlet NSMenuItem *menuItemCheckUpdate;
@property (weak) IBOutlet NSMenuItem *menuItemAbout;
@property (weak) IBOutlet NSMenuItem *menuItemDonate;
@property (weak) IBOutlet NSMenuItem *menuItemQuit;

@property (strong) NSStatusItem *statusItem;

@end

@implementation GNApplicationController {
    NSImage *_appIcon;
    NSImage *_appAltIcon;
    NSImage *_mailIcon;
    NSImage *_mailAltIcon;
    NSImage *_checkIcon;
    NSImage *_checkAltIcon;
    NSImage *_errorIcon;

    NSMutableArray *_checkers;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadIcons];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];

    [self localizeMenuItems];
    
    [self.statusItem setImage:_appIcon];
    [self.statusItem setAlternateImage:_appAltIcon];

    [GNPreferences setupDefaults];

    [self registerObservers];

    [self registerMailtoHandler];

    [self registerGrowl];

    [self setupMenu];

    [self setupCheckers];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)showAbout:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
}

- (IBAction)checkAll:(id)sender {
    [self checkAllAccounts];
}

- (IBAction)showPreferencesWindow:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[GNPreferencesController sharedController] showWindow:sender];
}

- (IBAction)donate:(id)sedner {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.pledgie.com/campaigns/2046"]];
}

- (void)checkAccount:(id)sender {
    GNAccount *account = [self accountForGuid:[[sender menu] title]];
    [[self checkerForAccount:account] reset];
}

- (void)openInbox:(id)sender {
    NSString *guid = [[sender title] isEqualToString:NSLocalizedString(@"Open Inbox", nil)] ? [[sender menu] title] : [[sender submenu] title];
    [self openInboxForAccount:[self accountForGuid:guid]];
}

- (void)toggleAccount:(id)sender {
    GNAccount *account = [self accountForGuid:[[sender menu] title]];
    account.enabled = !account.enabled;
    [account save];

    [self updateMenuItemAccountEnabled:account];
}

- (void)openMessage:(id)sender {
    [self openURL:[NSURL URLWithString:[sender representedObject]] withBrowserIdentifier:[GNAccount accountByMessageLink:[sender representedObject]].browser];
}

- (void)accountAdded:(NSNotification *)notification {
    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    [self createMenuForAccount:account atIndex:[[GNPreferences sharedInstance].accounts count] - 1];
    GNChecker *checker = [[GNChecker alloc] initWithAccount:account];
    [_checkers addObject:checker];
    [checker reset];
}

- (void)accountChanged:(NSNotification *)notification {
    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    [self updateMenuItemAccountEnabled:account];
    [[self checkerForAccount:account] reset];
}

- (void)accountRemoved:(NSNotification *)notification {
    NSMenuItem *item = [self menuItemForGuid:[notification userInfo][@"guid"]];
    [[_statusItem menu] removeItem:item];
    GNChecker *checker = [self checkerForGuid:[notification userInfo][@"guid"]];
    [checker cleanupAndQuit];
    [_checkers removeObject:checker];
    [self updateMenuBarCount:notification];
}

- (void)accountsReordered:(NSNotification *)notification {
    NSMutableDictionary *menuItems = [[NSMutableDictionary alloc] init];
    for (GNAccount *account in [GNPreferences sharedInstance].accounts) {
        NSMenuItem *menuItem = [self menuItemForGuid:account.guid];
        [[_statusItem menu] removeItem:menuItem];
        menuItems[account.guid] = menuItem;
    }

    for (NSUInteger i = 0; i < [[GNPreferences sharedInstance].accounts count]; i++) {
        GNAccount *account = [GNPreferences sharedInstance].accounts[i];
        [self addAccountMenuItem:menuItems[account.guid] atIndex:i];
    }
}

- (void)accountChecking:(NSNotification *)notification {
    [_statusItem setToolTip:NSLocalizedString(@"Checking Mail", nil)];
    [_statusItem setImage:_checkIcon];
    [_statusItem setAlternateImage:_checkAltIcon];
}

- (void)loadIcons {
    _appIcon        = [NSImage imageNamed:@"app"];
    _appAltIcon     = [NSImage imageNamed:@"app_a"];
    _mailIcon       = [NSImage imageNamed:@"mail"];
    _mailAltIcon    = [NSImage imageNamed:@"mail_a"];
    _checkIcon      = [NSImage imageNamed:@"check"];
    _checkAltIcon   = [NSImage imageNamed:@"check_a"];
    _errorIcon      = [NSImage imageNamed:@"error"];
}

- (void)registerObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateMenuBarCount:) name:GNShowUnreadCountChangedNotification object:nil];
    [center addObserver:self selector:@selector(accountAdded:) name:GNAccountAddedNotification object:nil];
    [center addObserver:self selector:@selector(accountChanged:) name:GNAccountChangedNotification object:nil];
    [center addObserver:self selector:@selector(accountRemoved:) name:GNAccountRemovedNotification object:nil];
    [center addObserver:self selector:@selector(updateAccountMenuItem:) name:GNAccountMenuUpdateNotification object:nil];
    [center addObserver:self selector:@selector(accountChecking:) name:GNCheckingAccountNotification object:nil];
    [center addObserver:self selector:@selector(accountsReordered:) name:GNAccountsReorderedNotification object:nil];
}

- (void)registerMailtoHandler {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleMailToEvent:eventReply:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleMailToEvent:(NSAppleEventDescriptor *)event eventReply:(NSAppleEventDescriptor *)replyEvent {
    if ([[GNPreferences sharedInstance].accounts count] > 0) {
        GNAccount *account = [GNPreferences sharedInstance].accounts[0];
        NSString *link = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
        NSArray *urlComponents = [link componentsSeparatedByString:@"?"];
        NSString *recipients = [urlComponents[0] stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
        NSString *additionalParameters = @"";
        if ([urlComponents count] > 1) {
            // For some reason, Gmail does not interpret the query parameter "subject" correctly, and needs "su" instead.
            additionalParameters = [[NSString stringWithFormat:@"&%@",
                                     urlComponents[1]] stringByReplacingOccurrencesOfString:@"subject" withString:@"su"];
        }
        NSString *url = [NSString stringWithFormat:@"%@?view=cm&tf=0&fs=1&to=%@%@",
                            [account baseUrl],
                            recipients,
                            additionalParameters];
        [self openURL:[NSURL URLWithString:url] withBrowserIdentifier:account.browser];
    }
}

- (void)registerGrowl {
    [GrowlApplicationBridge setGrowlDelegate:self];
}

- (NSString *)applicationNameForGrowl {
    return @"Gmail Notifr";
}

- (void)growlNotificationWasClicked:(id)clickContext {
    if (clickContext) {
        [self openInboxForAccountName:clickContext browser:[GNAccount accountByUsername:clickContext].browser];
    }
}

- (void)setupMenu {
    for (NSUInteger i = 0; i < [[GNPreferences sharedInstance].accounts count]; i++) {
        GNAccount *account = [GNPreferences sharedInstance].accounts[i];
        [self createMenuForAccount:account atIndex:i];
    }
}

- (void)setupCheckers {
    _checkers = [[NSMutableArray alloc] init];
    for (GNAccount *account in [GNPreferences sharedInstance].accounts) {
        [_checkers addObject:[[GNChecker alloc] initWithAccount:account]];
    }

    [self checkAllAccounts];
}

- (void)checkAllAccounts {
    for (GNChecker *checker in _checkers) {
        [checker reset];
    }
}

- (GNAccount *)accountForGuid:(NSString *)guid {
    for (GNAccount *account in [GNPreferences sharedInstance].accounts) {
        if ([account.guid isEqualToString:guid]) {
            return account;
        }
    }

    return nil;
}

- (GNChecker *)checkerForAccount:(GNAccount *)account {
    for (GNChecker *checker in _checkers) {
        if ([checker isForAccount:account]) {
            return checker;;
        }
    }

    return nil;
}

- (GNChecker *)checkerForGuid:(NSString *)guid {
    for (GNChecker *checker in _checkers) {
        if ([checker isForGuid:guid]) {
            return checker;;
        }
    }

    return nil;
}

- (NSUInteger)messageCount {
    NSUInteger count = 0;
    for (GNChecker *checker in _checkers) {
        count += [checker messageCount];
    }

    return count;
}

- (void)openInboxForAccountName:(NSString *)name browser:(NSString *)browser {
    NSString *browserIdentier = browser ? browser : DefaultBrowserIdentifier;
    [self openURL:[NSURL URLWithString:[GNAccount baseUrlForUsername:name]] withBrowserIdentifier:browserIdentier];
}

- (void)openInboxForAccount:(GNAccount *)account {
    [self openInboxForAccountName:account.username browser:account.browser];
}

- (void)openURL:(NSURL *)url withBrowserIdentifier:(NSString *)browserIdentifier {
    if ([GNBrowser isDefault:browserIdentifier]) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    } else {
        [[NSWorkspace sharedWorkspace] openURLs:@[url]
                        withAppBundleIdentifier:browserIdentifier
                                        options:NSWorkspaceLaunchDefault
                 additionalEventParamDescriptor:nil
                              launchIdentifiers:nil];
    }
}

#pragma mark - Menu Manipulation

const NSUInteger ACCOUNT_MENUITEM_POS           = 2;
const NSUInteger CHECK_MENUITEM_POS             = 1;
const NSUInteger ENABLE_MENUITEM_POS            = 2;
const NSUInteger DEFAULT_ACCOUNT_SUBMENU_COUNT  = 4;

- (void)localizeMenuItems {
    [self.menuItemCheckAll setTitleWithMnemonic:NSLocalizedString(@"Check All", nil)];
    [self.menuItemPreferences setTitleWithMnemonic:NSLocalizedString(@"Preferences...", nil)];
    [self.menuItemCheckUpdate setTitleWithMnemonic:NSLocalizedString(@"Check for Updates...", nil)];
    [self.menuItemAbout setTitleWithMnemonic:NSLocalizedString(@"About Gmail Notifr", nil)];
    [self.menuItemDonate setTitleWithMnemonic:NSLocalizedString(@"Donate...", nil)];
    [self.menuItemQuit setTitleWithMnemonic:NSLocalizedString(@"Quit Gmail Notifr", nil)];
}

- (void)createMenuForAccount:(GNAccount *)account atIndex:(NSUInteger)index {
    NSMenu *accountMenu = [[NSMenu alloc] initWithTitle:account.guid];
    [accountMenu setAutoenablesItems:NO];

    NSMenuItem *openInboxItem = [accountMenu addItemWithTitle:NSLocalizedString(@"Open Inbox", nil) action:@selector(openInbox:) keyEquivalent:@""];
    [openInboxItem setTarget:self];
    [openInboxItem setEnabled:YES];

    NSMenuItem *checkItem = [accountMenu addItemWithTitle:NSLocalizedString(@"Check", nil) action:@selector(checkAccount:) keyEquivalent:@""];
    [checkItem setTarget:self];
    [checkItem setEnabled:account.enabled];

    NSMenuItem *enableAccountItem = [accountMenu addItemWithTitle:account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil)
                                                           action:@selector(toggleAccount:)
                                                    keyEquivalent:@""];
    [enableAccountItem setTarget:self];
    [enableAccountItem setEnabled:YES];

    [accountMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *accountItem = [[NSMenuItem alloc] init];
    [accountItem setTitle:account.username];
    [accountItem setSubmenu:accountMenu];
    [accountItem setTarget:self];
    [accountItem setAction:@selector(openInbox:)];

    [self addAccountMenuItem:accountItem atIndex:index];
}

- (void)updateAccountMenuItem:(NSNotification *)notification {
    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    NSMenuItem *menuItem = [self menuItemForAccount:account];
    [menuItem setTitle:account.username];

    NSUInteger count = [[[menuItem submenu] itemArray] count];
    if (count > DEFAULT_ACCOUNT_SUBMENU_COUNT) {
        for (NSUInteger i = count - 1; i >= DEFAULT_ACCOUNT_SUBMENU_COUNT; i--) {
            [[menuItem submenu] removeItemAtIndex:i];
        }
    }

    if (account.enabled) {
        GNChecker *checker = [self checkerForAccount:account];
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
            [menuItem setTitle:[NSString stringWithFormat:@"%@ (%lu)", account.username, [checker messageCount]]];
        }
 
        if ([checker messageCount] > 0) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        }

        // recent check timestamp
        NSString *timestampTitle = [[NSLocalizedString(@"Last Checked:", nil) stringByAppendingString:@" "] stringByAppendingString:[notification userInfo][@"checkedAt"]];
        [[[menuItem submenu] addItemWithTitle:timestampTitle action:nil keyEquivalent:@""] setEnabled:NO];
    }

    [self updateMenuBarCount:notification];
}

- (void)updateMenuBarCount:(NSNotification *)notification {
    NSUInteger messageCount = [self messageCount];

    if (messageCount > 0 && [GNPreferences sharedInstance].showUnreadCount) {
        [_statusItem setTitle:[NSString stringWithFormat:@"%lu", messageCount]];
    } else {
        [_statusItem setTitle:@""];
    }

    if (messageCount > 0) {
        NSString *toolTipFormat = messageCount == 1 ? NSLocalizedString(@"Unread Message", nil) : NSLocalizedString(@"Unread Messages", nil);
#warning This is duplication. See GNChecker#processResult
        if ([[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqualToString:@"ru"]) {
            NSUInteger count = messageCount % 100;
            if ((count % 10 > 4) || (count % 10 == 0) || ((count > 10) && (count < 15))) {
                toolTipFormat = NSLocalizedString(@"Unread Messages", nil);
            } else if (count % 10 == 1) {
                toolTipFormat = NSLocalizedString(@"Unread Message", nil);
            } else {
                toolTipFormat = NSLocalizedString(@"Unread Messages 2", nil);
            }
        }

        [_statusItem setToolTip:[NSString stringWithFormat:toolTipFormat, messageCount]];
        [_statusItem setImage:_mailIcon];
        [_statusItem setAlternateImage:_mailAltIcon];
    } else {
        [_statusItem setToolTip:@""];
        [_statusItem setImage:_appIcon];
        [_statusItem setAlternateImage:_appAltIcon];
    }
}

- (void)addAccountMenuItem:(NSMenuItem *)item atIndex:(NSUInteger)index {
    [[_statusItem menu] insertItem:item atIndex:ACCOUNT_MENUITEM_POS + index];
}

- (NSMenuItem *)menuItemForAccount:(GNAccount *)account {
    return [self menuItemForGuid:account.guid];
}

- (NSMenuItem *)menuItemForGuid:(NSString *)guid {
    for (NSMenuItem *item in [[_statusItem menu] itemArray]) {
        if ([[[item submenu] title] isEqualToString:guid]) {
            return item;
        }
    }

    return nil;
}

- (void)updateMenuItemAccountEnabled:(GNAccount *)account {
    NSMenu *menu = [[self menuItemForAccount:account] submenu];
    [menu itemAtIndex:ENABLE_MENUITEM_POS].title = account.enabled ? NSLocalizedString(@"Disable Account", nil) : NSLocalizedString(@"Enable Account", nil);
    [menu itemAtIndex:CHECK_MENUITEM_POS].enabled = account.enabled;
}

@end
