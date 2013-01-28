//
//  GNApplicationController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import "GNApplicationController.h"
#import "GNPreferences.h"

@interface GNApplicationController ()

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
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _appIcon        = [NSImage imageNamed:@"app"];
    _appAltIcon     = [NSImage imageNamed:@"app_a"];
    _mailIcon       = [NSImage imageNamed:@"mail"];
    _mailAltIcon    = [NSImage imageNamed:@"mail_a"];
    _checkIcon      = [NSImage imageNamed:@"check"];
    _checkAltIcon   = [NSImage imageNamed:@"check_a"];
    _errorIcon      = [NSImage imageNamed:@"error"];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setMenu:self.menu];

    [self localizeMenuItems];
    
    [self.statusItem setImage:_appIcon];
    [self.statusItem setAlternateImage:_appAltIcon];

    [GNPreferences setupDefaults];
    
    /*
    registerObservers
    
    registerMailtoHandler
    
    registerGrowl
    
    setupMenu
    
    setupCheckers*/
}

- (IBAction)showAbout:(id)sener {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sener];
}

- (IBAction)checkAll:(id)sener {
    //todo
}

- (IBAction)showPreferencesWindow:(id)sener {
    //todo
}

- (IBAction)donate:(id)sener {
    //todo
}

/*
 
 GNShowUnreadCountChangedNotification = "GNShowUnreadCountChanged"
 GNAccountAddedNotification = "GNAccountAddedNotification"
 GNAccountRemovedNotification = "GNAccountRemovedNotification"
 GNAccountChangedNotification = "GNAccountChangedNotification"
 GNAccountMenuUpdateNotification = "GNAccountMenuUpdateNotification"
 GNCheckingAccountNotification = "GNCheckingAccountNotification"
 GNAccountsReorderedNotification = "GNAccountsReorderedNotification"
 
 SOUND_NONE = "None"
 DEFAULT_BROWSER_IDENTIFIER = "default"
 
 class ApplicationController
 KInternetEventClass = KAEGetURL = 'GURL'.unpack('N').first
 KeyDirectObject = '----'.unpack('N').first
 
 ACCOUNT_MENUITEM_POS = 2
 CHECK_MENUITEM_POS = 1
 ENABLE_MENUITEM_POS = 2
 DEFAULT_ACCOUNT_SUBMENU_COUNT = 4
 DONATE_URL = "http://www.pledgie.com/campaigns/2046"
 
 
 def openInbox(sender)
 if sender.title == NSLocalizedString("Open Inbox")
 # "Open Inbox" menu item
 account = accountForGuid(sender.menu.title)
 else
 # top menu item for account
 account = accountForGuid(sender.submenu.title)
 end
 openInboxForAccount(account)
 end
 
 def toggleAccount(sender)
 account = accountForGuid(sender.menu.title)
 account.enabled = !account.enabled
 account.save
 
 updateMenuItemAccountEnabled(account)
 checkerForAccount(account).reset
 end
 
 def openURL(url, browserIdentifier = DEFAULT_BROWSER_IDENTIFIER)
 nsurl = NSURL.URLWithString(url)
 unless GNBrowser.isDefault(browserIdentifier)
 NSWorkspace.sharedWorkspace.openURLs([nsurl],
 withAppBundleIdentifier: browserIdentifier,
 options: NSWorkspaceLaunchDefault,
 additionalEventParamDescriptor:nil,
 launchIdentifiers:nil)
 else
 NSWorkspace.sharedWorkspace.openURL(nsurl)
 end
 end
 
 def openMessage(sender)
 openURL(sender.representedObject, GNAccount.accountByMessageLink(sender.representedObject).browser)
 end
 
 def checkAll(sender)
 checkAllAccounts
 end
 
 def checkAccount(sender)
 account = accountForGuid(sender.menu.title)
 checkerForAccount(account).reset
 end
 
 def showPreferencesWindow(sender)
 NSApplication.sharedApplication.activateIgnoringOtherApps(true)
 GNPreferencesController.sharedController.showWindow(sender)
 end
 
 def donate(sender)
 NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(DONATE_URL))
 end
 
 def updateMenuBarCount(notification = nil)
 msgCount = messageCount
 if GNPreferences.sharedInstance.showUnreadCount == 1 && msgCount > 0
 @status_item.setTitle(msgCount.to_s)
 else
 @status_item.setTitle('')
 end
 
 if msgCount > 0
 if NSLocale.currentLocale.objectForKey(NSLocaleLanguageCode) == "ru"
 count = msgCount % 100
 if ((count % 10 > 4) || (count % 10 == 0) || ((count > 10) && (count < 15)))
 toolTipText = NSLocalizedString("Unread Messages") % msgCount
 elsif (count % 10 == 1)
 toolTipText = NSLocalizedString("Unread Message") % msgCount
 else
 toolTipText = NSLocalizedString("Unread Messages 2") % msgCount
 end
 else
 toolTipText = (msgCount == 1 ? NSLocalizedString("Unread Message") % msgCount :
 NSLocalizedString("Unread Messages") % msgCount)
 end
 @status_item.setToolTip(toolTipText)
 @status_item.setImage(@mail_icon)
 @status_item.setAlternateImage(@mail_alter_icon)
 else
 @status_item.setToolTip("")
 @status_item.setImage(@app_icon)
 @status_item.setAlternateImage(@app_alter_icon)
 end
 end
 
 def accountAdded(notification)
 account = accountForGuid(notification.userInfo[:guid])
 createMenuForAccount(account, GNPreferences.sharedInstance.accounts.count - 1)
 checker = GNChecker.alloc.initWithAccount(account)
 @checkers << checker
 checker.reset
 end
 
 def accountChanged(notification)
 account = accountForGuid(notification.userInfo[:guid])
 updateMenuItemAccountEnabled(account)
 checkerForAccount(account).reset
 end
 
 def accountRemoved(notification)
 item = menuItemForGuid(notification.userInfo[:guid])
 @status_item.menu.removeItem(item)
 checker = checkerForGuid(notification.userInfo[:guid])
 checker.cleanupAndQuit
 @checkers.delete(checker)
 updateMenuBarCount
 end
 
 def accountsReordered(notification)
 menuItems = {}
 # Remove all existing account menus but hold on to them
 GNPreferences.sharedInstance.accounts.each do |account|
 menuItem = menuItemForGuid(account.guid)
 @status_item.menu.removeItem(menuItem)
 menuItems[account.guid] = menuItem
 end
 # Now add them back in the order of the accounts array
 i = 0
 GNPreferences.sharedInstance.accounts.each do |account|
 addAccountMenuItem(menuItems[account.guid], i)
 i += 1
 end
 end
 
 def accountChecking(notification)
 #account = accountForGuid(notification.userInfo[:guid])
 @status_item.setToolTip(NSLocalizedString("Checking Mail"))
 @status_item.setImage(@check_icon)
 @status_item.setAlternateImage(@check_alter_icon)
 end
 
 def updateAccountMenuItem(notification)
 account = accountForGuid(notification.userInfo[:guid])
 menuItem = menuItemForAccount(account)
 menuItem.title = account.username
 
 count = menuItem.submenu.itemArray.count
 if count > DEFAULT_ACCOUNT_SUBMENU_COUNT
 (count - 1).downto(DEFAULT_ACCOUNT_SUBMENU_COUNT) { |idx| menuItem.submenu.removeItemAtIndex(idx) }
 end
 
 if account.enabled
 checker = checkerForAccount(account)
 
 if checker.hasConnectionError == 1
 errorItem = menuItem.submenu.addItemWithTitle(NSLocalizedString("Connection Error"), action:nil, keyEquivalent:"")
 errorItem.enabled = false
 menuItem.setImage(@error_icon)
 elsif checker.hasUserError == 1
 errorItem = menuItem.submenu.addItemWithTitle(NSLocalizedString("Username/password Wrong"), action:nil, keyEquivalent:"")
 errorItem.enabled = false
 menuItem.setImage(@error_icon)
 else
 # messages list
 checker.messages.each do |msg|
 msgItem = menuItem.submenu.addItemWithTitle("#{msg[:author]}: #{msg[:subject]}", action:"openMessage:", keyEquivalent:"")
 msgItem.toolTip = msg[:summary]
 msgItem.enabled = true
 msgItem.setRepresentedObject(msg[:link])
 msgItem.target = self
 end
 menuItem.setImage(nil)
 menuItem.title = "#{account.username} (#{checker.messageCount})"
 end
 
 menuItem.submenu.addItem(NSMenuItem.separatorItem) if checker.messages.size > 0
 # recent check timestamp
 timeItem = menuItem.submenu.addItemWithTitle(NSLocalizedString("Last Checked:") + " #{notification.userInfo[:checkedAt]}", action:nil, keyEquivalent:"")
 timeItem.enabled = false
 end
 
 updateMenuBarCount
 end
 
 # Growl delegate
 def applicationNameForGrowl
 "Gmail Notifr"
 end
 
 def growlNotificationWasClicked(clickContext)
 openInboxForAccountName(clickContext, GNAccount.accountByUsername(clickContext).browser) if clickContext
 end
 
 def growlNotificationTimedOut(clickContext)
 end
 
 def handleMailToEvent(event, eventReply:reply)
 account = GNPreferences.sharedInstance.accounts.first
 if account
 link = event.paramDescriptorForKeyword(KeyDirectObject).stringValue
 url = account.baseurl << "?view=cm&tf=0&fs=1&to="
 url << link.split('?')[0].gsub(/mailto:/, '')
 url << "&#{link.split('?')[1]}".gsub(/&subject=/, "&su=")
 openURL(url)
 end
 end
 
 private
 
 def registerObservers
 center = NSNotificationCenter.defaultCenter
 [
 ["updateMenuBarCount:", GNShowUnreadCountChangedNotification],
 ["accountAdded:", GNAccountAddedNotification],
 ["accountChanged:", GNAccountChangedNotification],
 ["accountRemoved:", GNAccountRemovedNotification],
 ["updateAccountMenuItem:", GNAccountMenuUpdateNotification],
 ["accountChecking:", GNCheckingAccountNotification],
 ["accountsReordered:", GNAccountsReorderedNotification]
 ].each do |item|
 center.addObserver(self, selector:item[0], name:item[1], object:nil)
 end
 end
 
 def registerGrowl
 GrowlApplicationBridge.setGrowlDelegate(self)
 end
 
 def setupCheckers
 @checkers = []
 GNPreferences.sharedInstance.accounts.each do |a|
 @checkers << GNChecker.alloc.initWithAccount(a)
 end
 
 checkAllAccounts
 end
 
 def checkAllAccounts
 @checkers.map(&:reset)
 end
 
 def accountForGuid(guid)
 GNPreferences.sharedInstance.accounts.find { |a| a.guid == guid }
 end
 
 def checkerForAccount(account)
 @checkers.find { |c| c.isForAccount(account) == 1 }
 end
 
 def checkerForGuid(guid)
 @checkers.find { |c| c.isForGuid(guid) == 1 }
 end
 
 def messageCount
 @checkers.inject(0) { |n, c| n + c.messageCount }
 end
 
 def setupMenu
 GNPreferences.sharedInstance.accounts.each_with_index do |a, i|
 createMenuForAccount(a, i)
 end
 end
 
 def createMenuForAccount(account, index)
 accountMenu = NSMenu.alloc.initWithTitle(account.guid)
 accountMenu.setAutoenablesItems(false)
 
 #open inbox menu item
 openInboxItem = accountMenu.addItemWithTitle(NSLocalizedString("Open Inbox"), action:"openInbox:", keyEquivalent:"")
 openInboxItem.target = self
 openInboxItem.enabled = true
 
 #check menu item
 checkItem = accountMenu.addItemWithTitle(NSLocalizedString("Check"), action:"checkAccount:", keyEquivalent:"")
 checkItem.target = self
 checkItem.enabled = account.enabled
 
 #enable/disable menu item
 enableAccountItem = accountMenu.addItemWithTitle(
 account.enabled ? NSLocalizedString("Disable Account") : NSLocalizedString("Enable Account"),
 action:"toggleAccount:", keyEquivalent:""
 )
 enableAccountItem.target = self
 enableAccountItem.enabled = true
 
 accountMenu.addItem(NSMenuItem.separatorItem)
 
 #top level menu item for acount
 accountItem = NSMenuItem.alloc.init
 accountItem.title = account.username
 accountItem.submenu = accountMenu
 accountItem.target = self
 accountItem.action = 'openInbox:'
 
 addAccountMenuItem(accountItem, index)
 end
 
 def addAccountMenuItem(accountItem, index)
 @status_item.menu.insertItem(accountItem, atIndex:ACCOUNT_MENUITEM_POS + index)
 end
 
 def menuItemForAccount(account)
 menuItemForGuid(account.guid)
 end
 
 def menuItemForGuid(guid)
 @status_item.menu.itemArray.find { |i| i.submenu && i.submenu.title == guid }
 end
 
 def updateMenuItemAccountEnabled(account)
 menu = menuItemForAccount(account).submenu
 menu.itemAtIndex(ENABLE_MENUITEM_POS).title = account.enabled ? NSLocalizedString("Disable Account") : NSLocalizedString("Enable Account")
 menu.itemAtIndex(CHECK_MENUITEM_POS).enabled = account.enabled
 end
 
 def openInboxForAccount(account)
 openInboxForAccountName(account.username, account.browser)
 end
 
 def openInboxForAccountName(name, browserIdentifier = DEFAULT_BROWSER_IDENTIFIER)
 openURL(GNAccount.baseUrlForUsername(name), browserIdentifier)
 end
 
 def registerMailtoHandler
 e = NSAppleEventManager.sharedAppleEventManager
 e.setEventHandler(self,
 andSelector:'handleMailToEvent:eventReply:',
 forEventClass:KInternetEventClass,
 andEventID:KAEGetURL
 )
 end
 end

 */

- (void)localizeMenuItems {
    [self.menuItemCheckAll setTitleWithMnemonic:NSLocalizedString(@"Check All", nil)];
    [self.menuItemPreferences setTitleWithMnemonic:NSLocalizedString(@"Preferences...", nil)];
    [self.menuItemCheckUpdate setTitleWithMnemonic:NSLocalizedString(@"Check for Updates...", nil)];
    [self.menuItemAbout setTitleWithMnemonic:NSLocalizedString(@"About Gmail Notifr", nil)];
    [self.menuItemDonate setTitleWithMnemonic:NSLocalizedString(@"Donate...", nil)];
    [self.menuItemQuit setTitleWithMnemonic:NSLocalizedString(@"Quit Gmail Notifr", nil)];
}

@end
