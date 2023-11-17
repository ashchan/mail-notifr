//
//  MailNotifrApp.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppKit
import SwiftUI
import LaunchAtLogin

extension Notification.Name {
    static let mailToReceived = Notification.Name("mailToReceived")
}

@main
struct MailNotifrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var screen: String?

    init() {
        LaunchAtLogin.migrateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            MainView(selection: $screen)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .onOpenURL { url in
                    if url.absoluteString.starts(with: "mailnotifr") {
                        screen = url.host
                    } else if url.absoluteString.starts(with: OAuthClient.redirectURL) {
                        OAuthClient.shared.resumeAuthFlow(url: url)
                    } else if url.scheme == "mailto" {
                        NotificationCenter.default.post(name: .mailToReceived, object: url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
                    }
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands()
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Preferences...") {
                    screen = "preferences"
                }.keyboardShortcut(",", modifiers: [.command])
            }
            CommandGroup(replacing: .newItem, addition: {})
        }
    }
}
