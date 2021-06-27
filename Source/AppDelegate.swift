//
//  AppDelegate.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppKit
import Combine
import UserNotifications
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var subscriptions = Set<AnyCancellable>()
    private var fetchers: [String: MessageFetcher] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerShortCuts()
        subscribe()

        setupStatusItem()
        updateFetchers()

        if Accounts.hasAccounts {
            NSApp.windows.first?.orderOut(nil)
        } else {
            showInDock()
        }

        setupUserNotification()
    }

    func openURL(url: URL, in browser: Browser?) {
        if let browser = browser, !browser.isDefault {
            NSWorkspace.shared.open(
                [url],
                withAppBundleIdentifier: browser.identifier,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifiers: nil
            )
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension AppDelegate {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button!.image = NSImage(named: "NoMailsTemplate")
        statusItem.button!.imagePosition = .imageLeft

        menu = createMenu()
        statusItem.menu = menu
    }

    func subscribe() {
        NotificationCenter.default
            .publisher(for: .accountsChanged)
            .sink { _ in
                self.updateFetchers()
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: .showUnreadCountSettingChanged)
            .sink { _ in
                self.updateStatusItem()
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: .unreadCountUpdated)
            .sink { _ in
                self.updateMenu(self.menu)
                self.updateStatusItem()
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: .messagesFetched)
            .sink { notification in
                self.messagesFetched(notification)
            }
            .store(in: &subscriptions)
    }

    func updateFetchers() {
        let accounts = Accounts.default.enabled
 
        // Remove unused fetchers
        for email in fetchers.keys {
            if !accounts.contains(where: { $0.email == email }) {
                fetchers[email]?.cleanUp()
                fetchers[email] = nil
            }
        }

        // Add new fetchers
        for account in accounts {
            if fetchers[account.email] == nil {
                fetchers[account.email] = MessageFetcher(account: account)
            }
        }

        fetchers.values.forEach { $0.fetch() }

        updateMenu(menu)
        updateStatusItem()
    }

    func updateStatusItem() {
        let messagesCount = fetchers.values
            .map({ $0.unreadMessagesCount })
            .reduce(0, +)

        if messagesCount > 0 && AppSettings.shared.showUnreadCount {
            statusItem.button!.title = "\(messagesCount)"
        } else {
            statusItem.button!.title = ""
        }

        if messagesCount > 0 {
            let toolTipFormat = messagesCount == 1 ? NSLocalizedString("Unread Message", comment: "") : NSLocalizedString("Unread Messages", comment: "")
            statusItem.button!.toolTip = String(format: toolTipFormat, messagesCount)
            statusItem.button!.image = NSImage(named: "HaveMailsTemplate")
        } else {
            statusItem.button!.toolTip = ""
            statusItem.button!.image = NSImage(named: "NoMailsTemplate")
        }

        statusItem.button!.appearsDisabled = Accounts.default.enabled.isEmpty
    }
}

// MARK: - Show/hide in Dock
private extension AppDelegate {
    func showInDock() {
        NSApp.setActivationPolicy(.regular)

        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.activate(options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(200)) {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Commands
extension AppDelegate {
    private func email(from sender: Any) -> String? {
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as? String
        }
        return nil
    }

    private func account(from email: String?) -> Account? {
        if let email = email {
            return Accounts.default.find(email: email)
        }
        return nil
    }

    func fetcher(for email: String?) -> MessageFetcher? {
        fetchers[email ?? ""]
    }

    private func openMessage(messageId: String, email: String) {
        guard let account = account(from: email) else {
            return
        }

        // TODO: construct message URL
        openURL(url: URL(string: account.baseUrl)!, in: account.browser)
    }

    @objc func checkAllMails() {
        fetchers.values.forEach { $0.fetch() }
    }

    @objc func composeMail() {
        let account = Accounts.default.first
        let baseURL = account?.baseUrl ?? "https://mail.google.com/"
        let url = baseURL + "?view=cm&tf=0&fs=1"
        openURL(url: URL(string: url)!, in: account?.browser)
    }

    @objc func openInbox(_ sender: Any) {
        guard let account = account(from: email(from: sender)) else {
            return
        }
        openURL(url: URL(string: account.baseUrl)!, in: account.browser)
    }

    @objc func checkMails(_ sender: Any) {
        guard let account = account(from: email(from: sender)) else {
            return
        }
        fetcher(for: account.email)?.fetch()
    }

    @objc func openMessage(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem,
           let message = menuItem.representedObject as? Message else {
            return
        }
        openMessage(messageId: message.id, email: message.email)
    }

    @objc func toggleAccount(_ sender: Any) {
        guard var account = account(from: email(from: sender)) else {
            return
        }
        account.enabled.toggle()
        Accounts.default.update(account: account)
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc func showPreferences() {
        NSWorkspace.shared.open(URL(string: "mailnotifr://preferences")!)
    }
}

extension AppDelegate:  UNUserNotificationCenterDelegate {
    func setupUserNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { [weak self] granted, error in
            if error == nil && granted {
                UNUserNotificationCenter.current().delegate = self
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
        let userInfo = response.notification.request.content.userInfo
        if let messageId = userInfo["messageId"] as? String,
           let email = userInfo["email"] as? String {
            openMessage(messageId: messageId, email: email)
        }
        completionHandler()
    }

    func delilverNotifications(for messages: [Message]) {
        // TODO: better filter: should NOT send notification for any messages that been sent already
        UNUserNotificationCenter.current().getDeliveredNotifications { requests in
            let deliveredIds = requests.map { $0.request.identifier }
            for msg in messages.filter({ !deliveredIds.contains($0.id) }) {
               let content = UNMutableNotificationContent()
                content.title = msg.sender
                content.subtitle = msg.subject
                content.body = msg.snippet
                content.userInfo = [
                    "messageId": msg.id,
                    "email": msg.email
                ]
                content.threadIdentifier = msg.email

                let request = UNNotificationRequest(identifier: msg.id, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request) { _ in
                }
            }
        }
    }

    func messagesFetched(_ notification: Notification) {
        updateMenu(menu)

        let email = notification.object as? String ?? ""
        guard let account = account(from: email), account.enabled else {
            return
        }

        if let sound = account.sound {
            sound.nsSound?.play()
        }

        if !account.notificationEnabled {
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                    (settings.authorizationStatus == .provisional) else {
                        return
                    }

            if settings.alertSetting != .enabled {
                return
            }

            if let fetcher = self.fetcher(for: email) {
                self.delilverNotifications(for: fetcher.messages)
            }
        }
    }
}


// MARK: - Shortcuts
extension KeyboardShortcuts.Name {
    static let checkAllMails = Self("checkAllMails")
    static let composeMail = Self("composeMail")
}

private extension AppDelegate {
    func registerShortCuts() {
        KeyboardShortcuts.onKeyUp(for: .checkAllMails) { [self] in
            checkAllMails()
        }
        KeyboardShortcuts.onKeyUp(for: .composeMail) { [self] in
            composeMail()
        }
    }
}
