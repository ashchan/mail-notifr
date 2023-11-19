//
//  AppDelegate+Menu.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/21.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppKit

private enum MenuItemTag: Int {
    case checkAllMenuItem
    case separatorBelowComposeItem
    case separatorAboveAboutItem
}

extension AppDelegate {
    func createMenu() -> NSMenu {
        let menu = NSMenu()

        let checkAllMenuItem = NSMenuItem(title: NSLocalizedString("Check", comment: ""), action: #selector(checkAllMails), keyEquivalent: "")
        checkAllMenuItem.tag = MenuItemTag.checkAllMenuItem.rawValue
        menu.addItem(checkAllMenuItem)
        menu.addItem(withTitle: NSLocalizedString("Compose Mail", comment: ""), action: #selector(composeMail), keyEquivalent: "")

        let separatorBelowComposeItem = NSMenuItem.separator()
        separatorBelowComposeItem.tag = MenuItemTag.separatorBelowComposeItem.rawValue
        menu.addItem(separatorBelowComposeItem)

        let separatorAboveAboutItem = NSMenuItem.separator()
        separatorAboveAboutItem.tag = MenuItemTag.separatorAboveAboutItem.rawValue
        menu.addItem(separatorAboveAboutItem)

        menu.addItem(withTitle: NSLocalizedString("About Mail Notifr", comment: ""), action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("Preferences...", comment: ""), action: #selector(showPreferences), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: NSLocalizedString("Quit Mail Notifr", comment: ""), action: #selector(NSApp.terminate(_:)), keyEquivalent: "")

        return menu
    }

    func updateMenu(_ menu: NSMenu) {
        let checkAllMenuItem = menu.item(withTag: MenuItemTag.checkAllMenuItem.rawValue)!
        checkAllMenuItem.title = NSLocalizedString(Accounts.default.count > 1 ? "Check All" : "Check", comment: "")
        checkAllMenuItem.action = Accounts.default.enabled.isEmpty ? nil : #selector(checkAllMails)

        let indexBelowComposeItem = menu.indexOfItem(withTag: MenuItemTag.separatorBelowComposeItem.rawValue)
        let indexAboveAboutItem = menu.indexOfItem(withTag: MenuItemTag.separatorAboveAboutItem.rawValue)
        for index in ((indexBelowComposeItem + 1)..<indexAboveAboutItem).reversed() {
            menu.removeItem(at: index)
        }

        var offset = indexBelowComposeItem + 1
        if Accounts.default.count > 1 {
            for account in Accounts.default {
                menu.insertItem(createSubmenu(for: account), at: offset)
                offset += 1
            }
        } else {
            for item in createMenuItems(for: Accounts.default.first) {
                menu.insertItem(item, at: offset)
                offset += 1
            }
        }
    }
}

private extension AppDelegate {
    static var lastCheckedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd HH:mm"
        return formatter
    }()

    // When there're multiple accounts each sits in its own submenu.
    func createSubmenu(for account: Account) -> NSMenuItem {
        let menu = NSMenu()
        let result = NSMenuItem(title: account.email, action: #selector(openInbox(_:)), keyEquivalent: "")
        result.representedObject = account.email
        result.submenu = menu

        menu.addItem(withTitle: NSLocalizedString("Open Inbox", comment: ""), action: #selector(openInbox(_:)), keyEquivalent: "")
        let checkMailsItem = NSMenuItem(
            title: NSLocalizedString("Check", comment: ""),
            action: account.enabled ? #selector(checkMails(_:)) : nil,
            keyEquivalent: ""
        )
        menu.addItem(checkMailsItem)
        menu.addItem(NSMenuItem.separator())

        if let fetcher = fetcher(for: account.email), account.enabled {
            if fetcher.unreadMessagesCount > 0 {
                result.title = "\(account.email) (\(fetcher.unreadMessagesCount))"
            }

            if fetcher.hasAuthError {
                menu.addItem(
                    NSMenuItem(
                        title: NSLocalizedString("🚫 Auth error, please reauthroize.", comment: ""),
                        action: #selector(reauthorize),
                        keyEquivalent: ""
                    )
                )
            }

            for message in (fetcher.messages) {
                let messageItem = NSMenuItem(title: "\(message.sender): \(message.subject)", action: #selector(openMessage(_:)), keyEquivalent: "")
                messageItem.representedObject = message
                messageItem.toolTip = message.decodedSnippet
                menu.addItem(messageItem)
            }

            menu.addItem(NSMenuItem.separator())

            let lastChecked: String
            if #available(macOS 12.0, *) {
                lastChecked = fetcher.lastCheckedAt.formatted()
            } else {
                let lastCheckedDate = fetcher.lastCheckedAt
                lastChecked = Self.lastCheckedDateFormatter.string(from: lastCheckedDate)
            }
            menu.addItem(
                NSMenuItem(
                    title: NSLocalizedString("Last Checked:", comment: "") + " " + lastChecked,
                    action: nil,
                    keyEquivalent: ""
                )
            )
        }

        menu.addItem(
            withTitle: NSLocalizedString(account.enabled ? "Disable Account" : "Enable Account", comment: ""),
            action: #selector(toggleAccount(_:)),
            keyEquivalent: ""
        )

        for item in menu.items.filter({ !$0.isSeparatorItem && $0.representedObject == nil }) {
            item.representedObject = account.email
        }

        return result
    }

    // When there's only one account its menu items are in the middle of the top level item menu.
    func createMenuItems(for account: Account?) -> [NSMenuItem] {
        guard let account = account else {
            return []
        }

        var items = [NSMenuItem]()
        items.append(NSMenuItem(title: NSLocalizedString("Open Inbox", comment: ""), action: #selector(openInbox(_:)), keyEquivalent: ""))
        items.append(NSMenuItem.separator())

        if let fetcher = fetcher(for: account.email), account.enabled {
            if fetcher.hasAuthError {
                items.append(
                    NSMenuItem(
                        title: NSLocalizedString("🚫 Auth error, please reauthroize.", comment: ""),
                        action: #selector(reauthorize),
                        keyEquivalent: ""
                    )
                )
            }

            for message in (fetcher.messages) {
                let messageItem = NSMenuItem(title: "\(message.sender): \(message.subject)", action: #selector(openMessage(_:)), keyEquivalent: "")
                messageItem.representedObject = message
                messageItem.toolTip = message.decodedSnippet
                items.append(messageItem)
            }

            let lastChecked: String
            if #available(macOS 12.0, *) {
                lastChecked = fetcher.lastCheckedAt.formatted()
            } else {
                let lastCheckedDate = fetcher.lastCheckedAt
                lastChecked = Self.lastCheckedDateFormatter.string(from: lastCheckedDate)
            }
            items.append(
                NSMenuItem(
                    title: NSLocalizedString("Last Checked:", comment: "") + " " + lastChecked,
                    action: nil,
                    keyEquivalent: ""
                )
            )

            items.append(NSMenuItem.separator())
        }

        items.append(
            NSMenuItem(
                title: NSLocalizedString(account.enabled ? "Disable Account" : "Enable Account", comment: ""),
                action: #selector(toggleAccount(_:)),
                keyEquivalent: ""
            )
        )
        items.append(NSMenuItem.separator())

        for item in items.filter({ !$0.isSeparatorItem && $0.representedObject == nil }) {
            item.representedObject = account.email
        }

        return items
    }
}
