//
//  GNApplicationController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import <MASShortcut/Shortcut.h>
#import "GNApplicationController.h"
#import "GNPreferences.h"
#import "GNAccount.h"
#import "GNBrowser.h"
#import "GNChecker.h"
#import "GNPreferencesController.h"
#import "GNAccountMenuController.h"

@interface GNApplicationController () <NSUserNotificationCenterDelegate>

@property (strong) IBOutlet NSMenu *menu;

@property (weak) IBOutlet NSMenuItem *menuItemCheckAll;
@property (weak) IBOutlet NSMenuItem *menuItemComposeMail;
@property (weak) IBOutlet NSMenuItem *menuItemPreferences;
@property (weak) IBOutlet NSMenuItem *menuItemAbout;
@property (weak) IBOutlet NSMenuItem *menuItemQuit;
@property (weak) IBOutlet NSMenuItem *menuItemRate;

@property (strong) NSStatusItem *statusItem;

@end

@implementation GNApplicationController {
    NSMutableArray *_checkers;
    NSMutableArray *_accountMenuControllers;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];

    [self localizeMenuItems];

    self.statusItem.image = [NSImage imageNamed:@"NoMailsTemplate"];

    [GNPreferences setupDefaults];

    [self registerObservers];

    [self registerMailtoHandler];

    [self registerNotification];

    [self setupMenu];

    [self setupCheckers];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:GNDefaultsKeyCheckAllShortcut toAction:^{
        [self checkAll:nil];
    }];
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

- (IBAction)composeMail:(id)sender {
    GNAccount *account = [GNPreferences sharedInstance].accounts.firstObject;
    NSString *baseURL = account ? [account baseUrl] : @"https://mail.google.com/";
    NSString *url = [baseURL stringByAppendingString:@"?view=cm&tf=0&fs=1"];
    [self openURL:[NSURL URLWithString:url] withBrowserIdentifier:account.browser];
}

- (IBAction)showPreferencesWindow:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[GNPreferencesController sharedController] showWindow:sender];
}

- (IBAction)rateOnAppStore:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/gmail-notifr/id808154494?ls=1&mt=12"]];
}

- (void)showFAQs:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://ashchan.com/projects/gmail-notifr#faqs"]];
}

- (void)showFeedback:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://blog.ashchan.com/archive/2008/10/29/gmail-notifr-changelog/"]];
}

- (void)checkAccount:(id)sender {
    GNAccount *account = [self accountForGuid:[sender representedObject]];
    [[self checkerForAccount:account] reset];
}

- (void)openInbox:(id)sender {
    NSString *guid = [sender representedObject];
    [self openInboxForAccount:[self accountForGuid:guid]];

    // Check this account a short while after opening its inbox, so we don't have to check it
    // again manually just to clear the inbox count, since any unread mail is probably read now.
    // This can only be activated by a hidden default.
    NSTimeInterval autoCheckInterval = [GNPreferences sharedInstance].autoCheckAfterInboxInterval;
    if (autoCheckInterval > 0) {
        [[self checkerForGuid:guid] checkAfterInterval:autoCheckInterval];
    }
}

- (void)toggleAccount:(id)sender {
    GNAccount *account = [self accountForGuid:[sender representedObject]];
    account.enabled = !account.enabled;
    [account save];

    [self updateMenuItemAccountEnabled:account];
    [self updateMainMenu];
}

- (void)openMessage:(id)sender {
    [self openURL:[NSURL URLWithString:[sender representedObject]] withBrowserIdentifier:[GNAccount accountByMessageLink:[sender representedObject]].browser];
}

