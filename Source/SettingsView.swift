//
//  SettingsView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/18.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @AppStorage(AppSettings.showUnreadCount) var showUnreadCount = AppSettings.shared.showUnreadCount

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.largeTitle)
 
            HStack {
                Toggle(isOn: $launchAtLogin.isEnabled) {
                    Text("Launch at login")
                }
                Spacer()
            }
            HStack {
                Toggle(isOn: $showUnreadCount) {
                    Text("Show unread count in menu bar")
                }
                .onChange(of: showUnreadCount) { newValue in
                    AppSettings.shared.showUnreadCountSettingChanged()
                }
                Spacer()
            }

            Divider()

            Text("Shortcuts")
                .font(.title)

            VStack(alignment: .trailing) {
                HStack(alignment: .firstTextBaseline, spacing: 15) {
                    Text("Check All Mails")
                        .frame(alignment: .trailing)
                    KeyboardShortcuts.Recorder(for: .checkAllMails)
                }

                HStack(alignment: .firstTextBaseline, spacing: 15) {
                    Text("Compose Mail")
                        .frame(alignment: .trailing)
                    KeyboardShortcuts.Recorder(for: .composeMail)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color("Background"))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
