//
//  GNAccountDetailController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import "GNAccountDetailController.h"
#import <AppKit/NSSound.h>
#import "GNAccount.h"
#import "GNBrowser.h"
#import "GNSound.h"

@interface GNAccountDetailController ()

@property (weak) IBOutlet NSTextField   *usernameLabel;
@property (weak) IBOutlet NSTextField   *passwordLabel;
@property (weak) IBOutlet NSTextField   *checkLabel;
@property (weak) IBOutlet NSTextField   *minuteLabel;
@property (weak) IBOutlet NSTextField   *browserLabel;
@property (weak) IBOutlet NSTextField   *soundLabel;
@property (weak) IBOutlet NSTextField   *hint;
@property (weak) IBOutlet NSButton      *okButton;
@property (weak) IBOutlet NSButton      *cancelButton;
@property (weak) IBOutlet NSTextField   *username;
@property (weak) IBOutlet NSTextField   *password;
@property (weak) IBOutlet NSTextField   *interval;
@property (weak) IBOutlet NSButton      *accountEnabled;
@property (weak) IBOutlet NSButton      *growl;
@property (weak) IBOutlet NSPopUpButton *soundList;
@property (weak) IBOutlet NSPopUpButton *browserList;

@property (retain) GNAccount *account;

@end

@implementation GNAccountDetailController

- (id)initWithAccount:(GNAccount *)account {
    if (self = [super initWithWindowNibName:@"AccountDetail"]) {
        self.account = account;
    }

    return self;
}

+ (void)editAccount:(GNAccount *)account onWindow:(NSWindow *)window {
    static GNAccountDetailController *_accountDetailController;
    _accountDetailController = [[GNAccountDetailController alloc] initWithAccount:account];
    [NSApp beginSheet:[_accountDetailController window]
       modalForWindow:window
        modalDelegate:_accountDetailController
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)awakeFromNib {
    [self.soundList removeAllItems];
    [self.soundList addItemWithTitle:GNSoundNone];
    [[self.soundList menu] addItem:[NSMenuItem separatorItem]];
    for (NSString *sound in [GNSound all]) {
        [self.soundList addItemWithTitle:sound];
    }
    [self.soundList selectItemWithTitle:self.account.sound];

    [self.interval setTitleWithMnemonic:[NSString stringWithFormat:@"%ld", self.account.interval]];
    [self.accountEnabled setState:self.account.enabled ? NSOnState : NSOffState];
    [self.growl setState:self.account.growl ? NSOnState : NSOffState];
    [self.username setTitleWithMnemonic:self.account.username];
    [self.password setTitleWithMnemonic:self.account.password];

    [self.browserList removeAllItems];
    for (NSArray *browser in [GNBrowser all]) {
        [self.browserList addItemWithTitle:browser[0]];
    }
    [self.browserList selectItemWithTitle:[GNBrowser getNameByIdentifier:self.account.browser]];

    [self.usernameLabel setTitleWithMnemonic:NSLocalizedString(@"Username:", nil)];
    [self.passwordLabel setTitleWithMnemonic:NSLocalizedString(@"Password:", nil)];
    [self.checkLabel setTitleWithMnemonic:NSLocalizedString(@"Check for new mail every", nil)];
    [self.minuteLabel setTitleWithMnemonic:NSLocalizedString(@"minutes", nil)];
    [self.accountEnabled setTitle:NSLocalizedString(@"Enable this account", nil)];
    [self.growl setTitle:NSLocalizedString(@"Use Growl Notification", nil)];
    [self.soundLabel setTitleWithMnemonic:NSLocalizedString(@"Play sound:", nil)];
    [self.browserLabel setTitleWithMnemonic:NSLocalizedString(@"Open in browser:", nil)];
    [self.hint setTitleWithMnemonic:NSLocalizedString(@"To add a Google Hosted Account, specify the full email address as username, eg: admin@ashchan.com.", nil)];
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)];
    [self.okButton setTitle:NSLocalizedString(@"OK", nil)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:nil];
}

- (IBAction)save:(id)sender {
    self.account.sound      = [self.soundList titleOfSelectedItem];
    self.account.interval   = [self.interval integerValue];
    self.account.enabled    = [self.accountEnabled state] == NSOnState;
    self.account.growl      = [self.growl state] == NSOnState;
    self.account.username   = [self.username stringValue];
    self.account.password   = [self.password stringValue];
    self.account.browser    = [GNBrowser getIdentifierByName:[self.browserList titleOfSelectedItem]];
    [self.account save];

    [self closeWindow];
}

- (IBAction)cancel:(id)sender {
    [self closeWindow];
}

- (IBAction)soundSelected:(id)sender {
    [[NSSound soundNamed:[self.soundList titleOfSelectedItem]] play];
}

- (void)closeWindow {
    [NSApp endSheet:[self window]];
}

@end
