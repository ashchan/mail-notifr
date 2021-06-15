//
//  GNApplicationController.h
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

import Cocoa
import SwiftUI
import MASShortcut
import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Gmail // SWIFT_PACKAGE=1 required, see https://github.com/google/google-api-objectivec-client-for-rest/issues/400

//@main
class GNApplicationController: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    @IBOutlet var menu: NSMenu!
    @IBOutlet weak var menuItemCheckAll: NSMenuItem!
    @IBOutlet weak var menuItemComposeMail: NSMenuItem!
    @IBOutlet weak var menuItemPreferences: NSMenuItem!
    @IBOutlet weak var menuItemAbout: NSMenuItem!
    @IBOutlet weak var menuItemQuit: NSMenuItem!

    var statusItem: NSStatusItem!
    var checkers = [GNChecker]()
    var accountMenuControllers = [GNAccountMenuController]()

    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var authorization: GTMAppAuthFetcherAuthorization?
    static let clientID = "270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k.apps.googleusercontent.com"
    static let redirectURL = "com.googleusercontent.apps.270244963224-8viqhtgpdks3vk56ffhvnfn112u4h26k:/oauthredirect"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        statusItem.button!.image = NSImage(named: "NoMailsTemplate")
        statusItem.button!.imagePosition = .imageLeft

        localizeMenuItems()

        GNPreferences.setupDefaults()

        registerObservers()
        registerURLHandler()
        registerNotification()

        setupMenu()
        setupCheckers()

        let contentView = MainView(selection: .constant(nil))

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: GNDefaultsKeyCheckAllShortcut) {
            self.checkAll(nil)
        }
   }

    func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func showAbout(_ sender: AnyObject) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(sender)
    }

    @IBAction func checkAll(_ sender: AnyObject?) {
        checkAllAccounts()
    }

    @IBAction func composeMail(_ sender: AnyObject) {
        let account = GNPreferences.sharedInstance().accounts.firstObject as? GNAccount
        let baseURL = account?.baseUrl() ?? "https://mail.google.com/"
        let url = baseURL + "?view=cm&tf=0&fs=1"
        openURL(url: URL(string: url)!, browserIdentifier: account?.browser ?? "")
    }

    @IBAction func showPreferencesWindow(_ sender: AnyObject) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        GNPreferencesController.shared()?.showWindow(sender)
    }

    @IBAction func showFAQs(_ sender: AnyObject) {
        NSWorkspace.shared.open(URL(string: "http://ashchan.com/projects/gmail-notifr#faqs")!)
    }

    @IBAction func showFeedback(_ sender: AnyObject) {
        NSWorkspace.shared.open(URL(string: "http://blog.ashchan.com/archive/2008/10/29/gmail-notifr-changelog/")!)
    }

    @IBAction func rateOnAppStore(_ sender: AnyObject) {
        NSWorkspace.shared.open(URL(string: "https://itunes.apple.com/app/gmail-notifr/id808154494?ls=1&mt=12")!)
    }

    @objc func checkAccount(_ sender: AnyObject) {
        if let account = accountForGuid(guid: sender.representedObject as! String) {
            checkerForAccount(account: account)?.reset()
        }
    }

    @objc func openInbox(_ sender: AnyObject) {
        let guid = sender.representedObject as! String
        openInboxForAccount(account: accountForGuid(guid: guid)!)

        // Check this account a short while after opening its inbox, so we don't have to check it
        // again manually just to clear the inbox count, since any unread mail is probably read now.
        // This can only be activated by a hidden default.
        let autoCheckInterval = GNPreferences.sharedInstance().autoCheckAfterInboxInterval
        if autoCheckInterval > 0 {
            checkerForGuid(guid: guid)?.check(afterInterval: Int(autoCheckInterval))
        }
    }

    @objc func toggleAccount(_ sender: AnyObject) {
        let account = accountForGuid(guid: sender.representedObject as! String)!
        account.enabled.toggle()
        account.save()

        updateMenuItemAccountEnabled(account: account)
        updateMenu()
    }

    @objc func openMessage(_ sender: AnyObject) {
        openURL(url: URL(string: sender.representedObject as! String)!, browserIdentifier: GNAccount(byMessageLink: sender.representedObject as? String).browser)
    }

    @objc func accountAdded(_ notification: NSNotification) {
        if accountMenuControllers.count == 1 {
            let firstAccountMenuController = accountMenuControllers[0]
            firstAccountMenuController.detach()
            firstAccountMenuController.singleMode = false
            firstAccountMenuController.attach(at: 0, actionTarget: self)
            checkers[0].reset()
        }

        let account = accountForGuid(guid: notification.userInfo!["guid"] as! String)!
        createMenuForAccount(account: account, index: GNPreferences.sharedInstance().accounts.count - 1)

        let checker = GNChecker(account: account)!
        checkers.append(checker)
        checker.reset()

        updateMenu()
    }

    @objc func accountChanged(_ notification: NSNotification) {
        if let account = accountForGuid(guid: notification.userInfo!["guid"] as! String) {
            updateMenuItemAccountEnabled(account: account)
            checkerForAccount(account: account)?.reset()
        }
    }

    @objc func accountRemoved(_ notification: NSNotification) {
        let guid = notification.userInfo!["guid"] as! String
        let menuController = menuController(for: guid)!
        menuController.detach()
        accountMenuControllers.removeAll { c in
            c.guid == menuController.guid
        }
        let checker = checkerForGuid(guid: guid)
        checker?.cleanupAndQuit()
        checkers.removeAll { c in
            c.is(forGuid: guid)
        }

        if accountMenuControllers.count == 1 {
            let singleAccountMenuController = accountMenuControllers[0]
            singleAccountMenuController.detach()
            singleAccountMenuController.singleMode = true
            singleAccountMenuController.attach(at: 0, actionTarget: self)
            checkAll(nil)
        } else {
            updateMenuBarCount(notification)
        }

        updateMenu()
    }

    @objc func accountsReordered(_ notification: NSNotification) {
        var menuControllers = [String: GNAccountMenuController]()
        let accounts = GNPreferences.sharedInstance().accounts as! [GNAccount]
        for account in accounts {
            let controller = menuController(for: account.guid)!
            controller.detach()
            menuControllers[account.guid] = controller
        }

        for (index, account) in accounts.enumerated() {
            menuControllers[account.guid]?.attach(at: index, actionTarget: self)
        }

        checkAll(nil)
    }

    @objc func accountChecking(_ notification: NSNotification) {
        statusItem.button!.toolTip = NSLocalizedString("Checking Mail", comment: "")
    }

    func registerObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateMenuBarCount(_:)), name: NSNotification.Name.GNShowUnreadCountChanged, object: nil)
        center.addObserver(self, selector: #selector(accountAdded(_:)), name: NSNotification.Name.GNAccountAdded, object: nil)
        center.addObserver(self, selector: #selector(accountChanged(_:)), name: NSNotification.Name.GNAccountChanged, object: nil)
        center.addObserver(self, selector: #selector(accountRemoved(_:)), name: NSNotification.Name.GNAccountRemoved, object: nil)
        center.addObserver(self, selector: #selector(updateAccountMenuItem(_:)), name: NSNotification.Name.GNAccountMenuUpdate, object: nil)
        center.addObserver(self, selector: #selector(accountChecking(_:)), name: NSNotification.Name.GNCheckingAccount, object: nil)
        center.addObserver(self, selector: #selector(accountsReordered(_:)), name: NSNotification.Name.GNAccountsReordered, object: nil)
    }

    func registerURLHandler() {
         NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(event:reply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        let url = event.paramDescriptor(forKeyword: keyDirectObject)!.stringValue!

        if url.starts(with: "mailto:") {
            if GNPreferences.sharedInstance().accounts.count > 0 {
                let account = GNPreferences.sharedInstance().accounts[0] as! GNAccount
                let urlComponents = url.split(separator: "?")
                let recipients = urlComponents[0].replacingOccurrences(of: "mailto:", with: "")
                var additionalParameters = ""
                if urlComponents.count > 1 {
                    // For some reason, Gmail does not interpret the query parameter "subject" correctly, and needs "su" instead.
                    additionalParameters = String(format: "&%@", String(urlComponents[1])).replacingOccurrences(of: "subject=", with: "su=")
                }
                let url = "\(account.baseUrl()!)?view=cm&tf=0&fs=1&to=\(recipients)\(additionalParameters)"
                openURL(url: URL(string: url)!, browserIdentifier: account.browser)
            }
        } else {
            // OAuth
            currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: URL(string: url)!)
        }
    }

    func setupMenu() {
        for (index, account) in GNPreferences.sharedInstance().accounts.enumerated() {
            createMenuForAccount(account: account as! GNAccount, index: index)
        }
    }

    func setupCheckers() {
        for account in GNPreferences.sharedInstance().accounts {
            checkers.append(GNChecker(account: account as? GNAccount))
        }

        checkAllAccounts()
    }

    func checkAllAccounts() {
        checkers.forEach { c in
            c.reset()
        }
    }

    func accountForGuid(guid: String) -> GNAccount? {
        (GNPreferences.sharedInstance().accounts as! [GNAccount]).first { $0.guid == guid }
    }

    func checkerForAccount(account: GNAccount) -> GNChecker? {
        checkers.first { $0.is(for: account) }
    }

    func checkerForGuid(guid: String) -> GNChecker? {
        checkers.first { $0.is(forGuid: guid) }
    }

    func messageCount() -> UInt {
        checkers.map({ $0.messageCount() }).reduce(0, +)
    }

    func openInboxForAccount(name: String, browser: String?) {
        let browserIdentier =  browser ?? GNBrowserDefaultIdentifier
        openURL(url: URL(string: GNAccount.baseUrl(forUsername: name))!, browserIdentifier: browserIdentier)
    }

    func openInboxForAccount(account: GNAccount) {
        openInboxForAccount(name: account.username, browser: account.browser)
    }

    func openURL(url: URL, browserIdentifier: String) {
        if GNBrowser.isDefault(browserIdentifier) {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(
                [url],
                withAppBundleIdentifier: browserIdentifier,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifiers: nil
            )
        }
    }
}

// MARK: - Menu Manipulation
extension GNApplicationController {
    func updateMenu() {
        // Update Check All
        let stringToLocalize = GNPreferences.sharedInstance()!.accounts.count <= 1 ? "Check" : "Check All"
        menuItemCheckAll.title = NSLocalizedString(stringToLocalize, comment: "")
        let enabledAccounts = GNPreferences.sharedInstance()!.accounts.filter { a in
            (a as! GNAccount).enabled
        }
        menuItemCheckAll.isEnabled = !enabledAccounts.isEmpty

        // Show disable icon if no accounts enabled
        if (NSAppKitVersion.current > NSAppKitVersion.macOS10_9) {
            statusItem.button!.appearsDisabled = GNPreferences.sharedInstance().allAccountsDisabled
        }
    }

    func localizeMenuItems() {
        updateMenu()
        menuItemComposeMail.title = NSLocalizedString("Compose Mail", comment: "")
        menuItemPreferences.title = NSLocalizedString("Preferences...", comment: "")
        menuItemAbout.title = NSLocalizedString("About Gmail Notifr", comment: "")
        menuItemQuit.title = NSLocalizedString("Quit Gmail Notifr", comment: "")
    }

    func createMenuForAccount(account: GNAccount, index: Int) {
        let menuController = GNAccountMenuController(statusItem: statusItem, gnAccount: account)!
        menuController.singleMode = GNPreferences.sharedInstance().accounts.count == 1
        accountMenuControllers.append(menuController)
        menuController.attach(at: index, actionTarget: self)
    }

    func updateMenuItemAccountEnabled(account: GNAccount) {
        let controller = menuController(for: account.guid)
        controller?.updateStatus()
    }

    @objc func updateAccountMenuItem(_ notification: NSNotification) {
        let account = accountForGuid(guid: notification.userInfo!["guid"] as! String)!
        let menuController = menuController(for: account.guid)
        menuController?.update(with: checkerForAccount(account: account))
        updateMenuBarCount(notification)
    }

    @objc func updateMenuBarCount(_ notification: NSNotification) {
        let messageCount = messageCount()

        if messageCount > 0 && GNPreferences.sharedInstance().showUnreadCount {
            statusItem.button!.title = "\(messageCount)"
        } else {
            statusItem.button!.title = ""
        }

        if messageCount > 0 {
            var toolTipFormat = messageCount == 1 ? NSLocalizedString("Unread Message", comment: "") : NSLocalizedString("Unread Messages", comment: "")
#warning ("This is duplication. See GNChecker#processResult")
            if NSLocale.current.languageCode == "ru" {
                let count = messageCount % 100
                if (count % 10 > 4) || (count % 10 == 0) || (count > 10 && count < 15) {
                    toolTipFormat = NSLocalizedString("Unread Messages", comment: "")
                } else if count % 10 == 1 {
                    toolTipFormat = NSLocalizedString("Unread Message", comment: "")
                } else {
                    toolTipFormat = NSLocalizedString("Unread Messages 2", comment: "")
                }
            }

            statusItem.button!.toolTip = String(format: toolTipFormat, messageCount)
            statusItem.button!.image = NSImage(named: "HaveMailsTemplate")
        } else {
            statusItem.button!.toolTip = ""
            statusItem.button!.image = NSImage(named: "NoMailsTemplate")
        }
    }

    func menuController(for guid: String) -> GNAccountMenuController? {
        accountMenuControllers.first { $0.guid == guid }
    }
}

extension GNApplicationController: NSUserNotificationCenterDelegate {
    func registerNotification() {
        NSUserNotificationCenter.default.delegate = self
    }

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        openInboxForAccount(name: notification.title!, browser: GNAccount(byUsername: notification.title).browser)
        for noti in center.deliveredNotifications {
            if noti.title == notification.title {
                center.removeDeliveredNotification(noti)
            }
        }
    }
}

// MARK: - Google OAuth
extension GNApplicationController {
    func authorize() {
        let request = OIDAuthorizationRequest(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: Self.clientID,
            scopes: [OIDScopeEmail, "https://www.googleapis.com/auth/gmail.readonly"],
            redirectURL: URL(string: Self.redirectURL)!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request) { state, error in
            if let state = state {
                self.authorization = GTMAppAuthFetcherAuthorization(authState: state)
                // TODO: this is for experiment only
           }
        }
    }
}
