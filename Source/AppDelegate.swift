//
//  AppDelegate.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppKit
import Combine
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        registerShortCuts()
        subscribe()

        if Accounts.hasAccounts {
            NSApp.windows.first?.orderOut(nil)
        } else {
            showInDock()
        }
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
        updateMenu(menu)
        statusItem.menu = menu
    }

    func subscribe() {
        NotificationCenter.default
            .publisher(for: .accountsChanged)
            .sink { _ in
                self.updateMenu(self.menu)
            }
            .store(in: &subscriptions)
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

    @objc func checkAllMails() {
        // TODO
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
        //
    }

    @objc func checkMails(_ sender: Any) {
        guard let account = account(from: email(from: sender)) else {
            return
        }
        //
    }

    @objc func openMessage(_ sender: Any) {
        //
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
