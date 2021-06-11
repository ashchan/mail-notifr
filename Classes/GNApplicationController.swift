//
//  GNApplicationController.h
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

import Cocoa

@main
class GNApplicationController: NSObject, NSApplicationDelegate {
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var menuItemCheckAll: NSMenuItem!
    @IBOutlet weak var menuItemComposeMail: NSMenuItem!
    @IBOutlet weak var menuItemPreferences: NSMenuItem!
    @IBOutlet weak var menuItemAbout: NSMenuItem!
    @IBOutlet weak var menuItemQuit: NSMenuItem!
    @IBOutlet weak var menuItemRate: NSMenuItem!
    var statusItem: NSStatusItem!
    var _checkers = [Any]()
    var _accountMenuControllers = [Any]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.highlightMode = true
        statusItem.menu = menu
        statusItem.image = NSImage(named: "NoMailsTemplate")

        /*
        [self localizeMenuItems];


        [GNPreferences setupDefaults];

        [self registerObservers];

        [self registerMailtoHandler];

        [self registerNotification];

        [self setupMenu];

        [self setupCheckers];

        [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:GNDefaultsKeyCheckAllShortcut toAction:^{
            [self checkAll:nil];
        }];
        */
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func showAbout(_ sender: AnyObject) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(sender)
    }

    @IBAction func checkAll(_ sender: AnyObject) {
        //[self checkAllAccounts];
    }

    @IBAction func composeMail(_ sender: AnyObject) {
        /*
        GNAccount *account = [GNPreferences sharedInstance].accounts.firstObject;
        NSString *baseURL = account ? [account baseUrl] : @"https://mail.google.com/";
        NSString *url = [baseURL stringByAppendingString:@"?view=cm&tf=0&fs=1"];
        [self openURL:[NSURL URLWithString:url] withBrowserIdentifier:account.browser];
         */
    }

    @IBAction func showPreferencesWindow(_ sender: AnyObject) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        GNPreferencesController.shared()?.showWindow(sender)
    }
}

extension GNApplicationController: NSUserNotificationCenterDelegate {
    // TODO
}
