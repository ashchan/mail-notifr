//
//  MailNotifrApp.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/15.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import AppKit
import SwiftUI

@main
struct MailNotifrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage(Accounts.storageKey) var accounts = Accounts()
    @State var screen: String?

    var body: some Scene {
        WindowGroup {
            MainView(selection: $screen)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .onOpenURL { url in
                    if url.absoluteString.starts(with: "mailnotifr") {
                        screen = url.host
                    } else if url.absoluteString.starts(with: OAuthClient.redirectURL) {
                        OAuthClient.shared.resumeAuthFlow(url: url)
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
