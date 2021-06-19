//
//  SettingsView.swift
//  Mail Notifr
//
//  Created by James Chen on 2021/06/18.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @AppStorage(AppSettings.showUnreadCount) var showUnreadCount = true

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
                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color.white)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