- (void)accountAdded:(NSNotification *)notification {
    if ([_accountMenuControllers count] == 1) {
        GNAccountMenuController *firstAccountMenuController = [_accountMenuControllers firstObject];
        [firstAccountMenuController detach];
        firstAccountMenuController.singleMode = NO;
        [firstAccountMenuController attachAtIndex:0 actionTarget:self];
        [[_checkers firstObject] reset];
    }

    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    [self createMenuForAccount:account atIndex:[[GNPreferences sharedInstance].accounts count] - 1];

    GNChecker *checker = [[GNChecker alloc] initWithAccount:account];
    [_checkers addObject:checker];
    [checker reset];

    [self updateMainMenu];
}

- (void)accountChanged:(NSNotification *)notification {
    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    [self updateMenuItemAccountEnabled:account];
    [[self checkerForAccount:account] reset];
}

- (void)accountRemoved:(NSNotification *)notification {
    GNAccountMenuController *menuController = [self menuControllerForGuid:[notification userInfo][@"guid"]];
    [menuController detach];
    [_accountMenuControllers removeObject:menuController];

    GNChecker *checker = [self checkerForGuid:[notification userInfo][@"guid"]];
    [checker cleanupAndQuit];
    [_checkers removeObject:checker];

    if ([_accountMenuControllers count] == 1) {
        GNAccountMenuController *singleAccountMenuController = [_accountMenuControllers firstObject];
        [singleAccountMenuController detach];
        singleAccountMenuController.singleMode = YES;
        [singleAccountMenuController attachAtIndex:0 actionTarget:self];
        [self checkAll:nil];
    } else {
        [self updateMenuBarCount:notification];
    }

    [self updateMainMenu];
}

- (void)accountsReordered:(NSNotification *)notification {
    NSMutableDictionary *menuControllers = [[NSMutableDictionary alloc] init];
    for (GNAccount *account in [GNPreferences sharedInstance].accounts) {
        GNAccountMenuController *controller = [self menuControllerForGuid:account.guid];
        [controller detach];
        menuControllers[account.guid] = controller;
    }

    for (NSUInteger i = 0; i < [[GNPreferences sharedInstance].accounts count]; i++) {
        GNAccount *account = [GNPreferences sharedInstance].accounts[i];
        [menuControllers[account.guid] attachAtIndex:i actionTarget:self];
    }

    [self checkAll:nil];
}

- (void)accountChecking:(NSNotification *)notification {
    [_statusItem setToolTip:NSLocalizedString(@"Checking Mail", nil)];
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
                                     urlComponents[1]] stringByReplacingOccurrencesOfString:@"subject=" withString:@"su="];
        }
        NSString *url = [NSString stringWithFormat:@"%@?view=cm&tf=0&fs=1&to=%@%@",
                            [account baseUrl],
                            recipients,
                            additionalParameters];
        [self openURL:[NSURL URLWithString:url] withBrowserIdentifier:account.browser];
    }
}

- (void)registerNotification {
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [self openInboxForAccountName:notification.title browser:[GNAccount accountByUsername:notification.title].browser];
    for (NSUserNotification *noti in center.deliveredNotifications) {
        if ([noti.title isEqualToString:notification.title]) {
            [center removeDeliveredNotification:noti];
        }
    }
}

- (void)setupMenu {
    _accountMenuControllers = [[NSMutableArray alloc] init];
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
            return checker;
        }
    }

    return nil;
}

- (GNChecker *)checkerForGuid:(NSString *)guid {
    for (GNChecker *checker in _checkers) {
        if ([checker isForGuid:guid]) {
            return checker;
        }
    }

    return nil;
}

- (void)openInboxForAccountName:(NSString *)name browser:(NSString *)browser {
    NSString *browserIdentier = browser ? browser : GNBrowserDefaultIdentifier;
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

- (void)updateMainMenu {
    // Update Check All
    NSString *stringToLocalize = [[GNPreferences sharedInstance].accounts count] <= 1 ? @"Check" : @"Check All";
    [self.menuItemCheckAll setTitleWithMnemonic:NSLocalizedString(stringToLocalize, nil)];
    NSArray *enabledAccounts = [[GNPreferences sharedInstance].accounts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject enabled];
    }]];
    [self.menuItemCheckAll setEnabled:[enabledAccounts count] > 0];

    // Show disable icon if no accounts enabled
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
        self.statusItem.button.appearsDisabled = [GNPreferences sharedInstance].allAccountsDisabled;
    }
}

