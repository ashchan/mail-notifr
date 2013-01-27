//
//  PrefsAccountsViewController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import "PrefsAccountsViewController.h"
#import "GNPreferences.h"
#import "GNAccount.h"
#import "GNAccountDetailController.h"

@interface PrefsAccountsViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSButton *editButton;
@property (weak) IBOutlet NSTableView *accountList;

@end

NSString *const PBOARD_DRAG_TYPE = @"GNDragType";

@implementation PrefsAccountsViewController

- (id)init {
    if (self = [super initWithNibName:@"PreferencesAccounts" bundle:nil]) {
    }

    return self;
}

- (NSString *)title {
    return NSLocalizedString(@"Accounts", nil);
}

- (NSImage *)image {
    return [NSImage imageNamed:@"NSUserAccounts"];
}

- (NSString *)identifier {
    return PrefsToolbarItemAccounts;
}

- (void)loadView {
    [super loadView];
    [self registerObservers];

    [self.editButton setTitle:NSLocalizedString(@"Edit", nil)];
    [self.accountList setTarget:self];
    [self.accountList setDoubleAction:@selector(startEditingAccount:)];
    [self.accountList registerForDraggedTypes:@[PBOARD_DRAG_TYPE]];
    [self forceRefresh];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self accounts] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < [[self accounts] count]) {
        GNAccount *account = [self accounts][row];
        if ([tableColumn.identifier isEqualToString:@"AccountName"]) {
            return account.username;
        } else if ([tableColumn.identifier isEqualToString:@"EnableStatus"]) {
            return @(account.enabled);
        }
    }

    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualToString:@"EnableStatus"] && row < [[self accounts] count]) {
        GNAccount *account = [self accounts][row];
        account.enabled = [object boolValue];
        [account save];
    }
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:@[PBOARD_DRAG_TYPE] owner:self];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:PBOARD_DRAG_TYPE];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    if (dropOperation == NSTableViewDropAbove) {
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSData *rowData = [[info draggingPasteboard] dataForType:PBOARD_DRAG_TYPE];
    NSUInteger oldRow = [[NSKeyedUnarchiver unarchiveObjectWithData:rowData] firstIndex];
    [[GNPreferences sharedInstance] moveAccountFromRow:oldRow toRow:row];
    [tableView reloadData];

    return YES;
}

// NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self forceRefresh];
}

// Button Actions

- (IBAction)startAddingAccount:(id)sender {
    GNAccount *account = [[GNAccount alloc] initWithUsername:@"username" interval:0 enabled:YES growl:YES sound:nil browser:nil];
    [GNAccountDetailController editAccount:account onWindow:[[[self view] superview] window]];
}

- (void)endAddingAccount:(id)sender {
    [self forceRefresh];
    NSUInteger index = [[self accounts] count] - 1;
    [self.accountList selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self.accountList scrollRowToVisible:index];
 }

- (IBAction)removeAccount:(id)sender {
    if ([self currentAccount]) {
        [[GNPreferences sharedInstance] removeAccount:[self currentAccount]];
        [self forceRefresh];
    }
}

- (IBAction)startEditingAccount:(id)sender {
    if ([self currentAccount]) {
        [GNAccountDetailController editAccount:[self currentAccount] onWindow:[[[self view] superview] window]];
    }
}

- (void)endEditingAccount:(id)sender {
    [self forceRefresh];
}

#pragma mark - Private Methods

- (NSArray *)accounts {
    return [GNPreferences sharedInstance].accounts;
}

- (GNAccount *)currentAccount {
    if (self.accountList.selectedRow > -1) {
        return self.accounts[self.accountList.selectedRow];
    } else {
        return nil;
    }
}

- (void)forceRefresh {
    [self.accountList reloadData];
    self.removeButton.enabled = self.editButton.enabled = [self currentAccount] != nil;
}

- (void)registerObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endAddingAccount:) name:GNAccountAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingAccount:) name:GNAccountChangedNotification object:nil];
}
     
@end