- (void)localizeMenuItems {
    [self updateMainMenu];
    [self.menuItemComposeMail setTitleWithMnemonic:NSLocalizedString(@"Compose Mail", nil)];
    [self.menuItemPreferences setTitleWithMnemonic:NSLocalizedString(@"Preferences...", nil)];
    [self.menuItemAbout setTitleWithMnemonic:NSLocalizedString(@"About Gmail Notifr", nil)];
    [self.menuItemQuit setTitleWithMnemonic:NSLocalizedString(@"Quit Gmail Notifr", nil)];
    [self.menuItemRate setTitleWithMnemonic:NSLocalizedString(@"Rate on App Store", nil)];
}

- (void)createMenuForAccount:(GNAccount *)account atIndex:(NSUInteger)index {
    GNAccountMenuController *menuController = [[GNAccountMenuController alloc] initWithStatusItem:self.statusItem GNAccount:account];
    menuController.singleMode = [[GNPreferences sharedInstance].accounts count] == 1;
    [_accountMenuControllers addObject:menuController];
    [menuController attachAtIndex:index actionTarget:self];
}

- (void)updateAccountMenuItem:(NSNotification *)notification {
    GNAccount *account = [self accountForGuid:[notification userInfo][@"guid"]];
    GNAccountMenuController *menuController = [self menuControllerForGuid:account.guid];
    [menuController updateWithChecker:[self checkerForAccount:account]];
    [self updateMenuBarCount:notification];
}

- (void)updateMenuItemAccountEnabled:(GNAccount *)account {
    GNAccountMenuController *controller = [self menuControllerForGuid:account.guid];
    [controller updateStatus];
}

- (void)updateMenuBarCount:(NSNotification *)notification {
    NSMutableString *menuText = [NSMutableString new];
    NSMutableString *tooltipText = [NSMutableString new];
    NSUInteger messageCount = 0;
    BOOL useSeparateUnreadCounts = [GNPreferences sharedInstance].useSeparateUnreadCounts;
    for (GNChecker *checker in _checkers) {
        // show separate unread mail counts for each account (ie: "0:2")
        if (useSeparateUnreadCounts) {
            if ([menuText length] > 0) {
                [menuText appendString:@":"];
            }
            [menuText appendFormat:@"%d", (int)[checker messageCount]];
        }
        // show separate unread mail count in tooltips
        if ([tooltipText length] > 0) {
            [tooltipText appendString:@"\n"];
        }
        [tooltipText appendFormat:@"%@ (%d)", [checker.account username], (int)[checker messageCount]];

        messageCount += [checker messageCount];
    }

    if (!useSeparateUnreadCounts) {
        [menuText appendFormat:@"%d", (int)messageCount];
    }

    if (messageCount > 0 && [GNPreferences sharedInstance].showUnreadCount) {
        [_statusItem setTitle:menuText];
    } else {                                  
        [_statusItem setTitle:@""];
    }

    if (messageCount > 0) {
        [self.statusItem setToolTip:tooltipText];

        if ([GNPreferences sharedInstance].useColorIcon) {
            self.statusItem.image = [NSImage imageNamed:@"HaveMails-red"];
        } else {
            self.statusItem.image = [NSImage imageNamed:@"HaveMailsTemplate"];
        }
    } else {
        [self.statusItem setToolTip:@""];
        self.statusItem.image = [NSImage imageNamed:@"NoMailsTemplate"];
    }
}

- (GNAccountMenuController *)menuControllerForGuid:(NSString *)guid {
    for (GNAccountMenuController *controller in _accountMenuControllers) {
        if ([controller.guid isEqualToString:guid]) {
            return controller;
        }
    }

    return nil;
}

@end
